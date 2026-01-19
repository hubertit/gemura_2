#!/bin/bash

# Migrate All Missing Milk Sales (including invalid data)
# Handles invalid dates and zero account IDs

set -e

MYSQL_DB="gemura_migration_temp"

echo "🔄 Migrating All Missing Milk Sales"
echo "===================================="
echo ""

# Helper function to get UUID from legacy_id
get_uuid() {
    local table=$1
    local legacy_id=$2
    docker exec -i devslab-postgres psql -U devslab_admin -d gemura_db -t -A -c \
        "SELECT id FROM $table WHERE legacy_id = $legacy_id LIMIT 1;" 2>/dev/null | head -1
}

# Get default account and user for invalid references
default_account_uuid=$(docker exec -i devslab-postgres psql -U devslab_admin -d gemura_db -t -A -c \
    "SELECT id FROM accounts ORDER BY created_at LIMIT 1;" | head -1)
default_user_uuid=$(docker exec -i devslab-postgres psql -U devslab_admin -d gemura_db -t -A -c \
    "SELECT id FROM users ORDER BY created_at LIMIT 1;" | head -1)

echo "📋 Default account UUID: $default_account_uuid"
echo "📋 Default user UUID: $default_user_uuid"
echo ""

# Get list of missing milk_sales IDs
echo "📊 Finding missing milk_sales..."
mysql -u root $MYSQL_DB -N -e "SELECT id FROM milk_sales ORDER BY id;" > /tmp/mysql_milk_sales_ids.txt
docker exec -i devslab-postgres psql -U devslab_admin -d gemura_db -t -A -c \
    "SELECT legacy_id FROM milk_sales WHERE legacy_id IS NOT NULL ORDER BY legacy_id;" > /tmp/pg_milk_sales_ids.txt

missing_ids=$(comm -23 <(sort /tmp/mysql_milk_sales_ids.txt) <(sort /tmp/pg_milk_sales_ids.txt))
missing_count=$(echo "$missing_ids" | wc -l | tr -d ' ')

echo "   Found $missing_count missing milk_sales"
echo ""

if [ "$missing_count" = "0" ]; then
    echo "✅ All milk_sales are already migrated!"
    exit 0
fi

# Migrate each missing milk_sale
migrated=0
failed=0
skipped=0

