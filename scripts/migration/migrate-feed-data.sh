#!/bin/bash

# Migrate feed data from MySQL temp database to PostgreSQL
# This script migrates feed_posts, feed_comments, feed_interactions, and user_bookmarks

set -e

MYSQL_DB="gemura_migration_temp"

echo "🔄 Migrating Feed Data"
echo "======================"
echo ""

# Function to get UUID from legacy_id
get_uuid() {
    local table=$1
    local legacy_id=$2
    docker exec -i devslab-postgres psql -U devslab_admin -d gemura_db -t -c \
        "SELECT id FROM $table WHERE legacy_id = $legacy_id LIMIT 1;" 2>/dev/null | \
        grep -E '^[a-f0-9-]{36}' | head -1 | tr -d ' '
}

# Function to escape SQL strings
escape_sql() {
    echo "$1" | sed "s/'/''/g"
}

echo "📦 Migrating feed_posts..."
mysql -u root $MYSQL_DB -N -e "
SELECT id, user_id, COALESCE(content, '') as content, 
       COALESCE(media_url, '') as media_url, 
       COALESCE(hashtags, '') as hashtags,
       COALESCE(location, '') as location,
       COALESCE(likes_count, 0) as likes_count,
       COALESCE(shares_count, 0) as shares_count,
       COALESCE(bookmarks_count, 0) as bookmarks_count,
       COALESCE(status, 'active') as status,
       created_at, updated_at
FROM feed_posts
ORDER BY id;
" | while IFS=$'\t' read -r legacy_id user_id content media_url hashtags location likes shares bookmarks status created updated; do
    new_id=$(uuidgen | tr '[:upper:]' '[:lower:]')
    user_uuid=$(get_uuid "users" "$user_id")
    
    if [ -z "$user_uuid" ]; then
        user_uuid="NULL"
    else
        user_uuid="'$user_uuid'"
    fi
    
    content_esc=$(escape_sql "$content")
    media_esc=$(escape_sql "$media_url")
    
    docker exec -i devslab-postgres psql -U devslab_admin -d gemura_db -c "
    INSERT INTO feed_posts (id, legacy_id, user_id, content, media_url, hashtags, location, 
                           likes_count, shares_count, bookmarks_count, status, created_at, updated_at)
    VALUES ('$new_id', $legacy_id, $user_uuid, '$content_esc', '$media_esc', NULL, NULL,
            $likes, $shares, $bookmarks, '$status', '$created', '$updated')
    ON CONFLICT (legacy_id) DO NOTHING;
    " > /dev/null 2>&1
done
echo "   ✅ Feed posts migrated"

echo ""
echo "📦 Migrating feed_comments..."
mysql -u root $MYSQL_DB -N -e "
SELECT id, post_id, user_id, COALESCE(content, '') as content,
       parent_comment_id, COALESCE(likes_count, 0) as likes_count,
       COALESCE(status, 'active') as status,
       created_at, updated_at
FROM feed_comments
ORDER BY id;
" | while IFS=$'\t' read -r legacy_id post_id user_id content parent_id likes status created updated; do
    new_id=$(uuidgen | tr '[:upper:]' '[:lower:]')
    post_uuid=$(get_uuid "feed_posts" "$post_id")
    user_uuid=$(get_uuid "users" "$user_id")
    
    [ -z "$post_uuid" ] && post_uuid="NULL" || post_uuid="'$post_uuid'"
    [ -z "$user_uuid" ] && user_uuid="NULL" || user_uuid="'$user_uuid'"
    
    parent_uuid="NULL"
    if [ ! -z "$parent_id" ] && [ "$parent_id" != "NULL" ] && [ "$parent_id" != "0" ]; then
        parent_uuid=$(get_uuid "feed_comments" "$parent_id")
        [ -z "$parent_uuid" ] && parent_uuid="NULL" || parent_uuid="'$parent_uuid'"
    fi
    
    content_esc=$(escape_sql "$content")
    
    docker exec -i devslab-postgres psql -U devslab_admin -d gemura_db -c "
    INSERT INTO feed_comments (id, legacy_id, post_id, user_id, content, parent_comment_id, 
                               likes_count, status, created_at, updated_at)
    VALUES ('$new_id', $legacy_id, $post_uuid, $user_uuid, '$content_esc', $parent_uuid,
            $likes, '$status', '$created', '$updated')
    ON CONFLICT (legacy_id) DO NOTHING;
    " > /dev/null 2>&1
done
echo "   ✅ Feed comments migrated"

echo ""
echo "📦 Migrating feed_interactions..."
mysql -u root $MYSQL_DB -N -e "
SELECT id, user_id, post_id, story_id, interaction_type, created_at
FROM feed_interactions
ORDER BY id;
" | while IFS=$'\t' read -r legacy_id user_id post_id story_id interaction_type created; do
    new_id=$(uuidgen | tr '[:upper:]' '[:lower:]')
    user_uuid=$(get_uuid "users" "$user_id")
    
    [ -z "$user_uuid" ] && user_uuid="NULL" || user_uuid="'$user_uuid'"
    
    post_uuid="NULL"
    if [ ! -z "$post_id" ] && [ "$post_id" != "NULL" ] && [ "$post_id" != "0" ]; then
        post_uuid=$(get_uuid "feed_posts" "$post_id")
        [ -z "$post_uuid" ] && post_uuid="NULL" || post_uuid="'$post_uuid'"
    fi
    
    story_uuid="NULL"
    if [ ! -z "$story_id" ] && [ "$story_id" != "NULL" ] && [ "$story_id" != "0" ]; then
        story_uuid=$(get_uuid "feed_stories" "$story_id")
        [ -z "$story_uuid" ] && story_uuid="NULL" || story_uuid="'$story_uuid'"
    fi
    
    docker exec -i devslab-postgres psql -U devslab_admin -d gemura_db -c "
    INSERT INTO feed_interactions (id, legacy_id, user_id, post_id, story_id, interaction_type, created_at)
    VALUES ('$new_id', $legacy_id, $user_uuid, $post_uuid, $story_uuid, '$interaction_type', '$created')
    ON CONFLICT (legacy_id) DO NOTHING;
    " > /dev/null 2>&1
done
echo "   ✅ Feed interactions migrated"

echo ""
echo "📦 Migrating user_bookmarks..."
mysql -u root $MYSQL_DB -N -e "
SELECT id, user_id, post_id, created_at
FROM user_bookmarks
ORDER BY id;
" | while IFS=$'\t' read -r legacy_id user_id post_id created; do
    new_id=$(uuidgen | tr '[:upper:]' '[:lower:]')
    user_uuid=$(get_uuid "users" "$user_id")
    post_uuid=$(get_uuid "feed_posts" "$post_id")
    
    [ -z "$user_uuid" ] && user_uuid="NULL" || user_uuid="'$user_uuid'"
    [ -z "$post_uuid" ] && post_uuid="NULL" || post_uuid="'$post_uuid'"
    
    docker exec -i devslab-postgres psql -U devslab_admin -d gemura_db -c "
    INSERT INTO user_bookmarks (id, legacy_id, user_id, post_id, created_at)
    VALUES ('$new_id', $legacy_id, $user_uuid, $post_uuid, '$created')
    ON CONFLICT (legacy_id) DO NOTHING;
    " > /dev/null 2>&1
done
echo "   ✅ User bookmarks migrated"

echo ""
echo "✅ Feed data migration completed!"
