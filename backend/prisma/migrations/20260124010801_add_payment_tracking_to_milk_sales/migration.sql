-- Add payment tracking fields to milk_sales table
-- Migration: add_payment_tracking_to_milk_sales

-- Add payment fields
ALTER TABLE "milk_sales" 
ADD COLUMN IF NOT EXISTS "amount_paid" DECIMAL(10,2) NOT NULL DEFAULT 0,
ADD COLUMN IF NOT EXISTS "payment_status" VARCHAR(20) DEFAULT 'unpaid',
ADD COLUMN IF NOT EXISTS "payment_history" JSONB;

-- Create index on payment_status for faster queries
CREATE INDEX IF NOT EXISTS "milk_sales_payment_status_idx" ON "milk_sales"("payment_status");

-- Update existing records: if they exist, we'll leave them as unpaid (amount_paid = 0)
-- This is safe as existing records would have been created without payment tracking
