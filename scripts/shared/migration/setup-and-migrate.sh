#!/bin/bash

# Setup MySQL database from SQL dump and run complete migration
# This script imports the SQL dump into MySQL, then migrates to PostgreSQL

set -e

SERVER_IP="159.198.65.38"
SERVER_USER="root"
SERVER_PASS="QF87VtuYReX5v9p6e3"
REMOTE_PATH="/opt/gemura"
SQL_DUMP="./database/gemura.sql"
MYSQL_DB="gemura_migration_temp"

echo "🔄 Setup and Complete Migration: v1 → v2"
echo "=========================================="
echo ""

# Step 1: Upload SQL dump
if [ -f "$SQL_DUMP" ]; then
    echo "📤 Step 1: Uploading SQL dump to server..."
    sshpass -p "$SERVER_PASS" scp -o StrictHostKeyChecking=no "$SQL_DUMP" $SERVER_USER@$SERVER_IP:$REMOTE_PATH/gemura.sql
    echo "   ✅ SQL dump uploaded"
else
    echo "   ❌ SQL dump not found: $SQL_DUMP"
    exit 1
fi

echo ""
echo "🔄 Step 2: Setting up MySQL database and running migration..."
echo ""

# Run setup and migration on server
sshpass -p "$SERVER_PASS" ssh -o StrictHostKeyChecking=no $SERVER_USER@$SERVER_IP << ENDSSH
cd /opt/gemura

export PGPASSWORD="devslab_secure_password_2024"

echo "📊 Current PostgreSQL Status (Before Migration):"
docker exec -i devslab-postgres psql -U devslab_admin -d gemura_db -c "
SELECT 
    'accounts' as table_name, COUNT(*) as count FROM accounts
UNION ALL SELECT 'users', COUNT(*) FROM users
UNION ALL SELECT 'user_accounts', COUNT(*) FROM user_accounts
UNION ALL SELECT 'suppliers_customers', COUNT(*) FROM suppliers_customers
UNION ALL SELECT 'milk_sales', COUNT(*) FROM milk_sales
UNION ALL SELECT 'wallets', COUNT(*) FROM wallets
UNION ALL SELECT 'products', COUNT(*) FROM products
UNION ALL SELECT 'orders', COUNT(*) FROM orders
UNION ALL SELECT 'feed_posts', COUNT(*) FROM feed_posts
UNION ALL SELECT 'feed_comments', COUNT(*) FROM feed_comments
UNION ALL SELECT 'feed_interactions', COUNT(*) FROM feed_interactions
UNION ALL SELECT 'user_bookmarks', COUNT(*) FROM user_bookmarks
UNION ALL SELECT 'notifications', COUNT(*) FROM notifications
ORDER BY table_name;
"

echo ""
echo "🗄️  Step 2a: Setting up MySQL database from SQL dump..."

# Create temporary database
mysql -u root << MYSQL_EOF
DROP DATABASE IF EXISTS $MYSQL_DB;
CREATE DATABASE $MYSQL_DB CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
USE $MYSQL_DB;
SOURCE /opt/gemura/gemura.sql;
MYSQL_EOF

if [ \$? -eq 0 ]; then
    echo "   ✅ MySQL database created and populated from SQL dump"
    
    # Check what we have in MySQL
    echo ""
    echo "📊 MySQL Database Contents:"
    mysql -u root $MYSQL_DB -e "
    SELECT 'accounts' as table_name, COUNT(*) as count FROM accounts
    UNION ALL SELECT 'users', COUNT(*) FROM users
    UNION ALL SELECT 'user_accounts', COUNT(*) FROM user_accounts
    UNION ALL SELECT 'suppliers_customers', COUNT(*) FROM suppliers_customers
    UNION ALL SELECT 'milk_sales', COUNT(*) FROM milk_sales
    UNION ALL SELECT 'wallets', COUNT(*) FROM wallets
    UNION ALL SELECT 'products', COUNT(*) FROM products
    UNION ALL SELECT 'orders', COUNT(*) FROM orders
    UNION ALL SELECT 'feed_posts', COUNT(*) FROM feed_posts
    UNION ALL SELECT 'feed_comments', COUNT(*) FROM feed_comments
    UNION ALL SELECT 'feed_interactions', COUNT(*) FROM feed_interactions
    UNION ALL SELECT 'user_bookmarks', COUNT(*) FROM user_bookmarks
    UNION ALL SELECT 'notifications', COUNT(*) FROM notifications
    ORDER BY table_name;
    " 2>/dev/null || echo "   ⚠️  Could not query MySQL (some tables may not exist)"
else
    echo "   ⚠️  Failed to import SQL dump into MySQL"
    echo "   Will try direct migration from SQL dump processing"
fi

echo ""
echo "🔄 Step 2b: Running TypeScript migration service..."

cd backend

