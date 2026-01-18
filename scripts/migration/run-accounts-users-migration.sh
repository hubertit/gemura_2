#!/bin/bash

# Run Accounts & Users Migration on Server
# This script uploads migration scripts to server and runs them there

set -e

SERVER_IP="159.198.65.38"
SERVER_USER="root"
SERVER_PASS="QF87VtuYReX5v9p6e3"
REMOTE_PATH="/opt/gemura"

echo "🔄 Running Accounts & Users Migration on Server"
echo "================================================="
echo ""

# Upload migration scripts to server
echo "📤 Uploading migration scripts to server..."
sshpass -p "$SERVER_PASS" ssh -o StrictHostKeyChecking=no $SERVER_USER@$SERVER_IP "mkdir -p $REMOTE_PATH/scripts/migration/tables"

# Upload the specific migration scripts we need
sshpass -p "$SERVER_PASS" scp -o StrictHostKeyChecking=no \
    ./scripts/migration/tables/migrate-accounts.sh \
    ./scripts/migration/tables/migrate-users.sh \
    ./scripts/migration/tables/migrate-user-accounts.sh \
    $SERVER_USER@$SERVER_IP:$REMOTE_PATH/scripts/migration/tables/

# Make scripts executable
sshpass -p "$SERVER_PASS" ssh -o StrictHostKeyChecking=no $SERVER_USER@$SERVER_IP \
    "chmod +x $REMOTE_PATH/scripts/migration/tables/*.sh"

echo "✅ Scripts uploaded"
echo ""

# Run migration on server
echo "🔄 Running migration on server..."
echo ""

sshpass -p "$SERVER_PASS" ssh -o StrictHostKeyChecking=no $SERVER_USER@$SERVER_IP << 'ENDSSH'
cd /opt/gemura

# Configuration
MYSQL_HOST="localhost"
MYSQL_PORT="3306"
MYSQL_DB="devsvknl_gemura"  # Actual database name from dump
MYSQL_USER="devsvknl_admin"  # Correct user from connection.php
MYSQL_PASS="]LdUd=a6{-vq"  # Correct password from connection.php

PG_HOST="devslab-postgres"
PG_PORT="5432"
PG_DB="gemura_db"
PG_USER="devslab_admin"
PG_PASS="devslab_secure_password_2024"

export PGPASSWORD="$PG_PASS"

# Colors
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

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

echo "Step 1: Current Data Counts"
echo "----------------------------"
MYSQL_ACCOUNTS=$(get_mysql_count "accounts")
MYSQL_USERS=$(get_mysql_count "users")
MYSQL_USER_ACCOUNTS=$(get_mysql_count "user_accounts")
PG_ACCOUNTS=$(get_pg_count "accounts")
PG_USERS=$(get_pg_count "users")
PG_USER_ACCOUNTS=$(get_pg_count "user_accounts")

echo "MySQL (Source):"
echo "   Accounts: $MYSQL_ACCOUNTS"
echo "   Users: $MYSQL_USERS"
echo "   User Accounts: $MYSQL_USER_ACCOUNTS"
echo ""
echo "PostgreSQL (Current):"
echo "   Accounts: $PG_ACCOUNTS"
echo "   Users: $PG_USERS"
echo "   User Accounts: $PG_USER_ACCOUNTS"
echo ""

# Migrate Accounts
echo "Step 2: Migrating Accounts"
echo "-------------------------"
bash /opt/gemura/scripts/migration/tables/migrate-accounts.sh \
    "$MYSQL_HOST" "$MYSQL_PORT" "$MYSQL_DB" "$MYSQL_USER" "$MYSQL_PASS" \
    "$PG_HOST" "$PG_PORT" "$PG_DB" "$PG_USER" "$PG_PASS"

PG_ACCOUNTS_AFTER=$(get_pg_count "accounts")
echo ""
echo "   Accounts after: $PG_ACCOUNTS_AFTER (Expected: $MYSQL_ACCOUNTS)"

# Migrate Users
echo ""
echo "Step 3: Migrating Users"
echo "-------------------------"
bash /opt/gemura/scripts/migration/tables/migrate-users.sh \
    "$MYSQL_HOST" "$MYSQL_PORT" "$MYSQL_DB" "$MYSQL_USER" "$MYSQL_PASS" \
    "$PG_HOST" "$PG_PORT" "$PG_DB" "$PG_USER" "$PG_PASS"

PG_USERS_AFTER=$(get_pg_count "users")
echo ""
echo "   Users after: $PG_USERS_AFTER (Expected: $MYSQL_USERS)"

# Migrate User Accounts
echo ""
echo "Step 4: Migrating User Accounts (Account Assignments)"
echo "-----------------------------------------------------"
bash /opt/gemura/scripts/migration/tables/migrate-user-accounts.sh \
    "$MYSQL_HOST" "$MYSQL_PORT" "$MYSQL_DB" "$MYSQL_USER" "$MYSQL_PASS" \
    "$PG_HOST" "$PG_PORT" "$PG_DB" "$PG_USER" "$PG_PASS"

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
ENDSSH

echo ""
echo "✅ Migration completed!"
