# Migration Fixes - Account Assignments & Feed Posts

**Date:** 2026-01-18  
**Status:** ✅ Fixed and Ready

## Issues Identified

### 1. User Accounts Migration Missing Fields
**Problem:** The `migrate-user-accounts.sh` script was not migrating `created_by` and `updated_by` fields, causing incomplete account assignment data.

**Fix:**
- Added `created_by` and `updated_by` to the MySQL SELECT query
- Added UUID mapping for both fields (maps legacy user IDs to new UUIDs)
- Updated INSERT statement to include both fields

### 2. Feed Posts Migration Missing
**Problem:** No migration script existed for `feed_posts` table, so all feed posts were not being migrated.

**Fix:**
- Created `migrate-feed-posts.sh` script
- Migrates all feed post data including:
  - Content, media_url, hashtags, location
  - Likes, shares, bookmarks counts
  - Status and timestamps
  - User relationships (user_id, created_by, updated_by)

### 3. Additional Feed Migration Scripts Created
Created complete feed migration suite:
- ✅ `migrate-feed-posts.sh` - Main feed posts
- ✅ `migrate-feed-comments.sh` - Post comments with parent support
- ✅ `migrate-feed-interactions.sh` - Likes, shares, interactions
- ✅ `migrate-user-bookmarks.sh` - Bookmarked posts

## Migration Scripts Updated

### `scripts/migration/tables/migrate-user-accounts.sh`
**Changes:**
- Now includes `created_by` and `updated_by` fields
- Maps legacy user IDs to new UUIDs for audit fields
- Ensures all account assignments are complete

### `scripts/migration/tables/migrate-feed-posts.sh` (NEW)
**Features:**
- Migrates all feed post data
- Maps user_id, created_by, updated_by to UUIDs
- Handles NULL values for optional fields
- Preserves hashtags (JSON or comma-separated)
- Preserves all metadata (likes, shares, bookmarks counts)

## How to Run Migrations

### Option 1: Run Full Migration
```bash
cd /path/to/gemura2
./scripts/migration/migrate-data.sh
```

This will migrate all tables including:
- User accounts (with created_by/updated_by)
- Feed posts
- Feed comments
- Feed interactions
- User bookmarks

### Option 2: Run Individual Migrations
```bash
# Migrate user accounts only
./scripts/migration/tables/migrate-user-accounts.sh \
  mysql_host mysql_port mysql_db mysql_user mysql_pass \
  pg_host pg_port pg_db pg_user pg_pass

# Migrate feed posts only
./scripts/migration/tables/migrate-feed-posts.sh \
  mysql_host mysql_port mysql_db mysql_user mysql_pass \
  pg_host pg_port pg_db pg_user pg_pass
```

## Verification

After running migrations, verify data:

```sql
-- Check user_accounts count
SELECT COUNT(*) FROM user_accounts;

-- Check feed_posts count
SELECT COUNT(*) FROM feed_posts;

-- Verify account assignments have created_by
SELECT COUNT(*) FROM user_accounts WHERE created_by IS NOT NULL;

-- Verify feed posts have user relationships
SELECT COUNT(*) FROM feed_posts WHERE user_id IS NOT NULL;
```

## Migration Order

When running migrations, ensure this order:
1. `accounts` - Base accounts
2. `users` - Users (needed for foreign keys)
3. `user_accounts` - User-account relationships (depends on users & accounts)
4. `feed_posts` - Feed posts (depends on users)
5. `feed_comments` - Comments (depends on feed_posts & users)
6. `feed_interactions` - Interactions (depends on feed_posts & users)
7. `user_bookmarks` - Bookmarks (depends on feed_posts & users)

## Notes

- All scripts are **idempotent** - safe to re-run (uses `ON CONFLICT (legacy_id) DO NOTHING`)
- UUIDs are automatically generated for new records
- Legacy IDs are preserved in `legacy_id` field for reference
- All foreign key relationships are properly mapped
