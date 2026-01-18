#!/bin/bash

# Migrate Accounts and Users Only
# This script focuses on migrating accounts and users first to ensure all data is available

set -e

echo "🔄 Gemura Migration: Accounts & Users"
echo "======================================"
echo ""

# Configuration
MYSQL_HOST="${MYSQL_HOST:-localhost}"
MYSQL_PORT="${MYSQL_PORT:-3306}"
MYSQL_DB="${MYSQL_DB:-gemura}"
MYSQL_USER="${MYSQL_USER:-root}"
MYSQL_PASS="${MYSQL_PASS:-mysql}"

PG_HOST="${PG_HOST:-devslab-postgres}"
PG_PORT="${PG_PORT:-5432}"
PG_DB="${PG_DB:-gemura_db}"
PG_USER="${PG_USER:-devslab_admin}"
PG_PASS="${PG_PASS:-devslab_secure_password_2024}"

export PGPASSWORD="$PG_PASS"

# Colors
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

# Function to check MySQL connection
check_mysql() {
    echo -n "Checking MySQL connection... "
    if mysql -h "$MYSQL_HOST" -P "$MYSQL_PORT" -u "$MYSQL_USER" -p"$MYSQL_PASS" -e "USE $MYSQL_DB;" 2>/dev/null; then
        echo -e "${GREEN}✓${NC}"
        return 0
    else
        echo -e "${RED}✗${NC}"
        echo "Cannot connect to MySQL. Please check credentials."
        return 1
    fi
}

# Function to check PostgreSQL connection
check_postgres() {
    echo -n "Checking PostgreSQL connection... "
    if psql -h "$PG_HOST" -p "$PG_PORT" -U "$PG_USER" -d "$PG_DB" -c "SELECT 1;" > /dev/null 2>&1; then
        echo -e "${GREEN}✓${NC}"
        return 0
    else
        echo -e "${RED}✗${NC}"
        echo "Cannot connect to PostgreSQL. Please check credentials."
        return 1
    fi
}

# Function to get row count
get_mysql_count() {
    local table=$1
    mysql -h "$MYSQL_HOST" -P "$MYSQL_PORT" -u "$MYSQL_USER" -p"$MYSQL_PASS" "$MYSQL_DB" \
        -se "SELECT COUNT(*) FROM $table;" 2>/dev/null || echo "0"
}

get_pg_count() {
    local table=$1
    psql -h "$PG_HOST" -p "$PG_PORT" -U "$PG_USER" -d "$PG_DB" \
        -t -c "SELECT COUNT(*) FROM $table;" 2>/dev/null | tr -d ' ' || echo "0"
}

# Start
echo "Step 1: Connection Checks"
echo "-------------------------"
check_mysql || exit 1
check_postgres || exit 1

echo ""
echo "Step 2: Current Data Counts"
echo "----------------------------"
MYSQL_ACCOUNTS=$(get_mysql_count "accounts")
MYSQL_USERS=$(get_mysql_count "users")
PG_ACCOUNTS=$(get_pg_count "accounts")
PG_USERS=$(get_pg_count "users")

echo "MySQL:"
echo "   Accounts: $MYSQL_ACCOUNTS"
echo "   Users: $MYSQL_USERS"
echo ""
echo "PostgreSQL (Current):"
echo "   Accounts: $PG_ACCOUNTS"
echo "   Users: $PG_USERS"
echo ""

# Migrate Accounts
echo "Step 3: Migrating Accounts"
echo "-------------------------"
echo "📦 Migrating: accounts"
bash ./scripts/migration/tables/migrate-accounts.sh \
    "$MYSQL_HOST" "$MYSQL_PORT" "$MYSQL_DB" "$MYSQL_USER" "$MYSQL_PASS" \
    "$PG_HOST" "$PG_PORT" "$PG_DB" "$PG_USER" "$PG_PASS"

