#!/bin/bash

# Migrate users table from MySQL to PostgreSQL
# Preserves tokens for authentication continuity

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

echo "   Exporting users from MySQL..."

# Export users with password hashes and tokens
mysql -h "$MYSQL_HOST" -P "$MYSQL_PORT" -u "$MYSQL_USER" -p"$MYSQL_PASS" "$MYSQL_DB" \
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
    
    # Map default_account_id to new UUID (will need to look up from accounts)
    if [ -n "$default_account_id" ] && [ "$default_account_id" != "NULL" ]; then
        mapped_account_id=$(psql -h "$PG_HOST" -p "$PG_PORT" -U "$PG_USER" -d "$PG_DB" -t -c \
            "SELECT id FROM accounts WHERE legacy_id = $default_account_id LIMIT 1;" | tr -d ' ')
        [ -z "$mapped_account_id" ] && mapped_account_id="NULL"
    else
        mapped_account_id="NULL"
    fi
    
    psql -h "$PG_HOST" -p "$PG_PORT" -U "$PG_USER" -d "$PG_DB" << EOF
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

