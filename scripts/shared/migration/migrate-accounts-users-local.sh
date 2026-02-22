#!/bin/bash

# Migrate Accounts and Users from Local AMPPS MySQL to Server PostgreSQL
# This script runs locally and connects to:
# - Local MySQL (AMPPS) on localhost:3306
# - Remote PostgreSQL on server (devslab-postgres:5432)

set -e

echo "🔄 Migrating Accounts & Users from Local AMPPS MySQL"
echo "======================================================"
echo ""

# MySQL Configuration (Local AMPPS)
MYSQL_HOST="${MYSQL_HOST:-localhost}"
MYSQL_PORT="${MYSQL_PORT:-3306}"
MYSQL_DB="${MYSQL_DB:-gemura}"  # Try 'gemura' first, fallback to 'devsvknl_gemura'
MYSQL_USER="${MYSQL_USER:-root}"
MYSQL_PASS="${MYSQL_PASS:-}"

# PostgreSQL Configuration (Remote Server via SSH tunnel)
# We'll use SSH to execute psql commands on the server
REMOTE_SERVER="root@159.198.65.38"
REMOTE_PASS="QF87VtuYReX5v9p6e3"
PG_HOST="devslab-postgres"  # Docker container name on server
PG_PORT="5432"
PG_DB="gemura_db"
PG_USER="devslab_admin"
PG_PASS="devslab_secure_password_2024"

export PGPASSWORD="$PG_PASS"

# Find MySQL binary (AMPPS or system)
# Try common AMPPS locations
MYSQL_BIN="${MYSQL_BIN:-$(which mysql 2>/dev/null || \
    find /Applications/AMPPS -name mysql -type f 2>/dev/null | head -1 || \
    echo '/Applications/AMPPS/apps/mysql/bin/mysql')}"

if [ ! -f "$MYSQL_BIN" ]; then
    echo "⚠️  MySQL binary not found at: $MYSQL_BIN"
    echo "   Please set MYSQL_BIN environment variable to the correct path"
    exit 1
fi

# Colors
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

# Function to check MySQL connection
check_mysql() {
    local db=$1
    echo -n "Checking MySQL connection (database: $db)... "
    if "$MYSQL_BIN" -h "$MYSQL_HOST" -P "$MYSQL_PORT" -u "$MYSQL_USER" ${MYSQL_PASS:+-p"$MYSQL_PASS"} -e "USE $db;" 2>/dev/null; then
        echo -e "${GREEN}✓${NC}"
        return 0
    else
        echo -e "${RED}✗${NC}"
        return 1
    fi
}

# Function to check PostgreSQL connection (via SSH)
check_postgres() {
    echo -n "Checking PostgreSQL connection (via SSH)... "
    if sshpass -p "$REMOTE_PASS" ssh -o StrictHostKeyChecking=no $REMOTE_SERVER \
        "docker exec -i devslab-postgres psql -U $PG_USER -d $PG_DB -c 'SELECT 1;' > /dev/null 2>&1"; then
        echo -e "${GREEN}✓${NC}"
        return 0
    else
        echo -e "${RED}✗${NC}"
        return 1
    fi
}

# Function to get MySQL count
get_mysql_count() {
    local db=$1
    local table=$2
    "$MYSQL_BIN" -h "$MYSQL_HOST" -P "$MYSQL_PORT" -u "$MYSQL_USER" ${MYSQL_PASS:+-p"$MYSQL_PASS"} "$db" \
        -se "SELECT COUNT(*) FROM $table;" 2>/dev/null || echo "0"
}

# Function to get PostgreSQL count (via SSH)
get_pg_count() {
    local table=$1
    sshpass -p "$REMOTE_PASS" ssh -o StrictHostKeyChecking=no $REMOTE_SERVER \
        "docker exec -i devslab-postgres psql -U $PG_USER -d $PG_DB -t -c \"SELECT COUNT(*) FROM $table;\"" 2>/dev/null | tr -d ' ' || echo "0"
}

# Determine which database exists
echo "Step 1: Finding MySQL Database"
echo "-------------------------------"
if check_mysql "gemura"; then
    MYSQL_DB="gemura"
elif check_mysql "devsvknl_gemura"; then
    MYSQL_DB="devsvknl_gemura"
else
    echo "❌ Cannot find MySQL database. Tried: gemura, devsvknl_gemura"
    exit 1
fi

echo ""
echo "Step 2: Connection Checks"
echo "-------------------------"
check_postgres || exit 1

echo ""
echo "Step 3: Current Data Counts"
echo "----------------------------"
MYSQL_ACCOUNTS=$(get_mysql_count "$MYSQL_DB" "accounts")
MYSQL_USERS=$(get_mysql_count "$MYSQL_DB" "users")
MYSQL_USER_ACCOUNTS=$(get_mysql_count "$MYSQL_DB" "user_accounts")
PG_ACCOUNTS=$(get_pg_count "accounts")
PG_USERS=$(get_pg_count "users")
PG_USER_ACCOUNTS=$(get_pg_count "user_accounts")

