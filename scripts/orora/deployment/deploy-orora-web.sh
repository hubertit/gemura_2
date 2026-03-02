#!/bin/bash
#
# Deploy Orora Web to Kwezi server (209.74.80.195) – Kwezi-style: rsync + docker build (with cache).
# Uses shared Gemura backend API on port 3007.
#
# Usage (from project root):
#   ./scripts/orora/deployment/deploy-orora-web.sh
#
set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/../../.." && pwd)"
CREDS_FILE="$REPO_ROOT/scripts/shared/deployment/server-credentials.sh"
[ -f "$CREDS_FILE" ] && source "$CREDS_FILE"

SERVER_IP="${SERVER_IP:-209.74.80.195}"
SERVER_USER="${SERVER_USER:-root}"
SERVER_PASS="${SERVER_PASS:-}"
DEPLOY_PATH="/opt/orora"
ORORA_WEB_PORT="3011"
API_URL="https://app.orora.rw/api"

if [ -z "$SERVER_PASS" ]; then
  echo "❌ SERVER_PASS not set. Configure scripts/shared/deployment/server-credentials.sh or export SERVER_PASS."
  exit 1
fi

SSH_OPTS="-o StrictHostKeyChecking=no -o ServerAliveInterval=30 -o ServerAliveCountMax=6 -o ConnectTimeout=15"
SSH_CONTROL_PATH="/tmp/orora-deploy-$$"
SSH_MASTER_OPTS="$SSH_OPTS -o ControlMaster=auto -o ControlPath=$SSH_CONTROL_PATH -o ControlPersist=300"
cleanup_ssh() { ssh -O exit -o ControlPath="$SSH_CONTROL_PATH" $SERVER_USER@$SERVER_IP 2>/dev/null || true; }
trap cleanup_ssh EXIT

echo "🚀 Orora Web Deployment (Kwezi-style: rsync + build with cache)"
echo "================================================"
echo "   Server: $SERVER_IP"
echo "   Port: $ORORA_WEB_PORT"
echo "   API: $API_URL"
echo ""

echo "🔌 Checking connectivity to $SERVER_IP..."
if ! sshpass -p "$SERVER_PASS" ssh $SSH_MASTER_OPTS -o ControlPersist=0 $SERVER_USER@$SERVER_IP "echo OK" 2>/dev/null; then
  echo "❌ Cannot reach the server."
  exit 1
fi
echo "   ✅ Server reachable"

echo ""
echo "📤 Syncing files (rsync, incremental)..."
cd "$REPO_ROOT"
sshpass -p "$SERVER_PASS" ssh $SSH_MASTER_OPTS -N -f $SERVER_USER@$SERVER_IP || { echo "❌ Failed to open SSH master."; exit 1; }
ssh $SSH_OPTS -o ControlPath=$SSH_CONTROL_PATH $SERVER_USER@$SERVER_IP "mkdir -p $DEPLOY_PATH/apps $DEPLOY_PATH/docker"
rsync -avz --delete \
  --exclude='node_modules' \
  --exclude='.next' \
  --exclude='.git' \
  --exclude='.env.local' \
  --exclude='*.log' \
  --exclude='.DS_Store' \
  -e "ssh $SSH_OPTS -o ControlPath=$SSH_CONTROL_PATH" \
  apps/orora-web/ \
  $SERVER_USER@$SERVER_IP:$DEPLOY_PATH/apps/orora-web/
rsync -avz \
  -e "ssh $SSH_OPTS -o ControlPath=$SSH_CONTROL_PATH" \
  docker/docker-compose.orora-web.yml \
  $SERVER_USER@$SERVER_IP:$DEPLOY_PATH/docker/
echo "   ✅ Sync complete"

echo ""
echo "🔨 Building and starting container (Docker cache used)..."
sshpass -p "$SERVER_PASS" ssh $SSH_OPTS $SERVER_USER@$SERVER_IP "cd $DEPLOY_PATH && docker compose -f docker/docker-compose.orora-web.yml up -d --build"

echo ""
echo "⏳ Waiting for Orora Web to be ready..."
for i in 1 2 3 4 5 6 7 8 9 10; do
  if curl -s -m 3 -o /dev/null -w "%{http_code}" "http://$SERVER_IP:$ORORA_WEB_PORT/auth/login" 2>/dev/null | grep -q "200"; then
    echo "   ✅ Orora Web is healthy"
    break
  fi
  [ "$i" -eq 10 ] && echo "   ⚠️  Orora Web may still be starting" || sleep 2
done

echo ""
echo "✅ Deployment complete"
echo "================================================"
echo "   Orora Web: https://app.orora.rw  (or http://$SERVER_IP:$ORORA_WEB_PORT)"
echo "   API (shared): $API_URL"
echo ""
