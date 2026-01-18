#!/bin/bash

# Migrate remaining feed data - simpler direct approach

set -e

MYSQL_DB="gemura_migration_temp"

echo "🔄 Migrating Remaining Feed Data"
echo "================================"
echo ""

# Helper function to get UUID
get_uuid() {
    local table=$1
    local legacy_id=$2
    docker exec -i devslab-postgres psql -U devslab_admin -d gemura_db -t -c \
        "SELECT id FROM $table WHERE legacy_id = $legacy_id LIMIT 1;" 2>/dev/null | \
        grep -E '^[a-f0-9-]{36}' | head -1 | tr -d ' \n'
}

echo "📦 Migrating feed_posts (23 total)..."
count=0
mysql -u root $MYSQL_DB -N -e "SELECT id, user_id, content, media_url, hashtags, location, likes_count, shares_count, bookmarks_count, status, created_at, updated_at FROM feed_posts;" | \
while IFS=$'\t' read -r id user_id content media_url hashtags location likes shares bookmarks status created updated; do
    new_id=$(uuidgen | tr '[:upper:]' '[:lower:]')
    user_uuid=$(get_uuid "users" "$user_id")
    
    [ -z "$user_uuid" ] && user_uuid="NULL" || user_uuid="'$user_uuid'"
    
    content_esc=$(echo "$content" | sed "s/'/''/g")
    media_esc=$(echo "$media_url" | sed "s/'/''/g")
    hashtags_esc=$(echo "$hashtags" | sed "s/'/''/g")
    location_esc=$(echo "$location" | sed "s/'/''/g")
    
    [ -z "$likes" ] && likes=0
    [ -z "$shares" ] && shares=0
    [ -z "$bookmarks" ] && bookmarks=0
    [ -z "$status" ] && status="active"
    
    docker exec -i devslab-postgres psql -U devslab_admin -d gemura_db -c "
    INSERT INTO feed_posts (id, legacy_id, user_id, content, media_url, hashtags, location, 
                           likes_count, shares_count, bookmarks_count, status, created_at, updated_at)
    VALUES ('$new_id', $id, $user_uuid, 
            $( [ -z "$content" ] && echo "NULL" || echo "'$content_esc'" ),
            $( [ -z "$media_url" ] && echo "NULL" || echo "'$media_esc'" ),
            $( [ -z "$hashtags" ] && echo "NULL" || echo "'$hashtags_esc'" ),
            $( [ -z "$location" ] && echo "NULL" || echo "'$location_esc'" ),
            $likes, $shares, $bookmarks, '$status', '$created', '$updated')
    ON CONFLICT (legacy_id) DO NOTHING;
    " > /dev/null 2>&1 && count=$((count+1))
done
echo "   ✅ Migrated $count feed posts"

echo ""
echo "📦 Migrating feed_comments (10 total)..."
count=0
mysql -u root $MYSQL_DB -N -e "SELECT id, post_id, user_id, content, parent_comment_id, likes_count, status, created_at, updated_at FROM feed_comments;" | \
while IFS=$'\t' read -r id post_id user_id content parent_id likes status created updated; do
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
    
    content_esc=$(echo "$content" | sed "s/'/''/g")
    [ -z "$likes" ] && likes=0
    [ -z "$status" ] && status="active"
    
    docker exec -i devslab-postgres psql -U devslab_admin -d gemura_db -c "
    INSERT INTO feed_comments (id, legacy_id, post_id, user_id, content, parent_comment_id, 
                               likes_count, status, created_at, updated_at)
    VALUES ('$new_id', $id, $post_uuid, $user_uuid, '$content_esc', $parent_uuid,
            $likes, '$status', '$created', '$updated')
    ON CONFLICT (legacy_id) DO NOTHING;
    " > /dev/null 2>&1 && count=$((count+1))
done
echo "   ✅ Migrated $count feed comments"

echo ""
echo "📦 Migrating feed_interactions (14 total)..."
count=0
mysql -u root $MYSQL_DB -N -e "SELECT id, user_id, post_id, story_id, interaction_type, created_at FROM feed_interactions;" | \
while IFS=$'\t' read -r id user_id post_id story_id interaction_type created; do
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
    VALUES ('$new_id', $id, $user_uuid, $post_uuid, $story_uuid, '$interaction_type', '$created')
    ON CONFLICT (legacy_id) DO NOTHING;
    " > /dev/null 2>&1 && count=$((count+1))
done
echo "   ✅ Migrated $count feed interactions"

echo ""
echo "📦 Migrating user_bookmarks (9 total)..."
count=0
mysql -u root $MYSQL_DB -N -e "SELECT id, user_id, post_id, created_at FROM user_bookmarks;" | \
while IFS=$'\t' read -r id user_id post_id created; do
    new_id=$(uuidgen | tr '[:upper:]' '[:lower:]')
    user_uuid=$(get_uuid "users" "$user_id")
    post_uuid=$(get_uuid "feed_posts" "$post_id")
    
    [ -z "$user_uuid" ] && user_uuid="NULL" || user_uuid="'$user_uuid'"
    [ -z "$post_uuid" ] && post_uuid="NULL" || post_uuid="'$post_uuid'"
    
    docker exec -i devslab-postgres psql -U devslab_admin -d gemura_db -c "
    INSERT INTO user_bookmarks (id, legacy_id, user_id, post_id, created_at)
    VALUES ('$new_id', $id, $user_uuid, $post_uuid, '$created')
    ON CONFLICT (legacy_id) DO NOTHING;
    " > /dev/null 2>&1 && count=$((count+1))
done
echo "   ✅ Migrated $count user bookmarks"

echo ""
echo "📦 Migrating remaining product (1 total)..."
mysql -u root $MYSQL_DB -N -e "SELECT id, name, COALESCE(description, '') as description, price, COALESCE(stock_quantity, 0) as stock_quantity, seller_id, created_at, updated_at FROM products WHERE id NOT IN (SELECT legacy_id FROM (SELECT legacy_id FROM products WHERE legacy_id IS NOT NULL) t);" | \
while IFS=$'\t' read -r id name desc price stock seller created updated; do
    new_id=$(uuidgen | tr '[:upper:]' '[:lower:]')
    name_esc=$(echo "$name" | sed "s/'/''/g")
    desc_esc=$(echo "$desc" | sed "s/'/''/g")
    
    docker exec -i devslab-postgres psql -U devslab_admin -d gemura_db -c "
    INSERT INTO products (id, legacy_id, name, description, price, stock_quantity, status, created_at, updated_at)
    VALUES ('$new_id', $id, '$name_esc', '$desc_esc', $price, $stock, 'active', '$created', '$updated')
    ON CONFLICT (legacy_id) DO NOTHING;
    " > /dev/null 2>&1 && echo "   ✅ Migrated product $id"
done

echo ""
echo "✅ All remaining data migration completed!"
