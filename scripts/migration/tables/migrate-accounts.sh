#!/bin/bash

# Migrate accounts table from MySQL to PostgreSQL
# Usage: migrate-accounts.sh mysql_host mysql_port mysql_db mysql_user mysql_pass pg_host pg_port pg_db pg_user pg_pass

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

echo "   Exporting accounts from MySQL..."

# Export from MySQL and import to PostgreSQL
mysql -h "$MYSQL_HOST" -P "$MYSQL_PORT" -u "$MYSQL_USER" -p"$MYSQL_PASS" "$MYSQL_DB" \
    -e "SELECT 
        id as legacy_id,
        code,
        name,
        type,
        status,
        parent_id,
        created_at,
        updated_at,
        created_by,
        updated_by
    FROM accounts
    ORDER BY id;" \
    --skip-column-names --raw | \
while IFS=$'\t' read -r legacy_id code name type status parent_id created_at updated_at created_by updated_by; do
    # Generate UUID for new record
    new_id=$(uuidgen | tr '[:upper:]' '[:lower:]')
    
    # Handle NULL values
    [ "$parent_id" = "NULL" ] && parent_id=""
    [ "$created_by" = "NULL" ] && created_by=""
    [ "$updated_by" = "NULL" ] && updated_by=""
    [ "$created_at" = "NULL" ] && created_at="CURRENT_TIMESTAMP"
    [ "$updated_at" = "NULL" ] && updated_at="CURRENT_TIMESTAMP"
    
    # Insert into PostgreSQL
    psql -h "$PG_HOST" -p "$PG_PORT" -U "$PG_USER" -d "$PG_DB" << EOF
INSERT INTO accounts (
    id, legacy_id, code, name, type, status, parent_id, 
    created_at, updated_at, created_by, updated_by
) VALUES (
    '$new_id',
    $legacy_id,
    '$(echo "$code" | sed "s/'/''/g")',
    '$(echo "$name" | sed "s/'/''/g")',
    '$type',
    '$status',
    $( [ -z "$parent_id" ] && echo "NULL" || echo "'$parent_id'" ),
    $( [ "$created_at" = "CURRENT_TIMESTAMP" ] && echo "CURRENT_TIMESTAMP" || echo "'$created_at'" ),
    $( [ "$updated_at" = "CURRENT_TIMESTAMP" ] && echo "CURRENT_TIMESTAMP" || echo "'$updated_at'" ),
    $( [ -z "$created_by" ] && echo "NULL" || echo "'$created_by'" ),
    $( [ -z "$updated_by" ] && echo "NULL" || echo "'$updated_by'" )
)
ON CONFLICT (legacy_id) DO NOTHING;
EOF
done

echo "   ✓ Accounts migrated"

