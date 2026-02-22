#!/bin/bash
# Backup production PostgreSQL database and restore to local PostgreSQL
#
# Usage:
#   ./scripts/deployment/backup-production-to-local.sh
#
# Environment variables (optional):
#   PROD_HOST=159.198.65.38     # Production server
#   PROD_PORT=5433               # Production PostgreSQL port
#   PROD_USER=devslab_admin
#   PROD_PASSWORD=devslab_secure_password_2024
#   PROD_DB=gemura_db
#
#   LOCAL_HOST=localhost         # Local PostgreSQL host
#   LOCAL_PORT=5432             # Local PostgreSQL port (5432 native, 5433 if using docker-compose.devlabs-db)
#   LOCAL_USER=postgres         # Local PostgreSQL user
#   LOCAL_PASSWORD=            # Local password (empty for trust auth)
#   LOCAL_DB=gemura_db
#
#   BACKUP_DIR=./backups       # Where to store backup files
#
# Prerequisites:
#   - pg_dump and psql in PATH (PostgreSQL client tools)
#   - Network access to production server
#   - Local PostgreSQL running (native or via docker-compose.devlabs-db.yml)

set -e

# Production database (remote)
PROD_HOST="${PROD_HOST:-159.198.65.38}"
PROD_PORT="${PROD_PORT:-5433}"
PROD_USER="${PROD_USER:-devslab_admin}"
PROD_PASS="${PROD_PASSWORD:-devslab_secure_password_2024}"
PROD_DB="${PROD_DB:-gemura_db}"

# Local database
LOCAL_HOST="${LOCAL_HOST:-localhost}"
LOCAL_PORT="${LOCAL_PORT:-5432}"
LOCAL_USER="${LOCAL_USER:-postgres}"
LOCAL_PASS="${LOCAL_PASSWORD:-}"
LOCAL_DB="${LOCAL_DB:-gemura_db}"

# Backup directory (relative to project root)
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
BACKUP_DIR="${BACKUP_DIR:-$PROJECT_ROOT/backups}"
STAMP=$(date +%Y%m%d-%H%M%S)
DUMP_FILE="$BACKUP_DIR/gemura_db_prod_$STAMP.sql"

echo "🔄 Backup Production to Local PostgreSQL"
echo "========================================"
echo ""
echo "Production: $PROD_HOST:$PROD_PORT/$PROD_DB (user: $PROD_USER)"
echo "Local:      $LOCAL_HOST:$LOCAL_PORT/$LOCAL_DB (user: $LOCAL_USER)"
echo "Backup:     $DUMP_FILE"
echo ""

# Check for pg_dump and psql
if ! command -v pg_dump &>/dev/null; then
  echo "❌ pg_dump not found. Install PostgreSQL client tools:"
  echo "   macOS: brew install libpq && brew link --force libpq"
  echo "   Ubuntu: sudo apt-get install postgresql-client"
  exit 1
fi
if ! command -v psql &>/dev/null; then
  echo "❌ psql not found. Install PostgreSQL client tools."
  exit 1
fi

mkdir -p "$BACKUP_DIR"

# Step 1: Dump from production
echo "📤 Step 1: Dumping from production..."
export PGPASSWORD="$PROD_PASS"
if ! pg_dump -h "$PROD_HOST" -p "$PROD_PORT" -U "$PROD_USER" -d "$PROD_DB" \
  --no-owner --no-acl -f "$DUMP_FILE" 2>/dev/null; then
  echo "   Trying Docker (pg_dump 15) for version compatibility..."
  if command -v docker &>/dev/null; then
    docker run --rm -e PGPASSWORD="$PROD_PASS" -v "$BACKUP_DIR:/backup" postgres:15-alpine \
      pg_dump -h "$PROD_HOST" -p "$PROD_PORT" -U "$PROD_USER" -d "$PROD_DB" \
      --no-owner --no-acl -f "/backup/$(basename "$DUMP_FILE")" || {
      echo "   ❌ Docker pg_dump failed."
      unset PGPASSWORD
      exit 1
    }
  else
    echo "   ❌ Failed to dump from production."
    echo "   Check: network access, credentials, or upgrade pg_dump (brew upgrade libpq)."
    unset PGPASSWORD
    exit 1
  fi
