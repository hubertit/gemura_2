#!/bin/bash

# Check Local MySQL Database for User Accounts
# Compares local MySQL with remote PostgreSQL to find missing accounts

set -e

echo "🔍 Checking Local MySQL Database for User Accounts"
echo "=================================================="
echo ""

# MySQL Configuration (Local)
MYSQL_HOST="${MYSQL_HOST:-localhost}"
MYSQL_PORT="${MYSQL_PORT:-3306}"
MYSQL_DB="${MYSQL_DB:-gemura}"
MYSQL_USER="${MYSQL_USER:-root}"
MYSQL_PASS="${MYSQL_PASS:-mysql}"

# PostgreSQL Configuration (Remote)
PG_HOST="159.198.65.38"
PG_PORT="5433"
PG_DB="gemura_db"
PG_USER="devslab_admin"
PG_PASS="devslab_secure_password_2024"

export PGPASSWORD="$PG_PASS"

# Find MySQL binary
MYSQL_BIN="${MYSQL_BIN:-$(which mysql 2>/dev/null || \
    find /Applications/AMPPS -name mysql -type f 2>/dev/null | head -1 || \
    find /Applications/MAMP -name mysql -type f 2>/dev/null | head -1 || \
    echo '/usr/local/bin/mysql')}"

if [ ! -f "$MYSQL_BIN" ] && ! command -v mysql &> /dev/null; then
    echo "❌ MySQL client not found"
    echo "   Please install MySQL client or set MYSQL_BIN environment variable"
    exit 1
fi

# Use mysql command if available
if command -v mysql &> /dev/null; then
    MYSQL_BIN="mysql"
fi

echo "Using MySQL: $MYSQL_BIN"
echo ""

# Check MySQL connection
echo "📊 Step 1: Checking MySQL connection..."
if "$MYSQL_BIN" -h "$MYSQL_HOST" -P "$MYSQL_PORT" -u "$MYSQL_USER" -p"$MYSQL_PASS" -e "USE $MYSQL_DB;" 2>/dev/null; then
    echo "✅ MySQL connection successful"
else
    echo "❌ Cannot connect to MySQL"
    echo "   Host: $MYSQL_HOST:$MYSQL_PORT"
    echo "   Database: $MYSQL_DB"
    echo "   User: $MYSQL_USER"
    exit 1
fi

echo ""
echo "📊 Step 2: Getting user info from MySQL..."
USER_INFO=$("$MYSQL_BIN" -h "$MYSQL_HOST" -P "$MYSQL_PORT" -u "$MYSQL_USER" -p"$MYSQL_PASS" "$MYSQL_DB" \
    -N -e "SELECT id, code, name, phone FROM users WHERE phone = '250788606765' OR phone = '0788606765' LIMIT 1;" 2>/dev/null)

if [ -z "$USER_INFO" ]; then
    echo "❌ User not found in MySQL"
    exit 1
fi

USER_ID=$(echo "$USER_INFO" | cut -f1)
USER_CODE=$(echo "$USER_INFO" | cut -f2)
USER_NAME=$(echo "$USER_INFO" | cut -f3)
USER_PHONE=$(echo "$USER_INFO" | cut -f4)

echo "✅ Found user: $USER_NAME (ID: $USER_ID, Code: $USER_CODE, Phone: $USER_PHONE)"

echo ""
echo "📊 Step 3: Getting accounts from MySQL..."
"$MYSQL_BIN" -h "$MYSQL_HOST" -P "$MYSQL_PORT" -u "$MYSQL_USER" -p"$MYSQL_PASS" "$MYSQL_DB" \
    -e "SELECT COUNT(*) as total_accounts FROM user_accounts WHERE user_id = $USER_ID AND status = 'active';" 2>/dev/null

echo ""
echo "📋 Step 4: Account list from MySQL:"
"$MYSQL_BIN" -h "$MYSQL_HOST" -P "$MYSQL_PORT" -u "$MYSQL_USER" -p"$MYSQL_PASS" "$MYSQL_DB" \
    -e "SELECT a.code, a.name, ua.role, ua.status FROM user_accounts ua JOIN accounts a ON ua.account_id = a.id WHERE ua.user_id = $USER_ID AND ua.status = 'active' ORDER BY a.code;" 2>/dev/null

echo ""
echo "📊 Step 5: Comparing with PostgreSQL..."
PG_COUNT=$(psql -h "$PG_HOST" -p "$PG_PORT" -U "$PG_USER" -d "$PG_DB" -t -A -c \
    "SELECT COUNT(*) FROM user_accounts WHERE user_id = (SELECT id FROM users WHERE phone = '250788606765') AND status = 'active';" 2>/dev/null | tr -d ' ')

MYSQL_COUNT=$("$MYSQL_BIN" -h "$MYSQL_HOST" -P "$MYSQL_PORT" -u "$MYSQL_USER" -p"$MYSQL_PASS" "$MYSQL_DB" \
    -N -e "SELECT COUNT(*) FROM user_accounts WHERE user_id = $USER_ID AND status = 'active';" 2>/dev/null | tr -d ' ')

echo "MySQL: $MYSQL_COUNT accounts"
echo "PostgreSQL: $PG_COUNT accounts"
echo ""

if [ "$MYSQL_COUNT" -gt "$PG_COUNT" ]; then
    echo "⚠️  MySQL has more accounts ($MYSQL_COUNT vs $PG_COUNT)"
    echo "   Some accounts may need to be migrated"
elif [ "$MYSQL_COUNT" -eq "$PG_COUNT" ]; then
    echo "✅ Account counts match"
else
    echo "ℹ️  PostgreSQL has more accounts (may include additional accounts)"
fi

echo ""
echo "✅ Check complete!"
