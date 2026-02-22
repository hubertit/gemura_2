#!/bin/bash
#
# Deploy Gemura (Backend + Web) to Kwezi server (209.74.80.195)
#
# Usage (from project root):
#   ./scripts/gemura/deployment/deploy-gemura.sh
#
set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/../../.." && pwd)"

# Server credentials
SERVER_IP="209.74.80.195"
SERVER_USER="root"
SERVER_PASS="yZ961O53GtQdP2prAu"
DEPLOY_PATH="/opt/gemura"
GEMURA_UI_PORT="3006"
GEMURA_API_PORT="3007"

SSH_OPTS="-o StrictHostKeyChecking=no -o ServerAliveInterval=30 -o ServerAliveCountMax=6 -o ConnectTimeout=15"
SCP_OPTS="-o StrictHostKeyChecking=no -o ServerAliveInterval=30 -o ServerAliveCountMax=6 -o ConnectTimeout=15"

echo "🚀 Gemura Deployment (Backend + Web)"
echo "================================================"
echo "   Server: $SERVER_IP"
echo "   UI Port: $GEMURA_UI_PORT"
echo "   API Port: $GEMURA_API_PORT"
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
  --exclude='backend/node_modules' \
  --exclude='backend/dist' \
  --exclude='apps/gemura-web/node_modules' \
  --exclude='apps/gemura-web/.next' \
  backend/ \
  apps/gemura-web/ \
  docker/docker-compose.kwezi.yml
echo "   ✅ Archive created ($(du -h /tmp/gemura-deploy.tar.gz | cut -f1))"

echo ""
echo "📤 Step 2: Uploading to server..."
sshpass -p "$SERVER_PASS" ssh $SSH_OPTS $SERVER_USER@$SERVER_IP "mkdir -p $DEPLOY_PATH" 2>/dev/null || true
sshpass -p "$SERVER_PASS" scp $SCP_OPTS /tmp/gemura-deploy.tar.gz $SERVER_USER@$SERVER_IP:$DEPLOY_PATH/
echo "   ✅ Upload complete"

echo ""
echo "📂 Step 3: Extracting on server..."
sshpass -p "$SERVER_PASS" ssh $SSH_OPTS $SERVER_USER@$SERVER_IP "cd $DEPLOY_PATH && tar -xzf gemura-deploy.tar.gz && rm gemura-deploy.tar.gz"
echo "   ✅ Extracted"

echo ""
echo "🔨 Step 4: Building and starting containers..."
sshpass -p "$SERVER_PASS" ssh $SSH_OPTS $SERVER_USER@$SERVER_IP "cd $DEPLOY_PATH && docker compose -f docker/docker-compose.kwezi.yml down 2>/dev/null || true && docker compose -f docker/docker-compose.kwezi.yml build && docker compose -f docker/docker-compose.kwezi.yml up -d"

echo ""
echo "⏳ Step 5: Waiting for services to be ready..."
for i in 1 2 3 4 5 6 7 8; do
  sleep 5
  API_STATUS=$(curl -s -o /dev/null -w "%{http_code}" http://$SERVER_IP:$GEMURA_API_PORT/api/health 2>/dev/null || echo "000")
  UI_STATUS=$(curl -s -o /dev/null -w "%{http_code}" http://$SERVER_IP:$GEMURA_UI_PORT/auth/login 2>/dev/null || echo "000")
  
  if [ "$API_STATUS" = "200" ] && [ "$UI_STATUS" = "200" ]; then
    echo "   ✅ Backend is healthy"
    echo "   ✅ Frontend is healthy"
    break
  fi
  [ "$i" -eq 8 ] && echo "   ⚠️  Services may still be starting (API: $API_STATUS, UI: $UI_STATUS)"
done

# Cleanup
rm -f /tmp/gemura-deploy.tar.gz

echo ""
echo "✅ Deployment complete"
echo "================================================"
echo "   Gemura Web: http://$SERVER_IP:$GEMURA_UI_PORT"
echo "   Gemura API: http://$SERVER_IP:$GEMURA_API_PORT/api"
echo ""
