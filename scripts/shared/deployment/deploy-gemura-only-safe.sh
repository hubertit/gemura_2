#!/bin/bash
#
# Safe Gemura-only deployment to Kwezi server (209.74.80.195):
# - Deploys ONLY Gemura backend and frontend containers.
# - Does NOT start, stop, or modify the database container (kwezi-postgres).
# - Does NOT touch any other containers.
#
# Usage (from project root):
#   ./scripts/shared/deployment/deploy-gemura-only-safe.sh
#
set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/../../.." && pwd)"
CREDS_FILE="$SCRIPT_DIR/server-credentials.sh"
[ -f "$CREDS_FILE" ] && source "$CREDS_FILE"

SERVER_IP="${SERVER_IP:-209.74.80.195}"
SERVER_USER="${SERVER_USER:-root}"
SERVER_PASS="${SERVER_PASS:-}"
DEPLOY_PATH="/opt/gemura"

if [ -z "$SERVER_PASS" ]; then
  echo "❌ SERVER_PASS not set. Configure scripts/shared/deployment/server-credentials.sh or export SERVER_PASS."
  exit 1
fi

SSH_OPTS="-o StrictHostKeyChecking=no -o ServerAliveInterval=30 -o ServerAliveCountMax=6 -o ConnectTimeout=15"
SCP_OPTS="-o StrictHostKeyChecking=no -o ServerAliveInterval=30 -o ServerAliveCountMax=6 -o ConnectTimeout=15"

echo "🚀 Safe Gemura-only deployment to Kwezi server"
echo "================================================"
echo "   Server: $SERVER_IP"
echo "   Backend Port: 3007"
echo "   Frontend Port: 3006"
echo ""

echo "🔌 Checking connectivity to $SERVER_IP..."
if ! sshpass -p "$SERVER_PASS" ssh $SSH_OPTS $SERVER_USER@$SERVER_IP "echo OK" 2>/dev/null; then
  echo "❌ Cannot reach the server."
  exit 1
fi
echo "   ✅ Server reachable"

echo ""
echo "📦 Step 1: Creating deployment archive..."
cd "$REPO_ROOT"
COPYFILE_DISABLE=1 tar -czf /tmp/gemura-deploy.tar.gz \
  --exclude='backend/node_modules' --exclude='backend/dist' \
  --exclude='apps/gemura-web/node_modules' --exclude='apps/gemura-web/.next' \
  backend/ apps/gemura-web/ docker/docker-compose.kwezi.yml
echo "   ✅ Archive created ($(du -h /tmp/gemura-deploy.tar.gz | cut -f1))"

echo ""
echo "📤 Step 2: Uploading to server..."
sshpass -p "$SERVER_PASS" ssh $SSH_OPTS $SERVER_USER@$SERVER_IP "mkdir -p $DEPLOY_PATH" 2>/dev/null || true
sshpass -p "$SERVER_PASS" scp $SCP_OPTS /tmp/gemura-deploy.tar.gz $SERVER_USER@$SERVER_IP:$DEPLOY_PATH/
sshpass -p "$SERVER_PASS" ssh $SSH_OPTS $SERVER_USER@$SERVER_IP "cd $DEPLOY_PATH && tar -xzf gemura-deploy.tar.gz && rm gemura-deploy.tar.gz"
rm -f /tmp/gemura-deploy.tar.gz
echo "   ✅ Upload and extract OK"

echo ""
echo "🔨 Step 3: Building and starting Gemura containers..."
sshpass -p "$SERVER_PASS" ssh $SSH_OPTS $SERVER_USER@$SERVER_IP 'bash -s' << 'ENDSSH'
export LC_ALL=C.UTF-8
cd /opt/gemura

# Get Postgres password from Kwezi
POSTGRES_PASSWORD=$(grep -E '^POSTGRES_PASSWORD=' /opt/kwezi/.env 2>/dev/null | cut -d= -f2- || echo "KweziPg2025!")

# Create/update .env
cat > .env << EOF
DATABASE_URL=postgresql://kwezi:${POSTGRES_PASSWORD}@kwezi-postgres:5432/gemura_db?schema=public
JWT_SECRET=gemura_jwt_secret_production_2026
JWT_EXPIRES_IN=7d
API_PORT=3007
UI_PORT=3006
NEXT_PUBLIC_API_URL=http://209.74.80.195:3007/api
CORS_ORIGIN=http://localhost:3006,http://209.74.80.195:3006,http://209.74.80.195:3007
EOF

echo "   Stopping Gemura containers..."
docker compose -f docker/docker-compose.kwezi.yml down --timeout 30 2>/dev/null || true
sleep 3

echo "   Building Gemura images..."
docker compose -f docker/docker-compose.kwezi.yml --env-file .env build

echo "   Starting Gemura containers..."
docker compose -f docker/docker-compose.kwezi.yml --env-file .env up -d

echo ""
echo "   ⏳ Waiting for backend to be ready..."
for i in 1 2 3 4 5 6 7 8 9 10 11 12; do
  if curl -s http://localhost:3007/api/health > /dev/null 2>&1; then
    echo "   ✅ Backend is healthy"
    break
  fi
  [ "$i" -eq 12 ] && echo "   ⚠️  Backend may still be starting" || sleep 5
done

echo ""
echo "   📊 Gemura containers:"
docker compose -f docker/docker-compose.kwezi.yml ps
ENDSSH

echo ""
echo "✅ Safe deployment complete"
echo "================================================"
echo "   Backend: http://$SERVER_IP:3007/api"
echo "   Frontend: http://$SERVER_IP:3006"
echo ""
