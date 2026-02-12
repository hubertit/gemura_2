-- Add payment tracking fields to milk_sales table
ALTER TABLE "milk_sales" 
ADD COLUMN IF NOT EXISTS "amount_paid" DECIMAL(10,2) NOT NULL DEFAULT 0,
ADD COLUMN IF NOT EXISTS "payment_status" VARCHAR(20) DEFAULT 'unpaid',
ADD COLUMN IF NOT EXISTS "payment_history" JSONB;
CREATE INDEX IF NOT EXISTS "milk_sales_payment_status_idx" ON "milk_sales"("payment_status");
