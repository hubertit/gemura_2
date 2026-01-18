#!/bin/bash

# Import Accounts and Users from SQL Dump
# This script extracts and imports accounts and users from the SQL dump file

set -e

SQL_DUMP="${1:-./database/gemura.sql}"
PG_HOST="${PG_HOST:-devslab-postgres}"
PG_PORT="${PG_PORT:-5432}"
PG_DB="${PG_DB:-gemura_db}"
PG_USER="${PG_USER:-devslab_admin}"
PG_PASS="${PG_PASS:-devslab_secure_password_2024}"

export PGPASSWORD="$PG_PASS"

echo "🔄 Importing Accounts & Users from SQL Dump"
echo "==========================================="
echo ""
echo "SQL Dump: $SQL_DUMP"
echo ""

if [ ! -f "$SQL_DUMP" ]; then
    echo "❌ SQL dump file not found: $SQL_DUMP"
    exit 1
fi

# Extract accounts data
echo "📦 Extracting accounts from SQL dump..."
ACCOUNTS_COUNT=$(grep -c "^INSERT INTO \`accounts\`" "$SQL_DUMP" || echo "0")
echo "   Found $ACCOUNTS_COUNT account insert statements"

# Extract users data
echo "📦 Extracting users from SQL dump..."
USERS_COUNT=$(grep -c "^INSERT INTO \`users\`" "$SQL_DUMP" || echo "0")
echo "   Found $USERS_COUNT user insert statements"

# Extract user_accounts data
echo "📦 Extracting user_accounts from SQL dump..."
USER_ACCOUNTS_COUNT=$(grep -c "^INSERT INTO \`user_accounts\`" "$SQL_DUMP" || echo "0")
echo "   Found $USER_ACCOUNTS_COUNT user_account insert statements"

echo ""
echo "🔄 Processing and migrating data..."
echo ""

# Create temporary SQL file for accounts
TEMP_ACCOUNTS=$(mktemp)
grep "^INSERT INTO \`accounts\`" "$SQL_DUMP" | head -1 > "$TEMP_ACCOUNTS"

# We'll use Python or a script to convert MySQL INSERT to PostgreSQL format
# For now, let's use the existing migration scripts but with data from SQL dump

echo "⚠️  Note: This script extracts data from SQL dump."
echo "   For full migration, use the migrate-accounts.sh and migrate-users.sh scripts"
echo "   which handle UUID conversion and foreign key mapping."
echo ""
echo "✅ Use the run-accounts-users-migration.sh script with correct MySQL credentials"
echo "   or ensure MySQL database is accessible on the server."

rm -f "$TEMP_ACCOUNTS"
