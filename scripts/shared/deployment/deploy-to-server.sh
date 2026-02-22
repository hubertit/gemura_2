#!/bin/bash

# Complete Deployment Script for Gemura to Server
# - Builds frontend locally (avoids OOM on server), uploads backend + web + pre-built .next
# - Uses docker-compose.gemura.prebuilt.yml on server (no Next.js build on server)
#
# DATA SAFETY (do not change):
# - Database lives in named volume devslab_postgres_data. Only the container may be removed when stuck.
# - This script must NEVER run for devlabs-db: "down -v", "down --volumes", or "docker volume rm devslab_postgres_data".
# - Backup runs in Step 0 when PostgreSQL is running; we do not overwrite or delete the DB volume.
#
# Full run can take 20-30 min (upload 5-15 min, server build ~5-10 min). Run in a terminal
# with no timeout so you see "Deployment Complete!" at the end.
#
# Usage (from project root):
#   cd /path/to/gemura2
#   ./scripts/deployment/deploy-to-server.sh
#
# If you see "overlay2 failed to remove root filesystem" / "device or resource busy":
#   1. ssh root@SERVER 'systemctl restart docker' then wait 15s and re-run this script.
#   2. If it persists: ssh root@SERVER 'reboot', wait ~2 min, then re-run.

set -e

# Server credentials: project-local only (scripts/deployment/server-credentials.sh)
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
CREDS_FILE="$SCRIPT_DIR/server-credentials.sh"
[ -f "$CREDS_FILE" ] && source "$CREDS_FILE"
# Optional override from env (e.g. CI or another path)
[ -n "${GEMURA_SERVER_CREDS:-}" ] && [ -f "$GEMURA_SERVER_CREDS" ] && source "$GEMURA_SERVER_CREDS"
SERVER_IP="${SERVER_IP:-209.74.80.195}"
SERVER_USER="${SERVER_USER:-root}"
SERVER_PASS="${SERVER_PASS:-}"
DEPLOY_PATH="/opt/gemura"

if [ -z "$SERVER_PASS" ]; then
    echo "❌ SERVER_PASS not set. Set up project credentials:"
    echo "   1. cp scripts/deployment/server-credentials.sh.example scripts/deployment/server-credentials.sh"
    echo "   2. Edit scripts/deployment/server-credentials.sh and set SERVER_PASS (and optionally SERVER_IP, SERVER_USER)"
    echo "   3. chmod 600 scripts/deployment/server-credentials.sh"
    echo "   Or export SERVER_PASS=your_password before running this script."
    exit 1
fi

# Reduce timeouts on long uploads (keepalive every 30s, allow 6 misses = 3 min)
SSH_OPTS="-o StrictHostKeyChecking=no -o ServerAliveInterval=30 -o ServerAliveCountMax=6 -o ConnectTimeout=15"
SCP_OPTS="-o StrictHostKeyChecking=no -o ServerAliveInterval=30 -o ServerAliveCountMax=6 -o ConnectTimeout=15"

echo "🚀 Starting Gemura Deployment to Server..."
echo "================================================"

# Quick connectivity check (fails fast if network blocks the server)
echo ""
echo "🔌 Checking connectivity to $SERVER_IP..."
if ! sshpass -p "$SERVER_PASS" ssh $SSH_OPTS $SERVER_USER@$SERVER_IP "echo OK" 2>/dev/null; then
  echo "❌ Cannot reach the server. Your network may be blocking access to $SERVER_IP."
  echo "   Try: different Wi‑Fi, mobile hotspot, or VPN. Then run this script again."
  exit 1
fi
echo "   ✅ Server reachable"
echo ""

# Step 0: Set Gemura ports (3007 for backend, 3006 for frontend) on Kwezi server
echo ""
echo "📌 Gemura Port Configuration (Kwezi Server):"
echo "   Backend Port: 3007"
echo "   Frontend Port: 3006"
echo ""

# Check if port 3007 is already running Gemura
if curl -s -o /dev/null -w "%{http_code}" --connect-timeout 2 http://$SERVER_IP:3007/api/health 2>/dev/null | grep -q "200"; then
    echo "✅ Port 3007: Gemura Backend is already running"
    echo "   Will update/redeploy existing deployment"
else
    echo "ℹ️  Port 3007: Will deploy new Gemura Backend"
fi

# Check port 3006 (use SSH_OPTS for keepalive)
result=$(sshpass -p "$SERVER_PASS" ssh $SSH_OPTS $SERVER_USER@$SERVER_IP \
    "netstat -tuln 2>/dev/null | grep -q ':3006 ' || ss -tuln 2>/dev/null | grep -q ':3006 ' || echo 'available'" 2>/dev/null)

if [ "$result" = "available" ]; then
    echo "✅ Port 3006: Available for Gemura Frontend"
else
    echo "⚠️  Port 3006: May be in use, but will proceed (frontend not deployed yet)"
fi

export BACKEND_PORT=3007
export FRONTEND_PORT=3006

