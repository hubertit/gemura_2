#!/bin/bash
#
# Safe Gemura-only deployment:
# - Deploys ONLY Gemura backend and frontend containers.
# - Does NOT start, stop, or modify the database container (devslab-postgres).
# - Does NOT run any DB operations (no backup, no CREATE DATABASE, no migrations
#   that could drop data — backend still runs "prisma migrate deploy" on startup,
#   which is additive only).
# - Does NOT touch any other containers (ResolveIT, etc.).
#
# Usage (from project root):
#   ./scripts/deployment/deploy-gemura-only-safe.sh
#
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

if [ -z "$SERVER_PASS" ]; then
  echo "❌ SERVER_PASS not set. Configure scripts/deployment/server-credentials.sh or export SERVER_PASS."
  exit 1
fi

SSH_OPTS="-o StrictHostKeyChecking=no -o ServerAliveInterval=30 -o ServerAliveCountMax=6 -o ConnectTimeout=15"
SCP_OPTS="-o StrictHostKeyChecking=no -o ServerAliveInterval=30 -o ServerAliveCountMax=6 -o ConnectTimeout=15"

echo "🚀 Safe Gemura-only deployment (DB and other containers untouched)"
echo "================================================"

echo ""
echo "🔌 Checking connectivity to $SERVER_IP..."
if ! sshpass -p "$SERVER_PASS" ssh $SSH_OPTS $SERVER_USER@$SERVER_IP "echo OK" 2>/dev/null; then
  echo "❌ Cannot reach the server."
  exit 1
fi
echo "   ✅ Server reachable"

echo ""
echo "🌐 Step 1: Building frontend locally..."
( cd "$REPO_ROOT/web" && NEXT_PUBLIC_API_URL=http://159.198.65.38:3004/api npm run build ) || {
  echo "   ❌ Local frontend build failed."
  exit 1
}
echo "   ✅ Frontend built"

echo ""
echo "📤 Step 2: Uploading to server (Gemura only; not overwriting DB compose)..."
( cd "$REPO_ROOT" && COPYFILE_DISABLE=1 tar -czf /tmp/gemura-deploy.tar.gz \
  --exclude='backend/node_modules' --exclude='backend/dist' \
  --exclude='web/node_modules' --exclude='web/dist' \
  backend/ web/ docker-compose.gemura.prebuilt.yml scripts/deployment/ )
echo "   ✅ Archive created (no docker-compose.devlabs-db.yml in archive)"

upload_ok=
for attempt in 1 2; do
  sshpass -p "$SERVER_PASS" ssh $SSH_OPTS $SERVER_USER@$SERVER_IP "mkdir -p $DEPLOY_PATH" 2>/dev/null || true
  echo "   Uploading..."
  if ! sshpass -p "$SERVER_PASS" scp $SCP_OPTS /tmp/gemura-deploy.tar.gz $SERVER_USER@$SERVER_IP:/tmp/ 2>/dev/null; then
    [ "$attempt" -eq 1 ] && echo "   Retrying in 15s..." && sleep 15
    continue
  fi
  echo "   Extracting (only Gemura paths; leaving docker-compose.devlabs-db.yml and other files unchanged)..."
  extract_cmd="cd $DEPLOY_PATH && rm -rf backend web docker-compose.gemura.prebuilt.yml scripts/deployment && tar -xzf /tmp/gemura-deploy.tar.gz && rm /tmp/gemura-deploy.tar.gz"
  if ! sshpass -p "$SERVER_PASS" ssh $SSH_OPTS $SERVER_USER@$SERVER_IP "$extract_cmd" 2>/dev/null; then
    [ "$attempt" -eq 1 ] && echo "   Retrying in 15s..." && sleep 15
    continue
  fi
  upload_ok=1
  break
done
rm -f /tmp/gemura-deploy.tar.gz
if [ -z "$upload_ok" ]; then
  echo "   ❌ Upload failed after 2 attempts."
  exit 1
fi
echo "   ✅ Upload and extract OK"

echo ""
echo "🔨 Step 3: Restarting only Gemura containers (backend + frontend)..."
sshpass -p "$SERVER_PASS" ssh $SSH_OPTS $SERVER_USER@$SERVER_IP 'bash -s' << 'ENDSSH'
export LC_ALL=C.UTF-8
cd /opt/gemura

# Do not touch Docker daemon, devslab-postgres, or any other container.
# Only use docker-compose.gemura.prebuilt.yml (backend + frontend).

[ -f .env.devlabs ] || cat > .env.devlabs << 'EOF'
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

echo "   Stopping only Gemura backend and frontend..."
docker compose -f docker-compose.gemura.prebuilt.yml --env-file .env.devlabs down --timeout 30 2>/dev/null || true
sleep 3

echo "   Building Gemura backend and frontend images..."
docker compose -f docker-compose.gemura.prebuilt.yml --env-file .env.devlabs build backend frontend

echo "   Starting Gemura backend and frontend (no other services)..."
docker compose -f docker-compose.gemura.prebuilt.yml --env-file .env.devlabs up -d --force-recreate --no-deps backend frontend

echo ""
echo "   ⏳ Waiting for backend to be ready..."
for i in 1 2 3 4 5 6 7 8 9 10 11 12; do
  if curl -s http://localhost:3004/api/health > /dev/null 2>&1; then
    echo "   ✅ Backend is healthy"
    break
  fi
  [ "$i" -eq 12 ] && echo "   ⚠️  Backend may still be starting (check logs if needed)" || sleep 5
done

echo ""
echo "   📊 Gemura containers only:"
docker compose -f docker-compose.gemura.prebuilt.yml --env-file .env.devlabs ps

echo ""
echo "   ✅ Safe deploy done. DB and other containers were not touched."
ENDSSH

echo ""
echo "✅ Safe deployment complete"
echo "================================================"
echo "   Backend: http://159.198.65.38:3004/api"
echo "   Frontend: http://159.198.65.38:3005"
echo "   Database and non-Gemura containers were not modified."
echo ""