echo "MySQL (Local AMPPS - $MYSQL_DB):"
echo "   Accounts: $MYSQL_ACCOUNTS"
echo "   Users: $MYSQL_USERS"
echo "   User Accounts: $MYSQL_USER_ACCOUNTS"
echo ""
echo "PostgreSQL (Remote Server):"
echo "   Accounts: $PG_ACCOUNTS"
echo "   Users: $PG_USERS"
echo "   User Accounts: $PG_USER_ACCOUNTS"
echo ""

# Migrate Accounts
echo "Step 4: Migrating Accounts"
echo "-------------------------"
echo "📦 Migrating: accounts"
bash ./scripts/migration/tables/migrate-accounts-remote-pg.sh \
    "$MYSQL_HOST" "$MYSQL_PORT" "$MYSQL_DB" "$MYSQL_USER" "$MYSQL_PASS" \
    "$REMOTE_SERVER" "$REMOTE_PASS" "$PG_HOST" "$PG_DB" "$PG_USER" "$PG_PASS" 2>&1 | grep -E "(Exporting|migrated|Error)" || true

PG_ACCOUNTS_AFTER=$(get_pg_count "accounts")
echo ""
echo "   Accounts after: $PG_ACCOUNTS_AFTER (Expected: $MYSQL_ACCOUNTS)"

# Migrate Users
echo ""
echo "Step 5: Migrating Users"
echo "-------------------------"
echo "📦 Migrating: users"
bash ./scripts/migration/tables/migrate-users-remote-pg.sh \
    "$MYSQL_HOST" "$MYSQL_PORT" "$MYSQL_DB" "$MYSQL_USER" "$MYSQL_PASS" \
    "$REMOTE_SERVER" "$REMOTE_PASS" "$PG_HOST" "$PG_DB" "$PG_USER" "$PG_PASS" 2>&1 | grep -E "(Exporting|migrated|Error)" || true

PG_USERS_AFTER=$(get_pg_count "users")
echo ""
echo "   Users after: $PG_USERS_AFTER (Expected: $MYSQL_USERS)"

# Migrate User Accounts
echo ""
echo "Step 6: Migrating User Accounts (Account Assignments)"
echo "-----------------------------------------------------"
echo "📦 Migrating: user_accounts"
bash ./scripts/migration/tables/migrate-user-accounts-remote-pg.sh \
    "$MYSQL_HOST" "$MYSQL_PORT" "$MYSQL_DB" "$MYSQL_USER" "$MYSQL_PASS" \
    "$REMOTE_SERVER" "$REMOTE_PASS" "$PG_HOST" "$PG_DB" "$PG_USER" "$PG_PASS" 2>&1 | grep -E "(Exporting|migrated|Error)" || true

PG_USER_ACCOUNTS_AFTER=$(get_pg_count "user_accounts")
echo ""
echo "   User Accounts after: $PG_USER_ACCOUNTS_AFTER (Expected: $MYSQL_USER_ACCOUNTS)"

# Final Summary
echo ""
echo "=============================================="
echo "Migration Summary"
echo "=============================================="
echo "Accounts:"
echo "   MySQL: $MYSQL_ACCOUNTS → PostgreSQL: $PG_ACCOUNTS_AFTER"
if [ "$PG_ACCOUNTS_AFTER" -ge "$MYSQL_ACCOUNTS" ]; then
    echo -e "   Status: ${GREEN}✅${NC}"
else
    echo -e "   Status: ${YELLOW}⚠️  Missing $((MYSQL_ACCOUNTS - PG_ACCOUNTS_AFTER))${NC}"
fi

echo ""
echo "Users:"
echo "   MySQL: $MYSQL_USERS → PostgreSQL: $PG_USERS_AFTER"
if [ "$PG_USERS_AFTER" -ge "$MYSQL_USERS" ]; then
    echo -e "   Status: ${GREEN}✅${NC}"
else
    echo -e "   Status: ${YELLOW}⚠️  Missing $((MYSQL_USERS - PG_USERS_AFTER))${NC}"
fi

echo ""
echo "User Accounts (Assignments):"
echo "   MySQL: $MYSQL_USER_ACCOUNTS → PostgreSQL: $PG_USER_ACCOUNTS_AFTER"
if [ "$PG_USER_ACCOUNTS_AFTER" -ge "$MYSQL_USER_ACCOUNTS" ]; then
    echo -e "   Status: ${GREEN}✅${NC}"
else
    echo -e "   Status: ${YELLOW}⚠️  Missing $((MYSQL_USER_ACCOUNTS - PG_USER_ACCOUNTS_AFTER))${NC}"
fi

echo ""
if [ "$PG_ACCOUNTS_AFTER" -ge "$MYSQL_ACCOUNTS" ] && [ "$PG_USERS_AFTER" -ge "$MYSQL_USERS" ] && [ "$PG_USER_ACCOUNTS_AFTER" -ge "$MYSQL_USER_ACCOUNTS" ]; then
    echo -e "${GREEN}✅ All accounts and users migrated successfully!${NC}"
else
    echo -e "${YELLOW}⚠️  Migration completed with some discrepancies${NC}"
fi
echo "=============================================="
