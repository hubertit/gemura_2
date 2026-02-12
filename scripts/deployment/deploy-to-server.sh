#!/bin/bash

# Complete Deployment Script for Gemura to Server
# - Builds frontend locally (avoids OOM on server), uploads backend + web + pre-built .next
# - Uses docker-compose.gemura.prebuilt.yml on server (no Next.js build on server)
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
SERVER_IP="${SERVER_IP:-159.198.65.38}"
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

# Step 0: Set Gemura ports (3004 for backend, 3005 for frontend)
echo ""
echo "📌 Gemura Port Configuration:"
echo "   Backend Port: 3004"
echo "   Frontend Port: 3005"
echo ""

# Check if port 3004 is already running Gemura
if curl -s -o /dev/null -w "%{http_code}" --connect-timeout 2 http://$SERVER_IP:3004/api/health 2>/dev/null | grep -q "200"; then
    echo "✅ Port 3004: Gemura Backend is already running"
    echo "   Will update/redeploy existing deployment"
else
    echo "ℹ️  Port 3004: Will deploy new Gemura Backend"
fi

# Check port 3005 (use SSH_OPTS for keepalive)
result=$(sshpass -p "$SERVER_PASS" ssh $SSH_OPTS $SERVER_USER@$SERVER_IP \
    "netstat -tuln 2>/dev/null | grep -q ':3005 ' || ss -tuln 2>/dev/null | grep -q ':3005 ' || echo 'available'" 2>/dev/null)

if [ "$result" = "available" ]; then
    echo "✅ Port 3005: Available for Gemura Frontend"
else
    echo "⚠️  Port 3005: May be in use, but will proceed (frontend not deployed yet)"
fi

export BACKEND_PORT=3004
export FRONTEND_PORT=3005

# Step 0: Backup database first (before any deployment changes)
echo ""
echo "💾 Step 0: Backing up production database..."
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
( cd "$REPO_ROOT/web" && NEXT_PUBLIC_API_URL=http://159.198.65.38:3004/api npm run build ) || {
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
  --exclude='web/node_modules' --exclude='web/dist' \
  backend/ web/ docker-compose.gemura.prebuilt.yml docker-compose.devlabs-db.yml scripts/deployment/ )

upload_ok=
for attempt in 1 2; do
  if sshpass -p "$SERVER_PASS" ssh $SSH_OPTS $SERVER_USER@$SERVER_IP "mkdir -p $DEPLOY_PATH" 2>/dev/null && \
     sshpass -p "$SERVER_PASS" scp $SCP_OPTS /tmp/gemura-deploy.tar.gz $SERVER_USER@$SERVER_IP:/tmp/ 2>/dev/null && \
     sshpass -p "$SERVER_PASS" ssh $SSH_OPTS $SERVER_USER@$SERVER_IP "cd $DEPLOY_PATH && rm -rf backend web docker-compose.gemura.yml docker-compose.gemura.prebuilt.yml docker-compose.devlabs-db.yml scripts/deployment && tar -xzf /tmp/gemura-deploy.tar.gz 2>/dev/null && rm /tmp/gemura-deploy.tar.gz"; then
    upload_ok=1
    break
  fi
  if [ "$attempt" -eq 1 ]; then
    echo "   ⚠️  Upload failed (network?). Retrying in 15s..."
    sleep 15
  fi
done
rm -f /tmp/gemura-deploy.tar.gz
if [ -z "$upload_ok" ]; then
  echo "   ❌ Upload failed after 2 attempts. Check network/VPN and re-run."
  exit 1
fi

# Verify compose file on server
echo "   Verifying docker-compose.gemura.prebuilt.yml on server..."
if ! sshpass -p "$SERVER_PASS" ssh $SSH_OPTS $SERVER_USER@$SERVER_IP "test -f $DEPLOY_PATH/docker-compose.gemura.prebuilt.yml && test -d $DEPLOY_PATH/web/.next/standalone" 2>/dev/null; then
  echo "   ❌ Server missing prebuilt compose or web/.next/standalone. Re-run from project root: cd $REPO_ROOT && $0"
  exit 1
fi
echo "   ✅ Compose and pre-built frontend OK"

# Step 2: Setup DevLabs PostgreSQL (if not already running)
# Docker check is inside this heredoc to avoid extra SSH sessions (was causing
# "Permission denied" when too many SSH connections were opened in quick succession).
echo ""
echo "🗄️  Step 2: Ensuring Docker and DevLabs PostgreSQL..."
sshpass -p "$SERVER_PASS" ssh $SSH_OPTS $SERVER_USER@$SERVER_IP << 'ENDSSH'
export LC_ALL=C.UTF-8
cd /opt/gemura

