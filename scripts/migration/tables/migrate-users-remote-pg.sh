#!/bin/bash

# Migrate users table from MySQL to PostgreSQL (via SSH for remote PG)
# Usage: migrate-users-remote-pg.sh mysql_host mysql_port mysql_db mysql_user mysql_pass remote_server remote_pass pg_container pg_db pg_user pg_pass

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

echo "   Exporting users from MySQL..."

# Export users with password hashes and tokens
"$MYSQL_BIN" -h "$MYSQL_HOST" -P "$MYSQL_PORT" -u "$MYSQL_USER" ${MYSQL_PASS:+-p"$MYSQL_PASS"} "$MYSQL_DB" \
    -e "SELECT 
        id as legacy_id,
        code,
        name,
        email,
        phone,
        password_hash,
        token,
        account_type,
        status,
        default_account_id,
        kyc_status,
        kyc_verified_at,
        created_at,
        updated_at
    FROM users
    ORDER BY id;" \
    --skip-column-names --raw | \
while IFS=$'\t' read -r legacy_id code name email phone password_hash token account_type status default_account_id kyc_status kyc_verified_at created_at updated_at; do
    new_id=$(uuidgen | tr '[:upper:]' '[:lower:]')
    
    # Handle NULL values
    [ "$code" = "NULL" ] && code=""
    [ "$name" = "NULL" ] && name=""
    [ "$email" = "NULL" ] && email=""
    [ "$phone" = "NULL" ] && phone=""
    [ "$token" = "NULL" ] && token=""
    [ "$default_account_id" = "NULL" ] && default_account_id=""
    [ "$kyc_verified_at" = "NULL" ] && kyc_verified_at=""
    [ "$created_at" = "NULL" ] && created_at="CURRENT_TIMESTAMP"
    [ "$updated_at" = "NULL" ] && updated_at="CURRENT_TIMESTAMP"
    
    # Map default_account_id to new UUID (look up from accounts via SSH)
    mapped_account_id="NULL"
    if [ -n "$default_account_id" ] && [ "$default_account_id" != "NULL" ]; then
        mapped_account_id=$(sshpass -p "$REMOTE_PASS" ssh -o StrictHostKeyChecking=no $REMOTE_SERVER \
            "docker exec -i $PG_CONTAINER psql -U $PG_USER -d $PG_DB -t -c \"SELECT id FROM accounts WHERE legacy_id = $default_account_id LIMIT 1;\"" 2>/dev/null | tr -d ' ')
        [ -z "$mapped_account_id" ] && mapped_account_id="NULL"
    fi
    
    # Insert into PostgreSQL via SSH
    sshpass -p "$REMOTE_PASS" ssh -o StrictHostKeyChecking=no $REMOTE_SERVER \
        "docker exec -i $PG_CONTAINER psql -U $PG_USER -d $PG_DB" << EOF
INSERT INTO users (
    id, legacy_id, code, name, email, phone, password_hash, token,
    account_type, status, default_account_id, kyc_status, kyc_verified_at,
    created_at, updated_at
) VALUES (
    '$new_id',
    $legacy_id,
    '$(echo "$code" | sed "s/'/''/g")',
    '$(echo "$name" | sed "s/'/''/g")',
    $( [ -z "$email" ] && echo "NULL" || echo "'$(echo "$email" | sed "s/'/''/g")'" ),
    $( [ -z "$phone" ] && echo "NULL" || echo "'$(echo "$phone" | sed "s/'/''/g")'" ),
    '$(echo "$password_hash" | sed "s/'/''/g")',
    $( [ -z "$token" ] && echo "NULL" || echo "'$(echo "$token" | sed "s/'/''/g")'" ),
    '$account_type',
    '$status',
    $( [ "$mapped_account_id" = "NULL" ] && echo "NULL" || echo "'$mapped_account_id'" ),
    $( [ -z "$kyc_status" ] && echo "NULL" || echo "'$kyc_status'" ),
    $( [ -z "$kyc_verified_at" ] && echo "NULL" || echo "'$kyc_verified_at'" ),
    $( [ "$created_at" = "CURRENT_TIMESTAMP" ] && echo "CURRENT_TIMESTAMP" || echo "'$created_at'" ),
    $( [ "$updated_at" = "CURRENT_TIMESTAMP" ] && echo "CURRENT_TIMESTAMP" || echo "'$updated_at'" )
)
ON CONFLICT (legacy_id) DO NOTHING;
EOF
done

echo "   ✓ Users migrated"
