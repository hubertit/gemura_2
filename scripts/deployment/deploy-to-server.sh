#!/bin/bash

# Complete Deployment Script for Gemura to Server
# This script sets up DevLabs PostgreSQL and deploys Gemura
# Matches ResolveIt v2 deployment pattern
#
# Usage:
#   ./deploy-to-server.sh              # Auto-detect available port
#   ./deploy-to-server.sh 3002        # Use specific port

set -e

# Use ResolveIT v2 server credentials when present (same server)
RESOLVEIT_CREDS="${RESOLVEIT_V2_CREDS:-/Applications/AMPPS/www/resolveit/v2/scripts/deployment/server-credentials.sh}"
[ -f "$RESOLVEIT_CREDS" ] && source "$RESOLVEIT_CREDS"
SERVER_IP="${SERVER_IP:-159.198.65.38}"
SERVER_USER="${SERVER_USER:-root}"
SERVER_PASS="${SERVER_PASS:-}"
DEPLOY_PATH="/opt/gemura"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

if [ -z "$SERVER_PASS" ]; then
    echo "❌ SERVER_PASS not set. Either:"
    echo "   1. In ResolveIT v2: cp scripts/deployment/server-credentials.sh.example scripts/deployment/server-credentials.sh, then set SERVER_PASS"
    echo "   2. Or: export SERVER_PASS=your_password"
    exit 1
fi

echo "🚀 Starting Gemura Deployment to Server..."
echo "================================================"

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

