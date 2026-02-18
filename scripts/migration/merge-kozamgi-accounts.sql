-- ============================================
-- Merge KOZAMGI accounts into KOPERATIVE KOZAMGI
-- ============================================
-- 1. Merge KOZAMGI (A_98EC4C) into KOPERATIVE KOZAMGI (A_16C846)
--    Keep name "KOPERATIVE KOZAMGI" on A_16C846.
--    All users with access to either account keep access to the merged account;
--    when a user had both, we keep the higher-privilege role.
-- 2. Reassign ACC_KOZAMGI's single relationship to A_16C846, then delete account ACC_KOZAMGI.
-- 3. Set merged account KOZAMGI (A_98EC4C) to inactive.
--
-- IDs:
--   A_16C846  (KOPERATIVE KOZAMGI - keep): 870e3ec0-3225-4a21-af07-7a9552a9bec3
--   A_98EC4C  (KOZAMGI - merge into above): 40804a32-e39f-4d2d-9410-a7c17c339f2c
--   ACC_KOZAMGI (delete): 1f1de0ce-4faf-4102-9886-b086c235f0d5
-- ============================================

BEGIN;

-- ---------------------------------------------------------------------------
-- PART 1: Merge A_98EC4C (KOZAMGI) into A_16C846 (KOPERATIVE KOZAMGI)
-- ---------------------------------------------------------------------------

-- 1a. user_accounts: For users who have BOTH accounts, set the kept row's role to the higher-privilege role, then remove the duplicate.
-- Role order (1=highest): owner, admin, manager, collector, supplier, customer, agent, viewer
DO $$
DECLARE
  r RECORD;
  best_role text;
  rank_98 int;
  rank_846 int;
BEGIN
  FOR r IN
    SELECT u98.user_id, u98.role AS role_98, u846.role AS role_846
    FROM user_accounts u98
    JOIN user_accounts u846 ON u846.user_id = u98.user_id AND u846.account_id = '870e3ec0-3225-4a21-af07-7a9552a9bec3'
    WHERE u98.account_id = '40804a32-e39f-4d2d-9410-a7c17c339f2c'
  LOOP
    rank_98  := CASE r.role_98  WHEN 'owner' THEN 1 WHEN 'admin' THEN 2 WHEN 'manager' THEN 3 WHEN 'collector' THEN 4 WHEN 'supplier' THEN 5 WHEN 'customer' THEN 6 WHEN 'agent' THEN 7 WHEN 'viewer' THEN 8 ELSE 9 END;
    rank_846 := CASE r.role_846 WHEN 'owner' THEN 1 WHEN 'admin' THEN 2 WHEN 'manager' THEN 3 WHEN 'collector' THEN 4 WHEN 'supplier' THEN 5 WHEN 'customer' THEN 6 WHEN 'agent' THEN 7 WHEN 'viewer' THEN 8 ELSE 9 END;
    best_role := CASE WHEN rank_98 <= rank_846 THEN r.role_98::text ELSE r.role_846::text END;
    UPDATE user_accounts SET role = best_role::"UserAccountRole"
    WHERE user_id = r.user_id AND account_id = '870e3ec0-3225-4a21-af07-7a9552a9bec3';
  END LOOP;
END $$;

-- 1b. Remove user_accounts for KOZAMGI where user already has KOPERATIVE (duplicate)
DELETE FROM user_accounts
WHERE account_id = '40804a32-e39f-4d2d-9410-a7c17c339f2c'
  AND EXISTS (SELECT 1 FROM user_accounts u2 WHERE u2.user_id = user_accounts.user_id AND u2.account_id = '870e3ec0-3225-4a21-af07-7a9552a9bec3');

-- 1c. Move remaining user_accounts from KOZAMGI to KOPERATIVE KOZAMGI
UPDATE user_accounts SET account_id = '870e3ec0-3225-4a21-af07-7a9552a9bec3' WHERE account_id = '40804a32-e39f-4d2d-9410-a7c17c339f2c';

-- 1d. users.default_account_id
UPDATE users SET default_account_id = '870e3ec0-3225-4a21-af07-7a9552a9bec3' WHERE default_account_id = '40804a32-e39f-4d2d-9410-a7c17c339f2c';

-- 1e. suppliers_customers: remove rows that would become duplicate (same pair with target account), then update
DELETE FROM suppliers_customers sc
WHERE sc.supplier_account_id = '40804a32-e39f-4d2d-9410-a7c17c339f2c'
  AND EXISTS (SELECT 1 FROM suppliers_customers s2 WHERE s2.supplier_account_id = '870e3ec0-3225-4a21-af07-7a9552a9bec3' AND s2.customer_account_id = sc.customer_account_id);
UPDATE suppliers_customers SET supplier_account_id = '870e3ec0-3225-4a21-af07-7a9552a9bec3' WHERE supplier_account_id = '40804a32-e39f-4d2d-9410-a7c17c339f2c';

DELETE FROM suppliers_customers sc
WHERE sc.customer_account_id = '40804a32-e39f-4d2d-9410-a7c17c339f2c'
  AND EXISTS (SELECT 1 FROM suppliers_customers s2 WHERE s2.supplier_account_id = sc.supplier_account_id AND s2.customer_account_id = '870e3ec0-3225-4a21-af07-7a9552a9bec3');
