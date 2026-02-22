#!/bin/bash
# Ensure all Gemura + DevLabs containers on the server are up and running.
# Safe to run after a reboot or when something is stopped. Does not remove
# any containers or volumes (no data loss). Uses "up -d" only (no --force-recreate).
#
# Run from project root:
#   ./scripts/deployment/ensure-all-containers-up.sh
#
# Or on the server:
#   cd /opt/gemura && bash scripts/deployment/ensure-all-containers-up.sh
#   (set SERVER_IP= to skip SSH and run locally)

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
CREDS_FILE="$SCRIPT_DIR/server-credentials.sh"
[ -f "$CREDS_FILE" ] && source "$CREDS_FILE"
[ -n "${GEMURA_SERVER_CREDS:-}" ] && [ -f "$GEMURA_SERVER_CREDS" ] && source "$GEMURA_SERVER_CREDS"
SERVER_IP="${SERVER_IP:-159.198.65.38}"
SERVER_USER="${SERVER_USER:-root}"
SERVER_PASS="${SERVER_PASS:-}"
DEPLOY_PATH="/opt/gemura"

SSH_OPTS="-o StrictHostKeyChecking=no -o ServerAliveInterval=30 -o ServerAliveCountMax=6 -o ConnectTimeout=15"

if [ -z "$SERVER_PASS" ]; then
  echo "❌ SERVER_PASS not set. Configure scripts/deployment/server-credentials.sh"
  exit 1
fi
if ! command -v sshpass &>/dev/null; then
  echo "❌ sshpass required. Install with: brew install sshpass"
  exit 1
fi

echo "🔄 Ensuring all containers are up on ${SERVER_IP}..."
echo ""

sshpass -p "$SERVER_PASS" ssh $SSH_OPTS $SERVER_USER@$SERVER_IP 'bash -s' << 'ENDSSH'
export LC_ALL=C.UTF-8
DEPLOY_PATH="/opt/gemura"
cd "$DEPLOY_PATH" 2>/dev/null || { echo "❌ $DEPLOY_PATH not found. Deploy first."; exit 1; }

echo "1. Docker..."
if ! docker info &>/dev/null; then
  echo "   Starting Docker..."
  systemctl start docker 2>/dev/null || service docker start 2>/dev/null || true
  sleep 3
fi
if ! docker info &>/dev/null; then
  echo "   ❌ Docker not running. On server: systemctl start docker"
  exit 1
fi
echo "   ✅ Docker is running"

echo ""
echo "2. PostgreSQL (devslab-postgres)..."
if [ ! -f docker-compose.devlabs-db.yml ]; then
  echo "   ⚠️  docker-compose.devlabs-db.yml not found"
else
  docker network create devslab-network 2>/dev/null || true
  if ! docker ps --format '{{.Names}}' | grep -qx devslab-postgres; then
    echo "   Starting PostgreSQL..."
    docker compose -f docker-compose.devlabs-db.yml up -d
    sleep 5
  fi
  if docker ps --format '{{.Names}}' | grep -qx devslab-postgres; then
    echo "   ✅ devslab-postgres is running"
  else
    echo "   ❌ devslab-postgres failed to start"
  fi
fi

echo ""
echo "3. Gemura backend & frontend..."
if [ ! -f docker-compose.gemura.prebuilt.yml ]; then
  echo "   ⚠️  docker-compose.gemura.prebuilt.yml not found (run full deploy first)"
else
  if [ ! -f .env.devlabs ]; then
    echo "   Creating .env.devlabs..."
    cat > .env.devlabs << 'EOF'
POSTGRES_USER=devslab_admin
POSTGRES_PASSWORD=devslab_secure_password_2024
POSTGRES_DB=postgres
POSTGRES_PORT=5433
BACKEND_PORT=3004
FRONTEND_PORT=3005
CORS_ORIGIN=http://localhost:3005,http://localhost:3004,http://159.198.65.38:3005,http://159.198.65.38:3004
NEXT_PUBLIC_API_URL=http://159.198.65.38:3004/api
DATABASE_URL=postgresql://devslab_admin:devslab_secure_password_2024@devslab-postgres:5432/gemura_db
EOF
  fi
  echo "   Starting Gemura (up -d, no force-recreate)..."
  docker compose -f docker-compose.gemura.prebuilt.yml --env-file .env.devlabs up -d
  sleep 5
  if docker ps --format '{{.Names}}' | grep -qx gemura-backend; then
    echo "   ✅ gemura-backend is running"
  else
    echo "   ❌ gemura-backend not running"
  fi
  if docker ps --format '{{.Names}}' | grep -qx gemura-frontend; then
    echo "   ✅ gemura-frontend is running"
  else
    echo "   ❌ gemura-frontend not running"
  fi
fi

echo ""
echo "4. Health check..."
if curl -s -o /dev/null -w "%{http_code}" http://localhost:3004/api/health 2>/dev/null | grep -q "200"; then
  echo "   ✅ Backend API: healthy"
else
  echo "   ⚠️  Backend API: not responding yet (may still be starting)"
fi

echo ""
echo "5. All containers on server:"
docker ps -a --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}" | head -30

echo ""
echo "   Done."
ENDSSH

echo ""
echo "================================================"
echo "✅ Ensure-all-containers complete."
echo "   Backend:  http://159.198.65.38:3004/api"
echo "   Frontend: http://159.198.65.38:3005"
echo "================================================"
