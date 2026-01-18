#!/bin/bash

# Migrate suppliers_customers table from MySQL to PostgreSQL

set -e

MYSQL_HOST=$1; MYSQL_PORT=$2; MYSQL_DB=$3; MYSQL_USER=$4; MYSQL_PASS=$5
PG_HOST=$6; PG_PORT=$7; PG_DB=$8; PG_USER=$9; PG_PASS=${10}

export PGPASSWORD="$PG_PASS"

echo "   Exporting suppliers_customers from MySQL..."

mysql -h "$MYSQL_HOST" -P "$MYSQL_PORT" -u "$MYSQL_USER" -p"$MYSQL_PASS" "$MYSQL_DB" \
    -e "SELECT 
        id as legacy_id,
        supplier_account_id,
        customer_account_id,
        price_per_liter,
        relationship_status,
        notes,
        created_at,
        updated_at
    FROM suppliers_customers
    ORDER BY id;" \
    --skip-column-names --raw | \
while IFS=$'\t' read -r legacy_id supplier_account_id customer_account_id price_per_liter relationship_status notes created_at updated_at; do
    new_id=$(uuidgen | tr '[:upper:]' '[:lower:]')
    
    # Map account IDs
    supplier_uuid=$(psql -h "$PG_HOST" -p "$PG_PORT" -U "$PG_USER" -d "$PG_DB" -t -c \
        "SELECT id FROM accounts WHERE legacy_id = $supplier_account_id LIMIT 1;" | tr -d ' ')
    customer_uuid=$(psql -h "$PG_HOST" -p "$PG_PORT" -U "$PG_USER" -d "$PG_DB" -t -c \
        "SELECT id FROM accounts WHERE legacy_id = $customer_account_id LIMIT 1;" | tr -d ' ')
    
    [ -z "$supplier_uuid" ] && supplier_uuid="NULL"
    [ -z "$customer_uuid" ] && customer_uuid="NULL"
    
    psql -h "$PG_HOST" -p "$PG_PORT" -U "$PG_USER" -d "$PG_DB" << EOF
INSERT INTO suppliers_customers (
    id, legacy_id, supplier_account_id, customer_account_id,
    price_per_liter, relationship_status, notes, created_at, updated_at
) VALUES (
    '$new_id',
    $legacy_id,
    $( [ "$supplier_uuid" = "NULL" ] && echo "NULL" || echo "'$supplier_uuid'" ),
    $( [ "$customer_uuid" = "NULL" ] && echo "NULL" || echo "'$customer_uuid'" ),
    $( [ "$price_per_liter" = "NULL" ] && echo "NULL" || echo "$price_per_liter" ),
    '$relationship_status',
    $( [ "$notes" = "NULL" ] && echo "NULL" || echo "'$(echo "$notes" | sed "s/'/''/g")'" ),
    '$created_at',
    '$updated_at'
)
ON CONFLICT (legacy_id) DO NOTHING;
EOF
done

echo "   ✓ Suppliers-customers migrated"

