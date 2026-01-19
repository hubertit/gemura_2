-- Remove unused accounting tables that are not used by the mobile app
-- These tables were part of features (invoices, receipts, ledger, fees) that are not implemented in the mobile app

-- Drop tables in order (child tables first, then parent tables)
DROP TABLE IF EXISTS "invoice_items" CASCADE;
DROP TABLE IF EXISTS "invoices" CASCADE;
DROP TABLE IF EXISTS "receipts" CASCADE;
DROP TABLE IF EXISTS "supplier_deductions" CASCADE;
DROP TABLE IF EXISTS "supplier_fee_rules" CASCADE;
DROP TABLE IF EXISTS "fee_types" CASCADE;
DROP TABLE IF EXISTS "supplier_ledger" CASCADE;
