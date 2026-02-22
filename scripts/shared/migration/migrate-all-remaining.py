#!/usr/bin/env python3

"""
Complete Migration Script for Remaining Data
Migrates all products, feed_posts, feed_comments, feed_interactions, and user_bookmarks
"""

import mysql.connector
import psycopg2
import uuid
import sys
from datetime import datetime

# Database connections
mysql_config = {
    'host': 'localhost',
    'user': 'root',
    'password': '',
    'database': 'gemura_migration_temp'
}

pg_config = {
    'host': 'devslab-postgres',
    'port': '5432',
    'database': 'gemura_db',
    'user': 'devslab_admin',
    'password': 'devslab_secure_password_2024'
}

def get_uuid_from_legacy_id(pg_cur, table, legacy_id):
    """Get UUID from legacy_id"""
    if legacy_id is None:
        return None
    pg_cur.execute(f"SELECT id FROM {table} WHERE legacy_id = %s LIMIT 1", (legacy_id,))
    result = pg_cur.fetchone()
    return result[0] if result else None

def escape_sql(value):
    """Escape SQL strings"""
    if value is None:
        return None
    return str(value).replace("'", "''")

print("🔄 Migrating All Remaining Data")
print("=" * 50)
print()

# Connect to databases
try:
    mysql_conn = mysql.connector.connect(**mysql_config)
    mysql_cur = mysql_conn.cursor(dictionary=True)
    print("✅ Connected to MySQL")
except Exception as e:
    print(f"❌ Failed to connect to MySQL: {e}")
    sys.exit(1)

try:
    pg_conn = psycopg2.connect(**pg_config)
    pg_cur = pg_conn.cursor()
    print("✅ Connected to PostgreSQL")
except Exception as e:
    print(f"❌ Failed to connect to PostgreSQL: {e}")
    mysql_conn.close()
    sys.exit(1)

# Migrate remaining products
print("\n📦 Migrating Products...")
mysql_cur.execute("SELECT id, name, description, price, stock_quantity, seller_id, created_at, updated_at FROM products")
products = mysql_cur.fetchall()

# Get existing product legacy_ids
pg_cur.execute("SELECT legacy_id FROM products WHERE legacy_id IS NOT NULL")
existing_product_ids = {row[0] for row in pg_cur.fetchall()}

product_count = 0
for product in products:
    if product['id'] in existing_product_ids:
        continue
    
    new_id = str(uuid.uuid4())
    name_esc = escape_sql(product['name'])
    desc_esc = escape_sql(product['description']) if product['description'] else ''
    price = float(product['price']) if product['price'] else 0
    stock = int(product['stock_quantity']) if product['stock_quantity'] else 0
    
    try:
        pg_cur.execute("""
            INSERT INTO products (id, legacy_id, name, description, price, stock_quantity, status, created_at, updated_at)
            VALUES (%s, %s, %s, %s, %s, %s, %s, %s, %s)
            ON CONFLICT (legacy_id) DO NOTHING
        """, (
            new_id, product['id'], name_esc, desc_esc, price, stock, 'active',
            product['created_at'], product['updated_at']
        ))
        if pg_cur.rowcount > 0:
            product_count += 1
    except Exception as e:
        print(f"   ⚠️  Error migrating product {product['id']}: {e}")

pg_conn.commit()
print(f"   ✅ Migrated {product_count} products")

# Migrate feed_posts
print("\n📦 Migrating Feed Posts...")
mysql_cur.execute("""
    SELECT id, user_id, content, media_url, hashtags, location, 
           likes_count, shares_count, bookmarks_count, status, created_at, updated_at
    FROM feed_posts
""")
feed_posts = mysql_cur.fetchall()

# Get existing feed_post legacy_ids
pg_cur.execute("SELECT legacy_id FROM feed_posts WHERE legacy_id IS NOT NULL")
existing_post_ids = {row[0] for row in pg_cur.fetchall()}

post_count = 0
for post in feed_posts:
    if post['id'] in existing_post_ids:
        continue
    
    new_id = str(uuid.uuid4())
    user_uuid = get_uuid_from_legacy_id(pg_cur, 'users', post['user_id'])
    content_esc = escape_sql(post['content'])
    media_esc = escape_sql(post['media_url'])
    hashtags_esc = escape_sql(post['hashtags'])
    location_esc = escape_sql(post['location'])
    likes = int(post['likes_count']) if post['likes_count'] else 0
    shares = int(post['shares_count']) if post['shares_count'] else 0
    bookmarks = int(post['bookmarks_count']) if post['bookmarks_count'] else 0
    status = post['status'] if post['status'] else 'active'
    
    try:
        pg_cur.execute("""
            INSERT INTO feed_posts (id, legacy_id, user_id, content, media_url, hashtags, location,
                                   likes_count, shares_count, bookmarks_count, status, created_at, updated_at)
            VALUES (%s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s)
            ON CONFLICT (legacy_id) DO NOTHING
        """, (
            new_id, post['id'], user_uuid, content_esc, media_esc, hashtags_esc, location_esc,
            likes, shares, bookmarks, status, post['created_at'], post['updated_at']
        ))
        if pg_cur.rowcount > 0:
            post_count += 1
    except Exception as e:
        print(f"   ⚠️  Error migrating feed_post {post['id']}: {e}")

pg_conn.commit()
print(f"   ✅ Migrated {post_count} feed posts")

# Migrate feed_comments
print("\n📦 Migrating Feed Comments...")
mysql_cur.execute("""
    SELECT id, post_id, user_id, content, parent_comment_id, likes_count, status, created_at, updated_at
    FROM feed_comments
""")
feed_comments = mysql_cur.fetchall()

