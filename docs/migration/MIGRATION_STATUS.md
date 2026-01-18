# Migration Status - Accounts & Users

**Date:** 2026-01-18  
**Status:** ⚠️ Partial - Missing Users

## Current Status

### PostgreSQL Database
- **Accounts:** 413 total (403 with legacy_id)
- **Users:** 356 total (349 with legacy_id)  
- **User Accounts:** 297 total (287 with legacy_id)

### SQL Dump Reference
- **Accounts:** ~200 records
- **Users:** ~602 records
- **User Accounts:** ~200 records

## Issue Identified

**Missing Users:** Approximately **246 users** need to be migrated from MySQL to PostgreSQL.

- Current: 356 users in PostgreSQL
- Expected: ~602 users (from SQL dump)
- Missing: ~246 users

## Migration Scripts Available

### 1. Bash Migration Scripts
- `scripts/migration/tables/migrate-accounts.sh` ✅
- `scripts/migration/tables/migrate-users.sh` ✅  
- `scripts/migration/tables/migrate-user-accounts.sh` ✅ (fixed with created_by/updated_by)

### 2. TypeScript Migration Service
- `backend/src/migration/migration.service.ts` ✅
- Run with: `npm run migrate`

### 3. Server Migration Scripts
- `scripts/migration/run-accounts-users-migration.sh` - Runs on server
- `scripts/migration/run-typescript-migration.sh` - Uses NestJS service

## Problem

**MySQL Database Access:** Cannot connect to MySQL database from server using credentials:
- User: `devsvknl_admin`
- Password: `]LdUd=a6{-vq`
- Database: `devsvknl_gemura`

**Error:** `ERROR 1045 (28000): Access denied for user 'devsvknl_admin'@'localhost'`

## Solutions

### Option 1: Fix MySQL Credentials
1. Verify MySQL credentials on server
2. Update migration scripts with correct credentials
3. Run migration scripts

### Option 2: Use SQL Dump Directly
1. Process SQL dump file to extract missing users
2. Convert MySQL INSERT statements to PostgreSQL format
3. Map legacy IDs to UUIDs
4. Insert missing records

### Option 3: Manual Migration
1. Export missing users from MySQL manually
2. Import using migration scripts
3. Verify all records migrated

## Next Steps

1. **Verify MySQL Access:**
   ```bash
   ssh root@159.198.65.38
   mysql -u devsvknl_admin -p devsvknl_gemura
   # Enter password when prompted
   ```

2. **Run Migration:**
   ```bash
   ./scripts/migration/run-accounts-users-migration.sh
   ```

3. **Verify Results:**
   ```bash
   docker exec -i devslab-postgres psql -U devslab_admin -d gemura_db -c "
   SELECT COUNT(*) FROM users;
   SELECT COUNT(*) FROM accounts;
   SELECT COUNT(*) FROM user_accounts;
   "
   ```

## Migration Scripts Fixed

✅ **user_accounts migration** - Now includes `created_by` and `updated_by` fields  
✅ **feed_posts migration** - Script created and ready  
✅ **feed_comments migration** - Script created  
✅ **feed_interactions migration** - Script created  
✅ **user_bookmarks migration** - Script created

All scripts are idempotent and safe to re-run.