UPDATE suppliers_customers SET customer_account_id = '870e3ec0-3225-4a21-af07-7a9552a9bec3' WHERE customer_account_id = '40804a32-e39f-4d2d-9410-a7c17c339f2c';

-- 1f. milk_sales (collections)
UPDATE milk_sales SET supplier_account_id = '870e3ec0-3225-4a21-af07-7a9552a9bec3' WHERE supplier_account_id = '40804a32-e39f-4d2d-9410-a7c17c339f2c';
UPDATE milk_sales SET customer_account_id = '870e3ec0-3225-4a21-af07-7a9552a9bec3' WHERE customer_account_id = '40804a32-e39f-4d2d-9410-a7c17c339f2c';

-- 1g. Other tables that reference account
UPDATE products       SET account_id = '870e3ec0-3225-4a21-af07-7a9552a9bec3' WHERE account_id = '40804a32-e39f-4d2d-9410-a7c17c339f2c';
UPDATE orders         SET account_id = '870e3ec0-3225-4a21-af07-7a9552a9bec3' WHERE account_id = '40804a32-e39f-4d2d-9410-a7c17c339f2c';
UPDATE wallets        SET account_id = '870e3ec0-3225-4a21-af07-7a9552a9bec3' WHERE account_id = '40804a32-e39f-4d2d-9410-a7c17c339f2c';
UPDATE payroll_suppliers SET supplier_account_id = '870e3ec0-3225-4a21-af07-7a9552a9bec3' WHERE supplier_account_id = '40804a32-e39f-4d2d-9410-a7c17c339f2c';
UPDATE payroll_payslips  SET supplier_account_id = '870e3ec0-3225-4a21-af07-7a9552a9bec3' WHERE supplier_account_id = '40804a32-e39f-4d2d-9410-a7c17c339f2c';
UPDATE charges        SET customer_account_id = '870e3ec0-3225-4a21-af07-7a9552a9bec3' WHERE customer_account_id = '40804a32-e39f-4d2d-9410-a7c17c339f2c';
UPDATE charge_suppliers SET supplier_account_id = '870e3ec0-3225-4a21-af07-7a9552a9bec3' WHERE supplier_account_id = '40804a32-e39f-4d2d-9410-a7c17c339f2c';
UPDATE charge_applications SET supplier_account_id = '870e3ec0-3225-4a21-af07-7a9552a9bec3' WHERE supplier_account_id = '40804a32-e39f-4d2d-9410-a7c17c339f2c';
UPDATE inventory_sales SET buyer_account_id = '870e3ec0-3225-4a21-af07-7a9552a9bec3' WHERE buyer_account_id = '40804a32-e39f-4d2d-9410-a7c17c339f2c';
UPDATE loans          SET lender_account_id = '870e3ec0-3225-4a21-af07-7a9552a9bec3' WHERE lender_account_id = '40804a32-e39f-4d2d-9410-a7c17c339f2c';
UPDATE loans          SET borrower_account_id = '870e3ec0-3225-4a21-af07-7a9552a9bec3' WHERE borrower_account_id = '40804a32-e39f-4d2d-9410-a7c17c339f2c';

-- 1h. Deactivate merged account KOZAMGI (A_98EC4C)
UPDATE accounts SET status = 'inactive', updated_at = NOW() WHERE id = '40804a32-e39f-4d2d-9410-a7c17c339f2c';

-- ---------------------------------------------------------------------------
-- PART 2: Reassign ACC_KOZAMGI data to A_16C846, then delete ACC_KOZAMGI
-- ---------------------------------------------------------------------------

-- 2a. suppliers_customers: ACC_KOZAMGI is customer in 1 row. Reassign to A_16C846; if (supplier, A_16C846) already exists, delete this row.
DELETE FROM suppliers_customers sc
WHERE sc.customer_account_id = '1f1de0ce-4faf-4102-9886-b086c235f0d5'
  AND EXISTS (SELECT 1 FROM suppliers_customers s2 WHERE s2.supplier_account_id = sc.supplier_account_id AND s2.customer_account_id = '870e3ec0-3225-4a21-af07-7a9552a9bec3');
UPDATE suppliers_customers SET customer_account_id = '870e3ec0-3225-4a21-af07-7a9552a9bec3' WHERE customer_account_id = '1f1de0ce-4faf-4102-9886-b086c235f0d5';

-- 2b. Any other references to ACC_KOZAMGI (user_accounts, users.default_account_id, etc.) then delete account
UPDATE users SET default_account_id = NULL WHERE default_account_id = '1f1de0ce-4faf-4102-9886-b086c235f0d5';
DELETE FROM user_accounts WHERE account_id = '1f1de0ce-4faf-4102-9886-b086c235f0d5';

-- 2c. Delete account ACC_KOZAMGI (no FKs left on accounts table for this id)
DELETE FROM accounts WHERE id = '1f1de0ce-4faf-4102-9886-b086c235f0d5';

COMMIT;

-- Verification (run manually after):
-- SELECT id, code, name, status FROM accounts WHERE name ILIKE '%kozamgi%' OR code ILIKE '%kozamgi%' ORDER BY status, name;
-- SELECT COUNT(*) FROM user_accounts WHERE account_id = '870e3ec0-3225-4a21-af07-7a9552a9bec3';