fi
unset PGPASSWORD
echo "   ✅ Dump saved to $DUMP_FILE"

# Get dump size
DUMP_SIZE=$(ls -lh "$DUMP_FILE" | awk '{print $5}')
echo "   Size: $DUMP_SIZE"
echo ""

# Step 2: Ensure local database exists and restore
echo "📥 Step 2: Restoring to local PostgreSQL..."

# Set local password if provided
if [ -n "$LOCAL_PASS" ]; then
  export PGPASSWORD="$LOCAL_PASS"
fi

# Terminate existing connections and drop/recreate database
echo "   Dropping and recreating local database $LOCAL_DB..."
psql -h "$LOCAL_HOST" -p "$LOCAL_PORT" -U "$LOCAL_USER" -d postgres -v ON_ERROR_STOP=1 << EOF
SELECT pg_terminate_backend(pid) FROM pg_stat_activity WHERE datname = '$LOCAL_DB' AND pid <> pg_backend_pid();
DROP DATABASE IF EXISTS $LOCAL_DB;
CREATE DATABASE $LOCAL_DB;
EOF

echo "   Restoring data..."
set +e
psql -h "$LOCAL_HOST" -p "$LOCAL_PORT" -U "$LOCAL_USER" -d "$LOCAL_DB" -f "$DUMP_FILE" 2>&1 | grep -v "^NOTICE:" | grep -v "^$" || true
set -e
echo "   ✅ Restore completed"

if [ -n "$LOCAL_PASS" ]; then
  unset PGPASSWORD
fi

# Step 3: Verify
echo ""
echo "✅ Step 3: Verifying restore..."
TABLE_COUNT=$(psql -h "$LOCAL_HOST" -p "$LOCAL_PORT" -U "$LOCAL_USER" -d "$LOCAL_DB" -t -A -c \
  "SELECT COUNT(*) FROM information_schema.tables WHERE table_schema = 'public' AND table_type = 'BASE TABLE';" 2>/dev/null || echo "0")
USER_COUNT=$(psql -h "$LOCAL_HOST" -p "$LOCAL_PORT" -U "$LOCAL_USER" -d "$LOCAL_DB" -t -A -c \
  "SELECT COUNT(*) FROM users;" 2>/dev/null || echo "0")
ACCOUNT_COUNT=$(psql -h "$LOCAL_HOST" -p "$LOCAL_PORT" -U "$LOCAL_USER" -d "$LOCAL_DB" -t -A -c \
  "SELECT COUNT(*) FROM accounts;" 2>/dev/null || echo "0")

echo "   Tables:  $TABLE_COUNT"
echo "   Users:  $USER_COUNT"
echo "   Accounts: $ACCOUNT_COUNT"
echo ""
echo "✅ Backup and restore complete!"
echo ""
echo "📋 Next steps:"
if [ -n "$LOCAL_PASS" ]; then
  echo "   1. Update backend/.env to use local database:"
  echo "      DATABASE_URL=\"postgresql://$LOCAL_USER:$LOCAL_PASS@$LOCAL_HOST:$LOCAL_PORT/$LOCAL_DB?schema=public\""
else
  echo "   1. Update backend/.env to use local database:"
  echo "      DATABASE_URL=\"postgresql://$LOCAL_USER@$LOCAL_HOST:$LOCAL_PORT/$LOCAL_DB?schema=public\""
fi
echo ""
echo "   2. Run Prisma to sync schema (if needed):"
echo "      cd backend && npx prisma migrate deploy"
echo ""
echo "   3. Start backend:"
echo "      cd backend && npm run start:dev"
echo ""
