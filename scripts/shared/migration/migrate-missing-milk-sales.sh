#!/bin/bash

# Migrate Missing Milk Sales
# Migrates milk_sales that are in MySQL but not in PostgreSQL

set -e

MYSQL_DB="gemura_migration_temp"

echo "🔄 Migrating Missing Milk Sales"
echo "================================"
echo ""

# Helper function to get UUID from legacy_id
get_uuid() {
    local table=$1
    local legacy_id=$2
    docker exec -i devslab-postgres psql -U devslab_admin -d gemura_db -t -A -c \
        "SELECT id FROM $table WHERE legacy_id = $legacy_id LIMIT 1;" 2>/dev/null | head -1
}

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

echo "📦 Migrating milk_sales (this may take a while)..."
count=0
for id in $missing_ids; do
    count=$((count + 1))
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
    
    # Get UUIDs for accounts and user
    supplier_uuid=$(get_uuid "accounts" "$supplier_account_id")
    customer_uuid=$(get_uuid "accounts" "$customer_account_id")
    # Get recorded_by UUID (required field, so find a default user if missing)
    recorded_by_uuid=$(get_uuid "users" "$recorded_by")
    if [ -z "$recorded_by_uuid" ] || [ "$recorded_by" = "0" ] || [ "$recorded_by" = "NULL" ]; then
        # Get first available user as fallback
        recorded_by_uuid=$(docker exec -i devslab-postgres psql -U devslab_admin -d gemura_db -t -A -c \
            "SELECT id FROM users ORDER BY created_at LIMIT 1;" | head -1)
        if [ -z "$recorded_by_uuid" ]; then
            skipped=$((skipped + 1))
            continue
        fi
    fi
    
    if [ -z "$supplier_uuid" ] || [ -z "$customer_uuid" ]; then
        skipped=$((skipped + 1))
        continue
    fi
    
    # Generate new UUID
    new_id=$(uuidgen | tr '[:upper:]' '[:lower:]')
    
    # Handle notes
    notes_esc="NULL"
    if [ ! -z "$notes" ] && [ "$notes" != "NULL" ]; then
        notes_esc=$(echo "$notes" | sed "s/'/''/g")
        notes_esc="'$notes_esc'"
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
        if [ $((migrated % 50)) -eq 0 ]; then
            echo "   ✅ Migrated $migrated/$missing_count milk_sales..."
        fi
    elif echo "$result" | grep -q "INSERT 0 0"; then
        skipped=$((skipped + 1))
    else
        failed=$((failed + 1))
        if [ $failed -le 5 ]; then
            echo "   ❌ Failed to migrate milk_sale $id"
        fi
    fi
done

echo ""
echo "================================"
echo "✅ Migration Complete!"
echo "================================"
echo "Migrated: $migrated"
echo "Skipped: $skipped"
echo "Failed: $failed"
echo ""

# Cleanup
rm -f /tmp/mysql_milk_sales_ids.txt /tmp/pg_milk_sales_ids.txt
