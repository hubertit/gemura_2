#!/bin/bash

# Migrate milk_sales table (collections) from MySQL to PostgreSQL

set -e

MYSQL_HOST=$1
MYSQL_PORT=$2
MYSQL_DB=$3
MYSQL_USER=$4
MYSQL_PASS=$5
PG_HOST=$6
PG_PORT=$7
PG_DB=$8
PG_USER=$9
PG_PASS=${10}

export PGPASSWORD="$PG_PASS"

echo "   Exporting milk_sales from MySQL..."

mysql -h "$MYSQL_HOST" -P "$MYSQL_PORT" -u "$MYSQL_USER" -p"$MYSQL_PASS" "$MYSQL_DB" \
    -e "SELECT 
        id as legacy_id,
        supplier_account_id,
        customer_account_id,
        quantity,
        unit_price,
        status,
        sale_at,
        notes,
        recorded_by,
        created_at,
        updated_at,
        created_by,
        updated_by
    FROM milk_sales
    ORDER BY id;" \
    --skip-column-names --raw | \
while IFS=$'\t' read -r legacy_id supplier_account_id customer_account_id quantity unit_price status sale_at notes recorded_by created_at updated_at created_by updated_by; do
    new_id=$(uuidgen | tr '[:upper:]' '[:lower:]')
    
    # Map account IDs
    supplier_uuid=$(psql -h "$PG_HOST" -p "$PG_PORT" -U "$PG_USER" -d "$PG_DB" -t -c \
        "SELECT id FROM accounts WHERE legacy_id = $supplier_account_id LIMIT 1;" | tr -d ' ')
    customer_uuid=$(psql -h "$PG_HOST" -p "$PG_PORT" -U "$PG_USER" -d "$PG_DB" -t -c \
        "SELECT id FROM accounts WHERE legacy_id = $customer_account_id LIMIT 1;" | tr -d ' ')
    recorded_by_uuid=$(psql -h "$PG_HOST" -p "$PG_PORT" -U "$PG_USER" -d "$PG_DB" -t -c \
        "SELECT id FROM users WHERE legacy_id = $recorded_by LIMIT 1;" | tr -d ' ')
    
    [ -z "$supplier_uuid" ] && supplier_uuid="NULL"
    [ -z "$customer_uuid" ] && customer_uuid="NULL"
    [ -z "$recorded_by_uuid" ] && recorded_by_uuid="NULL"
    
    psql -h "$PG_HOST" -p "$PG_PORT" -U "$PG_USER" -d "$PG_DB" << EOF
INSERT INTO milk_sales (
    id, legacy_id, supplier_account_id, customer_account_id,
    quantity, unit_price, status, sale_at, notes, recorded_by,
    created_at, updated_at, created_by, updated_by
) VALUES (
    '$new_id',
    $legacy_id,
    $( [ "$supplier_uuid" = "NULL" ] && echo "NULL" || echo "'$supplier_uuid'" ),
    $( [ "$customer_uuid" = "NULL" ] && echo "NULL" || echo "'$customer_uuid'" ),
    $quantity,
    $unit_price,
    '$status',
    '$sale_at',
    $( [ "$notes" = "NULL" ] && echo "NULL" || echo "'$(echo "$notes" | sed "s/'/''/g")'" ),
    $( [ "$recorded_by_uuid" = "NULL" ] && echo "NULL" || echo "'$recorded_by_uuid'" ),
    '$created_at',
    '$updated_at',
    $( [ "$created_by" = "NULL" ] && echo "NULL" || echo "'$created_by'" ),
    $( [ "$updated_by" = "NULL" ] && echo "NULL" || echo "'$updated_by'" )
)
ON CONFLICT (legacy_id) DO NOTHING;
EOF
done

echo "   ✓ Milk sales migrated"

