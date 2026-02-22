#!/bin/bash
# Deploy Gemura to Kwezi server (209.74.80.195)
# Uses existing Kwezi PostgreSQL, ports 3006 (UI) and 3007 (API)
# NO .env file on server - environment set via docker-compose or heredoc
#
# DATA SAFETY:
# - This script migrates data from existing server (159.198.65.38) to Kwezi
# - Database is backed up before any operations
# - Uses kwezi-postgres (existing PostgreSQL on Kwezi server)
#
# Usage:
#   cd /path/to/gemura2
#   ./scripts/deployment/deploy.prod.sh
#
set -e

# Load credentials
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
V2_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"

# Load Kwezi server credentials
CREDS_FILE="$SCRIPT_DIR/server-credentials-kwezi.sh"
if [ ! -f "$CREDS_FILE" ]; then
    echo "❌ Credentials file not found: $CREDS_FILE"
    exit 1
fi
source "$CREDS_FILE"

# Also load old server credentials for database migration
OLD_CREDS_FILE="$SCRIPT_DIR/server-credentials.sh"
if [ -f "$OLD_CREDS_FILE" ]; then
    OLD_SERVER_IP=$(grep 'SERVER_IP=' "$OLD_CREDS_FILE" | head -1 | cut -d'"' -f2)
    OLD_SERVER_USER=$(grep 'SERVER_USER=' "$OLD_CREDS_FILE" | head -1 | cut -d'"' -f2)
    OLD_SERVER_PASS=$(grep 'SERVER_PASS=' "$OLD_CREDS_FILE" | head -1 | cut -d'"' -f2)
fi

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

# Step 1: Backup and export database from old server
echo "💾 Step 1: Backing up database from old server ($OLD_SERVER_IP)..."
if [ -n "$OLD_SERVER_IP" ] && [ -n "$OLD_SERVER_PASS" ]; then
    echo "   Creating database dump on old server..."
    sshpass -p "$OLD_SERVER_PASS" ssh $SSH_OPTS $OLD_SERVER_USER@$OLD_SERVER_IP << 'ENDSSH'
set -e
export LC_ALL=C.UTF-8
mkdir -p /tmp/gemura-migration

# Dump the gemura_db database from devslab-postgres
echo "   Dumping gemura_db..."
docker exec devslab-postgres pg_dump -U devslab_admin -d gemura_db --clean --if-exists --no-owner --no-acl > /tmp/gemura-migration/gemura_db.sql
ls -lh /tmp/gemura-migration/gemura_db.sql
echo "   ✅ Database dump created"
ENDSSH

    echo "   Downloading database dump to local..."
    mkdir -p /tmp/gemura-migration
    sshpass -p "$OLD_SERVER_PASS" scp $SCP_OPTS $OLD_SERVER_USER@$OLD_SERVER_IP:/tmp/gemura-migration/gemura_db.sql /tmp/gemura-migration/
    echo "   ✅ Database dump downloaded ($(du -h /tmp/gemura-migration/gemura_db.sql | cut -f1))"
else
    echo "   ⚠️  Old server credentials not found - skipping database migration"
    echo "   (Set up scripts/deployment/server-credentials.sh for old server)"
fi
echo ""

# Step 2: Upload files to Kwezi server
echo "📤 Step 2: Uploading files to Kwezi server..."
sshpass -p "$SERVER_PASS" ssh $SSH_OPTS $SERVER_USER@$SERVER_IP "mkdir -p $DEPLOY_PATH"

echo "   Creating archive from project..."
tar -C "$V2_DIR" \
    --exclude='node_modules' \
    --exclude='dist' \
    --exclude='.next' \
    --exclude='build' \
    --exclude='.git' \
    --exclude='*.log' \
    --exclude='.env' \
    --exclude='.env.local' \
    --exclude='.env.prod' \
    --exclude='.env.devlabs' \
    --exclude='.DS_Store' \
    --exclude='mobile' \
    -czf /tmp/gemura-kwezi.tar.gz .

