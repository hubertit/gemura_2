-- ============================================
-- Delete Kozamgi (A_890A1C) and Test Supplier KOZAMGI (A_46F2E2)
-- ============================================
-- Reassign any references to KOPERATIVE KOZAMGI (A_16C846), then delete the two accounts.
--
-- IDs:
--   A_16C846 (KOPERATIVE KOZAMGI - keep): 870e3ec0-3225-4a21-af07-7a9552a9bec3
--   Kozamgi (delete):                      cbf89607-291e-4f40-bae8-3c74151b6ad7  (A_890A1C)
--   Test Supplier KOZAMGI (delete):        58c4d734-08bd-4fb4-a7c8-073eb3d96612  (A_46F2E2)
-- ============================================

BEGIN;

-- Reassign or remove references for A_890A1C (Kozamgi) and A_46F2E2 (Test Supplier KOZAMGI)
-- Target: A_16C846 (KOPERATIVE KOZAMGI)

-- 1. suppliers_customers: reassign to A_16C846; remove rows that would duplicate
DELETE FROM suppliers_customers sc
WHERE sc.supplier_account_id = '58c4d734-08bd-4fb4-a7c8-073eb3d96612'
  AND EXISTS (SELECT 1 FROM suppliers_customers s2 WHERE s2.supplier_account_id = '870e3ec0-3225-4a21-af07-7a9552a9bec3' AND s2.customer_account_id = sc.customer_account_id);
UPDATE suppliers_customers SET supplier_account_id = '870e3ec0-3225-4a21-af07-7a9552a9bec3' WHERE supplier_account_id = '58c4d734-08bd-4fb4-a7c8-073eb3d96612';

DELETE FROM suppliers_customers sc
WHERE sc.customer_account_id = 'cbf89607-291e-4f40-bae8-3c74151b6ad7'
  AND EXISTS (SELECT 1 FROM suppliers_customers s2 WHERE s2.supplier_account_id = sc.supplier_account_id AND s2.customer_account_id = '870e3ec0-3225-4a21-af07-7a9552a9bec3');
UPDATE suppliers_customers SET customer_account_id = '870e3ec0-3225-4a21-af07-7a9552a9bec3' WHERE customer_account_id = 'cbf89607-291e-4f40-bae8-3c74151b6ad7';

-- 2. milk_sales
UPDATE milk_sales SET supplier_account_id = '870e3ec0-3225-4a21-af07-7a9552a9bec3' WHERE supplier_account_id IN ('58c4d734-08bd-4fb4-a7c8-073eb3d96612','cbf89607-291e-4f40-bae8-3c74151b6ad7');
UPDATE milk_sales SET customer_account_id = '870e3ec0-3225-4a21-af07-7a9552a9bec3' WHERE customer_account_id IN ('58c4d734-08bd-4fb4-a7c8-073eb3d96612','cbf89607-291e-4f40-bae8-3c74151b6ad7');

-- 3. Other tables that may reference these accounts
UPDATE users SET default_account_id = NULL WHERE default_account_id IN ('58c4d734-08bd-4fb4-a7c8-073eb3d96612','cbf89607-291e-4f40-bae8-3c74151b6ad7');
DELETE FROM user_accounts WHERE account_id IN ('58c4d734-08bd-4fb4-a7c8-073eb3d96612','cbf89607-291e-4f40-bae8-3c74151b6ad7');
UPDATE products       SET account_id = NULL WHERE account_id IN ('58c4d734-08bd-4fb4-a7c8-073eb3d96612','cbf89607-291e-4f40-bae8-3c74151b6ad7');
UPDATE orders         SET account_id = '870e3ec0-3225-4a21-af07-7a9552a9bec3' WHERE account_id IN ('58c4d734-08bd-4fb4-a7c8-073eb3d96612','cbf89607-291e-4f40-bae8-3c74151b6ad7');
UPDATE wallets        SET account_id = '870e3ec0-3225-4a21-af07-7a9552a9bec3' WHERE account_id IN ('58c4d734-08bd-4fb4-a7c8-073eb3d96612','cbf89607-291e-4f40-bae8-3c74151b6ad7');
UPDATE payroll_suppliers SET supplier_account_id = '870e3ec0-3225-4a21-af07-7a9552a9bec3' WHERE supplier_account_id IN ('58c4d734-08bd-4fb4-a7c8-073eb3d96612','cbf89607-291e-4f40-bae8-3c74151b6ad7');
UPDATE payroll_payslips  SET supplier_account_id = '870e3ec0-3225-4a21-af07-7a9552a9bec3' WHERE supplier_account_id IN ('58c4d734-08bd-4fb4-a7c8-073eb3d96612','cbf89607-291e-4f40-bae8-3c74151b6ad7');
UPDATE charges        SET customer_account_id = '870e3ec0-3225-4a21-af07-7a9552a9bec3' WHERE customer_account_id IN ('58c4d734-08bd-4fb4-a7c8-073eb3d96612','cbf89607-291e-4f40-bae8-3c74151b6ad7');
UPDATE charge_suppliers SET supplier_account_id = '870e3ec0-3225-4a21-af07-7a9552a9bec3' WHERE supplier_account_id IN ('58c4d734-08bd-4fb4-a7c8-073eb3d96612','cbf89607-291e-4f40-bae8-3c74151b6ad7');
UPDATE charge_applications SET supplier_account_id = '870e3ec0-3225-4a21-af07-7a9552a9bec3' WHERE supplier_account_id IN ('58c4d734-08bd-4fb4-a7c8-073eb3d96612','cbf89607-291e-4f40-bae8-3c74151b6ad7');
UPDATE inventory_sales SET buyer_account_id = '870e3ec0-3225-4a21-af07-7a9552a9bec3' WHERE buyer_account_id IN ('58c4d734-08bd-4fb4-a7c8-073eb3d96612','cbf89607-291e-4f40-bae8-3c74151b6ad7');
UPDATE loans          SET lender_account_id = '870e3ec0-3225-4a21-af07-7a9552a9bec3' WHERE lender_account_id IN ('58c4d734-08bd-4fb4-a7c8-073eb3d96612','cbf89607-291e-4f40-bae8-3c74151b6ad7');
UPDATE loans          SET borrower_account_id = '870e3ec0-3225-4a21-af07-7a9552a9bec3' WHERE borrower_account_id IN ('58c4d734-08bd-4fb4-a7c8-073eb3d96612','cbf89607-291e-4f40-bae8-3c74151b6ad7');

-- 4. Delete the two accounts
DELETE FROM accounts WHERE id IN ('58c4d734-08bd-4fb4-a7c8-073eb3d96612','cbf89607-291e-4f40-bae8-3c74151b6ad7');

COMMIT;

-- Verification: SELECT id, code, name, status FROM accounts WHERE name ILIKE '%kozamgi%' OR code ILIKE '%kozamgi%';