PG_ACCOUNTS_AFTER=$(get_pg_count "accounts")
echo ""
echo "   Accounts after migration: $PG_ACCOUNTS_AFTER (Expected: $MYSQL_ACCOUNTS)"

# Migrate Users
echo ""
echo "Step 4: Migrating Users"
echo "-------------------------"
echo "📦 Migrating: users"
bash ./scripts/migration/tables/migrate-users.sh \
    "$MYSQL_HOST" "$MYSQL_PORT" "$MYSQL_DB" "$MYSQL_USER" "$MYSQL_PASS" \
    "$PG_HOST" "$PG_PORT" "$PG_DB" "$PG_USER" "$PG_PASS"

PG_USERS_AFTER=$(get_pg_count "users")
echo ""
echo "   Users after migration: $PG_USERS_AFTER (Expected: $MYSQL_USERS)"

# Migrate User Accounts
echo ""
echo "Step 5: Migrating User Accounts (Account Assignments)"
echo "-----------------------------------------------------"
echo "📦 Migrating: user_accounts"
bash ./scripts/migration/tables/migrate-user-accounts.sh \
    "$MYSQL_HOST" "$MYSQL_PORT" "$MYSQL_DB" "$MYSQL_USER" "$MYSQL_PASS" \
    "$PG_HOST" "$PG_PORT" "$PG_DB" "$PG_USER" "$PG_PASS"

PG_USER_ACCOUNTS=$(get_pg_count "user_accounts")
MYSQL_USER_ACCOUNTS=$(get_mysql_count "user_accounts")
echo ""
echo "   User Accounts after migration: $PG_USER_ACCOUNTS (Expected: $MYSQL_USER_ACCOUNTS)"

# Final Summary
echo ""
echo "=============================================="
echo "Migration Summary"
echo "=============================================="
echo "Accounts:"
echo "   MySQL: $MYSQL_ACCOUNTS"
echo "   PostgreSQL: $PG_ACCOUNTS_AFTER"
if [ "$PG_ACCOUNTS_AFTER" -ge "$MYSQL_ACCOUNTS" ]; then
    echo -e "   Status: ${GREEN}✅${NC}"
else
    echo -e "   Status: ${YELLOW}⚠️  Missing $((MYSQL_ACCOUNTS - PG_ACCOUNTS_AFTER)) accounts${NC}"
fi

echo ""
echo "Users:"
echo "   MySQL: $MYSQL_USERS"
echo "   PostgreSQL: $PG_USERS_AFTER"
if [ "$PG_USERS_AFTER" -ge "$MYSQL_USERS" ]; then
    echo -e "   Status: ${GREEN}✅${NC}"
else
    echo -e "   Status: ${YELLOW}⚠️  Missing $((MYSQL_USERS - PG_USERS_AFTER)) users${NC}"
fi

echo ""
echo "User Accounts (Assignments):"
echo "   MySQL: $MYSQL_USER_ACCOUNTS"
echo "   PostgreSQL: $PG_USER_ACCOUNTS"
if [ "$PG_USER_ACCOUNTS" -ge "$MYSQL_USER_ACCOUNTS" ]; then
    echo -e "   Status: ${GREEN}✅${NC}"
else
    echo -e "   Status: ${YELLOW}⚠️  Missing $((MYSQL_USER_ACCOUNTS - PG_USER_ACCOUNTS)) assignments${NC}"
fi

echo ""
if [ "$PG_ACCOUNTS_AFTER" -ge "$MYSQL_ACCOUNTS" ] && [ "$PG_USERS_AFTER" -ge "$MYSQL_USERS" ] && [ "$PG_USER_ACCOUNTS" -ge "$MYSQL_USER_ACCOUNTS" ]; then
    echo -e "${GREEN}✅ All accounts and users migrated successfully!${NC}"
else
    echo -e "${YELLOW}⚠️  Migration completed with some discrepancies${NC}"
    echo "   Please review the counts above"
fi
echo "=============================================="
