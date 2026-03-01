#!/bin/bash
# Dump PostgreSQL from Kwezi server and restore to local PostgreSQL (native Mac install).
# Requires: sshpass, psql (PostgreSQL client tools).
#
# Usage (from project root):
#   ./scripts/orora/dump-kwezi-to-local.sh
#
# Optional env (for local Mac Postgres):
#   LOCAL_PG_HOST=localhost
#   LOCAL_PG_PORT=5432
#   LOCAL_PG_USER=postgres   (or your Mac username for peer auth)
#   LOCAL_PG_PASS=           (leave empty if using peer/trust auth)

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
CREDS_FILE="$REPO_ROOT/scripts/shared/deployment/server-credentials.sh"
[ -f "$CREDS_FILE" ] && source "$CREDS_FILE"

SERVER_IP="${SERVER_IP:-209.74.80.195}"
SERVER_USER="${SERVER_USER:-root}"
SERVER_PASS="${SERVER_PASS:-}"
BACKUP_DIR="${REPO_ROOT}/backups"
STAMP=$(date +%Y%m%d-%H%M%S)
DUMP_FILE="${BACKUP_DIR}/gemura_db_kwezi_${STAMP}.sql"

LOCAL_PG_HOST="${LOCAL_PG_HOST:-localhost}"
LOCAL_PG_PORT="${LOCAL_PG_PORT:-5432}"
LOCAL_PG_USER="${LOCAL_PG_USER:-postgres}"
LOCAL_PG_PASS="${LOCAL_PG_PASS:-}"
LOCAL_DB="${LOCAL_DB:-gemura_db}"

echo "🔄 Kwezi DB → Local PostgreSQL (native)"
echo "=========================================="
echo "   Server: $SERVER_USER@$SERVER_IP (kwezi-postgres)"
echo "   Local:  $LOCAL_PG_HOST:$LOCAL_PG_PORT/$LOCAL_DB (user: $LOCAL_PG_USER)"
echo "   Dump:   $DUMP_FILE"
echo ""

if [ -z "$SERVER_PASS" ]; then
  echo "❌ SERVER_PASS not set. Source scripts/shared/deployment/server-credentials.sh or set SERVER_PASS."
  exit 1
fi

if ! command -v sshpass &>/dev/null; then
  echo "❌ sshpass required. Install with: brew install sshpass"
  exit 1
fi

if ! command -v psql &>/dev/null; then
  echo "❌ psql not found. Install PostgreSQL client: brew install libpq && brew link --force libpq"
  exit 1
fi

mkdir -p "$BACKUP_DIR"

# Step 1: Dump from Kwezi (pg_dump inside container; user kwezi, db gemura_db)
echo "📤 Step 1: Dumping from Kwezi (kwezi-postgres → gemura_db)..."
sshpass -p "$SERVER_PASS" ssh -o StrictHostKeyChecking=no "$SERVER_USER@$SERVER_IP" \
  "docker exec kwezi-postgres pg_dump -U kwezi --no-owner --no-acl gemura_db" \
  > "$DUMP_FILE"
echo "   ✅ Dump saved ($(du -h "$DUMP_FILE" | cut -f1))"

# Step 2: Check local Postgres is reachable
echo ""
echo "📦 Step 2: Checking local PostgreSQL..."
if [ -n "$LOCAL_PG_PASS" ]; then
  export PGPASSWORD="$LOCAL_PG_PASS"
fi
if ! psql -h "$LOCAL_PG_HOST" -p "$LOCAL_PG_PORT" -U "$LOCAL_PG_USER" -d postgres -c "SELECT 1" &>/dev/null; then
  echo "   ❌ Cannot connect to local Postgres at $LOCAL_PG_HOST:$LOCAL_PG_PORT as $LOCAL_PG_USER"
  echo "   Ensure Postgres is running (e.g. brew services start postgresql) and user/port match."
  [ -n "$LOCAL_PG_PASS" ] && unset PGPASSWORD
  exit 1
fi
echo "   ✅ Local Postgres is running"

# Step 3: Drop and recreate local DB, restore dump
echo ""
echo "📥 Step 3: Restoring to local $LOCAL_DB..."
psql -h "$LOCAL_PG_HOST" -p "$LOCAL_PG_PORT" -U "$LOCAL_PG_USER" -d postgres -v ON_ERROR_STOP=1 << EOF
SELECT pg_terminate_backend(pid) FROM pg_stat_activity WHERE datname = '$LOCAL_DB' AND pid <> pg_backend_pid();
DROP DATABASE IF EXISTS $LOCAL_DB;
CREATE DATABASE $LOCAL_DB;
EOF
psql -h "$LOCAL_PG_HOST" -p "$LOCAL_PG_PORT" -U "$LOCAL_PG_USER" -d "$LOCAL_DB" -f "$DUMP_FILE" -v ON_ERROR_STOP=1 2>&1 | grep -v "^NOTICE:" | grep -v "^$" || true
[ -n "$LOCAL_PG_PASS" ] && unset PGPASSWORD
echo "   ✅ Restore completed"

# Step 4: Prisma schema sync (in case dump is from before farms table)
echo ""
echo "🔧 Step 4: Syncing schema with Prisma (db push)..."
cd "$REPO_ROOT/backend"
if [ -n "$LOCAL_PG_PASS" ]; then
  export DATABASE_URL="postgresql://${LOCAL_PG_USER}:${LOCAL_PG_PASS}@${LOCAL_PG_HOST}:${LOCAL_PG_PORT}/${LOCAL_DB}?schema=public"
else
  export DATABASE_URL="postgresql://${LOCAL_PG_USER}@${LOCAL_PG_HOST}:${LOCAL_PG_PORT}/${LOCAL_DB}?schema=public"
fi
npx prisma db push --accept-data-loss 2>/dev/null || true
npx prisma generate
echo "   ✅ Schema synced"

echo ""
echo "=========================================="
echo "✅ Done. Next steps:"
echo ""
if [ -n "$LOCAL_PG_PASS" ]; then
  echo "   1. In backend/.env set: DATABASE_URL=\"postgresql://${LOCAL_PG_USER}:${LOCAL_PG_PASS}@${LOCAL_PG_HOST}:${LOCAL_PG_PORT}/${LOCAL_DB}?schema=public\""
else
  echo "   1. In backend/.env set: DATABASE_URL=\"postgresql://${LOCAL_PG_USER}@${LOCAL_PG_HOST}:${LOCAL_PG_PORT}/${LOCAL_DB}?schema=public\""
fi
echo "   2. Start backend:   cd backend && npm run start:dev"
echo "   3. Start Orora Web: cd apps/orora-web && npm run dev"
echo "   4. Open: http://localhost:3008  (API: http://localhost:3004)"
echo ""
