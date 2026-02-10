#!/bin/bash
# Ensure Gemura backend is up on the production server.
# Uses same SSH approach as ResolveIT v2 (deploy-improved.sh) and Gemura deploy-to-server.sh.
#
# Run from your local machine (requires sshpass):
#   ./scripts/deployment/ensure-backend-up.sh
#
# Or run from ResolveIT v2 directory to use its pattern:
#   Same server (159.198.65.38); this script handles Gemura at /opt/gemura, port 3004.

set -e

# Use ResolveIT v2 server credentials when present (same server)
RESOLVEIT_CREDS="${RESOLVEIT_V2_CREDS:-/Applications/AMPPS/www/resolveit/v2/scripts/deployment/server-credentials.sh}"
[ -f "$RESOLVEIT_CREDS" ] && source "$RESOLVEIT_CREDS"
SERVER_IP="${SERVER_IP:-159.198.65.38}"
SERVER_USER="${SERVER_USER:-root}"
SERVER_PASS="${SERVER_PASS:-}"
DEPLOY_PATH="/opt/gemura"

if [ -z "$SERVER_PASS" ]; then
    echo "❌ SERVER_PASS not set. Source ResolveIT v2 credentials or set SERVER_PASS:"
    echo "   source /Applications/AMPPS/www/resolveit/v2/scripts/deployment/server-credentials.sh"
    echo "   Or: export SERVER_PASS=your_password"
    exit 1
fi

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
echo "🔍 Ensuring Gemura backend is up on server..."
echo "   Server: $SERVER_USER@$SERVER_IP"
echo "   Path:   $DEPLOY_PATH"
echo ""

if ! command -v sshpass &>/dev/null; then
    echo "❌ sshpass is required. Install with: brew install sshpass (or apt install sshpass)"
    exit 1
fi

# Run on server: ensure Docker, devslab-postgres, then Gemura backend; verify health
sshpass -p "$SERVER_PASS" ssh -o StrictHostKeyChecking=no "$SERVER_USER@$SERVER_IP" << 'ENDSSH'
set -e
DEPLOY_PATH="/opt/gemura"

echo "1. Docker..."
if ! docker info &>/dev/null; then
    echo "   Starting Docker..."
    systemctl start docker 2>/dev/null || service docker start 2>/dev/null || true
    sleep 2
fi
if ! docker info &>/dev/null; then
    echo "   ❌ Docker is not running. Start it on the server and re-run."
    exit 1
fi
echo "   ✅ Docker is running"

echo ""
echo "2. PostgreSQL (devslab-postgres)..."
if ! docker ps --format '{{.Names}}' | grep -qx devslab-postgres; then
    echo "   Starting PostgreSQL..."
    if [ -f "$DEPLOY_PATH/docker-compose.devlabs-db.yml" ]; then
        cd "$DEPLOY_PATH" && docker compose -f docker-compose.devlabs-db.yml up -d
        sleep 5
    else
        echo "   ⚠️  docker-compose.devlabs-db.yml not found; assuming Postgres is elsewhere"
    fi
fi
if docker ps --format '{{.Names}}' | grep -qx devslab-postgres; then
    echo "   ✅ devslab-postgres is running"
else
    echo "   ⚠️  devslab-postgres not running (Gemura may fail if it needs DB)"
fi

echo ""
echo "3. Gemura backend..."
if [ ! -f "$DEPLOY_PATH/docker-compose.gemura.yml" ] || [ ! -f "$DEPLOY_PATH/.env.devlabs" ]; then
    echo "   ❌ $DEPLOY_PATH not set up (missing docker-compose.gemura.yml or .env.devlabs). Deploy first: ./scripts/deployment/deploy-to-server.sh"
    exit 1
fi

cd "$DEPLOY_PATH"
if ! docker ps --format '{{.Names}}' | grep -qx gemura-backend; then
    echo "   Starting Gemura backend..."
    docker compose -f docker-compose.gemura.yml --env-file .env.devlabs up -d backend
    echo "   Waiting for backend to be ready..."
    for i in 1 2 3 4 5 6 7 8 9 10; do
        if curl -s -o /dev/null -w "%{http_code}" http://127.0.0.1:3004/api/health 2>/dev/null | grep -q "200"; then
            echo "   ✅ Backend is up"
            break
        fi
        sleep 2
    done
else
    echo "   Container already running; checking health..."
fi

echo ""
echo "4. Health check..."
if curl -s http://127.0.0.1:3004/api/health > /dev/null 2>&1; then
    echo "   ✅ Backend health: OK"
    curl -s http://127.0.0.1:3004/api/health | head -c 200
    echo ""
else
    echo "   ❌ Health check failed. Restarting backend..."
    docker compose -f docker-compose.gemura.yml --env-file .env.devlabs restart backend
    sleep 5
    if curl -s http://127.0.0.1:3004/api/health > /dev/null 2>&1; then
        echo "   ✅ Backend is up after restart"
    else
        echo "   ❌ Still unhealthy. Check logs: docker logs gemura-backend --tail 80"
        exit 1
    fi
fi
ENDSSH

echo ""
echo "=========================================="
echo "✅ Gemura backend is up on the server."
echo "   Health (from server): http://127.0.0.1:3004/api/health"
echo "   From outside (if firewall allows): http://$SERVER_IP:3004/api/health"
echo "   Logs: ssh $SERVER_USER@$SERVER_IP 'cd $DEPLOY_PATH && docker compose -f docker-compose.gemura.yml logs -f backend'"
echo "=========================================="
