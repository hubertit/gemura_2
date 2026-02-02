-- Add inventory_sale_id to PayrollDeduction for linking inventory debt deductions
ALTER TABLE "payroll_deductions" 
  ADD COLUMN IF NOT EXISTS "inventory_sale_id" UUID;

-- Add foreign key constraint
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_constraint WHERE conname = 'payroll_deductions_inventory_sale_id_fkey'
  ) THEN
    ALTER TABLE "payroll_deductions" 
      ADD CONSTRAINT "payroll_deductions_inventory_sale_id_fkey" 
      FOREIGN KEY ("inventory_sale_id") REFERENCES "inventory_sales"("id") ON DELETE SET NULL ON UPDATE CASCADE;
  END IF;
END $$;

-- Create index for faster lookups
CREATE INDEX IF NOT EXISTS "payroll_deductions_inventory_sale_id_idx" ON "payroll_deductions"("inventory_sale_id");
