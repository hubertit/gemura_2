#!/bin/bash
# Ensure Gemura app (backend + frontend) is up on the server. Does NOT touch the database.
# Run from project root: ./scripts/deployment/ensure-app-up.sh

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CREDS_FILE="$SCRIPT_DIR/server-credentials.sh"
[ -f "$CREDS_FILE" ] && source "$CREDS_FILE"
[ -n "${GEMURA_SERVER_CREDS:-}" ] && [ -f "$GEMURA_SERVER_CREDS" ] && source "$GEMURA_SERVER_CREDS"
SERVER_IP="${SERVER_IP:-209.74.80.195}"
SERVER_USER="${SERVER_USER:-root}"
SERVER_PASS="${SERVER_PASS:-}"
DEPLOY_PATH="/opt/gemura"

if [ -z "$SERVER_PASS" ]; then
    echo "❌ SERVER_PASS not set. See scripts/deployment/server-credentials.sh"
    exit 1
fi

if ! command -v sshpass &>/dev/null; then
    echo "❌ sshpass required. Install: brew install sshpass"
    exit 1
fi

echo "🔄 Ensuring Gemura app is up (backend + frontend only, no DB changes)..."
echo "   Server: $SERVER_USER@$SERVER_IP"
echo ""

sshpass -p "$SERVER_PASS" ssh -o StrictHostKeyChecking=no "$SERVER_USER@$SERVER_IP" << 'ENDSSH'
set -e
DEPLOY_PATH="/opt/gemura"

echo "1. Docker..."
if ! docker info &>/dev/null; then
    systemctl start docker 2>/dev/null || service docker start 2>/dev/null || true
    sleep 3
fi
if ! docker info &>/dev/null; then
    echo "   ❌ Docker not running."
    exit 1
fi
echo "   ✅ Docker running"

echo ""
echo "2. App containers (backend + frontend)..."
cd "$DEPLOY_PATH"
ENV_FILE=""
[ -f .env.devlabs ] && ENV_FILE="--env-file .env.devlabs"

if [ -f docker-compose.gemura.prebuilt.yml ]; then
    COMPOSE="-f docker-compose.gemura.prebuilt.yml"
elif [ -f docker-compose.gemura.yml ]; then
    COMPOSE="-f docker-compose.gemura.yml"
else
    echo "   ❌ No compose file found in $DEPLOY_PATH"
    exit 1
fi

# Start or restart backend and frontend only (no DB)
docker compose $COMPOSE $ENV_FILE up -d backend frontend 2>/dev/null || true
docker compose $COMPOSE $ENV_FILE restart backend frontend
echo "   ✅ Backend and frontend restarted"

echo ""
echo "3. Waiting for app to be ready..."
sleep 8

echo ""
echo "4. Status..."
docker ps --filter name=gemura-backend --filter name=gemura-frontend --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}"

BACKEND_OK=0
FRONTEND_OK=0
if curl -s -o /dev/null -w "%{http_code}" http://127.0.0.1:3004/api/health 2>/dev/null | grep -q "200"; then
    BACKEND_OK=1
fi
if curl -s -o /dev/null -w "%{http_code}" --connect-timeout 3 http://127.0.0.1:3005 2>/dev/null | grep -qE "200|301|302"; then
    FRONTEND_OK=1
fi

echo ""
if [ "$BACKEND_OK" = "1" ]; then
    echo "   ✅ Backend health: OK (http://127.0.0.1:3004/api/health)"
else
    echo "   ⚠️  Backend not responding yet (may need a few more seconds)"
fi
if [ "$FRONTEND_OK" = "1" ]; then
    echo "   ✅ Frontend: OK (http://127.0.0.1:3005)"
else
    echo "   ⚠️  Frontend not responding yet (may need a few more seconds)"
fi
ENDSSH

echo ""
echo "=========================================="
echo "✅ App bring-up complete."
echo "   Backend:  http://$SERVER_IP:3004/api"
echo "   Frontend: http://$SERVER_IP:3005"
echo "=========================================="
