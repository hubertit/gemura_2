#!/bin/bash

# Data Migration Script: MySQL → PostgreSQL
# Migrates all data from Gemura v1 (PHP/MySQL) to v2 (NestJS/PostgreSQL)

set -e

echo "🔄 Gemura Data Migration: MySQL → PostgreSQL"
echo "=============================================="
echo ""

# Configuration
MYSQL_HOST="${MYSQL_HOST:-localhost}"
MYSQL_PORT="${MYSQL_PORT:-3306}"
MYSQL_DB="${MYSQL_DB:-gemura}"
MYSQL_USER="${MYSQL_USER:-root}"
MYSQL_PASS="${MYSQL_PASS:-}"

PG_HOST="${PG_HOST:-devslab-postgres}"
PG_PORT="${PG_PORT:-5432}"
PG_DB="${PG_DB:-gemura_db}"
PG_USER="${PG_USER:-devslab_admin}"
PG_PASS="${PG_PASS:-devslab_secure_password_2024}"

# Export password for psql
export PGPASSWORD="$PG_PASS"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Function to check if MySQL connection works
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

# Function to check if PostgreSQL connection works
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

# Function to get row count from MySQL
get_mysql_count() {
    local table=$1
    mysql -h "$MYSQL_HOST" -P "$MYSQL_PORT" -u "$MYSQL_USER" -p"$MYSQL_PASS" "$MYSQL_DB" \
        -se "SELECT COUNT(*) FROM $table;" 2>/dev/null || echo "0"
}

# Function to get row count from PostgreSQL
get_pg_count() {
    local table=$1
    psql -h "$PG_HOST" -p "$PG_PORT" -U "$PG_USER" -d "$PG_DB" \
        -t -c "SELECT COUNT(*) FROM $table;" 2>/dev/null | tr -d ' ' || echo "0"
}

# Main migration function
migrate_table() {
    local table=$1
    local script=$2
    
    echo ""
    echo "📦 Migrating: $table"
    echo "----------------------------------------"
    
    # Get counts
    mysql_count=$(get_mysql_count "$table")
    echo "   MySQL rows: $mysql_count"
    
    if [ "$mysql_count" -eq 0 ]; then
        echo -e "   ${YELLOW}⚠ Skipping (no data)${NC}"
        return 0
    fi
    
    # Run migration script
    if [ -f "$script" ]; then
        echo "   Running migration script..."
        bash "$script" "$MYSQL_HOST" "$MYSQL_PORT" "$MYSQL_DB" "$MYSQL_USER" "$MYSQL_PASS" \
             "$PG_HOST" "$PG_PORT" "$PG_DB" "$PG_USER" "$PG_PASS"
        
        # Verify
        pg_count=$(get_pg_count "$table")
        echo "   PostgreSQL rows: $pg_count"
        
        if [ "$pg_count" -ge "$mysql_count" ]; then
            echo -e "   ${GREEN}✓ Success${NC}"
        else
            echo -e "   ${YELLOW}⚠ Partial (expected $mysql_count, got $pg_count)${NC}"
        fi
    else
        echo -e "   ${RED}✗ Script not found: $script${NC}"
        return 1
    fi
}

# Start migration
echo "Step 1: Connection Checks"
echo "-------------------------"
check_mysql || exit 1
check_postgres || exit 1

echo ""
echo "Step 2: Data Migration"
echo "----------------------"

# Migration order (respecting foreign key dependencies)
MIGRATIONS=(
    "accounts:scripts/migration/tables/migrate-accounts.sh"
    "users:scripts/migration/tables/migrate-users.sh"
    "user_accounts:scripts/migration/tables/migrate-user-accounts.sh"
    "suppliers_customers:scripts/migration/tables/migrate-suppliers-customers.sh"
    "milk_sales:scripts/migration/tables/migrate-milk-sales.sh"
    "products:scripts/migration/tables/migrate-products.sh"
    "product_categories:scripts/migration/tables/migrate-product-categories.sh"
    "product_images:scripts/migration/tables/migrate-product-images.sh"
    "categories:scripts/migration/tables/migrate-categories.sh"
    "orders:scripts/migration/tables/migrate-orders.sh"
    "order_items:scripts/migration/tables/migrate-order-items.sh"
    "wallets:scripts/migration/tables/migrate-wallets.sh"
    "notifications:scripts/migration/tables/migrate-notifications.sh"
    "feed_posts:scripts/migration/tables/migrate-feed-posts.sh"
    "feed_stories:scripts/migration/tables/migrate-feed-stories.sh"
    "feed_comments:scripts/migration/tables/migrate-feed-comments.sh"
    "feed_interactions:scripts/migration/tables/migrate-feed-interactions.sh"
    "user_bookmarks:scripts/migration/tables/migrate-user-bookmarks.sh"
    "user_relationships:scripts/migration/tables/migrate-user-relationships.sh"
    "api_keys:scripts/migration/tables/migrate-api-keys.sh"
    "password_resets:scripts/migration/tables/migrate-password-resets.sh"
    "user_onboardings:scripts/migration/tables/migrate-user-onboardings.sh"
    "user_points:scripts/migration/tables/migrate-user-points.sh"
    "user_referrals:scripts/migration/tables/migrate-user-referrals.sh"
    "user_rewards:scripts/migration/tables/migrate-user-rewards.sh"
)

for migration in "${MIGRATIONS[@]}"; do
    IFS=':' read -r table script <<< "$migration"
    migrate_table "$table" "$script" || echo "   Failed to migrate $table"
done

echo ""
echo "Step 3: Validation"
echo "-----------------"
echo "Comparing row counts..."

TOTAL_MYSQL=0
TOTAL_PG=0

for migration in "${MIGRATIONS[@]}"; do
    IFS=':' read -r table script <<< "$migration"
    mysql_count=$(get_mysql_count "$table")
    pg_count=$(get_pg_count "$table")
    TOTAL_MYSQL=$((TOTAL_MYSQL + mysql_count))
    TOTAL_PG=$((TOTAL_PG + pg_count))
    
    if [ "$mysql_count" -gt 0 ]; then
        echo "   $table: MySQL=$mysql_count, PostgreSQL=$pg_count"
    fi
done

echo ""
echo "=============================================="
echo "Migration Summary"
echo "=============================================="
echo "Total MySQL rows: $TOTAL_MYSQL"
echo "Total PostgreSQL rows: $TOTAL_PG"
echo ""

if [ "$TOTAL_PG" -ge "$TOTAL_MYSQL" ]; then
    echo -e "${GREEN}✅ Migration completed successfully!${NC}"
else
    echo -e "${YELLOW}⚠ Migration completed with warnings${NC}"
    echo "Some data may need manual review."
fi

echo ""
echo "Next steps:"
echo "1. Verify data integrity"
echo "2. Test API endpoints with migrated data"
echo "3. Update mobile app to use new API"

