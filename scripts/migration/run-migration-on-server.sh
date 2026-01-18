#!/bin/bash

# Run data migration on server where MySQL is accessible
# This script will be uploaded to server and executed there

set -e

echo "🔄 Gemura Data Migration: MySQL → PostgreSQL"
echo "=============================================="
echo ""

# MySQL Configuration (Version 1)
MYSQL_HOST="${MYSQL_HOST:-localhost}"
MYSQL_PORT="${MYSQL_PORT:-3306}"
MYSQL_DB="${MYSQL_DB:-gemura}"
MYSQL_USER="${MYSQL_USER:-root}"
MYSQL_PASS="${MYSQL_PASS:-mysql}"

# PostgreSQL Configuration (Version 2)
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

# Check MySQL
echo -n "Checking MySQL connection... "
if mysql -h "$MYSQL_HOST" -P "$MYSQL_PORT" -u "$MYSQL_USER" -p"$MYSQL_PASS" -e "USE $MYSQL_DB;" 2>/dev/null; then
    echo -e "${GREEN}✓${NC}"
else
    echo -e "${RED}✗${NC}"
    echo "Cannot connect to MySQL. Please check credentials."
    exit 1
fi

# Check PostgreSQL
echo -n "Checking PostgreSQL connection... "
if psql -h "$PG_HOST" -p "$PG_PORT" -U "$PG_USER" -d "$PG_DB" -c "SELECT 1;" > /dev/null 2>&1; then
    echo -e "${GREEN}✓${NC}"
else
    echo -e "${RED}✗${NC}"
    echo "Cannot connect to PostgreSQL. Please check credentials."
    exit 1
fi

# Get MySQL row counts
echo ""
echo "📊 MySQL Data Counts:"
echo "---------------------"
ACCOUNTS_COUNT=$(mysql -h "$MYSQL_HOST" -P "$MYSQL_PORT" -u "$MYSQL_USER" -p"$MYSQL_PASS" "$MYSQL_DB" -se "SELECT COUNT(*) FROM accounts;" 2>/dev/null || echo "0")
USERS_COUNT=$(mysql -h "$MYSQL_HOST" -P "$MYSQL_PORT" -u "$MYSQL_USER" -p"$MYSQL_PASS" "$MYSQL_DB" -se "SELECT COUNT(*) FROM users;" 2>/dev/null || echo "0")
MILK_SALES_COUNT=$(mysql -h "$MYSQL_HOST" -P "$MYSQL_PORT" -u "$MYSQL_USER" -p"$MYSQL_PASS" "$MYSQL_DB" -se "SELECT COUNT(*) FROM milk_sales;" 2>/dev/null || echo "0")
SUPPLIERS_COUNT=$(mysql -h "$MYSQL_HOST" -P "$MYSQL_PORT" -u "$MYSQL_USER" -p"$MYSQL_PASS" "$MYSQL_DB" -se "SELECT COUNT(*) FROM suppliers_customers;" 2>/dev/null || echo "0")

echo "   Accounts: $ACCOUNTS_COUNT"
echo "   Users: $USERS_COUNT"
echo "   Milk Sales: $MILK_SALES_COUNT"
echo "   Suppliers: $SUPPLIERS_COUNT"

# Run migrations
echo ""
echo "🔄 Starting Migration..."
echo "========================"

MIGRATION_DIR="$(cd "$(dirname "$0")" && pwd)/tables"

# Migrate in dependency order
tables=(
    "accounts:migrate-accounts.sh"
    "users:migrate-users.sh"
    "user_accounts:migrate-user-accounts.sh"
    "suppliers_customers:migrate-suppliers-customers.sh"
    "milk_sales:migrate-milk-sales.sh"
    "wallets:migrate-wallets.sh"
    "products:migrate-products.sh"
    "orders:migrate-orders.sh"
    "notifications:migrate-notifications.sh"
)

for table_info in "${tables[@]}"; do
    IFS=':' read -r table script <<< "$table_info"
    echo ""
    echo "📦 Migrating: $table"
    bash "$MIGRATION_DIR/$script" \
        "$MYSQL_HOST" "$MYSQL_PORT" "$MYSQL_DB" "$MYSQL_USER" "$MYSQL_PASS" \
        "$PG_HOST" "$PG_PORT" "$PG_DB" "$PG_USER" "$PG_PASS"
done

# Validation
echo ""
echo "✅ Validation"
echo "-------------"

PG_ACCOUNTS=$(psql -h "$PG_HOST" -p "$PG_PORT" -U "$PG_USER" -d "$PG_DB" -t -c "SELECT COUNT(*) FROM accounts;" | tr -d ' ')
PG_USERS=$(psql -h "$PG_HOST" -p "$PG_PORT" -U "$PG_USER" -d "$PG_DB" -t -c "SELECT COUNT(*) FROM users;" | tr -d ' ')
PG_MILK_SALES=$(psql -h "$PG_HOST" -p "$PG_PORT" -U "$PG_USER" -d "$PG_DB" -t -c "SELECT COUNT(*) FROM milk_sales;" | tr -d ' ')
PG_SUPPLIERS=$(psql -h "$PG_HOST" -p "$PG_PORT" -U "$PG_USER" -d "$PG_DB" -t -c "SELECT COUNT(*) FROM suppliers_customers;" | tr -d ' ')

echo "PostgreSQL Data:"
echo "   Accounts: $PG_ACCOUNTS (MySQL: $ACCOUNTS_COUNT)"
echo "   Users: $PG_USERS (MySQL: $USERS_COUNT)"
echo "   Milk Sales: $PG_MILK_SALES (MySQL: $MILK_SALES_COUNT)"
echo "   Suppliers: $PG_SUPPLIERS (MySQL: $SUPPLIERS_COUNT)"

echo ""
echo "=============================================="
if [ "$PG_ACCOUNTS" -ge "$ACCOUNTS_COUNT" ] && [ "$PG_USERS" -ge "$USERS_COUNT" ]; then
    echo -e "${GREEN}✅ Migration completed successfully!${NC}"
else
    echo -e "${YELLOW}⚠ Migration completed with some discrepancies${NC}"
fi
echo "=============================================="