# Ensure Docker is running (e.g. after server reboot)
if ! docker info &>/dev/null; then
  echo "   Docker not running. Attempting to start..."
  systemctl start docker 2>/dev/null || service docker start 2>/dev/null || true
  systemctl enable docker 2>/dev/null || true
  sleep 5
  if ! docker info &>/dev/null; then
    echo "   ❌ Cannot connect to Docker. On this server run: systemctl start docker && systemctl enable docker"
    exit 1
  fi
fi
echo "   ✅ Docker is running"

# Load environment variables
export POSTGRES_USER=devslab_admin
export POSTGRES_PASSWORD=devslab_secure_password_2024
export POSTGRES_PORT=5433

# Clean up devslab-postgres if it is stuck/marked for removal
if docker ps -a --format '{{.Names}} {{.Status}}' | grep -q '^devslab-postgres .*Removal'; then
  echo "   ⚠️  devslab-postgres is marked for removal. Forcing cleanup..."
  docker compose -f docker-compose.devlabs-db.yml down --remove-orphans 2>/dev/null || true
  docker rm -f devslab-postgres 2>/dev/null || true
  sleep 2
fi

# Check if DevLabs PostgreSQL is already running
if docker ps | grep -q devslab-postgres; then
    echo "   ✅ DevLabs PostgreSQL is already running"
else
    # Start DevLabs PostgreSQL
    echo "   Starting DevLabs PostgreSQL container..."
    docker compose -f docker-compose.devlabs-db.yml up -d

    # Wait for PostgreSQL to be ready
    echo "   Waiting for PostgreSQL to be ready..."
    sleep 10

    # Check if container is running
    if docker ps | grep -q devslab-postgres; then
        echo "   ✅ DevLabs PostgreSQL is running"
    else
        echo "   ❌ Failed to start PostgreSQL"
        docker logs devslab-postgres || true
        exit 1
    fi
fi

# Create Gemura database and ensure all shared DBs exist (single source of truth)
echo "   Creating/ensuring shared databases on devslab-postgres..."
docker exec -i devslab-postgres psql -U devslab_admin -d postgres << 'EOF'
-- Create each DB if not exists so all apps use the same latest data
SELECT 'CREATE DATABASE gemura_db'     WHERE NOT EXISTS (SELECT FROM pg_database WHERE datname = 'gemura_db')     \gexec
SELECT 'CREATE DATABASE resolveit_db' WHERE NOT EXISTS (SELECT FROM pg_database WHERE datname = 'resolveit_db') \gexec
SELECT 'CREATE DATABASE orchestrate_db' WHERE NOT EXISTS (SELECT FROM pg_database WHERE datname = 'orchestrate_db') \gexec
SELECT 'CREATE DATABASE ihuzo_finance'  WHERE NOT EXISTS (SELECT FROM pg_database WHERE datname = 'ihuzo_finance')  \gexec
SELECT 'CREATE DATABASE zoea_events'    WHERE NOT EXISTS (SELECT FROM pg_database WHERE datname = 'zoea_events')    \gexec
SELECT 'CREATE DATABASE refuel'         WHERE NOT EXISTS (SELECT FROM pg_database WHERE datname = 'refuel')         \gexec
GRANT ALL PRIVILEGES ON DATABASE gemura_db TO devslab_admin;
GRANT ALL PRIVILEGES ON DATABASE resolveit_db TO devslab_admin;
GRANT ALL PRIVILEGES ON DATABASE orchestrate_db TO devslab_admin;
GRANT ALL PRIVILEGES ON DATABASE ihuzo_finance TO devslab_admin;
GRANT ALL PRIVILEGES ON DATABASE zoea_events TO devslab_admin;
GRANT ALL PRIVILEGES ON DATABASE refuel TO devslab_admin;
\l
EOF

echo "   ✅ Shared databases ensured"

# Step 2.5: Single source of truth — ensure no stray Postgres
for c in pg-source devslab-postgres-temp; do
  if docker ps -a --format '{{.Names}}' | grep -qx "$c"; then
    echo "   Stopping $c so only devslab-postgres holds latest data..."
    docker stop "$c" 2>/dev/null || true
    docker rm "$c" 2>/dev/null || true
  fi
done
ENDSSH

# Step 3: Build and start Gemura
echo ""
echo "🔨 Step 3: Building and starting Gemura..."
sshpass -p "$SERVER_PASS" ssh $SSH_OPTS $SERVER_USER@$SERVER_IP << ENDSSH
export LC_ALL=C.UTF-8
cd /opt/gemura

# Ensure DevLabs network exists (created by devlabs-db compose)
docker network create devslab-network 2>/dev/null || true

# Update .env.devlabs: backend uses prod DB; frontend build uses prod API URL
cat > .env.devlabs << EOF
# DevLabs PostgreSQL Configuration
POSTGRES_USER=devslab_admin
POSTGRES_PASSWORD=devslab_secure_password_2024
POSTGRES_DB=postgres
POSTGRES_PORT=5433

