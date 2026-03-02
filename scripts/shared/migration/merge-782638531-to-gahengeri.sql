-- ============================================
-- Merge festo (A_F37B17) and Inyange into MCC Gahengeri (A_33FDF4)
-- Same phone +250 782 638 531 stored as 250782638531, 2500782638531, 782638531
-- Target: MCC Gahengeri - keep all sales, collections, supplier/customer relationships
-- ============================================
-- Target (keep): MCC Gahengeri  d0fd05c3-868f-42df-b0a9-f51257cba91c  (A_33FDF4)
-- Source 1:      festo           e8133975-d284-4d1b-8a55-cb7de56c9c99  (A_F37B17)
-- Source 2:      Inyange         77133c4f-1872-4622-b7aa-6ca7d891ea90
-- ============================================

BEGIN;

-- Helper: merge one source account into target (Gahengeri), handling duplicates
-- We run the same steps for each source. Run for festo first, then Inyange.

-- ========== MERGE FESTO (e8133975-...) INTO GAHENGERI ==========

-- 1a. user_accounts: users who have BOTH festo and Gahengeri -> keep best role on Gahengeri, delete festo link
DO $$
DECLARE r RECORD; best_role text; rank_s int; rank_t int;
BEGIN
  FOR r IN
    SELECT u_s.user_id, u_s.role AS role_s, u_t.role AS role_t
    FROM user_accounts u_s
    JOIN user_accounts u_t ON u_t.user_id = u_s.user_id AND u_t.account_id = 'd0fd05c3-868f-42df-b0a9-f51257cba91c'
    WHERE u_s.account_id = 'e8133975-d284-4d1b-8a55-cb7de56c9c99'
  LOOP
    rank_s := CASE r.role_s WHEN 'owner' THEN 1 WHEN 'admin' THEN 2 WHEN 'manager' THEN 3 WHEN 'collector' THEN 4 WHEN 'supplier' THEN 5 WHEN 'customer' THEN 6 WHEN 'agent' THEN 7 WHEN 'viewer' THEN 8 ELSE 9 END;
    rank_t := CASE r.role_t WHEN 'owner' THEN 1 WHEN 'admin' THEN 2 WHEN 'manager' THEN 3 WHEN 'collector' THEN 4 WHEN 'supplier' THEN 5 WHEN 'customer' THEN 6 WHEN 'agent' THEN 7 WHEN 'viewer' THEN 8 ELSE 9 END;
    best_role := CASE WHEN rank_s <= rank_t THEN r.role_s::text ELSE r.role_t::text END;
    UPDATE user_accounts SET role = best_role::"UserAccountRole" WHERE user_id = r.user_id AND account_id = 'd0fd05c3-868f-42df-b0a9-f51257cba91c';
  END LOOP;
END $$;

DELETE FROM user_accounts WHERE account_id = 'e8133975-d284-4d1b-8a55-cb7de56c9c99' AND EXISTS (SELECT 1 FROM user_accounts u2 WHERE u2.user_id = user_accounts.user_id AND u2.account_id = 'd0fd05c3-868f-42df-b0a9-f51257cba91c');
UPDATE user_accounts SET account_id = 'd0fd05c3-868f-42df-b0a9-f51257cba91c' WHERE account_id = 'e8133975-d284-4d1b-8a55-cb7de56c9c99';
UPDATE users SET default_account_id = 'd0fd05c3-868f-42df-b0a9-f51257cba91c' WHERE default_account_id = 'e8133975-d284-4d1b-8a55-cb7de56c9c99';

