-- Add payment tracking fields to PayrollPayslip
ALTER TABLE "payroll_payslips" 
  ADD COLUMN IF NOT EXISTS "payment_date" TIMESTAMP(3),
  ADD COLUMN IF NOT EXISTS "paid_by" UUID;

-- Create index on payment_date for faster queries
CREATE INDEX IF NOT EXISTS "payroll_payslips_payment_date_idx" ON "payroll_payslips"("payment_date");
