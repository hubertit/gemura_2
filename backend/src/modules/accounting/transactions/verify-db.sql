-- Verify Database Tables for Transactions API
-- Run these queries to verify the database is ready

-- 1. Check if accounting_transactions table exists
SELECT 
    table_name, 
    column_name, 
    data_type,
    is_nullable
FROM information_schema.columns
WHERE table_schema = 'public' 
  AND table_name = 'accounting_transactions'
ORDER BY ordinal_position;

-- 2. Check if accounting_transaction_entries table exists
SELECT 
    table_name, 
    column_name, 
    data_type,
    is_nullable
FROM information_schema.columns
WHERE table_schema = 'public' 
  AND table_name = 'accounting_transaction_entries'
ORDER BY ordinal_position;

-- 3. Check if chart_of_accounts table exists
SELECT 
    table_name, 
    column_name, 
    data_type,
    is_nullable
FROM information_schema.columns
WHERE table_schema = 'public' 
  AND table_name = 'chart_of_accounts'
ORDER BY ordinal_position;

-- 4. Check foreign key constraints
SELECT
    tc.table_name, 
    kcu.column_name, 
    ccu.table_name AS foreign_table_name,
    ccu.column_name AS foreign_column_name 
FROM information_schema.table_constraints AS tc 
JOIN information_schema.key_column_usage AS kcu
  ON tc.constraint_name = kcu.constraint_name
JOIN information_schema.constraint_column_usage AS ccu
  ON ccu.constraint_name = tc.constraint_name
WHERE tc.constraint_type = 'FOREIGN KEY' 
  AND (tc.table_name = 'accounting_transactions' 
       OR tc.table_name = 'accounting_transaction_entries');

-- 5. Check indexes
SELECT
    tablename,
    indexname,
    indexdef
FROM pg_indexes
WHERE schemaname = 'public'
  AND (tablename = 'accounting_transactions' 
       OR tablename = 'accounting_transaction_entries'
       OR tablename = 'chart_of_accounts')
ORDER BY tablename, indexname;

-- 6. Sample query to check if data can be inserted (dry run)
-- This will show the structure without inserting
SELECT 
    'accounting_transactions' as table_name,
    COUNT(*) as current_count
FROM accounting_transactions
UNION ALL
SELECT 
    'accounting_transaction_entries' as table_name,
    COUNT(*) as current_count
FROM accounting_transaction_entries
UNION ALL
SELECT 
    'chart_of_accounts' as table_name,
    COUNT(*) as current_count
FROM chart_of_accounts;

-- 7. Verify users table has default_account_id column
SELECT 
    column_name,
    data_type,
    is_nullable
FROM information_schema.columns
WHERE table_schema = 'public' 
  AND table_name = 'users'
  AND column_name = 'default_account_id';