-- suppliers_customers: remove rows that would duplicate after update, then update
DELETE FROM suppliers_customers sc WHERE sc.supplier_account_id = 'e8133975-d284-4d1b-8a55-cb7de56c9c99' AND EXISTS (SELECT 1 FROM suppliers_customers s2 WHERE s2.supplier_account_id = 'd0fd05c3-868f-42df-b0a9-f51257cba91c' AND s2.customer_account_id = sc.customer_account_id);
UPDATE suppliers_customers SET supplier_account_id = 'd0fd05c3-868f-42df-b0a9-f51257cba91c' WHERE supplier_account_id = 'e8133975-d284-4d1b-8a55-cb7de56c9c99';
DELETE FROM suppliers_customers sc WHERE sc.customer_account_id = 'e8133975-d284-4d1b-8a55-cb7de56c9c99' AND EXISTS (SELECT 1 FROM suppliers_customers s2 WHERE s2.supplier_account_id = sc.supplier_account_id AND s2.customer_account_id = 'd0fd05c3-868f-42df-b0a9-f51257cba91c');
UPDATE suppliers_customers SET customer_account_id = 'd0fd05c3-868f-42df-b0a9-f51257cba91c' WHERE customer_account_id = 'e8133975-d284-4d1b-8a55-cb7de56c9c99';

-- milk_sales (collections + sales)
UPDATE milk_sales SET supplier_account_id = 'd0fd05c3-868f-42df-b0a9-f51257cba91c' WHERE supplier_account_id = 'e8133975-d284-4d1b-8a55-cb7de56c9c99';
UPDATE milk_sales SET customer_account_id = 'd0fd05c3-868f-42df-b0a9-f51257cba91c' WHERE customer_account_id = 'e8133975-d284-4d1b-8a55-cb7de56c9c99';

-- Other tables
UPDATE milk_productions SET account_id = 'd0fd05c3-868f-42df-b0a9-f51257cba91c' WHERE account_id = 'e8133975-d284-4d1b-8a55-cb7de56c9c99';
UPDATE products SET account_id = 'd0fd05c3-868f-42df-b0a9-f51257cba91c' WHERE account_id = 'e8133975-d284-4d1b-8a55-cb7de56c9c99';
UPDATE orders SET account_id = 'd0fd05c3-868f-42df-b0a9-f51257cba91c' WHERE account_id = 'e8133975-d284-4d1b-8a55-cb7de56c9c99';
UPDATE wallets SET account_id = 'd0fd05c3-868f-42df-b0a9-f51257cba91c' WHERE account_id = 'e8133975-d284-4d1b-8a55-cb7de56c9c99';
UPDATE payroll_payslips SET supplier_account_id = 'd0fd05c3-868f-42df-b0a9-f51257cba91c' WHERE supplier_account_id = 'e8133975-d284-4d1b-8a55-cb7de56c9c99';
-- payroll_suppliers: unique per supplier_account_id; target already has row -> delete source rows
DELETE FROM payroll_suppliers WHERE supplier_account_id = 'e8133975-d284-4d1b-8a55-cb7de56c9c99';
UPDATE charges SET customer_account_id = 'd0fd05c3-868f-42df-b0a9-f51257cba91c' WHERE customer_account_id = 'e8133975-d284-4d1b-8a55-cb7de56c9c99';
UPDATE charge_suppliers SET supplier_account_id = 'd0fd05c3-868f-42df-b0a9-f51257cba91c' WHERE supplier_account_id = 'e8133975-d284-4d1b-8a55-cb7de56c9c99';
UPDATE charge_applications SET supplier_account_id = 'd0fd05c3-868f-42df-b0a9-f51257cba91c' WHERE supplier_account_id = 'e8133975-d284-4d1b-8a55-cb7de56c9c99';
UPDATE inventory_sales SET buyer_account_id = 'd0fd05c3-868f-42df-b0a9-f51257cba91c' WHERE buyer_account_id = 'e8133975-d284-4d1b-8a55-cb7de56c9c99';
UPDATE loans SET lender_account_id = 'd0fd05c3-868f-42df-b0a9-f51257cba91c' WHERE lender_account_id = 'e8133975-d284-4d1b-8a55-cb7de56c9c99';
UPDATE loans SET borrower_account_id = 'd0fd05c3-868f-42df-b0a9-f51257cba91c' WHERE borrower_account_id = 'e8133975-d284-4d1b-8a55-cb7de56c9c99';
UPDATE farms SET account_id = 'd0fd05c3-868f-42df-b0a9-f51257cba91c' WHERE account_id = 'e8133975-d284-4d1b-8a55-cb7de56c9c99';
UPDATE animals SET account_id = 'd0fd05c3-868f-42df-b0a9-f51257cba91c' WHERE account_id = 'e8133975-d284-4d1b-8a55-cb7de56c9c99';
UPDATE payroll_runs SET account_id = 'd0fd05c3-868f-42df-b0a9-f51257cba91c' WHERE account_id = 'e8133975-d284-4d1b-8a55-cb7de56c9c99';

