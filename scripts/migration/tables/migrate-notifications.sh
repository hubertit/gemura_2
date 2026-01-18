#!/bin/bash

# Migrate notifications table from MySQL to PostgreSQL

set -e

MYSQL_HOST=$1; MYSQL_PORT=$2; MYSQL_DB=$3; MYSQL_USER=$4; MYSQL_PASS=$5
PG_HOST=$6; PG_PORT=$7; PG_DB=$8; PG_USER=$9; PG_PASS=${10}

export PGPASSWORD="$PG_PASS"

echo "   Exporting notifications from MySQL..."

mysql -h "$MYSQL_HOST" -P "$MYSQL_PORT" -u "$MYSQL_USER" -p"$MYSQL_PASS" "$MYSQL_DB" \
    -e "SELECT 
        id as legacy_id,
        user_id,
        title,
        message,
        type,
        status,
        created_at,
        updated_at
    FROM notifications
    ORDER BY id;" \
    --skip-column-names --raw | \
while IFS=$'\t' read -r legacy_id user_id title message type status created_at updated_at; do
    new_id=$(uuidgen | tr '[:upper:]' '[:lower:]')
    
    # Map user_id
    user_uuid=$(psql -h "$PG_HOST" -p "$PG_PORT" -U "$PG_USER" -d "$PG_DB" -t -c \
        "SELECT id FROM users WHERE legacy_id = $user_id LIMIT 1;" | tr -d ' ')
    [ -z "$user_uuid" ] && user_uuid="NULL"
    
    psql -h "$PG_HOST" -p "$PG_PORT" -U "$PG_USER" -d "$PG_DB" << EOF
INSERT INTO notifications (
    id, legacy_id, user_id, title, message, type, status, created_at, updated_at
) VALUES (
    '$new_id',
    $legacy_id,
    $( [ "$user_uuid" = "NULL" ] && echo "NULL" || echo "'$user_uuid'" ),
    '$(echo "$title" | sed "s/'/''/g")',
    '$(echo "$message" | sed "s/'/''/g")',
    '$type',
    '$status',
    '$created_at',
    '$updated_at'
)
ON CONFLICT (legacy_id) DO NOTHING;
EOF
done

echo "   ✓ Notifications migrated"

