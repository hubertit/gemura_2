#!/bin/bash
# Restart the Gemura frontend container on the production server.
# Run from project root (uses same credentials as deploy-to-server.sh):
#   ./scripts/deployment/restart-frontend-on-server.sh

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
    echo "❌ SERVER_PASS not set. Set up project credentials:"
    echo "   cp scripts/deployment/server-credentials.sh.example scripts/deployment/server-credentials.sh"
    echo "   Edit server-credentials.sh and set SERVER_PASS. Or: export SERVER_PASS=your_password"
    exit 1
fi

if ! command -v sshpass &>/dev/null; then
    echo "❌ sshpass is required. Install with: brew install sshpass (or apt install sshpass)"
    exit 1
fi

echo "🔄 Restarting Gemura frontend on server..."
echo "   Server: $SERVER_USER@$SERVER_IP"
echo "   Path:   $DEPLOY_PATH"
echo ""

sshpass -p "$SERVER_PASS" ssh -o StrictHostKeyChecking=no "$SERVER_USER@$SERVER_IP" << 'ENDSSH'
set -e
DEPLOY_PATH="/opt/gemura"
cd "$DEPLOY_PATH"

if [ -f docker-compose.gemura.prebuilt.yml ]; then
    echo "Using docker-compose.gemura.prebuilt.yml..."
    docker compose -f docker-compose.gemura.prebuilt.yml restart frontend
elif [ -f docker-compose.gemura.yml ]; then
    echo "Using docker-compose.gemura.yml..."
    docker compose -f docker-compose.gemura.yml restart frontend
else
    echo "Restarting container by name..."
    docker restart gemura-frontend
fi

echo ""
echo "Waiting a few seconds for container to come up..."
sleep 5
docker ps --filter name=gemura-frontend --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}"
ENDSSH

echo ""
echo "=========================================="
echo "✅ Frontend restart requested on server."
echo "   App URL: http://$SERVER_IP:3005"
echo "   Logs:    ssh $SERVER_USER@$SERVER_IP 'docker logs gemura-frontend --tail 50'"
echo "=========================================="
