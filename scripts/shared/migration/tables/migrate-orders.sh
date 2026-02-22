#!/bin/bash

# Migrate orders table from MySQL to PostgreSQL

set -e

MYSQL_HOST=$1; MYSQL_PORT=$2; MYSQL_DB=$3; MYSQL_USER=$4; MYSQL_PASS=$5
PG_HOST=$6; PG_PORT=$7; PG_DB=$8; PG_USER=$9; PG_PASS=${10}

export PGPASSWORD="$PG_PASS"

echo "   Exporting orders from MySQL..."

mysql -h "$MYSQL_HOST" -P "$MYSQL_PORT" -u "$MYSQL_USER" -p"$MYSQL_PASS" "$MYSQL_DB" \
    -e "SELECT 
        id as legacy_id,
        customer_id,
        seller_id,
        account_id,
        total_amount,
        status,
        shipping_address,
        created_at,
        updated_at
    FROM orders
    ORDER BY id;" \
    --skip-column-names --raw | \
while IFS=$'\t' read -r legacy_id customer_id seller_id account_id total_amount status shipping_address created_at updated_at; do
    new_id=$(uuidgen | tr '[:upper:]' '[:lower:]')
    
    # Map IDs
    account_uuid=$(psql -h "$PG_HOST" -p "$PG_PORT" -U "$PG_USER" -d "$PG_DB" -t -c \
        "SELECT id FROM accounts WHERE legacy_id = $account_id LIMIT 1;" | tr -d ' ')
    [ -z "$account_uuid" ] && account_uuid="NULL"
    
    psql -h "$PG_HOST" -p "$PG_PORT" -U "$PG_USER" -d "$PG_DB" << EOF
INSERT INTO orders (
    id, legacy_id, customer_id, seller_id, account_id, total_amount, status,
    shipping_address, created_at, updated_at
) VALUES (
    '$new_id',
    $legacy_id,
    $( [ "$customer_id" = "NULL" ] && echo "NULL" || echo "'$customer_id'" ),
    $( [ "$seller_id" = "NULL" ] && echo "NULL" || echo "'$seller_id'" ),
    $( [ "$account_uuid" = "NULL" ] && echo "NULL" || echo "'$account_uuid'" ),
    $total_amount,
    '$status',
    $( [ "$shipping_address" = "NULL" ] && echo "NULL" || echo "'$(echo "$shipping_address" | sed "s/'/''/g")'" ),
    '$created_at',
    '$updated_at'
)
ON CONFLICT (legacy_id) DO NOTHING;
EOF
done

echo "   ✓ Orders migrated"