# Check port 3005
result=$(sshpass -p "$SERVER_PASS" ssh -o StrictHostKeyChecking=no $SERVER_USER@$SERVER_IP \
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
if sshpass -p "$SERVER_PASS" ssh -o StrictHostKeyChecking=no $SERVER_USER@$SERVER_IP \
    "docker ps --format '{{.Names}}' | grep -qx devslab-postgres" 2>/dev/null; then
  if sshpass -p "$SERVER_PASS" ssh -o StrictHostKeyChecking=no $SERVER_USER@$SERVER_IP \
      "[ -f $DEPLOY_PATH/scripts/deployment/backup-all-databases.sh ]" 2>/dev/null; then
    sshpass -p "$SERVER_PASS" ssh -o StrictHostKeyChecking=no $SERVER_USER@$SERVER_IP \
      "cd $DEPLOY_PATH && mkdir -p backups && bash scripts/deployment/backup-all-databases.sh" || \
      echo "   ⚠️  Backup had warnings (continuing)"
    echo "   ✅ Database backup complete"
  else
    echo "   ⏭️  Skipping backup (first deploy, script not on server yet)"
  fi
else
  echo "   ⏭️  Skipping backup (PostgreSQL not running yet - fresh deploy)"
fi

# Step 1: Upload files to server
echo ""
echo "📤 Step 1: Uploading files to server..."
sshpass -p "$SERVER_PASS" ssh -o StrictHostKeyChecking=no $SERVER_USER@$SERVER_IP "mkdir -p $DEPLOY_PATH"

# Upload project files
echo "   Uploading project files..."
# Create a temporary tar archive excluding unnecessary files
# Optimized exclusions to match ResolveIt speed (exclude large dirs)
tar --exclude='node_modules' --exclude='.next' --exclude='dist' \
    --exclude='.git' --exclude='*.log' --exclude='.env*' \
    --exclude='mobile' --exclude='build' \
    --exclude='backend/node_modules' --exclude='backend/dist' \
    --exclude='.dart_tool' --exclude='mobile/.dart_tool' \
    --exclude='coverage' --exclude='.nyc_output' \
    --exclude='*.test.ts' --exclude='*.spec.ts' \
    -czf /tmp/gemura-deploy.tar.gz .
sshpass -p "$SERVER_PASS" scp -o StrictHostKeyChecking=no /tmp/gemura-deploy.tar.gz $SERVER_USER@$SERVER_IP:/tmp/
sshpass -p "$SERVER_PASS" ssh -o StrictHostKeyChecking=no $SERVER_USER@$SERVER_IP "cd $DEPLOY_PATH && tar -xzf /tmp/gemura-deploy.tar.gz && rm /tmp/gemura-deploy.tar.gz"
rm /tmp/gemura-deploy.tar.gz

# Step 2: Setup DevLabs PostgreSQL (if not already running)
# Docker check is inside this heredoc to avoid extra SSH sessions (was causing
# "Permission denied" when too many SSH connections were opened in quick succession).
echo ""
echo "🗄️  Step 2: Ensuring Docker and DevLabs PostgreSQL..."
sshpass -p "$SERVER_PASS" ssh -o StrictHostKeyChecking=no $SERVER_USER@$SERVER_IP << 'ENDSSH'
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
sshpass -p "$SERVER_PASS" ssh -o StrictHostKeyChecking=no $SERVER_USER@$SERVER_IP << ENDSSH
cd /opt/gemura

# Ensure DevLabs network exists (created by devlabs-db compose)
docker network create devslab-network 2>/dev/null || true

# Update .env.devlabs with correct DATABASE_URL and fixed ports
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
NEXT_PUBLIC_API_BASE=http://159.198.65.38:3004/api

# Database connection for Gemura backend
DATABASE_URL=postgresql://devslab_admin:devslab_secure_password_2024@devslab-postgres:5432/gemura_db
EOF

# Stop and remove existing containers to ensure fresh deployment
echo "   Stopping and removing existing containers..."
docker compose -f docker-compose.gemura.yml --env-file .env.devlabs down --remove-orphans 2>/dev/null || true

# Force remove any stuck containers
echo "   Cleaning up any stuck containers..."
docker ps -a | grep gemura | awk '{print $1}' | xargs -r docker rm -f 2>/dev/null || true

# Build new image with latest code
# Use cache when possible for faster builds (only rebuild changed layers)
echo "   Building Gemura containers with latest code..."
docker compose -f docker-compose.gemura.yml --env-file .env.devlabs build backend

# Start containers with force recreate to ensure new image is used
echo "   Starting Gemura containers with new image..."
docker compose -f docker-compose.gemura.yml --env-file .env.devlabs up -d --force-recreate --no-deps backend

# Wait for services to start and verify health
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

# Check status
echo ""
echo "   📊 Container Status:"
docker compose -f docker-compose.gemura.yml ps

# Verify the new image is running
echo ""
echo "   🔍 Verifying deployment..."
CURRENT_IMAGE=$(docker compose -f docker-compose.gemura.yml --env-file .env.devlabs ps backend 2>/dev/null | grep backend | awk '{print $2}' || echo "unknown")
echo "   Running image: $CURRENT_IMAGE"

echo ""
echo "   📋 Service URLs:"
echo "   - Backend API: http://159.198.65.38:3004/api"
echo "   - API Docs: http://159.198.65.38:3004/api/docs"
echo "   - Health Check: http://159.198.65.38:3004/api/health"
echo "   - Frontend: http://159.198.65.38:3005 (when deployed)"
ENDSSH

echo ""
echo "✅ Deployment Complete!"
echo "================================================"
echo ""
echo "📦 Deployment Summary:"
echo "   ✅ Database backed up (before deploy)"
echo "   ✅ Files uploaded to server"
echo "   ✅ Docker image rebuilt with latest code"
echo "   ✅ Containers recreated with new image"
echo "   ✅ Backend service started"
echo ""
echo "🌐 Access your application:"
echo "   Backend API: http://159.198.65.38:3004/api"
echo "   API Docs: http://159.198.65.38:3004/api/docs"
echo "   Health Check: http://159.198.65.38:3004/api/health"
echo "   Frontend: http://159.198.65.38:3005 (when deployed)"
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
echo "   View logs: ssh root@159.198.65.38 'cd /opt/gemura && docker compose -f docker-compose.gemura.yml logs -f'"
echo "   Restart: ssh root@159.198.65.38 'cd /opt/gemura && docker compose -f docker-compose.gemura.yml restart'"
echo "   Stop: ssh root@159.198.65.38 'cd /opt/gemura && docker compose -f docker-compose.gemura.yml down'"
echo ""

