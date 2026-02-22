#!/bin/bash

# Simple migration from SQL dump using existing migration scripts
# This uploads the SQL dump and uses it as reference, but runs migrations via MySQL connection

set -e

SQL_DUMP="${1:-./database/gemura.sql}"
SERVER_IP="159.198.65.38"
SERVER_USER="root"
SERVER_PASS="QF87VtuYReX5v9p6e3"
REMOTE_PATH="/opt/gemura"

echo "🔄 Migrating Accounts & Users"
echo "==============================="
echo ""

# Upload migration scripts and SQL dump
echo "📤 Uploading files to server..."
sshpass -p "$SERVER_PASS" ssh -o StrictHostKeyChecking=no $SERVER_USER@$SERVER_IP "mkdir -p $REMOTE_PATH/scripts/migration/tables"

sshpass -p "$SERVER_PASS" scp -o StrictHostKeyChecking=no \
    ./scripts/migration/tables/migrate-accounts.sh \
    ./scripts/migration/tables/migrate-users.sh \
    ./scripts/migration/tables/migrate-user-accounts.sh \
    $SERVER_USER@$SERVER_IP:$REMOTE_PATH/scripts/migration/tables/

sshpass -p "$SERVER_PASS" scp -o StrictHostKeyChecking=no "$SQL_DUMP" $SERVER_USER@$SERVER_IP:$REMOTE_PATH/gemura.sql

sshpass -p "$SERVER_PASS" ssh -o StrictHostKeyChecking=no $SERVER_USER@$SERVER_IP \
    "chmod +x $REMOTE_PATH/scripts/migration/tables/*.sh"

echo "✅ Files uploaded"
echo ""

# Run migration on server
echo "🔄 Running migration on server..."
echo ""

sshpass -p "$SERVER_PASS" ssh -o StrictHostKeyChecking=no $SERVER_USER@$SERVER_IP << 'ENDSSH'
cd /opt/gemura

PG_HOST="devslab-postgres"
PG_PORT="5432"
PG_DB="gemura_db"
PG_USER="devslab_admin"
PG_PASS="devslab_secure_password_2024"

export PGPASSWORD="$PG_PASS"

# Try different MySQL credentials
MYSQL_HOST="localhost"
MYSQL_PORT="3306"
MYSQL_DB="devsvknl_gemura"
MYSQL_USER="devsvknl_admin"
MYSQL_PASS="]LdUd=a6{-vq"

# Check current counts
echo "📊 Current PostgreSQL Counts:"
PG_ACCOUNTS=$(docker exec -i devslab-postgres psql -U devslab_admin -d gemura_db -t -c "SELECT COUNT(*) FROM accounts;" 2>/dev/null | tr -d ' ')
PG_USERS=$(docker exec -i devslab-postgres psql -U devslab_admin -d gemura_db -t -c "SELECT COUNT(*) FROM users;" 2>/dev/null | tr -d ' ')
PG_USER_ACCOUNTS=$(docker exec -i devslab-postgres psql -U devslab_admin -d gemura_db -t -c "SELECT COUNT(*) FROM user_accounts;" 2>/dev/null | tr -d ' ')

echo "   Accounts: $PG_ACCOUNTS"
echo "   Users: $PG_USERS"
echo "   User Accounts: $PG_USER_ACCOUNTS"
echo ""

