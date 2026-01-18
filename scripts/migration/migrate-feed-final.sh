#!/bin/bash

# Final Feed Data Migration
# Migrates all remaining feed_posts, feed_comments, feed_interactions, and user_bookmarks

set -e

MYSQL_DB="gemura_migration_temp"

echo "🔄 Final Feed Data Migration"
echo "============================="
echo ""

# Helper function
get_uuid() {
    local table=$1
    local legacy_id=$2
    docker exec -i devslab-postgres psql -U devslab_admin -d gemura_db -t -c \
        "SELECT id FROM $table WHERE legacy_id = $legacy_id LIMIT 1;" 2>/dev/null | \
        grep -E '^[a-f0-9-]{36}' | head -1 | tr -d ' \n'
}

# Migrate feed_posts
echo "📦 Migrating feed_posts..."
post_count=0
mysql -u root $MYSQL_DB -N -e "SELECT id FROM feed_posts ORDER BY id;" | while read id; do
    existing=$(docker exec -i devslab-postgres psql -U devslab_admin -d gemura_db -t -c \
        "SELECT COUNT(*) FROM feed_posts WHERE legacy_id = $id;" | tr -d ' \n')
    if [ "$existing" = "0" ]; then
        data=$(mysql -u root $MYSQL_DB -N -e \
            "SELECT user_id, COALESCE(content, ''), COALESCE(likes_count, 0), COALESCE(shares_count, 0), 
                    COALESCE(bookmarks_count, 0), COALESCE(status, 'active'), created_at, updated_at 
             FROM feed_posts WHERE id = $id;")
        IFS=$'\t' read -r user_id content likes shares bookmarks status created updated <<< "$data"
        new_id=$(uuidgen | tr '[:upper:]' '[:lower:]')
        user_uuid=$(get_uuid "users" "$user_id")
        [ -z "$user_uuid" ] && user_uuid="NULL" || user_uuid="'$user_uuid'"
        content_esc=$(echo "$content" | sed "s/'/''/g")
        docker exec -i devslab-postgres psql -U devslab_admin -d gemura_db -c \
            "INSERT INTO feed_posts (id, legacy_id, user_id, content, likes_count, shares_count, 
                                    bookmarks_count, status, created_at, updated_at)
             VALUES ('$new_id', $id, $user_uuid, '$content_esc', $likes, $shares, $bookmarks, 
                     '$status', '$created', '$updated')
             ON CONFLICT (legacy_id) DO NOTHING;" > /dev/null 2>&1 && post_count=$((post_count+1)) && echo "   Migrated post $id"
    fi
done
echo "   ✅ Migrated $post_count feed posts"

# Migrate feed_comments
echo ""
echo "📦 Migrating feed_comments..."
comment_count=0
mysql -u root $MYSQL_DB -N -e "SELECT id FROM feed_comments ORDER BY id;" | while read id; do
    existing=$(docker exec -i devslab-postgres psql -U devslab_admin -d gemura_db -t -c \
        "SELECT COUNT(*) FROM feed_comments WHERE legacy_id = $id;" | tr -d ' \n')
    if [ "$existing" = "0" ]; then
        data=$(mysql -u root $MYSQL_DB -N -e \
            "SELECT post_id, user_id, COALESCE(content, ''), parent_comment_id, 
                    COALESCE(likes_count, 0), COALESCE(status, 'active'), created_at, updated_at
             FROM feed_comments WHERE id = $id;")
        IFS=$'\t' read -r post_id user_id content parent_id likes status created updated <<< "$data"
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
        docker exec -i devslab-postgres psql -U devslab_admin -d gemura_db -c \
            "INSERT INTO feed_comments (id, legacy_id, post_id, user_id, content, parent_comment_id,
                                       likes_count, status, created_at, updated_at)
             VALUES ('$new_id', $id, $post_uuid, $user_uuid, '$content_esc', $parent_uuid,
                     $likes, '$status', '$created', '$updated')
             ON CONFLICT (legacy_id) DO NOTHING;" > /dev/null 2>&1 && comment_count=$((comment_count+1)) && echo "   Migrated comment $id"
    fi
done
echo "   ✅ Migrated $comment_count feed comments"

# Migrate feed_interactions
echo ""
echo "📦 Migrating feed_interactions..."
interaction_count=0
mysql -u root $MYSQL_DB -N -e "SELECT id FROM feed_interactions ORDER BY id;" | while read id; do
    existing=$(docker exec -i devslab-postgres psql -U devslab_admin -d gemura_db -t -c \
        "SELECT COUNT(*) FROM feed_interactions WHERE legacy_id = $id;" | tr -d ' \n')
    if [ "$existing" = "0" ]; then
        data=$(mysql -u root $MYSQL_DB -N -e \
            "SELECT user_id, post_id, story_id, interaction_type, created_at
             FROM feed_interactions WHERE id = $id;")
        IFS=$'\t' read -r user_id post_id story_id interaction_type created <<< "$data"
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
        docker exec -i devslab-postgres psql -U devslab_admin -d gemura_db -c \
            "INSERT INTO feed_interactions (id, legacy_id, user_id, post_id, story_id, interaction_type, created_at)
             VALUES ('$new_id', $id, $user_uuid, $post_uuid, $story_uuid, '$interaction_type', '$created')
             ON CONFLICT (legacy_id) DO NOTHING;" > /dev/null 2>&1 && interaction_count=$((interaction_count+1)) && echo "   Migrated interaction $id"
    fi
done
echo "   ✅ Migrated $interaction_count feed interactions"

# Migrate user_bookmarks
echo ""
echo "📦 Migrating user_bookmarks..."
bookmark_count=0
mysql -u root $MYSQL_DB -N -e "SELECT id FROM user_bookmarks ORDER BY id;" | while read id; do
    existing=$(docker exec -i devslab-postgres psql -U devslab_admin -d gemura_db -t -c \
        "SELECT COUNT(*) FROM user_bookmarks WHERE legacy_id = $id;" | tr -d ' \n')
    if [ "$existing" = "0" ]; then
        data=$(mysql -u root $MYSQL_DB -N -e \
            "SELECT user_id, post_id, created_at FROM user_bookmarks WHERE id = $id;")
        IFS=$'\t' read -r user_id post_id created <<< "$data"
        new_id=$(uuidgen | tr '[:upper:]' '[:lower:]')
        user_uuid=$(get_uuid "users" "$user_id")
        post_uuid=$(get_uuid "feed_posts" "$post_id")
        [ -z "$user_uuid" ] && user_uuid="NULL" || user_uuid="'$user_uuid'"
        [ -z "$post_uuid" ] && post_uuid="NULL" || post_uuid="'$post_uuid'"
        docker exec -i devslab-postgres psql -U devslab_admin -d gemura_db -c \
            "INSERT INTO user_bookmarks (id, legacy_id, user_id, post_id, created_at)
             VALUES ('$new_id', $id, $user_uuid, $post_uuid, '$created')
             ON CONFLICT (legacy_id) DO NOTHING;" > /dev/null 2>&1 && bookmark_count=$((bookmark_count+1)) && echo "   Migrated bookmark $id"
    fi
done
echo "   ✅ Migrated $bookmark_count user bookmarks"

echo ""
echo "✅ Feed data migration completed!"