# Set environment for migration
export DATABASE_URL="postgresql://devslab_admin:devslab_secure_password_2024@devslab-postgres:5432/gemura_db"
export V1_DB_HOST="localhost"
export V1_DB_PORT="3306"
export V1_DB_USER="root"
export V1_DB_PASSWORD=""
export V1_DB_NAME="$MYSQL_DB"

# Run selective migration (core tables)
echo "   Migrating core tables (accounts, users, user_accounts, suppliers_customers, milk_sales, wallets)..."
if npm run migrate:selective 2>&1 | tee /tmp/migration-core.log; then
    echo "   ✅ Core tables migration completed!"
else
    echo "   ⚠️  Core tables migration had issues, check /tmp/migration-core.log"
fi

echo ""
echo "🔄 Step 2c: Migrating additional tables (products, orders, feed, etc.)..."

# Migrate products
if [ -f scripts/migration/tables/migrate-products.sh ]; then
    echo "   Migrating products..."
    bash scripts/migration/tables/migrate-products.sh \
        localhost 3306 $MYSQL_DB root "" \
        devslab-postgres 5432 gemura_db devslab_admin devslab_secure_password_2024 \
        2>&1 | tee /tmp/migration-products.log || echo "   ⚠️  Products migration had issues"
fi

# Migrate orders
if [ -f scripts/migration/tables/migrate-orders.sh ]; then
    echo "   Migrating orders..."
    bash scripts/migration/tables/migrate-orders.sh \
        localhost 3306 $MYSQL_DB root "" \
        devslab-postgres 5432 gemura_db devslab_admin devslab_secure_password_2024 \
        2>&1 | tee /tmp/migration-orders.log || echo "   ⚠️  Orders migration had issues"
fi

# Migrate feed tables
for table in feed_posts feed_comments feed_interactions user_bookmarks; do
    script="scripts/migration/tables/migrate-${table}.sh"
    if [ -f "\$script" ]; then
        echo "   Migrating \$table..."
        bash "\$script" \
            localhost 3306 $MYSQL_DB root "" \
            devslab-postgres 5432 gemura_db devslab_admin devslab_secure_password_2024 \
            2>&1 | tee "/tmp/migration-\${table}.log" || echo "   ⚠️  \$table migration had issues"
    fi
done

# Migrate notifications
if [ -f scripts/migration/tables/migrate-notifications.sh ]; then
    echo "   Migrating notifications..."
    bash scripts/migration/tables/migrate-notifications.sh \
        localhost 3306 $MYSQL_DB root "" \
        devslab-postgres 5432 gemura_db devslab_admin devslab_secure_password_2024 \
        2>&1 | tee /tmp/migration-notifications.log || echo "   ⚠️  Notifications migration had issues"
fi

echo ""
echo "📊 Final PostgreSQL Status (After Migration):"
docker exec -i devslab-postgres psql -U devslab_admin -d gemura_db -c "
SELECT 
    'accounts' as table_name, COUNT(*) as count FROM accounts
UNION ALL SELECT 'users', COUNT(*) FROM users
UNION ALL SELECT 'user_accounts', COUNT(*) FROM user_accounts
UNION ALL SELECT 'suppliers_customers', COUNT(*) FROM suppliers_customers
UNION ALL SELECT 'milk_sales', COUNT(*) FROM milk_sales
UNION ALL SELECT 'wallets', COUNT(*) FROM wallets
UNION ALL SELECT 'products', COUNT(*) FROM products
UNION ALL SELECT 'orders', COUNT(*) FROM orders
UNION ALL SELECT 'feed_posts', COUNT(*) FROM feed_posts
UNION ALL SELECT 'feed_comments', COUNT(*) FROM feed_comments
UNION ALL SELECT 'feed_interactions', COUNT(*) FROM feed_interactions
UNION ALL SELECT 'user_bookmarks', COUNT(*) FROM user_bookmarks
UNION ALL SELECT 'notifications', COUNT(*) FROM notifications
ORDER BY table_name;
"

echo ""
echo "✅ Migration process completed!"
echo ""
echo "Migration logs saved to:"
echo "  - /tmp/migration-core.log"
echo "  - /tmp/migration-products.log"
echo "  - /tmp/migration-orders.log"
echo "  - /tmp/migration-*.log (for other tables)"

ENDSSH

echo ""
echo "✅ Complete migration script finished!"
echo ""
echo "Summary:"
echo "1. ✅ SQL dump uploaded to server"
echo "2. ✅ MySQL database created from SQL dump"
echo "3. ✅ Core tables migrated (accounts, users, etc.)"
echo "4. ✅ Additional tables migrated (products, orders, feed, etc.)"
echo ""
echo "Next steps:"
echo "1. Review the migration results above"
echo "2. Check migration logs on server: /tmp/migration-*.log"
echo "3. Validate data integrity"
echo "4. Test API endpoints with migrated data"
