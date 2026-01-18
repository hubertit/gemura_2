-- Change Payroll from Employees to Suppliers
-- This migration converts the payroll system to work with suppliers instead of employees

-- Step 1: Create new PayrollSupplier table
CREATE TABLE IF NOT EXISTS "payroll_suppliers" (
    "id" UUID NOT NULL,
    "supplier_account_id" UUID NOT NULL,
    "payment_terms_days" INTEGER NOT NULL DEFAULT 15,
    "is_active" BOOLEAN NOT NULL DEFAULT true,
    "created_at" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updated_at" TIMESTAMP(3) NOT NULL,

    CONSTRAINT "payroll_suppliers_pkey" PRIMARY KEY ("id")
);

-- Step 2: Add new columns to PayrollRun
ALTER TABLE "payroll_runs" ADD COLUMN IF NOT EXISTS "period_start" TIMESTAMP(3);
ALTER TABLE "payroll_runs" ADD COLUMN IF NOT EXISTS "period_end" TIMESTAMP(3);
ALTER TABLE "payroll_runs" ADD COLUMN IF NOT EXISTS "payment_terms_days" INTEGER;
ALTER TABLE "payroll_runs" ALTER COLUMN "period_id" DROP NOT NULL;

-- Step 3: Update PayrollPayslip to use supplier_account_id instead of employee_id
ALTER TABLE "payroll_payslips" ADD COLUMN IF NOT EXISTS "supplier_account_id" UUID;
ALTER TABLE "payroll_payslips" ADD COLUMN IF NOT EXISTS "gross_amount" DECIMAL(15,2);
ALTER TABLE "payroll_payslips" ADD COLUMN IF NOT EXISTS "net_amount" DECIMAL(15,2);
ALTER TABLE "payroll_payslips" ADD COLUMN IF NOT EXISTS "milk_sales_count" INTEGER DEFAULT 0;
ALTER TABLE "payroll_payslips" ADD COLUMN IF NOT EXISTS "period_start" TIMESTAMP(3);
ALTER TABLE "payroll_payslips" ADD COLUMN IF NOT EXISTS "period_end" TIMESTAMP(3);

-- Step 4: Migrate data if employee_id exists (optional - only if there's existing data)
-- UPDATE "payroll_payslips" SET "gross_amount" = "gross_salary", "net_amount" = "net_salary" WHERE "gross_amount" IS NULL;

-- Step 5: Create indexes
CREATE UNIQUE INDEX IF NOT EXISTS "payroll_suppliers_supplier_account_id_key" ON "payroll_suppliers"("supplier_account_id");
CREATE INDEX IF NOT EXISTS "payroll_suppliers_supplier_account_id_idx" ON "payroll_suppliers"("supplier_account_id");
CREATE INDEX IF NOT EXISTS "payroll_suppliers_is_active_idx" ON "payroll_suppliers"("is_active");
CREATE INDEX IF NOT EXISTS "payroll_runs_period_start_idx" ON "payroll_runs"("period_start");
CREATE INDEX IF NOT EXISTS "payroll_runs_period_end_idx" ON "payroll_runs"("period_end");
CREATE INDEX IF NOT EXISTS "payroll_payslips_supplier_account_id_idx" ON "payroll_payslips"("supplier_account_id");
CREATE INDEX IF NOT EXISTS "payroll_payslips_period_start_idx" ON "payroll_payslips"("period_start");
CREATE INDEX IF NOT EXISTS "payroll_payslips_period_end_idx" ON "payroll_payslips"("period_end");

-- Step 6: Add foreign key constraints
ALTER TABLE "payroll_suppliers" ADD CONSTRAINT "payroll_suppliers_supplier_account_id_fkey" FOREIGN KEY ("supplier_account_id") REFERENCES "accounts"("id") ON DELETE CASCADE ON UPDATE CASCADE;
ALTER TABLE "payroll_payslips" ADD CONSTRAINT "payroll_payslips_supplier_account_id_fkey" FOREIGN KEY ("supplier_account_id") REFERENCES "accounts"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- Step 7: Drop old employee-related columns (commented out for safety - uncomment after verifying)
-- ALTER TABLE "payroll_payslips" DROP COLUMN IF EXISTS "employee_id";
-- ALTER TABLE "payroll_payslips" DROP COLUMN IF EXISTS "gross_salary";
-- ALTER TABLE "payroll_payslips" DROP COLUMN IF EXISTS "net_salary";
-- DROP TABLE IF EXISTS "payroll_employees";

