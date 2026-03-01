#!/bin/bash
# Diagnose and fix Orora Web 502 on production (e.g. after backend deploy).
# - Checks if orora-ui container is running and if port 3011 responds
# - Shows last log lines
# - Restarts Orora Web and waits for health
#
# Usage (from repo root):
#   ./scripts/orora/deployment/check-and-restart-orora-web.sh
#
set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/../../.." && pwd)"
CREDS_FILE="$REPO_ROOT/scripts/shared/deployment/server-credentials.sh"
[ -f "$CREDS_FILE" ] && source "$CREDS_FILE"

SERVER_IP="${SERVER_IP:-209.74.80.195}"
SERVER_USER="${SERVER_USER:-root}"
SERVER_PASS="${SERVER_PASS:-}"
ORORA_DEPLOY_PATH="${ORORA_DEPLOY_PATH:-/opt/orora}"
ORORA_WEB_PORT="${ORORA_WEB_PORT:-3011}"

if [ -z "$SERVER_PASS" ]; then
  echo "❌ SERVER_PASS not set. Configure scripts/shared/deployment/server-credentials.sh or export SERVER_PASS."
  exit 1
fi

SSH_OPTS="-o StrictHostKeyChecking=no -o ServerAliveInterval=30 -o ConnectTimeout=15"

echo "🔍 Orora Web diagnostic (Kwezi: $SERVER_IP)"
echo "================================================"

sshpass -p "$SERVER_PASS" ssh $SSH_OPTS $SERVER_USER@$SERVER_IP "ORORA_WEB_PORT=$ORORA_WEB_PORT ORORA_DEPLOY_PATH='$ORORA_DEPLOY_PATH' bash -s" << 'ENDSSH'
set -e
echo ""
echo "1️⃣  Container status (orora-ui):"
docker ps -a --filter name=orora-ui --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}" || true

echo ""
echo "2️⃣  Port $ORORA_WEB_PORT (host):"
if command -v ss >/dev/null 2>&1; then
  ss -tlnp 2>/dev/null | grep ":$ORORA_WEB_PORT " || echo "   Nothing listening on $ORORA_WEB_PORT"
else
  netstat -tlnp 2>/dev/null | grep ":$ORORA_WEB_PORT " || echo "   (ss/netstat not available)"
fi

echo ""
echo "3️⃣  HTTP check (localhost:$ORORA_WEB_PORT/auth/login):"
CODE=$(curl -s -o /dev/null -w "%{http_code}" -m 5 "http://127.0.0.1:$ORORA_WEB_PORT/auth/login" 2>/dev/null || echo "000")
if [ "$CODE" = "200" ]; then
  echo "   ✅ Returns 200 (Orora Web is up)"
else
  echo "   ❌ Returns $CODE (or connection failed) – likely cause of 502"
fi

echo ""
echo "4️⃣  Last 35 lines of orora-ui logs:"
docker logs orora-ui --tail 35 2>&1 || true

echo ""
echo "5️⃣  Restarting Orora Web..."
cd "$ORORA_DEPLOY_PATH"
docker compose -f docker/docker-compose.orora-web.yml restart

echo ""
echo "   Waiting for Orora Web to be ready (up to 30s)..."
for i in 1 2 3 4 5 6 7 8 9 10 11 12 13 14 15; do
  if curl -s -m 3 "http://127.0.0.1:$ORORA_WEB_PORT/auth/login" >/dev/null 2>&1; then
    echo "   ✅ Orora Web is healthy"
    break
  fi
  [ $i -eq 15 ] && echo "   ⚠️  Still not responding; check logs: docker logs orora-ui -f"
  sleep 2
done
ENDSSH

echo ""
echo "================================================"
echo "   Test from your machine:"
echo "   curl -I http://$SERVER_IP:$ORORA_WEB_PORT/auth/login"
echo "   or https://app.orora.rw"
echo ""