echo "📦 Migrating milk_sales (including invalid data with fixes)..."
for id in $missing_ids; do
    # Get milk_sale data from MySQL
    data=$(mysql -u root $MYSQL_DB -N -e \
        "SELECT supplier_account_id, customer_account_id, quantity, unit_price, 
                COALESCE(status, 'completed'), sale_at, COALESCE(notes, ''), 
                recorded_by, created_at, updated_at
         FROM milk_sales WHERE id = $id;")
    
    if [ -z "$data" ]; then
        failed=$((failed + 1))
        continue
    fi
    
    IFS=$'\t' read -r supplier_account_id customer_account_id quantity unit_price status sale_at notes recorded_by created updated <<< "$data"
    
    # Handle invalid supplier_account_id (0 or NULL)
    if [ "$supplier_account_id" = "0" ] || [ -z "$supplier_account_id" ] || [ "$supplier_account_id" = "NULL" ]; then
        # Use customer_account_id as supplier if valid, otherwise use default
        if [ "$customer_account_id" != "0" ] && [ ! -z "$customer_account_id" ]; then
            supplier_uuid=$(get_uuid "accounts" "$customer_account_id")
            if [ -z "$supplier_uuid" ]; then
                supplier_uuid="$default_account_uuid"
            fi
        else
            supplier_uuid="$default_account_uuid"
        fi
    else
        supplier_uuid=$(get_uuid "accounts" "$supplier_account_id")
        if [ -z "$supplier_uuid" ]; then
            supplier_uuid="$default_account_uuid"
        fi
    fi
    
    # Handle invalid customer_account_id (0 or NULL)
    if [ "$customer_account_id" = "0" ] || [ -z "$customer_account_id" ] || [ "$customer_account_id" = "NULL" ]; then
        customer_uuid="$default_account_uuid"
    else
        customer_uuid=$(get_uuid "accounts" "$customer_account_id")
        if [ -z "$customer_uuid" ]; then
            customer_uuid="$default_account_uuid"
        fi
    fi
    
    # Handle invalid sale_at date (0000-00-00 or NULL)
    if [ -z "$sale_at" ] || [ "$sale_at" = "NULL" ] || [ "$sale_at" = "0000-00-00 00:00:00" ] || [ "$sale_at" = "0000-00-00" ]; then
        # Use created_at if valid, otherwise use current date
        if [ ! -z "$created" ] && [ "$created" != "NULL" ] && [ "$created" != "0000-00-00 00:00:00" ]; then
            sale_at="$created"
        else
            sale_at=$(date '+%Y-%m-%d %H:%M:%S')
        fi
    fi
    
    # Handle invalid created_at date
    if [ -z "$created" ] || [ "$created" = "NULL" ] || [ "$created" = "0000-00-00 00:00:00" ] || [ "$created" = "0000-00-00" ]; then
        created=$(date '+%Y-%m-%d %H:%M:%S')
    fi
    
    # Handle invalid updated_at date
    if [ -z "$updated" ] || [ "$updated" = "NULL" ] || [ "$updated" = "0000-00-00 00:00:00" ] || [ "$updated" = "0000-00-00" ]; then
        updated="$created"
    fi
    
    # Generate new UUID
    new_id=$(uuidgen | tr '[:upper:]' '[:lower:]')
    
    # Handle notes
    notes_esc="NULL"
    if [ ! -z "$notes" ] && [ "$notes" != "NULL" ]; then
        notes_esc=$(echo "$notes" | sed "s/'/''/g")
        notes_esc="'$notes_esc'"
    fi
    
    # Get recorded_by UUID (required field)
    recorded_by_uuid=$(get_uuid "users" "$recorded_by")
    if [ -z "$recorded_by_uuid" ] || [ "$recorded_by" = "0" ] || [ "$recorded_by" = "NULL" ]; then
        recorded_by_uuid="$default_user_uuid"
    fi
    
    # Insert into PostgreSQL
    result=$(docker exec -i devslab-postgres psql -U devslab_admin -d gemura_db -c \
        "INSERT INTO milk_sales (id, legacy_id, supplier_account_id, customer_account_id, 
                                quantity, unit_price, status, sale_at, notes, 
                                recorded_by, created_at, updated_at)
         VALUES ('$new_id', $id, '$supplier_uuid', '$customer_uuid', $quantity, $unit_price, 
                 '$status', '$sale_at', $notes_esc, '$recorded_by_uuid', 
                 '$created', '$updated')
         ON CONFLICT (legacy_id) DO NOTHING
         RETURNING id;" 2>&1)
    
    if echo "$result" | grep -q "INSERT 0 1"; then
        migrated=$((migrated + 1))
        if [ $((migrated % 100)) -eq 0 ]; then
            echo "   ✅ Migrated $migrated/$missing_count milk_sales..."
        fi
    elif echo "$result" | grep -q "INSERT 0 0"; then
        skipped=$((skipped + 1))
    else
        failed=$((failed + 1))
        if [ $failed -le 10 ]; then
            echo "   ❌ Failed to migrate milk_sale $id: $(echo "$result" | head -1)"
        fi
    fi
done

echo ""
echo "===================================="
echo "✅ Migration Complete!"
echo "===================================="
echo "Migrated: $migrated"
echo "Skipped: $skipped"
echo "Failed: $failed"
echo ""

# Cleanup
rm -f /tmp/mysql_milk_sales_ids.txt /tmp/pg_milk_sales_ids.txt