# Try to get MySQL counts
echo "📊 Checking MySQL database..."
if mysql -h "$MYSQL_HOST" -P "$MYSQL_PORT" -u "$MYSQL_USER" -p"$MYSQL_PASS" "$MYSQL_DB" -e "SELECT 1;" 2>/dev/null; then
    MYSQL_ACCOUNTS=$(mysql -h "$MYSQL_HOST" -P "$MYSQL_PORT" -u "$MYSQL_USER" -p"$MYSQL_PASS" "$MYSQL_DB" -se "SELECT COUNT(*) FROM accounts;" 2>/dev/null || echo "0")
    MYSQL_USERS=$(mysql -h "$MYSQL_HOST" -P "$MYSQL_PORT" -u "$MYSQL_USER" -p"$MYSQL_PASS" "$MYSQL_DB" -se "SELECT COUNT(*) FROM users;" 2>/dev/null || echo "0")
    MYSQL_USER_ACCOUNTS=$(mysql -h "$MYSQL_HOST" -P "$MYSQL_PORT" -u "$MYSQL_USER" -p"$MYSQL_PASS" "$MYSQL_DB" -se "SELECT COUNT(*) FROM user_accounts;" 2>/dev/null || echo "0")
    
    echo "MySQL (Source):"
    echo "   Accounts: $MYSQL_ACCOUNTS"
    echo "   Users: $MYSQL_USERS"
    echo "   User Accounts: $MYSQL_USER_ACCOUNTS"
    echo ""
    
    # Run migrations
    echo "🔄 Migrating Accounts..."
    bash /opt/gemura/scripts/migration/tables/migrate-accounts.sh \
        "$MYSQL_HOST" "$MYSQL_PORT" "$MYSQL_DB" "$MYSQL_USER" "$MYSQL_PASS" \
        "$PG_HOST" "$PG_PORT" "$PG_DB" "$PG_USER" "$PG_PASS" 2>&1 | tail -2
    
    echo ""
    echo "🔄 Migrating Users..."
    bash /opt/gemura/scripts/migration/tables/migrate-users.sh \
        "$MYSQL_HOST" "$MYSQL_PORT" "$MYSQL_DB" "$MYSQL_USER" "$MYSQL_PASS" \
        "$PG_HOST" "$PG_PORT" "$PG_DB" "$PG_USER" "$PG_PASS" 2>&1 | tail -2
    
    echo ""
    echo "🔄 Migrating User Accounts..."
    bash /opt/gemura/scripts/migration/tables/migrate-user-accounts.sh \
        "$MYSQL_HOST" "$MYSQL_PORT" "$MYSQL_DB" "$MYSQL_USER" "$MYSQL_PASS" \
        "$PG_HOST" "$PG_PORT" "$PG_DB" "$PG_USER" "$PG_PASS" 2>&1 | tail -2
else
    echo "⚠️  Cannot connect to MySQL database"
    echo "   Will check SQL dump file for reference..."
    
    # Count from SQL dump
    DUMP_ACCOUNTS=$(grep -c "^([0-9]*," gemura.sql | head -1 || echo "0")
    DUMP_USERS=$(grep -c "^([0-9]*," gemura.sql | head -1 || echo "0")
    
    echo "   SQL Dump has data, but MySQL connection failed"
    echo "   Please ensure MySQL is accessible or use alternative migration method"
fi

# Final counts
echo ""
echo "📊 Final PostgreSQL Counts:"
PG_ACCOUNTS_AFTER=$(docker exec -i devslab-postgres psql -U devslab_admin -d gemura_db -t -c "SELECT COUNT(*) FROM accounts;" 2>/dev/null | tr -d ' ')
PG_USERS_AFTER=$(docker exec -i devslab-postgres psql -U devslab_admin -d gemura_db -t -c "SELECT COUNT(*) FROM users;" 2>/dev/null | tr -d ' ')
PG_USER_ACCOUNTS_AFTER=$(docker exec -i devslab-postgres psql -U devslab_admin -d gemura_db -t -c "SELECT COUNT(*) FROM user_accounts;" 2>/dev/null | tr -d ' ')

echo "   Accounts: $PG_ACCOUNTS_AFTER (was $PG_ACCOUNTS)"
echo "   Users: $PG_USERS_AFTER (was $PG_USERS)"
echo "   User Accounts: $PG_USER_ACCOUNTS_AFTER (was $PG_USER_ACCOUNTS)"
echo ""

if [ "$PG_USERS_AFTER" -gt "$PG_USERS" ] || [ "$PG_ACCOUNTS_AFTER" -gt "$PG_ACCOUNTS" ] || [ "$PG_USER_ACCOUNTS_AFTER" -gt "$PG_USER_ACCOUNTS" ]; then
    echo "✅ Migration added new records!"
else
    echo "ℹ️  No new records migrated (may already be complete)"
fi

ENDSSH

echo ""
echo "✅ Migration process completed!"
