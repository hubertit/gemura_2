#!/usr/bin/env bash
# Clean and repopulate locations on production (gemura_db on Kwezi).
# Uses the same logic as local: backend/prisma/clean-and-seed-locations.ts
# (full Rwanda hierarchy from dsacco_adm_location.tsv, or minimal seed if TSV missing).
#
# Usage (from repo root):
#   ./scripts/shared/deployment/run-prod-seed-locations.sh
#
# Requires: server-credentials.sh with SERVER_PASS.

set -e
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/../../.." && pwd)"
BACKEND="$REPO_ROOT/backend"
[ -f "$SCRIPT_DIR/server-credentials.sh" ] && source "$SCRIPT_DIR/server-credentials.sh"
SERVER_IP="${SERVER_IP:-209.74.80.195}"
SERVER_USER="${SERVER_USER:-root}"
DEPLOY_PATH="${GEMURA_DEPLOY_PATH:-/opt/gemura}"

if [ -z "${SERVER_PASS}" ]; then
  echo "❌ SERVER_PASS not set. Source server-credentials.sh or export it."
  exit 1
fi

# Compile seed script to JS (so we can run with node in the API image)
echo "📦 Compiling seed script..."
( cd "$BACKEND" && npx tsc prisma/clean-and-seed-locations.ts --outDir dist/prisma --module commonjs --esModuleInterop --skipLibCheck --resolveJsonModule --target ES2021 --declaration false --sourceMap false ) || true
cp "$BACKEND/prisma/dsacco_adm_location.tsv" "$BACKEND/dist/prisma/" 2>/dev/null || true
if [ ! -f "$BACKEND/dist/prisma/clean-and-seed-locations.js" ]; then
  echo "❌ Compiled script not found. Run from repo root and ensure backend has dist/prisma/clean-and-seed-locations.js"
  exit 1
fi

# Upload JS + TSV to server
echo "📤 Uploading seed files to server..."
sshpass -p "$SERVER_PASS" ssh -o StrictHostKeyChecking=no -o ConnectTimeout=15 "$SERVER_USER@$SERVER_IP" "mkdir -p $DEPLOY_PATH/seed-locations"
sshpass -p "$SERVER_PASS" scp -o StrictHostKeyChecking=no -o ConnectTimeout=15 \
  "$BACKEND/dist/prisma/clean-and-seed-locations.js" \
  "$BACKEND/dist/prisma/dsacco_adm_location.tsv" \
  "$SERVER_USER@$SERVER_IP:$DEPLOY_PATH/seed-locations/"

SSH_OPTS="-o StrictHostKeyChecking=no -o ConnectTimeout=15"
echo "📍 Cleaning and repopulating locations on prod (gemura_db)..."
sshpass -p "$SERVER_PASS" ssh $SSH_OPTS "$SERVER_USER@$SERVER_IP" "bash -s" << 'ENDSSH'
set -e
cd /opt/gemura
set -a
[ -f .env ] && . ./.env
[ -f /opt/kwezi/.env ] && . /opt/kwezi/.env
set +a
export DATABASE_URL="${DATABASE_URL:-postgresql://${POSTGRES_USER:-kwezi}:${POSTGRES_PASSWORD}@kwezi-postgres:5432/gemura_db?schema=public}"
if [ -z "$DATABASE_URL" ] || [ "$DATABASE_URL" = "postgresql://@kwezi-postgres" ]; then
  echo "❌ DATABASE_URL not set. Ensure /opt/gemura/.env or /opt/kwezi/.env has DB credentials."
  exit 1
fi
echo "   Using database: gemura_db"
echo "   Running clean-and-seed..."
docker run --rm \
  --network kwezi_default \
  -e DATABASE_URL \
  -v "$(pwd)/seed-locations:/app/seed-locations:ro" \
  -w /app \
  docker-gemura-api \
  node /app/seed-locations/clean-and-seed-locations.js
echo "   ✅ Done."
ENDSSH
echo "✅ Prod locations cleaned and repopulated."
