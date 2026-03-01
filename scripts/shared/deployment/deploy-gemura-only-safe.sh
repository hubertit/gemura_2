#!/bin/bash
#
# Safe Gemura-only deployment to Kwezi server (209.74.80.195) – rsync (parallel) + docker build (cache).
# - Deploys ONLY Gemura backend and frontend containers.
# - Does NOT start, stop, or modify the database container (kwezi-postgres).
# - Backend and gemura-web rsync run in parallel for faster sync.
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

echo "🚀 Safe Gemura deployment (parallel rsync + build with cache)"
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
echo "📤 Syncing files (rsync, parallel)..."
cd "$REPO_ROOT"
RSYNC_SSH="sshpass -p $SERVER_PASS ssh $SSH_OPTS"
sshpass -p "$SERVER_PASS" ssh $SSH_OPTS $SERVER_USER@$SERVER_IP "mkdir -p $DEPLOY_PATH/backend $DEPLOY_PATH/apps/gemura-web $DEPLOY_PATH/docker"

# Backend and frontend rsync in parallel (docker compose file is small, run after)
rsync -avz --delete \
  --exclude='node_modules' \
  --exclude='dist' \
  --exclude='.git' \
  --exclude='.env' \
  --exclude='.env.local' \
  --exclude='*.log' \
  --exclude='.DS_Store' \
  --exclude='*.tsbuildinfo' \
  --exclude='coverage' \
  -e "$RSYNC_SSH" \
  backend/ \
  $SERVER_USER@$SERVER_IP:$DEPLOY_PATH/backend/ &
RSYNC_BACKEND_PID=$!
rsync -avz --delete \
  --exclude='node_modules' \
  --exclude='.next' \
  --exclude='.git' \
  --exclude='.env.local' \
  --exclude='*.log' \
  --exclude='.DS_Store' \
  -e "$RSYNC_SSH" \
  apps/gemura-web/ \
  $SERVER_USER@$SERVER_IP:$DEPLOY_PATH/apps/gemura-web/ &
RSYNC_UI_PID=$!
wait $RSYNC_BACKEND_PID $RSYNC_UI_PID

rsync -avz -e "$RSYNC_SSH" \
  docker/docker-compose.kwezi.yml \
  $SERVER_USER@$SERVER_IP:$DEPLOY_PATH/docker/
echo "   ✅ Sync complete"

echo ""
echo "🔨 Building and starting containers (Docker cache used)..."
sshpass -p "$SERVER_PASS" ssh $SSH_OPTS $SERVER_USER@$SERVER_IP 'bash -s' << 'ENDSSH'
export LC_ALL=C.UTF-8
cd /opt/gemura

# Get Postgres password from Kwezi (or default)
POSTGRES_PASSWORD=$(grep -E '^POSTGRES_PASSWORD=' /opt/kwezi/.env 2>/dev/null | cut -d= -f2- || echo "KweziPg2025!")

# Create/update .env (preserve existing if you want to edit manually)
if [ ! -f .env ] || ! grep -q "DATABASE_URL" .env 2>/dev/null; then
  cat > .env << EOF
DATABASE_URL=postgresql://kwezi:${POSTGRES_PASSWORD}@kwezi-postgres:5432/gemura_db?schema=public
JWT_SECRET=gemura_jwt_secret_production_2026
JWT_EXPIRES_IN=7d
API_PORT=3007
UI_PORT=3006
NEXT_PUBLIC_API_URL=https://app.gemura.rw/api
CORS_ORIGIN=http://localhost:3006,http://209.74.80.195:3006,http://209.74.80.195:3007,http://209.74.80.195:3011,https://app.gemura.rw,https://app.orora.rw
EOF
  echo "   Created .env"
fi

echo "   Stopping Gemura containers..."
docker compose -f docker/docker-compose.kwezi.yml down --timeout 20 2>/dev/null || true
sleep 1

echo "   Building and starting (with cache)..."
docker compose -f docker/docker-compose.kwezi.yml --env-file .env up -d --build

echo ""
echo "   ⏳ Waiting for backend to be ready..."
for i in 1 2 3 4 5 6 7 8 9 10 11 12; do
  if curl -s -m 3 http://localhost:3007/api/health > /dev/null 2>&1; then
    echo "   ✅ Backend is healthy"
    break
  fi
  [ "$i" -eq 12 ] && echo "   ⚠️  Backend may still be starting" || sleep 2
done

echo ""
echo "   📊 Gemura containers:"
docker compose -f docker/docker-compose.kwezi.yml ps
ENDSSH

echo ""
echo "✅ Safe deployment complete"
echo "================================================"
echo "   Backend: http://$SERVER_IP:3007/api"
echo "   Frontend: https://app.gemura.rw  (or http://$SERVER_IP:3006)"
echo ""
echo "   Tip: Use --no-cache only when needed:"
echo "   ssh $SERVER_USER@$SERVER_IP 'cd /opt/gemura && docker compose -f docker/docker-compose.kwezi.yml --env-file .env build --no-cache && docker compose -f docker/docker-compose.kwezi.yml --env-file .env up -d'"
echo ""
