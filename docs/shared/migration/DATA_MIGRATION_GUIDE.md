# Data Migration Guide: MySQL → PostgreSQL

**Status:** Ready to Execute  
**Date:** 2026-01-04

## Overview

This guide explains how to migrate all data from Gemura v1 (PHP/MySQL) to v2 (NestJS/PostgreSQL).

## Current Status

- ✅ **Schema Migration**: Complete (all 25 tables)
- ✅ **API Endpoints**: Implemented
- ⏳ **Data Migration**: Ready to execute
- ⏳ **Validation**: Pending

## What Will Be Migrated

### Core Data (25 Tables)
1. Accounts (tenant/branch accounts)
2. Users (with preserved tokens)
3. User-Account relationships
4. Supplier-Customer relationships
5. Milk Sales (collections)
6. Products & Categories
7. Orders & Order Items
8. Wallets
9. Notifications
10. Feed (posts, stories, comments, interactions)
11. User relationships & bookmarks
12. API keys
13. Password resets
14. Onboarding, points, referrals, rewards

### Key Data Preserved
- ✅ **Authentication tokens** - Users can continue using existing tokens
- ✅ **All relationships** - Foreign keys properly mapped
- ✅ **Timestamps** - Created/updated dates preserved
- ✅ **Legacy IDs** - Old numeric IDs stored for reference

## Migration Process

### Step 1: Prepare

1. **Backup MySQL Database**
   ```bash
   mysqldump -u root -p gemura > gemura_backup_$(date +%Y%m%d).sql
   ```

2. **Backup PostgreSQL Database**
   ```bash
   pg_dump -h devslab-postgres -U devslab_admin gemura_db > gemura_db_backup_$(date +%Y%m%d).sql
   ```

3. **Set Environment Variables**
   ```bash
   export MYSQL_HOST="your_mysql_host"
   export MYSQL_PORT="3306"
   export MYSQL_DB="gemura"
   export MYSQL_USER="root"
   export MYSQL_PASS="your_password"
   
   export PG_HOST="devslab-postgres"
   export PG_PORT="5432"
   export PG_DB="gemura_db"
   export PG_USER="devslab_admin"
   export PG_PASS="devslab_secure_password_2024"
   ```

### Step 2: Run Migration

```bash
cd /path/to/gemura2
./scripts/migration/migrate-data.sh
```

### Step 3: Validate

The script will:
- Show row counts for each table
- Compare MySQL vs PostgreSQL totals
- Report any discrepancies

### Step 4: Verify

1. **Check Critical Data**
   ```sql
   -- PostgreSQL
   SELECT COUNT(*) FROM users;
   SELECT COUNT(*) FROM accounts;
   SELECT COUNT(*) FROM milk_sales;
   ```

2. **Test Authentication**
   - Try logging in with existing credentials
   - Verify tokens still work

3. **Test API Endpoints**
   - Test collections endpoint
   - Test sales endpoint
   - Test suppliers endpoint

## Migration Scripts

### Main Script
- `scripts/migration/migrate-data.sh` - Orchestrates full migration

### Table Scripts
- `scripts/migration/tables/migrate-accounts.sh`
- `scripts/migration/tables/migrate-users.sh`
- `scripts/migration/tables/migrate-milk-sales.sh`
- ... (one per table)

## ID Mapping

**Old System (MySQL):**
- Uses numeric IDs (INT, BIGINT)
- Foreign keys reference numeric IDs

**New System (PostgreSQL):**
- Uses UUIDs (primary keys)
- Stores old IDs in `legacy_id` field
- Foreign keys reference UUIDs

**Migration Process:**
1. Export data with old numeric IDs
2. Generate new UUIDs for each record
3. Store old ID in `legacy_id` field
4. Map foreign keys to new UUIDs
5. Insert into PostgreSQL

## Safety Features

✅ **Idempotent**: Can run multiple times safely  
✅ **Conflict Handling**: Uses `ON CONFLICT DO NOTHING`  
✅ **Validation**: Compares row counts  
✅ **Preserves Data**: No data loss  
✅ **Rollback Ready**: Backups created first  

## Expected Results

After successful migration:

- **All users** can log in with existing credentials
- **All accounts** accessible
- **All collections/sales** visible
- **All relationships** maintained
- **All tokens** still valid

## Troubleshooting

### Issue: Foreign Key Errors
**Solution**: Ensure parent tables migrated first. Check migration order.

### Issue: Missing Data
**Solution**: Check MySQL connection. Verify table names match.

### Issue: Token Authentication Fails
**Solution**: Verify users table migration. Check token field preserved.

### Issue: Row Count Mismatch
**Solution**: Check for NULL values, data type issues, or constraint violations.

## Post-Migration Checklist

- [ ] Verify user count matches
- [ ] Test login with existing credentials
- [ ] Verify collections/sales data
- [ ] Check supplier-customer relationships
- [ ] Test API endpoints with real data
- [ ] Monitor for errors
- [ ] Update mobile app configuration

## Rollback Plan

If migration fails:

1. **Restore PostgreSQL from backup**
   ```bash
   psql -h devslab-postgres -U devslab_admin -d gemura_db < backup.sql
   ```

2. **Investigate issues**
   - Check migration logs
   - Verify MySQL data integrity
   - Fix script issues

3. **Re-run migration**
   - Fix identified issues
   - Re-run migration script

---

**Ready to migrate? Run the script and monitor the output!**