UPDATE accounts SET status = 'inactive', updated_at = NOW() WHERE id = 'e8133975-d284-4d1b-8a55-cb7de56c9c99';

-- ========== MERGE INYANGE (77133c4f-...) INTO GAHENGERI ==========

DO $$
DECLARE r RECORD; best_role text; rank_s int; rank_t int;
BEGIN
  FOR r IN
    SELECT u_s.user_id, u_s.role AS role_s, u_t.role AS role_t
    FROM user_accounts u_s
    JOIN user_accounts u_t ON u_t.user_id = u_s.user_id AND u_t.account_id = 'd0fd05c3-868f-42df-b0a9-f51257cba91c'
    WHERE u_s.account_id = '77133c4f-1872-4622-b7aa-6ca7d891ea90'
  LOOP
    rank_s := CASE r.role_s WHEN 'owner' THEN 1 WHEN 'admin' THEN 2 WHEN 'manager' THEN 3 WHEN 'collector' THEN 4 WHEN 'supplier' THEN 5 WHEN 'customer' THEN 6 WHEN 'agent' THEN 7 WHEN 'viewer' THEN 8 ELSE 9 END;
    rank_t := CASE r.role_t WHEN 'owner' THEN 1 WHEN 'admin' THEN 2 WHEN 'manager' THEN 3 WHEN 'collector' THEN 4 WHEN 'supplier' THEN 5 WHEN 'customer' THEN 6 WHEN 'agent' THEN 7 WHEN 'viewer' THEN 8 ELSE 9 END;
    best_role := CASE WHEN rank_s <= rank_t THEN r.role_s::text ELSE r.role_t::text END;
    UPDATE user_accounts SET role = best_role::"UserAccountRole" WHERE user_id = r.user_id AND account_id = 'd0fd05c3-868f-42df-b0a9-f51257cba91c';
  END LOOP;
END $$;

DELETE FROM user_accounts WHERE account_id = '77133c4f-1872-4622-b7aa-6ca7d891ea90' AND EXISTS (SELECT 1 FROM user_accounts u2 WHERE u2.user_id = user_accounts.user_id AND u2.account_id = 'd0fd05c3-868f-42df-b0a9-f51257cba91c');
UPDATE user_accounts SET account_id = 'd0fd05c3-868f-42df-b0a9-f51257cba91c' WHERE account_id = '77133c4f-1872-4622-b7aa-6ca7d891ea90';
UPDATE users SET default_account_id = 'd0fd05c3-868f-42df-b0a9-f51257cba91c' WHERE default_account_id = '77133c4f-1872-4622-b7aa-6ca7d891ea90';

DELETE FROM suppliers_customers sc WHERE sc.supplier_account_id = '77133c4f-1872-4622-b7aa-6ca7d891ea90' AND EXISTS (SELECT 1 FROM suppliers_customers s2 WHERE s2.supplier_account_id = 'd0fd05c3-868f-42df-b0a9-f51257cba91c' AND s2.customer_account_id = sc.customer_account_id);
UPDATE suppliers_customers SET supplier_account_id = 'd0fd05c3-868f-42df-b0a9-f51257cba91c' WHERE supplier_account_id = '77133c4f-1872-4622-b7aa-6ca7d891ea90';
DELETE FROM suppliers_customers sc WHERE sc.customer_account_id = '77133c4f-1872-4622-b7aa-6ca7d891ea90' AND EXISTS (SELECT 1 FROM suppliers_customers s2 WHERE s2.supplier_account_id = sc.supplier_account_id AND s2.customer_account_id = 'd0fd05c3-868f-42df-b0a9-f51257cba91c');
UPDATE suppliers_customers SET customer_account_id = 'd0fd05c3-868f-42df-b0a9-f51257cba91c' WHERE customer_account_id = '77133c4f-1872-4622-b7aa-6ca7d891ea90';

