-- Fix PayrollPayslip: Remove employee_id constraint and make supplier_account_id required
-- This migration fixes the issue where employee_id is still NOT NULL but code uses supplier_account_id

-- Step 1: Drop foreign key constraint on employee_id if it exists
ALTER TABLE "payroll_payslips" 
  DROP CONSTRAINT IF EXISTS "payroll_payslips_employee_id_fkey";

-- Step 2: Drop index on employee_id if it exists
DROP INDEX IF EXISTS "payroll_payslips_employee_id_idx";

-- Step 3: Make employee_id nullable (since we're not using it anymore)
ALTER TABLE "payroll_payslips" 
  ALTER COLUMN "employee_id" DROP NOT NULL;

-- Step 4: Make supplier_account_id NOT NULL (it's required for the new system)
ALTER TABLE "payroll_payslips" 
  ALTER COLUMN "supplier_account_id" SET NOT NULL;

-- Step 5: Make gross_amount NOT NULL if it's not already
ALTER TABLE "payroll_payslips" 
  ALTER COLUMN "gross_amount" SET NOT NULL;

-- Step 6: Make net_amount NOT NULL if it's not already
ALTER TABLE "payroll_payslips" 
  ALTER COLUMN "net_amount" SET NOT NULL;

-- Step 7: Make period_start NOT NULL if it's not already
ALTER TABLE "payroll_payslips" 
  ALTER COLUMN "period_start" SET NOT NULL;

-- Step 8: Make period_end NOT NULL if it's not already
ALTER TABLE "payroll_payslips" 
  ALTER COLUMN "period_end" SET NOT NULL;

-- Step 9: Make old salary columns nullable (they're being replaced by gross_amount/net_amount)
ALTER TABLE "payroll_payslips" 
  ALTER COLUMN "gross_salary" DROP NOT NULL;

ALTER TABLE "payroll_payslips" 
  ALTER COLUMN "net_salary" DROP NOT NULL;
