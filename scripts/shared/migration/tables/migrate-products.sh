#!/bin/bash

# Migrate products table from MySQL to PostgreSQL

set -e

MYSQL_HOST=$1; MYSQL_PORT=$2; MYSQL_DB=$3; MYSQL_USER=$4; MYSQL_PASS=$5
PG_HOST=$6; PG_PORT=$7; PG_DB=$8; PG_USER=$9; PG_PASS=${10}

export PGPASSWORD="$PG_PASS"

echo "   Exporting products from MySQL..."

mysql -h "$MYSQL_HOST" -P "$MYSQL_PORT" -u "$MYSQL_USER" -p"$MYSQL_PASS" "$MYSQL_DB" \
    -e "SELECT 
        id as legacy_id,
        name,
        description,
        price,
        stock_quantity,
        status,
        created_at,
        updated_at,
        created_by,
        updated_by
    FROM products
    ORDER BY id;" \
    --skip-column-names --raw | \
while IFS=$'\t' read -r legacy_id name description price stock_quantity status created_at updated_at created_by updated_by; do
    new_id=$(uuidgen | tr '[:upper:]' '[:lower:]')
    
    psql -h "$PG_HOST" -p "$PG_PORT" -U "$PG_USER" -d "$PG_DB" << EOF
INSERT INTO products (
    id, legacy_id, name, description, price, stock_quantity, status,
    created_at, updated_at, created_by, updated_by
) VALUES (
    '$new_id',
    $legacy_id,
    '$(echo "$name" | sed "s/'/''/g")',
    $( [ "$description" = "NULL" ] && echo "NULL" || echo "'$(echo "$description" | sed "s/'/''/g")'" ),
    $price,
    ${stock_quantity:-0},
    '$status',
    '$created_at',
    '$updated_at',
    $( [ "$created_by" = "NULL" ] && echo "NULL" || echo "'$created_by'" ),
    $( [ "$updated_by" = "NULL" ] && echo "NULL" || echo "'$updated_by'" )
)
ON CONFLICT (legacy_id) DO NOTHING;
EOF
done

echo "   ✓ Products migrated"