UPDATE milk_sales SET supplier_account_id = 'd0fd05c3-868f-42df-b0a9-f51257cba91c' WHERE supplier_account_id = '77133c4f-1872-4622-b7aa-6ca7d891ea90';
UPDATE milk_sales SET customer_account_id = 'd0fd05c3-868f-42df-b0a9-f51257cba91c' WHERE customer_account_id = '77133c4f-1872-4622-b7aa-6ca7d891ea90';

UPDATE milk_productions SET account_id = 'd0fd05c3-868f-42df-b0a9-f51257cba91c' WHERE account_id = '77133c4f-1872-4622-b7aa-6ca7d891ea90';
UPDATE products SET account_id = 'd0fd05c3-868f-42df-b0a9-f51257cba91c' WHERE account_id = '77133c4f-1872-4622-b7aa-6ca7d891ea90';
UPDATE orders SET account_id = 'd0fd05c3-868f-42df-b0a9-f51257cba91c' WHERE account_id = '77133c4f-1872-4622-b7aa-6ca7d891ea90';
UPDATE wallets SET account_id = 'd0fd05c3-868f-42df-b0a9-f51257cba91c' WHERE account_id = '77133c4f-1872-4622-b7aa-6ca7d891ea90';
UPDATE payroll_payslips SET supplier_account_id = 'd0fd05c3-868f-42df-b0a9-f51257cba91c' WHERE supplier_account_id = '77133c4f-1872-4622-b7aa-6ca7d891ea90';
DELETE FROM payroll_suppliers WHERE supplier_account_id = '77133c4f-1872-4622-b7aa-6ca7d891ea90';
UPDATE charges SET customer_account_id = 'd0fd05c3-868f-42df-b0a9-f51257cba91c' WHERE customer_account_id = '77133c4f-1872-4622-b7aa-6ca7d891ea90';
UPDATE charge_suppliers SET supplier_account_id = 'd0fd05c3-868f-42df-b0a9-f51257cba91c' WHERE supplier_account_id = '77133c4f-1872-4622-b7aa-6ca7d891ea90';
UPDATE charge_applications SET supplier_account_id = 'd0fd05c3-868f-42df-b0a9-f51257cba91c' WHERE supplier_account_id = '77133c4f-1872-4622-b7aa-6ca7d891ea90';
UPDATE inventory_sales SET buyer_account_id = 'd0fd05c3-868f-42df-b0a9-f51257cba91c' WHERE buyer_account_id = '77133c4f-1872-4622-b7aa-6ca7d891ea90';
UPDATE loans SET lender_account_id = 'd0fd05c3-868f-42df-b0a9-f51257cba91c' WHERE lender_account_id = '77133c4f-1872-4622-b7aa-6ca7d891ea90';
UPDATE loans SET borrower_account_id = 'd0fd05c3-868f-42df-b0a9-f51257cba91c' WHERE borrower_account_id = '77133c4f-1872-4622-b7aa-6ca7d891ea90';
UPDATE farms SET account_id = 'd0fd05c3-868f-42df-b0a9-f51257cba91c' WHERE account_id = '77133c4f-1872-4622-b7aa-6ca7d891ea90';
UPDATE animals SET account_id = 'd0fd05c3-868f-42df-b0a9-f51257cba91c' WHERE account_id = '77133c4f-1872-4622-b7aa-6ca7d891ea90';
UPDATE payroll_runs SET account_id = 'd0fd05c3-868f-42df-b0a9-f51257cba91c' WHERE account_id = '77133c4f-1872-4622-b7aa-6ca7d891ea90';

UPDATE accounts SET status = 'inactive', updated_at = NOW() WHERE id = '77133c4f-1872-4622-b7aa-6ca7d891ea90';

COMMIT;
