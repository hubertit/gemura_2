-- Add inventory fields to Product model
-- This migration adds account_id, is_listed_in_marketplace, and min_stock_level fields

-- Step 1: Add new columns to products table
ALTER TABLE "products" 
  ADD COLUMN IF NOT EXISTS "account_id" UUID,
  ADD COLUMN IF NOT EXISTS "is_listed_in_marketplace" BOOLEAN DEFAULT false,
  ADD COLUMN IF NOT EXISTS "min_stock_level" INTEGER;

-- Step 2: Create indexes
CREATE INDEX IF NOT EXISTS "products_account_id_idx" ON "products"("account_id");
CREATE INDEX IF NOT EXISTS "products_is_listed_in_marketplace_idx" ON "products"("is_listed_in_marketplace");

-- Step 3: Add foreign key constraint
ALTER TABLE "products" 
  ADD CONSTRAINT IF NOT EXISTS "products_account_id_fkey" 
  FOREIGN KEY ("account_id") REFERENCES "accounts"("id") ON DELETE SET NULL ON UPDATE CASCADE;
