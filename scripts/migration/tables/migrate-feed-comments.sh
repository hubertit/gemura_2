#!/bin/bash

# Migrate feed_comments table from MySQL to PostgreSQL

set -e

MYSQL_HOST=$1; MYSQL_PORT=$2; MYSQL_DB=$3; MYSQL_USER=$4; MYSQL_PASS=$5
PG_HOST=$6; PG_PORT=$7; PG_DB=$8; PG_USER=$9; PG_PASS=${10}

export PGPASSWORD="$PG_PASS"

echo "   Exporting feed_comments from MySQL..."

mysql -h "$MYSQL_HOST" -P "$MYSQL_PORT" -u "$MYSQL_USER" -p"$MYSQL_PASS" "$MYSQL_DB" \
    -e "SELECT 
        id as legacy_id,
        post_id,
        user_id,
        content,
        parent_comment_id,
        likes_count,
        status,
        created_at,
        updated_at,
        created_by,
        updated_by
    FROM feed_comments
    ORDER BY id;" \
    --skip-column-names --raw | \
while IFS=$'\t' read -r legacy_id post_id user_id content parent_comment_id likes_count status created_at updated_at created_by updated_by; do
    new_id=$(uuidgen | tr '[:upper:]' '[:lower:]')
    
    # Map post_id and user_id to new UUIDs
    post_uuid=$(psql -h "$PG_HOST" -p "$PG_PORT" -U "$PG_USER" -d "$PG_DB" -t -c \
        "SELECT id FROM feed_posts WHERE legacy_id = $post_id LIMIT 1;" | tr -d ' ')
    user_uuid=$(psql -h "$PG_HOST" -p "$PG_PORT" -U "$PG_USER" -d "$PG_DB" -t -c \
        "SELECT id FROM users WHERE legacy_id = $user_id LIMIT 1;" | tr -d ' ')
    
    [ -z "$post_uuid" ] && post_uuid="NULL"
    [ -z "$user_uuid" ] && user_uuid="NULL"
    
    # Map parent_comment_id if it exists
    parent_comment_uuid="NULL"
    if [ "$parent_comment_id" != "NULL" ] && [ -n "$parent_comment_id" ]; then
        parent_comment_uuid=$(psql -h "$PG_HOST" -p "$PG_PORT" -U "$PG_USER" -d "$PG_DB" -t -c \
            "SELECT id FROM feed_comments WHERE legacy_id = $parent_comment_id LIMIT 1;" | tr -d ' ')
        [ -z "$parent_comment_uuid" ] && parent_comment_uuid="NULL"
    fi
    
    # Map created_by and updated_by to UUIDs if they exist
    created_by_uuid="NULL"
    if [ "$created_by" != "NULL" ] && [ -n "$created_by" ]; then
        created_by_uuid=$(psql -h "$PG_HOST" -p "$PG_PORT" -U "$PG_USER" -d "$PG_DB" -t -c \
            "SELECT id FROM users WHERE legacy_id = $created_by LIMIT 1;" | tr -d ' ')
        [ -z "$created_by_uuid" ] && created_by_uuid="NULL"
    fi
    
    updated_by_uuid="NULL"
    if [ "$updated_by" != "NULL" ] && [ -n "$updated_by" ]; then
        updated_by_uuid=$(psql -h "$PG_HOST" -p "$PG_PORT" -U "$PG_USER" -d "$PG_DB" -t -c \
            "SELECT id FROM users WHERE legacy_id = $updated_by LIMIT 1;" | tr -d ' ')
        [ -z "$updated_by_uuid" ] && updated_by_uuid="NULL"
    fi
    
    # Handle NULL values and escape single quotes
    content_escaped=$(echo "$content" | sed "s/'/''/g")
    
    psql -h "$PG_HOST" -p "$PG_PORT" -U "$PG_USER" -d "$PG_DB" << EOF
INSERT INTO feed_comments (
    id, legacy_id, post_id, user_id, content, parent_comment_id, likes_count, status,
    created_at, updated_at, created_by, updated_by
) VALUES (
    '$new_id',
    $legacy_id,
    $( [ "$post_uuid" = "NULL" ] && echo "NULL" || echo "'$post_uuid'" ),
    $( [ "$user_uuid" = "NULL" ] && echo "NULL" || echo "'$user_uuid'" ),
    '$(echo "$content_escaped")',
    $( [ "$parent_comment_uuid" = "NULL" ] && echo "NULL" || echo "'$parent_comment_uuid'" ),
    $( [ "$likes_count" = "NULL" ] || [ -z "$likes_count" ] && echo "0" || echo "$likes_count" ),
    $( [ "$status" = "NULL" ] || [ -z "$status" ] && echo "'active'" || echo "'$status'" ),
    '$created_at',
    '$updated_at',
    $( [ "$created_by_uuid" = "NULL" ] && echo "NULL" || echo "'$created_by_uuid'" ),
    $( [ "$updated_by_uuid" = "NULL" ] && echo "NULL" || echo "'$updated_by_uuid'" )
)
ON CONFLICT (legacy_id) DO NOTHING;
EOF
done

echo "   ✓ Feed comments migrated"