# Step 0: Backup database first (before any deployment changes). Read-only; no data loss.
echo ""
echo "💾 Step 0: Backing up production database (if PostgreSQL is running)..."
if sshpass -p "$SERVER_PASS" ssh $SSH_OPTS $SERVER_USER@$SERVER_IP \
    "docker ps --format '{{.Names}}' | grep -qx devslab-postgres" 2>/dev/null; then
  if sshpass -p "$SERVER_PASS" ssh $SSH_OPTS $SERVER_USER@$SERVER_IP \
      "[ -f $DEPLOY_PATH/scripts/deployment/backup-all-databases.sh ]" 2>/dev/null; then
    sshpass -p "$SERVER_PASS" ssh $SSH_OPTS $SERVER_USER@$SERVER_IP \
      "export LC_ALL=C.UTF-8; cd $DEPLOY_PATH && mkdir -p backups && bash scripts/deployment/backup-all-databases.sh" || \
      echo "   ⚠️  Backup had warnings (continuing)"
    echo "   ✅ Database backup complete"
  else
    echo "   ⏭️  Skipping backup (first deploy, script not on server yet)"
  fi
else
  echo "   ⏭️  Skipping backup (PostgreSQL not running yet - fresh deploy)"
fi

# Step 1: Build frontend locally (avoids OOM on server during Next.js build)
echo ""
echo "🌐 Step 1a: Building frontend locally (prod API URL)..."
( cd "$REPO_ROOT/apps/gemura-web" && NEXT_PUBLIC_API_URL=http://209.74.80.195:3007/api npm run build ) || {
  echo "   ❌ Local frontend build failed. Fix errors and re-run."
  exit 1
}
echo "   ✅ Frontend built (.next/standalone + static)"

# Step 1b: Upload files to server (retry once on connection failure)
echo ""
echo "📤 Step 1b: Uploading files to server..."
echo "   Creating archive (backend + web with pre-built .next + prebuilt compose)..."
( cd "$REPO_ROOT" && COPYFILE_DISABLE=1 tar -czf /tmp/gemura-deploy.tar.gz \
  --exclude='backend/node_modules' --exclude='backend/dist' \
  --exclude='apps/gemura-web/node_modules' --exclude='apps/gemura-web/.next' \
  backend/ apps/gemura-web/ docker/docker-compose.kwezi.yml scripts/ )
echo "   ✅ Archive created ($(du -h /tmp/gemura-deploy.tar.gz 2>/dev/null | cut -f1))."

upload_ok=
for attempt in 1 2; do
  if ! sshpass -p "$SERVER_PASS" ssh $SSH_OPTS $SERVER_USER@$SERVER_IP "mkdir -p $DEPLOY_PATH" 2>/dev/null; then
    [ "$attempt" -eq 1 ] && echo "   ⚠️  Upload failed (network?). Retrying in 15s..." && sleep 15
    continue
  fi
  echo "   Uploading to server (may take 5–15 min depending on connection)..."
  if ! sshpass -p "$SERVER_PASS" scp $SCP_OPTS /tmp/gemura-deploy.tar.gz $SERVER_USER@$SERVER_IP:/tmp/ 2>/dev/null; then
    [ "$attempt" -eq 1 ] && echo "   ⚠️  Upload failed (network?). Retrying in 15s..." && sleep 15
    continue
  fi
  echo "   ✅ Upload done. Extracting on server..."
  extract_err=$(sshpass -p "$SERVER_PASS" ssh $SSH_OPTS $SERVER_USER@$SERVER_IP "cd $DEPLOY_PATH && rm -rf backend web docker-compose.gemura.yml docker-compose.gemura.prebuilt.yml docker-compose.devlabs-db.yml scripts/deployment && tar -xzf /tmp/gemura-deploy.tar.gz 2>&1 && rm /tmp/gemura-deploy.tar.gz" 2>&1)
  if [ $? -ne 0 ]; then
    echo "   ⚠️  Extract failed: $extract_err"
    [ "$attempt" -eq 1 ] && echo "   Retrying upload in 15s..." && sleep 15
    continue
  fi
  upload_ok=1
  break
done
rm -f /tmp/gemura-deploy.tar.gz
if [ -z "$upload_ok" ]; then
  echo "   ❌ Upload failed after 2 attempts. Check network/VPN and re-run."
  exit 1
fi

# Verify compose file on server
echo "   Verifying docker-compose.kwezi.yml on server..."
if ! sshpass -p "$SERVER_PASS" ssh $SSH_OPTS $SERVER_USER@$SERVER_IP "test -f $DEPLOY_PATH/docker/docker-compose.kwezi.yml" 2>/dev/null; then
  echo "   ❌ Server missing docker-compose.kwezi.yml. Re-run from project root: cd $REPO_ROOT && $0"
  exit 1
fi
echo "   ✅ Compose file OK"

