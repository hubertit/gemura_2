#!/bin/bash

# Migrate data from temporary MySQL database to PostgreSQL
# This script migrates all tables that need migration

set -e

SERVER_IP="159.198.65.38"
SERVER_USER="root"
SERVER_PASS="QF87VtuYReX5v9p6e3"
MYSQL_DB="gemura_migration_temp"

echo "🔄 Migrating from MySQL temp database to PostgreSQL"
echo "===================================================="
echo ""

sshpass -p "$SERVER_PASS" ssh -o StrictHostKeyChecking=no $SERVER_USER@$SERVER_IP << 'ENDSSH'
cd /opt/gemura

export PGPASSWORD="devslab_secure_password_2024"

# Function to run psql
psql_cmd() {
    docker exec -i devslab-postgres psql -U devslab_admin -d gemura_db -c "$1"
}

# Function to get UUID from legacy_id
get_uuid() {
    local table=$1
    local legacy_id=$2
    psql_cmd "SELECT id FROM $table WHERE legacy_id = $legacy_id LIMIT 1;" | grep -E '^[a-f0-9-]{36}' | head -1 | tr -d ' '
}

echo "📦 Migrating products..."
mysql -u root gemura_migration_temp -N -e "
SELECT id, name, COALESCE(description, '') as description, price, 
       COALESCE(stock_quantity, 0) as stock_quantity, seller_id
FROM products;
" | while IFS=$'\t' read -r id name desc price stock seller_id; do
    new_id=$(uuidgen | tr '[:upper:]' '[:lower:]')
    
    # Map seller_id to user UUID
    seller_uuid="NULL"
    if [ ! -z "$seller_id" ] && [ "$seller_id" != "NULL" ]; then
        seller_uuid=$(get_uuid "users" "$seller_id")
        [ -z "$seller_uuid" ] && seller_uuid="NULL" || seller_uuid="'$seller_uuid'"
    fi
    
    # Escape single quotes
    name_escaped=$(echo "$name" | sed "s/'/''/g")
    desc_escaped=$(echo "$desc" | sed "s/'/''/g")
    
    psql_cmd "INSERT INTO products (id, legacy_id, name, description, price, stock_quantity, status, seller_id) 
              VALUES ('$new_id', $id, '$name_escaped', '$desc_escaped', $price, $stock, 'active', $seller_uuid) 
              ON CONFLICT (legacy_id) DO NOTHING;" > /dev/null 2>&1
done

echo "   ✅ Products migrated"

echo ""
echo "📦 Migrating orders (if table exists)..."
if mysql -u root gemura_migration_temp -e "SHOW TABLES LIKE 'orders';" 2>/dev/null | grep -q orders; then
    mysql -u root gemura_migration_temp -N -e "
    SELECT id, customer_id, seller_id, account_id, total_amount, 
           COALESCE(status, 'pending') as status, shipping_address
    FROM orders;
    " | while IFS=$'\t' read -r id customer_id seller_id account_id total status shipping; do
        new_id=$(uuidgen | tr '[:upper:]' '[:lower:]')
        
        # Map account_id
        account_uuid="NULL"
        if [ ! -z "$account_id" ] && [ "$account_id" != "NULL" ]; then
            account_uuid=$(get_uuid "accounts" "$account_id")
            [ -z "$account_uuid" ] && account_uuid="NULL" || account_uuid="'$account_uuid'"
        fi
        
        shipping_escaped=$(echo "$shipping" | sed "s/'/''/g")
        
        psql_cmd "INSERT INTO orders (id, legacy_id, customer_id, seller_id, account_id, total_amount, status, shipping_address) 
                  VALUES ('$new_id', $id, NULL, NULL, $account_uuid, $total, '$status', '$shipping_escaped') 
                  ON CONFLICT (legacy_id) DO NOTHING;" > /dev/null 2>&1
    done
    echo "   ✅ Orders migrated"
else
    echo "   ⚠️  Orders table not found in MySQL"
fi

echo ""
echo "📊 Final Status:"
psql_cmd "
SELECT 
    'accounts' as table_name, COUNT(*) as count FROM accounts
UNION ALL SELECT 'users', COUNT(*) FROM users
UNION ALL SELECT 'products', COUNT(*) FROM products
UNION ALL SELECT 'orders', COUNT(*) FROM orders
UNION ALL SELECT 'milk_sales', COUNT(*) FROM milk_sales
ORDER BY table_name;
"

echo ""
echo "✅ Migration completed!"

ENDSSH

echo ""
echo "✅ Migration script finished!"