# Get existing comment legacy_ids
pg_cur.execute("SELECT legacy_id FROM feed_comments WHERE legacy_id IS NOT NULL")
existing_comment_ids = {row[0] for row in pg_cur.fetchall()}

comment_count = 0
for comment in feed_comments:
    if comment['id'] in existing_comment_ids:
        continue
    
    new_id = str(uuid.uuid4())
    post_uuid = get_uuid_from_legacy_id(pg_cur, 'feed_posts', comment['post_id'])
    user_uuid = get_uuid_from_legacy_id(pg_cur, 'users', comment['user_id'])
    parent_uuid = get_uuid_from_legacy_id(pg_cur, 'feed_comments', comment['parent_comment_id']) if comment['parent_comment_id'] else None
    content_esc = escape_sql(comment['content'])
    likes = int(comment['likes_count']) if comment['likes_count'] else 0
    status = comment['status'] if comment['status'] else 'active'
    
    try:
        pg_cur.execute("""
            INSERT INTO feed_comments (id, legacy_id, post_id, user_id, content, parent_comment_id,
                                      likes_count, status, created_at, updated_at)
            VALUES (%s, %s, %s, %s, %s, %s, %s, %s, %s, %s)
            ON CONFLICT (legacy_id) DO NOTHING
        """, (
            new_id, comment['id'], post_uuid, user_uuid, content_esc, parent_uuid,
            likes, status, comment['created_at'], comment['updated_at']
        ))
        if pg_cur.rowcount > 0:
            comment_count += 1
    except Exception as e:
        print(f"   ⚠️  Error migrating feed_comment {comment['id']}: {e}")

pg_conn.commit()
print(f"   ✅ Migrated {comment_count} feed comments")

# Migrate feed_interactions
print("\n📦 Migrating Feed Interactions...")
mysql_cur.execute("""
    SELECT id, user_id, post_id, story_id, interaction_type, created_at
    FROM feed_interactions
""")
feed_interactions = mysql_cur.fetchall()

# Get existing interaction legacy_ids
pg_cur.execute("SELECT legacy_id FROM feed_interactions WHERE legacy_id IS NOT NULL")
existing_interaction_ids = {row[0] for row in pg_cur.fetchall()}

interaction_count = 0
for interaction in feed_interactions:
    if interaction['id'] in existing_interaction_ids:
        continue
    
    new_id = str(uuid.uuid4())
    user_uuid = get_uuid_from_legacy_id(pg_cur, 'users', interaction['user_id'])
    post_uuid = get_uuid_from_legacy_id(pg_cur, 'feed_posts', interaction['post_id']) if interaction['post_id'] else None
    story_uuid = get_uuid_from_legacy_id(pg_cur, 'feed_stories', interaction['story_id']) if interaction['story_id'] else None
    
    try:
        pg_cur.execute("""
            INSERT INTO feed_interactions (id, legacy_id, user_id, post_id, story_id, interaction_type, created_at)
            VALUES (%s, %s, %s, %s, %s, %s, %s)
            ON CONFLICT (legacy_id) DO NOTHING
        """, (
            new_id, interaction['id'], user_uuid, post_uuid, story_uuid,
            interaction['interaction_type'], interaction['created_at']
        ))
        if pg_cur.rowcount > 0:
            interaction_count += 1
    except Exception as e:
        print(f"   ⚠️  Error migrating feed_interaction {interaction['id']}: {e}")

pg_conn.commit()
print(f"   ✅ Migrated {interaction_count} feed interactions")

# Migrate user_bookmarks
print("\n📦 Migrating User Bookmarks...")
mysql_cur.execute("SELECT id, user_id, post_id, created_at FROM user_bookmarks")
user_bookmarks = mysql_cur.fetchall()

# Get existing bookmark legacy_ids
pg_cur.execute("SELECT legacy_id FROM user_bookmarks WHERE legacy_id IS NOT NULL")
existing_bookmark_ids = {row[0] for row in pg_cur.fetchall()}

bookmark_count = 0
for bookmark in user_bookmarks:
    if bookmark['id'] in existing_bookmark_ids:
        continue
    
    new_id = str(uuid.uuid4())
    user_uuid = get_uuid_from_legacy_id(pg_cur, 'users', bookmark['user_id'])
    post_uuid = get_uuid_from_legacy_id(pg_cur, 'feed_posts', bookmark['post_id'])
    
    try:
        pg_cur.execute("""
            INSERT INTO user_bookmarks (id, legacy_id, user_id, post_id, created_at)
            VALUES (%s, %s, %s, %s, %s)
            ON CONFLICT (legacy_id) DO NOTHING
        """, (
            new_id, bookmark['id'], user_uuid, post_uuid, bookmark['created_at']
        ))
        if pg_cur.rowcount > 0:
            bookmark_count += 1
    except Exception as e:
        print(f"   ⚠️  Error migrating user_bookmark {bookmark['id']}: {e}")

pg_conn.commit()
print(f"   ✅ Migrated {bookmark_count} user bookmarks")

# Final summary
print("\n" + "=" * 50)
print("✅ Migration Complete!")
print("=" * 50)
print(f"Products: {product_count} migrated")
print(f"Feed Posts: {post_count} migrated")
print(f"Feed Comments: {comment_count} migrated")
print(f"Feed Interactions: {interaction_count} migrated")
print(f"User Bookmarks: {bookmark_count} migrated")

# Close connections
mysql_cur.close()
mysql_conn.close()
pg_cur.close()
pg_conn.close()

print("\n✅ All connections closed")
