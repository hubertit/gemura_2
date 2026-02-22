#!/bin/bash
# Deploy Gemura to Kwezi server (209.74.80.195)
# Uses existing Kwezi PostgreSQL, ports 3006 (UI) and 3007 (API)
#
# Usage:
#   cd /path/to/orora
#   ./scripts/shared/deployment/deploy.prod.sh
#
set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
V2_DIR="$(cd "$SCRIPT_DIR/../../.." && pwd)"

# Load server credentials
CREDS_FILE="$SCRIPT_DIR/server-credentials.sh"
if [ ! -f "$CREDS_FILE" ]; then
    echo "❌ Credentials file not found: $CREDS_FILE"
    exit 1
fi
source "$CREDS_FILE"

# Use shared variables
DEPLOY_PATH="${GEMURA_DEPLOY_PATH:-/opt/gemura}"
UI_PORT="${GEMURA_UI_PORT:-3006}"
API_PORT="${GEMURA_API_PORT:-3007}"

SSH_OPTS="-o StrictHostKeyChecking=no -o ServerAliveInterval=30 -o ServerAliveCountMax=6 -o ConnectTimeout=15"
SCP_OPTS="-o StrictHostKeyChecking=no -o ServerAliveInterval=30 -o ServerAliveCountMax=6 -o ConnectTimeout=15"

echo "🚀 Gemura deployment to Kwezi server"
echo "=============================================="
echo "   Server: $SERVER_USER@$SERVER_IP"
echo "   Path:   $DEPLOY_PATH"
echo "   Ports:  UI=$UI_PORT, API=$API_PORT"
echo ""

# Step 0: Check connectivity
echo "🔌 Checking connectivity to $SERVER_IP..."
if ! sshpass -p "$SERVER_PASS" ssh $SSH_OPTS $SERVER_USER@$SERVER_IP "echo OK" 2>/dev/null; then
    echo "❌ Cannot reach the server."
    exit 1
fi
echo "   ✅ Server reachable"
echo ""

echo ""

# Step 1: Upload files to Kwezi server
echo "📤 Step 1: Uploading files to Kwezi server..."
sshpass -p "$SERVER_PASS" ssh $SSH_OPTS $SERVER_USER@$SERVER_IP "mkdir -p $DEPLOY_PATH"

echo "   Creating archive from project..."
cd "$V2_DIR"
COPYFILE_DISABLE=1 tar -czf /tmp/gemura-kwezi.tar.gz \
    --exclude='backend/node_modules' \
    --exclude='backend/dist' \
    --exclude='apps/gemura-web/node_modules' \
    --exclude='apps/gemura-web/.next' \
    --exclude='.git' \
    --exclude='*.log' \
    --exclude='.DS_Store' \
    --exclude='apps/orora-*' \
    --exclude='apps/gemura-mobile' \
    backend/ apps/gemura-web/ docker/docker-compose.kwezi.yml scripts/

echo "   Archive created ($(du -h /tmp/gemura-kwezi.tar.gz | cut -f1))"
echo "   Uploading to server..."
sshpass -p "$SERVER_PASS" scp $SCP_OPTS /tmp/gemura-kwezi.tar.gz $SERVER_USER@$SERVER_IP:$DEPLOY_PATH/
sshpass -p "$SERVER_PASS" ssh $SSH_OPTS $SERVER_USER@$SERVER_IP "cd $DEPLOY_PATH && tar -xzf gemura-kwezi.tar.gz && rm gemura-kwezi.tar.gz"
rm -f /tmp/gemura-kwezi.tar.gz
echo "   ✅ Files uploaded and extracted"
echo ""

# Step 2: Ensure database exists on Kwezi PostgreSQL
echo "🗄️  Step 2: Setting up database on Kwezi PostgreSQL..."
sshpass -p "$SERVER_PASS" ssh $SSH_OPTS $SERVER_USER@$SERVER_IP << 'ENDSSH'
set -e

# Check if kwezi-postgres is running
if ! docker ps | grep -q kwezi-postgres; then
    echo "   ❌ kwezi-postgres not running!"
    exit 1
fi

# Create database if not exists
echo "   Creating database gemura_db..."
docker exec kwezi-postgres psql -U kwezi -d postgres -tc "SELECT 1 FROM pg_database WHERE datname = 'gemura_db'" | grep -q 1 || \
docker exec kwezi-postgres psql -U kwezi -d postgres -c "CREATE DATABASE gemura_db;"
echo "   ✅ Database gemura_db ready"
ENDSSH
echo ""

# Step 3: Create environment configuration and build containers
echo "🔧 Step 3: Creating environment and building containers..."
sshpass -p "$SERVER_PASS" ssh $SSH_OPTS $SERVER_USER@$SERVER_IP << ENDSSH
set -e
cd $DEPLOY_PATH

# Get Postgres password from Kwezi
POSTGRES_PASSWORD=\$(grep -E '^POSTGRES_PASSWORD=' /opt/kwezi/.env 2>/dev/null | cut -d= -f2- || echo "KweziPg2025!")

# Create .env file
cat > .env << EOF
DATABASE_URL=postgresql://kwezi:\${POSTGRES_PASSWORD}@kwezi-postgres:5432/gemura_db?schema=public
JWT_SECRET=gemura_jwt_secret_production_2026
JWT_EXPIRES_IN=7d
API_PORT=$API_PORT
UI_PORT=$UI_PORT
NEXT_PUBLIC_API_URL=http://$SERVER_IP:$API_PORT/api
CORS_ORIGIN=http://localhost:$UI_PORT,http://$SERVER_IP:$UI_PORT,http://$SERVER_IP:$API_PORT
EOF

echo "   ✅ Environment configuration created"

echo "   Stopping existing containers..."
docker compose -f docker/docker-compose.kwezi.yml down 2>/dev/null || true

echo "   Building containers..."
docker compose -f docker/docker-compose.kwezi.yml --env-file .env build

echo "   Starting containers..."
docker compose -f docker/docker-compose.kwezi.yml --env-file .env up -d

echo "   Waiting for services to start..."
sleep 10
ENDSSH
echo ""

# Step 4: Health check
echo "🔍 Step 4: Health check..."
sleep 5

API_STATUS=$(curl -s -o /dev/null -w "%{http_code}" http://$SERVER_IP:$API_PORT/api 2>/dev/null || echo "000")
UI_STATUS=$(curl -s -o /dev/null -w "%{http_code}" http://$SERVER_IP:$UI_PORT 2>/dev/null || echo "000")

echo ""
echo "=============================================="
echo "✅ Gemura deployment complete!"
echo ""
echo "   🌐 UI:      http://$SERVER_IP:$UI_PORT (status: $UI_STATUS)"
echo "   📡 API:     http://$SERVER_IP:$API_PORT/api (status: $API_STATUS)"
echo "   📚 Swagger: http://$SERVER_IP:$API_PORT/api/docs"
echo ""
echo "   Database: gemura_db on kwezi-postgres"
echo "=============================================="