echo "   Archive created ($(du -h /tmp/gemura-kwezi.tar.gz | cut -f1))"
echo "   Uploading to server (may take 5-15 min)..."
sshpass -p "$SERVER_PASS" scp $SCP_OPTS /tmp/gemura-kwezi.tar.gz $SERVER_USER@$SERVER_IP:/tmp/
sshpass -p "$SERVER_PASS" ssh $SSH_OPTS $SERVER_USER@$SERVER_IP "cd $DEPLOY_PATH && tar -xzf /tmp/gemura-kwezi.tar.gz && rm /tmp/gemura-kwezi.tar.gz"
rm -f /tmp/gemura-kwezi.tar.gz
echo "   ✅ Files uploaded and extracted"
echo ""

# Step 3: Create database on Kwezi PostgreSQL and import data
echo "🗄️  Step 3: Setting up database on Kwezi PostgreSQL..."
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

# Upload database dump to Kwezi and import
if [ -f "/tmp/gemura-migration/gemura_db.sql" ]; then
    echo "   Uploading database dump to Kwezi server..."
    sshpass -p "$SERVER_PASS" scp $SCP_OPTS /tmp/gemura-migration/gemura_db.sql $SERVER_USER@$SERVER_IP:/tmp/
    
    echo "   Importing database dump..."
    sshpass -p "$SERVER_PASS" ssh $SSH_OPTS $SERVER_USER@$SERVER_IP << 'ENDSSH'
set -e
echo "   Restoring database..."
docker exec -i kwezi-postgres psql -U kwezi -d gemura_db < /tmp/gemura_db.sql
rm /tmp/gemura_db.sql
echo "   ✅ Database imported successfully"
ENDSSH
    rm -rf /tmp/gemura-migration
else
    echo "   ⚠️  No database dump found - skipping import"
fi
echo ""

# Step 4: Get Kwezi Postgres password and create .env
echo "🔧 Step 4: Creating environment configuration..."
sshpass -p "$SERVER_PASS" ssh $SSH_OPTS $SERVER_USER@$SERVER_IP << ENDSSH
set -e
cd $DEPLOY_PATH

# Get Postgres password from Kwezi
POSTGRES_PASSWORD=\$(grep -E '^POSTGRES_PASSWORD=' /opt/kwezi/.env 2>/dev/null | cut -d= -f2- || echo "KweziPg2025!")

# Create .env file (used only for docker-compose variable substitution, not committed)
cat > .env << EOF
# Gemura – Production on Kwezi server
DATABASE_URL=postgresql://kwezi:\${POSTGRES_PASSWORD}@kwezi-postgres:5432/gemura_db?schema=public
JWT_SECRET=gemura_jwt_secret_production_2026
JWT_EXPIRES_IN=7d
API_PORT=3007
UI_PORT=3006
NEXT_PUBLIC_API_URL=http://$SERVER_IP:3007/api
CORS_ORIGIN=http://localhost:3006,http://$SERVER_IP:3006,http://$SERVER_IP:3007
EOF

echo "   ✅ Environment configuration created"
ENDSSH
echo ""

# Step 5: Build and start containers
echo "🔨 Step 5: Building and starting containers..."
sshpass -p "$SERVER_PASS" ssh $SSH_OPTS $SERVER_USER@$SERVER_IP << ENDSSH
set -e
cd $DEPLOY_PATH

echo "   Stopping existing containers..."
docker compose -f docker-compose.kwezi.yml down 2>/dev/null || true

echo "   Building containers..."
docker compose -f docker-compose.kwezi.yml --env-file .env build

echo "   Starting containers..."
docker compose -f docker-compose.kwezi.yml --env-file .env up -d

echo "   Waiting for services to start..."
sleep 10
ENDSSH
echo ""

# Step 6: Health check
echo "🔍 Step 6: Health check..."
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