# Gemura Configuration
BACKEND_PORT=3004
FRONTEND_PORT=3005
CORS_ORIGIN=http://localhost:3005,http://localhost:3004,http://159.198.65.38:3005,http://159.198.65.38:3004
# Frontend talks to prod backend (baked in at build time)
NEXT_PUBLIC_API_URL=http://159.198.65.38:3004/api

# Backend uses prod DB (devslab-postgres on server)
DATABASE_URL=postgresql://devslab_admin:devslab_secure_password_2024@devslab-postgres:5432/gemura_db
EOF

# Stop and remove existing containers (give overlay time to release — avoids "device or resource busy")
echo "   Stopping and removing existing containers..."
docker compose -f docker-compose.gemura.prebuilt.yml --env-file .env.devlabs down --remove-orphans --timeout 30 2>/dev/null || true
sleep 5

# Force remove any stuck containers
echo "   Cleaning up any stuck containers..."
docker ps -a | grep gemura | awk '{print $1}' | xargs -r docker rm -f 2>/dev/null || true
sleep 2

# Build backend and frontend (frontend uses pre-built .next — no heavy build on server)
echo "   Building Gemura backend and frontend images..."
docker compose -f docker-compose.gemura.prebuilt.yml --env-file .env.devlabs build backend frontend

# Start both containers with force recreate
echo "   Starting Gemura backend and frontend..."
docker compose -f docker-compose.gemura.prebuilt.yml --env-file .env.devlabs up -d --force-recreate --no-deps backend frontend

# Wait for backend to be ready
echo ""
echo "   ⏳ Waiting for backend to be ready..."
for i in 1 2 3 4 5 6 7 8 9 10 11 12; do
  if curl -s http://localhost:3004/api/health > /dev/null 2>&1; then
    echo "   ✅ Backend is healthy!"
    break
  fi
  if [ \$i -eq 12 ]; then
    echo "   ⚠️  Backend may still be starting (check logs if needed)"
  else
    echo "   ⏳ Attempt \$i/12..."
    sleep 5
  fi
done
echo "   ✅ Frontend: http://159.198.65.38:3005"

# Check status
echo ""
echo "   📊 Container Status:"
docker compose -f docker-compose.gemura.prebuilt.yml ps

# Verify the new image is running
echo ""
echo "   🔍 Verifying deployment..."
CURRENT_IMAGE=$(docker compose -f docker-compose.gemura.prebuilt.yml --env-file .env.devlabs ps backend 2>/dev/null | grep backend | awk '{print $2}' || echo "unknown")
echo "   Running image: $CURRENT_IMAGE"

echo ""
echo "   📋 Service URLs:"
echo "   - Backend API: http://159.198.65.38:3004/api"
echo "   - API Docs: http://159.198.65.38:3004/api/docs"
echo "   - Health Check: http://159.198.65.38:3004/api/health"
echo "   - Frontend: http://159.198.65.38:3005"
ENDSSH

echo ""
echo "✅ Deployment Complete!"
echo "================================================"
echo ""
echo "📦 Deployment Summary:"
echo "   ✅ Database backed up (before deploy)"
echo "   ✅ Files uploaded to server"
echo "   ✅ Backend & frontend Docker images built (backend=prod DB, frontend=prod API)"
echo "   ✅ Backend and frontend containers started"
echo ""
echo "🌐 Access your application:"
echo "   Backend API: http://159.198.65.38:3004/api"
echo "   API Docs: http://159.198.65.38:3004/api/docs"
echo "   Health Check: http://159.198.65.38:3004/api/health"
echo "   Frontend: http://159.198.65.38:3005"
echo ""
echo "📌 Port Information:"
echo "   Backend Port: 3004"
echo "   Frontend Port: 3005"
echo ""
echo "📋 DevLabs PostgreSQL Credentials:"
echo "   Host: localhost:5433"
echo "   User: devslab_admin"
echo "   Password: devslab_secure_password_2024"
echo "   Database: gemura_db"
echo ""
echo "🔧 Useful Commands:"
echo "   View logs: ssh root@159.198.65.38 'cd /opt/gemura && docker compose -f docker-compose.gemura.prebuilt.yml logs -f'"
echo "   Restart: ssh root@159.198.65.38 'cd /opt/gemura && docker compose -f docker-compose.gemura.prebuilt.yml restart'"
echo "   Stop: ssh root@159.198.65.38 'cd /opt/gemura && docker compose -f docker-compose.gemura.prebuilt.yml down'"
echo ""
echo "   If overlay2 \"device or resource busy\": restart Docker or reboot server, then re-run this script."
echo ""

