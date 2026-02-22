#!/bin/bash

# Migrate user_accounts table from MySQL to PostgreSQL (via SSH for remote PG)
# Usage: migrate-user-accounts-remote-pg.sh mysql_host mysql_port mysql_db mysql_user mysql_pass remote_server remote_pass pg_container pg_db pg_user pg_pass

set -e

MYSQL_HOST=$1
MYSQL_PORT=$2
MYSQL_DB=$3
MYSQL_USER=$4
MYSQL_PASS=$5
REMOTE_SERVER=$6
REMOTE_PASS=$7
PG_CONTAINER=$8
PG_DB=$9
PG_USER=${10}
PG_PASS=${11}

export PGPASSWORD="$PG_PASS"

# Find MySQL binary
MYSQL_BIN="${MYSQL_BIN:-$(which mysql 2>/dev/null || find /Applications/AMPPS -name mysql 2>/dev/null | head -1 || echo 'mysql')}"

echo "   Exporting user_accounts from MySQL..."

# Export from MySQL and import to PostgreSQL via SSH
"$MYSQL_BIN" -h "$MYSQL_HOST" -P "$MYSQL_PORT" -u "$MYSQL_USER" ${MYSQL_PASS:+-p"$MYSQL_PASS"} "$MYSQL_DB" \
    -e "SELECT 
        id as legacy_id,
        user_id,
        account_id,
        role,
        permissions,
        status,
        created_at,
        created_by,
        updated_by
    FROM user_accounts
    ORDER BY id;" \
    --skip-column-names --raw | \
while IFS=$'\t' read -r legacy_id user_id account_id role permissions status created_at created_by updated_by; do
    # Generate UUID for new record
    new_id=$(uuidgen | tr '[:upper:]' '[:lower:]')
    
    # Handle NULL values
    [ "$role" = "NULL" ] && role="supplier"
    [ "$permissions" = "NULL" ] && permissions=""
    [ "$status" = "NULL" ] && status="active"
    [ "$created_at" = "NULL" ] && created_at="CURRENT_TIMESTAMP"
    [ "$created_by" = "NULL" ] && created_by=""
    [ "$updated_by" = "NULL" ] && updated_by=""
    
    # Map user_id and account_id to UUIDs (via SSH)
    user_uuid=$(sshpass -p "$REMOTE_PASS" ssh -o StrictHostKeyChecking=no $REMOTE_SERVER \
        "docker exec -i $PG_CONTAINER psql -U $PG_USER -d $PG_DB -t -c \"SELECT id FROM users WHERE legacy_id = $user_id LIMIT 1;\"" 2>/dev/null | tr -d ' ')
    
    account_uuid=$(sshpass -p "$REMOTE_PASS" ssh -o StrictHostKeyChecking=no $REMOTE_SERVER \
        "docker exec -i $PG_CONTAINER psql -U $PG_USER -d $PG_DB -t -c \"SELECT id FROM accounts WHERE legacy_id = $account_id LIMIT 1;\"" 2>/dev/null | tr -d ' ')
    
    # Skip if user or account not found
    [ -z "$user_uuid" ] && continue
    [ -z "$account_uuid" ] && continue
    
    # Map created_by and updated_by
    created_by_uuid=""
    if [ -n "$created_by" ] && [ "$created_by" != "NULL" ]; then
        created_by_uuid=$(sshpass -p "$REMOTE_PASS" ssh -o StrictHostKeyChecking=no $REMOTE_SERVER \
            "docker exec -i $PG_CONTAINER psql -U $PG_USER -d $PG_DB -t -c \"SELECT id FROM users WHERE legacy_id = $created_by LIMIT 1;\"" 2>/dev/null | tr -d ' ')
    fi
    
    updated_by_uuid=""
    if [ -n "$updated_by" ] && [ "$updated_by" != "NULL" ]; then
        updated_by_uuid=$(sshpass -p "$REMOTE_PASS" ssh -o StrictHostKeyChecking=no $REMOTE_SERVER \
            "docker exec -i $PG_CONTAINER psql -U $PG_USER -d $PG_DB -t -c \"SELECT id FROM users WHERE legacy_id = $updated_by LIMIT 1;\"" 2>/dev/null | tr -d ' ')
    fi
    
    # Insert into PostgreSQL via SSH
    sshpass -p "$REMOTE_PASS" ssh -o StrictHostKeyChecking=no $REMOTE_SERVER \
        "docker exec -i $PG_CONTAINER psql -U $PG_USER -d $PG_DB" << EOF
INSERT INTO user_accounts (
    id, legacy_id, user_id, account_id, role, permissions, status,
    created_at, created_by, updated_by
) VALUES (
    '$new_id',
    $legacy_id,
    '$user_uuid',
    '$account_uuid',
    '$role',
    $( [ -z "$permissions" ] && echo "NULL::jsonb" || echo "'$permissions'::jsonb" ),
    '$status',
    $( [ "$created_at" = "CURRENT_TIMESTAMP" ] && echo "CURRENT_TIMESTAMP" || echo "'$created_at'" ),
    $( [ -z "$created_by_uuid" ] && echo "NULL" || echo "'$created_by_uuid'" ),
    $( [ -z "$updated_by_uuid" ] && echo "NULL" || echo "'$updated_by_uuid'" )
)
ON CONFLICT (legacy_id) DO NOTHING;
EOF
done

echo "   ✓ User accounts migrated"