# Step 2: Ensure Docker and Kwezi PostgreSQL are running
echo ""
echo "🗄️  Step 2: Ensuring Docker and Kwezi PostgreSQL..."
sshpass -p "$SERVER_PASS" ssh $SSH_OPTS $SERVER_USER@$SERVER_IP 'bash -s' << 'ENDSSH'
export LC_ALL=C.UTF-8
cd /opt/gemura

# Ensure Docker is running
if ! docker info &>/dev/null; then
  echo "   Docker not running. Attempting to start..."
  systemctl start docker 2>/dev/null || service docker start 2>/dev/null || true
  systemctl enable docker 2>/dev/null || true
  sleep 5
  if ! docker info &>/dev/null; then
    echo "   ❌ Cannot connect to Docker."
    exit 1
  fi
fi
echo "   ✅ Docker is running"

# Verify Kwezi PostgreSQL is running
if docker ps | grep -q kwezi-postgres; then
    echo "   ✅ Kwezi PostgreSQL is running"
else
    echo "   ❌ kwezi-postgres not running! Start it first."
    exit 1
fi

# Create Gemura database if not exists
echo "   Ensuring gemura_db exists..."
docker exec kwezi-postgres psql -U kwezi -d postgres -tc "SELECT 1 FROM pg_database WHERE datname = 'gemura_db'" | grep -q 1 || \
docker exec kwezi-postgres psql -U kwezi -d postgres -c "CREATE DATABASE gemura_db;"
echo "   ✅ Database gemura_db ready"
ENDSSH

# Step 3: Build and start Gemura on Kwezi server
echo ""
echo "🔨 Step 3: Building and starting Gemura..."
sshpass -p "$SERVER_PASS" ssh $SSH_OPTS $SERVER_USER@$SERVER_IP << ENDSSH
export LC_ALL=C.UTF-8
cd /opt/gemura

# Get Postgres password from Kwezi
POSTGRES_PASSWORD=\$(grep -E '^POSTGRES_PASSWORD=' /opt/kwezi/.env 2>/dev/null | cut -d= -f2- || echo "KweziPg2025!")

# Create .env file
cat > .env << EOF
DATABASE_URL=postgresql://kwezi:\${POSTGRES_PASSWORD}@kwezi-postgres:5432/gemura_db?schema=public
JWT_SECRET=gemura_jwt_secret_production_2026
JWT_EXPIRES_IN=7d
API_PORT=3007
UI_PORT=3006
NEXT_PUBLIC_API_URL=http://$SERVER_IP:3007/api
CORS_ORIGIN=http://localhost:3006,http://$SERVER_IP:3006,http://$SERVER_IP:3007
EOF

# Stop existing containers
echo "   Stopping existing containers..."
docker compose -f docker/docker-compose.kwezi.yml down --timeout 30 2>/dev/null || true
sleep 3

# Build and start
echo "   Building Gemura images..."
docker compose -f docker/docker-compose.kwezi.yml --env-file .env build

echo "   Starting Gemura containers..."
docker compose -f docker/docker-compose.kwezi.yml --env-file .env up -d

# Wait for backend
echo ""
echo "   ⏳ Waiting for backend to be ready..."
for i in 1 2 3 4 5 6 7 8 9 10 11 12; do
  if curl -s http://localhost:3007/api/health > /dev/null 2>&1; then
    echo "   ✅ Backend is healthy!"
    break
  fi
  [ \$i -eq 12 ] && echo "   ⚠️  Backend may still be starting" || sleep 5
done

echo ""
echo "   📊 Container Status:"
docker compose -f docker/docker-compose.kwezi.yml ps

echo ""
echo "   📋 Service URLs:"
echo "   - Backend API: http://$SERVER_IP:3007/api"
echo "   - API Docs: http://$SERVER_IP:3007/api/docs"
echo "   - Frontend: http://$SERVER_IP:3006"
ENDSSH

echo ""
echo "✅ Deployment Complete!"
echo "================================================"
echo ""
echo "📦 Deployment Summary:"
echo "   ✅ Files uploaded to server"
echo "   ✅ Backend & frontend Docker images built"
echo "   ✅ Backend and frontend containers started"
echo ""
echo "🌐 Access your application:"
echo "   Backend API: http://$SERVER_IP:3007/api"
echo "   API Docs: http://$SERVER_IP:3007/api/docs"
echo "   Frontend: http://$SERVER_IP:3006"
echo ""
echo "📌 Port Information:"
echo "   Backend Port: 3007"
echo "   Frontend Port: 3006"
echo ""
echo "🔧 Useful Commands:"
echo "   View logs: ssh root@$SERVER_IP 'cd /opt/gemura && docker compose -f docker/docker-compose.kwezi.yml logs -f'"
echo "   Restart: ssh root@$SERVER_IP 'cd /opt/gemura && docker compose -f docker/docker-compose.kwezi.yml restart'"
echo "   Stop: ssh root@$SERVER_IP 'cd /opt/gemura && docker compose -f docker/docker-compose.kwezi.yml down'"
echo ""

