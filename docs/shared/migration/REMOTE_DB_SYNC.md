# Remote Database Synchronization Guide

**Last Updated**: January 20, 2026

---

## 📋 **OVERVIEW**

This guide explains how to ensure the remote database (production) has all the schema changes that were applied to the local database during development.

---

## 🔍 **CHECKING MIGRATION STATUS**

### On the Server

SSH into the server and run:

```bash
cd /opt/gemura/backend
export DATABASE_URL="postgresql://devslab_admin:devslab_secure_password_2024@devslab-postgres:5432/gemura_db"
npx prisma migrate status
```

This will show:
- ✅ Which migrations have been applied
- ⚠️ Which migrations are pending
- ❌ Any migration conflicts

### Check Specific Tables

```bash
# Check if inventory_sales table exists
docker exec -i devslab-postgres psql -U devslab_admin -d gemura_db -c "\d inventory_sales"

# Check all tables
docker exec -i devslab-postgres psql -U devslab_admin -d gemura_db -c "\dt"
```

---

## 🔄 **APPLYING MIGRATIONS**

### Option 1: Using Prisma Migrate Deploy (Recommended)

On the server:

```bash
cd /opt/gemura/backend
export DATABASE_URL="postgresql://devslab_admin:devslab_secure_password_2024@devslab-postgres:5432/gemura_db"
npx prisma migrate deploy
```

This will:
- ✅ Apply all pending migrations
- ✅ Update the `_prisma_migrations` table
- ✅ Not create new migrations (safe for production)

### Option 2: Using Sync Script

Run the sync script on the server:

```bash
cd /opt/gemura
./scripts/migration/sync-remote-db.sh
```

This script will:
1. Check current migration status
2. Apply missing migrations
3. Verify key tables exist
4. Check schema structure

### Option 3: Manual Migration Application

If a specific migration needs to be applied manually:

```bash
# On the server
cd /opt/gemura/backend
docker exec -i devslab-postgres psql -U devslab_admin -d gemura_db < prisma/migrations/20250120000000_add_inventory_sales/migration.sql
```

---

## 📊 **VERIFICATION**

After applying migrations, verify:

### 1. Check Migration Status

```bash
npx prisma migrate status
```

Should show: "All migrations have been applied"

### 2. Verify Key Tables

```bash
docker exec -i devslab-postgres psql -U devslab_admin -d gemura_db << 'SQL'
SELECT table_name 
FROM information_schema.tables 
WHERE table_schema = 'public' 
  AND table_name IN (
    'inventory_sales',
    'milk_rejection_reasons',
    'payroll_payslips',
    'payroll_suppliers',
    'products'
  )
ORDER BY table_name;
SQL
```

### 3. Check Table Structure

```bash
# Check inventory_sales structure
docker exec -i devslab-postgres psql -U devslab_admin -d gemura_db -c "\d inventory_sales"

# Check enum types
docker exec -i devslab-postgres psql -U devslab_admin -d gemura_db << 'SQL'
SELECT t.typname, string_agg(e.enumlabel, ', ' ORDER BY e.enumsortorder) as values
FROM pg_type t 
JOIN pg_enum e ON t.oid = e.enumtypid  
WHERE t.typname IN ('InventorySaleBuyerType', 'InventorySalePaymentStatus')
GROUP BY t.typname;
SQL
```

---

## 🚨 **TROUBLESHOOTING**

### Migration Already Applied

If you see "Migration already applied" errors:

```bash
# Check _prisma_migrations table
docker exec -i devslab-postgres psql -U devslab_admin -d gemura_db -c "SELECT migration_name, finished_at FROM _prisma_migrations ORDER BY finished_at DESC;"
```

### Table Exists But Migration Not Recorded

If a table exists but Prisma thinks the migration wasn't applied:

```bash
# Manually mark migration as applied (use with caution)
docker exec -i devslab-postgres psql -U devslab_admin -d gemura_db << 'SQL'
INSERT INTO _prisma_migrations (migration_name, checksum, finished_at, started_at, applied_steps_count)
VALUES ('20250120000000_add_inventory_sales', 'checksum_here', NOW(), NOW(), 1)
ON CONFLICT DO NOTHING;
SQL
```

### Connection Issues

If you can't connect to the database:

```bash
# Check if postgres container is running
docker ps | grep devslab-postgres

# Check database connection
docker exec -i devslab-postgres psql -U devslab_admin -d gemura_db -c "SELECT version();"
```

---

## 📝 **RECENT CHANGES TO SYNC**

### January 20, 2026

The following migrations need to be applied to remote:

1. **20250120000000_add_inventory_sales**
   - Creates `inventory_sales` table
   - Creates `InventorySaleBuyerType` enum
   - Creates `InventorySalePaymentStatus` enum

2. **20260119_add_inventory_fields_to_product**
   - Adds inventory fields to `products` table

3. **20260119201154_add_milk_rejection_reasons**
   - Creates `milk_rejection_reasons` table

4. **20260119202434_remove_unused_accounting_tables**
   - Removes unused accounting tables

5. **20260119_add_payroll_payment_fields**
   - Adds payment fields to payroll tables

---

## ✅ **QUICK SYNC COMMAND**

Run this on the server to sync everything:

```bash
cd /opt/gemura/backend && \
export DATABASE_URL="postgresql://devslab_admin:devslab_secure_password_2024@devslab-postgres:5432/gemura_db" && \
npx prisma migrate deploy && \
npx prisma migrate status
```

---

## 🔗 **RELATED DOCUMENTATION**

- [Migration Scripts](../scripts/migration/README.md)
- [Deployment Guide](../deployment/DEPLOYMENT_GUIDE.md)
- [Prisma Migrations](https://www.prisma.io/docs/concepts/components/prisma-migrate)

---

**Last Updated**: January 20, 2026
