#!/bin/bash
#
# Deploy Orora Web to Kwezi server (209.74.80.195)
# Uses shared Gemura backend API on port 3007
#
# Usage (from project root):
#   ./scripts/orora/deployment/deploy-orora-web.sh
#
set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/../../.." && pwd)"

# Server credentials
SERVER_IP="209.74.80.195"
SERVER_USER="root"
SERVER_PASS="yZ961O53GtQdP2prAu"
DEPLOY_PATH="/opt/orora"
ORORA_WEB_PORT="3011"
API_URL="http://${SERVER_IP}:3007/api"

SSH_OPTS="-o StrictHostKeyChecking=no -o ServerAliveInterval=30 -o ServerAliveCountMax=6 -o ConnectTimeout=15"
SCP_OPTS="-o StrictHostKeyChecking=no -o ServerAliveInterval=30 -o ServerAliveCountMax=6 -o ConnectTimeout=15"

echo "🚀 Orora Web Deployment"
echo "================================================"
echo "   Server: $SERVER_IP"
echo "   Port: $ORORA_WEB_PORT"
echo "   API: $API_URL"
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
COPYFILE_DISABLE=1 tar -czf /tmp/orora-web-deploy.tar.gz \
  apps/orora-web/app \
  apps/orora-web/hooks \
  apps/orora-web/lib \
  apps/orora-web/public \
  apps/orora-web/store \
  apps/orora-web/types \
  apps/orora-web/Dockerfile \
  apps/orora-web/next.config.ts \
  apps/orora-web/package.json \
  apps/orora-web/package-lock.json \
  apps/orora-web/postcss.config.mjs \
  apps/orora-web/tsconfig.json \
  apps/orora-web/.env.production \
  docker/docker-compose.orora-web.yml
echo "   ✅ Archive created ($(du -h /tmp/orora-web-deploy.tar.gz | cut -f1))"

echo ""
echo "📤 Step 2: Uploading to server..."
sshpass -p "$SERVER_PASS" ssh $SSH_OPTS $SERVER_USER@$SERVER_IP "mkdir -p $DEPLOY_PATH" 2>/dev/null || true
sshpass -p "$SERVER_PASS" scp $SCP_OPTS /tmp/orora-web-deploy.tar.gz $SERVER_USER@$SERVER_IP:$DEPLOY_PATH/
echo "   ✅ Upload complete"

echo ""
echo "📂 Step 3: Extracting on server..."
sshpass -p "$SERVER_PASS" ssh $SSH_OPTS $SERVER_USER@$SERVER_IP "cd $DEPLOY_PATH && tar -xzf orora-web-deploy.tar.gz && rm orora-web-deploy.tar.gz"
echo "   ✅ Extracted"

echo ""
echo "🔨 Step 4: Building and starting container..."
sshpass -p "$SERVER_PASS" ssh $SSH_OPTS $SERVER_USER@$SERVER_IP "cd $DEPLOY_PATH && docker compose -f docker/docker-compose.orora-web.yml down 2>/dev/null || true && docker compose -f docker/docker-compose.orora-web.yml build && docker compose -f docker/docker-compose.orora-web.yml up -d"

echo ""
echo "⏳ Step 5: Waiting for Orora Web to be ready..."
for i in 1 2 3 4 5 6; do
  sleep 5
  if curl -s -o /dev/null -w "%{http_code}" http://$SERVER_IP:$ORORA_WEB_PORT/auth/login | grep -q "200"; then
    echo "   ✅ Orora Web is healthy"
    break
  fi
  [ "$i" -eq 6 ] && echo "   ⚠️  Orora Web may still be starting"
done

# Cleanup
rm -f /tmp/orora-web-deploy.tar.gz

echo ""
echo "✅ Deployment complete"
echo "================================================"
echo "   Orora Web: http://$SERVER_IP:$ORORA_WEB_PORT"
echo "   API (shared): $API_URL"
echo ""
