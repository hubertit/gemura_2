-- ============================================
-- Cleanup Duplicate Gahengeri Accounts
-- ============================================
-- This script safely removes duplicate "gahengeri" accounts
-- by migrating data to the correct account (A_33FDF4) and
-- soft-deleting the duplicates (setting status to 'inactive')
--
-- Accounts to remove:
--   - ACC_GAHENGERI (4cc65adf-8aed-4ec4-9a02-d65b083ca8c9) - 0 collections, 1 sale
--   - A_A9ABB8 (49c408e7-ddc2-4d78-838a-7c566f8d714f) - 0 data
--
-- Account to keep:
--   - A_33FDF4 (d0fd05c3-868f-42df-b0a9-f51257cba91c) - "Gahengeri" with all data
-- ============================================

BEGIN;

-- Step 1: Update any users that have these accounts as default_account_id
-- Set them to the correct account (A_33FDF4)
UPDATE users 
SET default_account_id = 'd0fd05c3-868f-42df-b0a9-f51257cba91c'
WHERE default_account_id IN ('4cc65adf-8aed-4ec4-9a02-d65b083ca8c9', '49c408e7-ddc2-4d78-838a-7c566f8d714f');

-- Step 2: Migrate the 1 milk sale from ACC_GAHENGERI to A_33FDF4
UPDATE milk_sales 
SET 
  supplier_account_id = CASE 
    WHEN supplier_account_id = '4cc65adf-8aed-4ec4-9a02-d65b083ca8c9' 
    THEN 'd0fd05c3-868f-42df-b0a9-f51257cba91c' 
    ELSE supplier_account_id 
  END,
  customer_account_id = CASE 
    WHEN customer_account_id = '4cc65adf-8aed-4ec4-9a02-d65b083ca8c9' 
    THEN 'd0fd05c3-868f-42df-b0a9-f51257cba91c' 
    ELSE customer_account_id 
  END
WHERE supplier_account_id = '4cc65adf-8aed-4ec4-9a02-d65b083ca8c9' 
   OR customer_account_id = '4cc65adf-8aed-4ec4-9a02-d65b083ca8c9';

-- Step 3: Migrate any supplier-customer relationships
UPDATE suppliers_customers
SET supplier_account_id = 'd0fd05c3-868f-42df-b0a9-f51257cba91c'
WHERE supplier_account_id IN ('4cc65adf-8aed-4ec4-9a02-d65b083ca8c9', '49c408e7-ddc2-4d78-838a-7c566f8d714f');

UPDATE suppliers_customers
SET customer_account_id = 'd0fd05c3-868f-42df-b0a9-f51257cba91c'
WHERE customer_account_id IN ('4cc65adf-8aed-4ec4-9a02-d65b083ca8c9', '49c408e7-ddc2-4d78-838a-7c566f8d714f');

-- Step 4: Migrate any wallets (if any exist)
UPDATE wallets
SET account_id = 'd0fd05c3-868f-42df-b0a9-f51257cba91c'
WHERE account_id IN ('4cc65adf-8aed-4ec4-9a02-d65b083ca8c9', '49c408e7-ddc2-4d78-838a-7c566f8d714f');

-- Step 5: Migrate any orders (if any exist)
UPDATE orders
SET account_id = 'd0fd05c3-868f-42df-b0a9-f51257cba91c'
WHERE account_id IN ('4cc65adf-8aed-4ec4-9a02-d65b083ca8c9', '49c408e7-ddc2-4d78-838a-7c566f8d714f');

-- Step 6: Migrate any products (if any exist)
UPDATE products
SET account_id = 'd0fd05c3-868f-42df-b0a9-f51257cba91c'
WHERE account_id IN ('4cc65adf-8aed-4ec4-9a02-d65b083ca8c9', '49c408e7-ddc2-4d78-838a-7c566f8d714f');

-- Step 7: Migrate any payroll suppliers (if any exist)
UPDATE payroll_suppliers
SET supplier_account_id = 'd0fd05c3-868f-42df-b0a9-f51257cba91c'
WHERE supplier_account_id IN ('4cc65adf-8aed-4ec4-9a02-d65b083ca8c9', '49c408e7-ddc2-4d78-838a-7c566f8d714f');

-- Step 8: Migrate any payroll payslips (if any exist)
UPDATE payroll_payslips
SET supplier_account_id = 'd0fd05c3-868f-42df-b0a9-f51257cba91c'
WHERE supplier_account_id IN ('4cc65adf-8aed-4ec4-9a02-d65b083ca8c9', '49c408e7-ddc2-4d78-838a-7c566f8d714f');

-- Step 9: Migrate any inventory sales (if any exist)
UPDATE inventory_sales
SET buyer_account_id = 'd0fd05c3-868f-42df-b0a9-f51257cba91c'
WHERE buyer_account_id IN ('4cc65adf-8aed-4ec4-9a02-d65b083ca8c9', '49c408e7-ddc2-4d78-838a-7c566f8d714f');

-- Step 10: Delete user_accounts links (these are just relationships, safe to hard delete)
DELETE FROM user_accounts 
WHERE account_id IN ('4cc65adf-8aed-4ec4-9a02-d65b083ca8c9', '49c408e7-ddc2-4d78-838a-7c566f8d714f');

-- Step 11: Soft delete the duplicate accounts (set status to 'inactive')
UPDATE accounts 
SET status = 'inactive', 
    updated_at = NOW()
WHERE id IN ('4cc65adf-8aed-4ec4-9a02-d65b083ca8c9', '49c408e7-ddc2-4d78-838a-7c566f8d714f');

COMMIT;

-- Verification queries (run after transaction)
-- SELECT id, code, name, status FROM accounts WHERE LOWER(name) LIKE '%gahengeri%' ORDER BY name, code;
-- SELECT COUNT(*) FROM milk_sales WHERE supplier_account_id = 'd0fd05c3-868f-42df-b0a9-f51257cba91c' OR customer_account_id = 'd0fd05c3-868f-42df-b0a9-f51257cba91c';
