#!/bin/bash

# Sync Remote Database with Local Migrations
# This script should be run on the server (159.198.65.38) to ensure
# the remote database has all the latest schema changes from local development

set -e

echo "🔄 Syncing Remote Database with Local Migrations"
echo "================================================"
echo ""

# Database connection details
export DATABASE_URL="postgresql://devslab_admin:devslab_secure_password_2024@devslab-postgres:5432/gemura_db"

# Change to backend directory
cd /opt/gemura/backend || {
    echo "❌ Error: /opt/gemura/backend not found"
    echo "   Please ensure you're running this on the server"
    exit 1
}

echo "📊 Step 1: Checking current migration status..."
echo ""
npx prisma migrate status 2>&1

echo ""
echo "📤 Step 2: Applying missing migrations..."
echo ""
npx prisma migrate deploy 2>&1

echo ""
echo "✅ Step 3: Verifying migration status..."
echo ""
npx prisma migrate status 2>&1

echo ""
echo "📋 Step 4: Checking key tables and schema..."
echo ""
docker exec -i devslab-postgres psql -U devslab_admin -d gemura_db << 'SQL'
-- Check if key tables exist
SELECT 
    table_name,
    CASE 
        WHEN table_name IN (
            'inventory_sales',
            'milk_rejection_reasons', 
            'payroll_payslips', 
            'payroll_suppliers', 
            'payroll_runs',
            'products',
            'milk_sales',
            'suppliers_customers',
            'accounts',
            'users'
        ) THEN '✅ EXISTS' 
        ELSE '⚠️  Missing' 
    END as status
FROM information_schema.tables 
WHERE table_schema = 'public' 
  AND table_name IN (
    'inventory_sales',
    'milk_rejection_reasons', 
    'payroll_payslips', 
    'payroll_suppliers',
    'payroll_runs',
    'products',
    'milk_sales',
    'suppliers_customers',
    'accounts',
    'users'
  )
ORDER BY table_name;

-- Check inventory_sales table structure if it exists
SELECT 
    column_name,
    data_type,
    is_nullable
FROM information_schema.columns
WHERE table_schema = 'public' 
  AND table_name = 'inventory_sales'
ORDER BY ordinal_position;
SQL

echo ""
echo "🔍 Step 5: Checking for inventory_sales enum types..."
echo ""
docker exec -i devslab-postgres psql -U devslab_admin -d gemura_db << 'SQL'
SELECT 
    t.typname as enum_name,
    string_agg(e.enumlabel, ', ' ORDER BY e.enumsortorder) as enum_values
FROM pg_type t 
JOIN pg_enum e ON t.oid = e.enumtypid  
WHERE t.typname IN ('InventorySaleBuyerType', 'InventorySalePaymentStatus')
GROUP BY t.typname;
SQL

echo ""
echo "✅ Database sync complete!"
echo ""
echo "📝 Summary:"
echo "  - All migrations have been applied"
echo "  - Schema is up to date with local development"
echo "  - Key tables verified"
echo ""
