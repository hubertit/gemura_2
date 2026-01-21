# Instructions: Sync Remote Database with Local Changes

**Date**: January 20, 2026

---

## 🎯 **OBJECTIVE**

Ensure the remote database (production at 159.198.65.38) has all the schema changes that were applied to the local database during development.

---

## 📋 **WHAT NEEDS TO BE SYNCED**

Based on local migration status, the following migrations need to be applied to remote:

1. ✅ `20250120000000_add_inventory_sales` - Creates inventory_sales table
2. ✅ `20260119_add_inventory_fields_to_product` - Adds inventory fields to products
3. ✅ `20260119201154_add_milk_rejection_reasons` - Creates milk_rejection_reasons table
4. ✅ `20260119202434_remove_unused_accounting_tables` - Removes unused tables
5. ✅ `20260119_add_payroll_payment_fields` - Adds payment fields to payroll
6. ✅ `20260119_fix_payroll_employee_id` - Fixes payroll employee ID

---

## 🚀 **QUICK SYNC (Recommended)**

### On the Server (SSH into 159.198.65.38)

Run this single command:

```bash
cd /opt/gemura/backend && \
export DATABASE_URL="postgresql://devslab_admin:devslab_secure_password_2024@devslab-postgres:5432/gemura_db" && \
npx prisma migrate deploy && \
npx prisma migrate status
```

This will:
- ✅ Apply all pending migrations
- ✅ Show final migration status
- ✅ Update the database schema

---

## 📝 **DETAILED STEPS**

### Step 1: SSH into Server

```bash
ssh root@159.198.65.38
# Password: QF87VtuYReX5v9p6e3
```

### Step 2: Navigate to Backend Directory

```bash
cd /opt/gemura/backend
```

### Step 3: Set Database URL

```bash
export DATABASE_URL="postgresql://devslab_admin:devslab_secure_password_2024@devslab-postgres:5432/gemura_db"
```

### Step 4: Check Current Status

```bash
npx prisma migrate status
```

This shows which migrations are pending.

### Step 5: Apply Migrations

```bash
npx prisma migrate deploy
```

This applies all pending migrations safely (doesn't create new ones).

### Step 6: Verify

```bash
# Check migration status
npx prisma migrate status

# Verify key tables exist
docker exec -i devslab-postgres psql -U devslab_admin -d gemura_db << 'SQL'
SELECT table_name 
FROM information_schema.tables 
WHERE table_schema = 'public' 
  AND table_name IN ('inventory_sales', 'milk_rejection_reasons', 'products')
ORDER BY table_name;
SQL
```

---

## 🔧 **USING THE SYNC SCRIPT**

If the sync script is available on the server:

```bash
cd /opt/gemura
./scripts/migration/sync-remote-db.sh
```

This script will:
1. Check migration status
2. Apply missing migrations
3. Verify key tables
4. Check schema structure

---

## ✅ **VERIFICATION CHECKLIST**

After syncing, verify:

- [ ] All migrations show as "applied" in `npx prisma migrate status`
- [ ] `inventory_sales` table exists
- [ ] `milk_rejection_reasons` table exists
- [ ] `products` table has inventory fields
- [ ] Payroll tables have payment fields
- [ ] No migration errors in output

### Quick Verification Commands

```bash
# Check inventory_sales table
docker exec -i devslab-postgres psql -U devslab_admin -d gemura_db -c "\d inventory_sales"

# Check enum types
docker exec -i devslab-postgres psql -U devslab_admin -d gemura_db -c "SELECT t.typname FROM pg_type t JOIN pg_enum e ON t.oid = e.enumtypid WHERE t.typname LIKE 'Inventory%';"

# Check products table structure
docker exec -i devslab-postgres psql -U devslab_admin -d gemura_db -c "\d products" | grep -i inventory
```

---

## 🚨 **TROUBLESHOOTING**

### Issue: "Migration already applied" but table doesn't exist

**Solution**: Manually create the table using the migration SQL file:

```bash
cd /opt/gemura/backend
docker exec -i devslab-postgres psql -U devslab_admin -d gemura_db < prisma/migrations/20250120000000_add_inventory_sales/migration.sql
```

### Issue: Connection timeout

**Solution**: Check if the postgres container is running:

```bash
docker ps | grep devslab-postgres
```

### Issue: Permission denied

**Solution**: Ensure you're using the correct database user:

```bash
export DATABASE_URL="postgresql://devslab_admin:devslab_secure_password_2024@devslab-postgres:5432/gemura_db"
```

---

## 📊 **EXPECTED RESULTS**

After successful sync:

1. ✅ All 6 pending migrations will be applied
2. ✅ `inventory_sales` table will exist with proper structure
3. ✅ `InventorySaleBuyerType` and `InventorySalePaymentStatus` enums will exist
4. ✅ `products` table will have inventory-related fields
5. ✅ `milk_rejection_reasons` table will exist
6. ✅ Payroll tables will have payment fields
7. ✅ `npx prisma migrate status` will show "All migrations have been applied"

---

## 🔗 **RELATED DOCUMENTATION**

- [Remote DB Sync Guide](./REMOTE_DB_SYNC.md) - Detailed sync procedures
- [Migration Scripts](../scripts/migration/README.md) - Migration scripts
- [Deployment Guide](../deployment/DEPLOYMENT_GUIDE.md) - Deployment procedures

---

## 📝 **NOTES**

- The `prisma migrate deploy` command is safe for production (doesn't create new migrations)
- All migrations are idempotent (can be run multiple times safely)
- The database connection uses Docker container networking (`devslab-postgres`)
- Migrations are tracked in the `_prisma_migrations` table

---

**Last Updated**: January 20, 2026
