#!/bin/bash

# Quick summary of migration status
# Compares local MySQL (AMPPS) with remote PostgreSQL

set -e

MYSQL_BIN="/Applications/AMPPS/apps/mysql/bin/mysql"
MYSQL_HOST="localhost"
MYSQL_PORT="3306"
MYSQL_DB="gemura"
MYSQL_USER="root"
MYSQL_PASS="mysql"

REMOTE_SERVER="root@159.198.65.38"
REMOTE_PASS="QF87VtuYReX5v9p6e3"

echo "📊 Migration Status Summary"
echo "============================"
echo ""

# Get MySQL counts
echo "MySQL (Local AMPPS - $MYSQL_DB):"
MYSQL_ACCOUNTS=$("$MYSQL_BIN" -h "$MYSQL_HOST" -P "$MYSQL_PORT" -u "$MYSQL_USER" -p"$MYSQL_PASS" "$MYSQL_DB" -se "SELECT COUNT(*) FROM accounts;" 2>/dev/null)
MYSQL_USERS=$("$MYSQL_BIN" -h "$MYSQL_HOST" -P "$MYSQL_PORT" -u "$MYSQL_USER" -p"$MYSQL_PASS" "$MYSQL_DB" -se "SELECT COUNT(*) FROM users;" 2>/dev/null)
MYSQL_USER_ACCOUNTS=$("$MYSQL_BIN" -h "$MYSQL_HOST" -P "$MYSQL_PORT" -u "$MYSQL_USER" -p"$MYSQL_PASS" "$MYSQL_DB" -se "SELECT COUNT(*) FROM user_accounts;" 2>/dev/null)

echo "   Accounts: $MYSQL_ACCOUNTS"
echo "   Users: $MYSQL_USERS"
echo "   User Accounts: $MYSQL_USER_ACCOUNTS"
echo ""

# Get PostgreSQL counts
echo "PostgreSQL (Remote Server):"
PG_ACCOUNTS=$(sshpass -p "$REMOTE_PASS" ssh -o StrictHostKeyChecking=no $REMOTE_SERVER \
    "docker exec -i devslab-postgres psql -U devslab_admin -d gemura_db -t -c 'SELECT COUNT(*) FROM accounts;'" 2>/dev/null | tr -d ' ')
PG_USERS=$(sshpass -p "$REMOTE_PASS" ssh -o StrictHostKeyChecking=no $REMOTE_SERVER \
    "docker exec -i devslab-postgres psql -U devslab_admin -d gemura_db -t -c 'SELECT COUNT(*) FROM users;'" 2>/dev/null | tr -d ' ')
PG_USER_ACCOUNTS=$(sshpass -p "$REMOTE_PASS" ssh -o StrictHostKeyChecking=no $REMOTE_SERVER \
    "docker exec -i devslab-postgres psql -U devslab_admin -d gemura_db -t -c 'SELECT COUNT(*) FROM user_accounts;'" 2>/dev/null | tr -d ' ')

echo "   Accounts: $PG_ACCOUNTS"
echo "   Users: $PG_USERS"
echo "   User Accounts: $PG_USER_ACCOUNTS"
echo ""

# Calculate differences
echo "Migration Status:"
echo "-----------------"

ACCOUNTS_DIFF=$((MYSQL_ACCOUNTS - PG_ACCOUNTS))
USERS_DIFF=$((MYSQL_USERS - PG_USERS))
USER_ACCOUNTS_DIFF=$((MYSQL_USER_ACCOUNTS - PG_USER_ACCOUNTS))

if [ "$ACCOUNTS_DIFF" -le 0 ]; then
    echo "   ✅ Accounts: Complete ($PG_ACCOUNTS >= $MYSQL_ACCOUNTS)"
else
    echo "   ⚠️  Accounts: Missing $ACCOUNTS_DIFF ($PG_ACCOUNTS < $MYSQL_ACCOUNTS)"
fi

if [ "$USERS_DIFF" -le 0 ]; then
    echo "   ✅ Users: Complete ($PG_USERS >= $MYSQL_USERS)"
else
    echo "   ⚠️  Users: Missing $USERS_DIFF ($PG_USERS < $MYSQL_USERS)"
fi

if [ "$USER_ACCOUNTS_DIFF" -le 0 ]; then
    echo "   ✅ User Accounts: Complete ($PG_USER_ACCOUNTS >= $MYSQL_USER_ACCOUNTS)"
else
    echo "   ⚠️  User Accounts: Missing $USER_ACCOUNTS_DIFF ($PG_USER_ACCOUNTS < $MYSQL_USER_ACCOUNTS)"
fi

echo ""
if [ "$ACCOUNTS_DIFF" -le 0 ] && [ "$USERS_DIFF" -le 0 ] && [ "$USER_ACCOUNTS_DIFF" -le 0 ]; then
    echo "✅ All accounts and users are migrated!"
else
    echo "⚠️  Some records still need migration"
    echo ""
    echo "To complete migration, run:"
    echo "  MYSQL_PASS=\"mysql\" ./scripts/migration/migrate-accounts-users-local.sh"
fi
