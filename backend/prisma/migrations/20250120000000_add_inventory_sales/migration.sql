-- Create InventorySale enums and table
-- Migration: add_inventory_sales

-- Step 1: Create enums
DO $$
BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_type WHERE typname = 'InventorySaleBuyerType') THEN
    CREATE TYPE "InventorySaleBuyerType" AS ENUM ('supplier', 'customer', 'other');
  END IF;
  
  IF NOT EXISTS (SELECT 1 FROM pg_type WHERE typname = 'InventorySalePaymentStatus') THEN
    CREATE TYPE "InventorySalePaymentStatus" AS ENUM ('paid', 'partial', 'unpaid');
  END IF;
END $$;

-- Step 2: Create inventory_sales table
CREATE TABLE IF NOT EXISTS "inventory_sales" (
  "id" UUID NOT NULL DEFAULT gen_random_uuid(),
  "product_id" UUID NOT NULL,
  "order_id" UUID,
  "buyer_type" "InventorySaleBuyerType" NOT NULL,
  "buyer_account_id" UUID,
  "buyer_name" TEXT,
  "buyer_phone" TEXT,
  "quantity" DECIMAL(10,2) NOT NULL,
  "unit_price" DECIMAL(10,2) NOT NULL,
  "total_amount" DECIMAL(10,2) NOT NULL,
  "amount_paid" DECIMAL(10,2) NOT NULL DEFAULT 0,
  "payment_status" "InventorySalePaymentStatus" NOT NULL DEFAULT 'unpaid',
  "sale_date" TIMESTAMP(3) NOT NULL,
  "notes" TEXT,
  "created_at" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
  "updated_at" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
  "created_by" UUID,

  CONSTRAINT "inventory_sales_pkey" PRIMARY KEY ("id")
);

-- Step 3: Create indexes
CREATE INDEX IF NOT EXISTS "inventory_sales_product_id_idx" ON "inventory_sales"("product_id");
CREATE INDEX IF NOT EXISTS "inventory_sales_order_id_idx" ON "inventory_sales"("order_id");
CREATE INDEX IF NOT EXISTS "inventory_sales_buyer_account_id_idx" ON "inventory_sales"("buyer_account_id");
CREATE INDEX IF NOT EXISTS "inventory_sales_buyer_type_idx" ON "inventory_sales"("buyer_type");
CREATE INDEX IF NOT EXISTS "inventory_sales_payment_status_idx" ON "inventory_sales"("payment_status");
CREATE INDEX IF NOT EXISTS "inventory_sales_sale_date_idx" ON "inventory_sales"("sale_date");

-- Step 4: Add foreign key constraints
DO $$
BEGIN
  -- Product foreign key
  IF NOT EXISTS (
    SELECT 1 FROM pg_constraint WHERE conname = 'inventory_sales_product_id_fkey'
  ) THEN
    ALTER TABLE "inventory_sales" 
      ADD CONSTRAINT "inventory_sales_product_id_fkey" 
      FOREIGN KEY ("product_id") REFERENCES "products"("id") ON DELETE RESTRICT ON UPDATE CASCADE;
  END IF;
  
  -- Order foreign key (nullable)
  IF NOT EXISTS (
    SELECT 1 FROM pg_constraint WHERE conname = 'inventory_sales_order_id_fkey'
  ) THEN
    ALTER TABLE "inventory_sales" 
      ADD CONSTRAINT "inventory_sales_order_id_fkey" 
      FOREIGN KEY ("order_id") REFERENCES "orders"("id") ON DELETE SET NULL ON UPDATE CASCADE;
  END IF;
  
  -- Buyer account foreign key (nullable)
  IF NOT EXISTS (
    SELECT 1 FROM pg_constraint WHERE conname = 'inventory_sales_buyer_account_id_fkey'
  ) THEN
    ALTER TABLE "inventory_sales" 
      ADD CONSTRAINT "inventory_sales_buyer_account_id_fkey" 
      FOREIGN KEY ("buyer_account_id") REFERENCES "accounts"("id") ON DELETE SET NULL ON UPDATE CASCADE;
  END IF;
  
  -- Created by user foreign key (nullable)
  IF NOT EXISTS (
    SELECT 1 FROM pg_constraint WHERE conname = 'inventory_sales_created_by_fkey'
  ) THEN
    ALTER TABLE "inventory_sales" 
      ADD CONSTRAINT "inventory_sales_created_by_fkey" 
      FOREIGN KEY ("created_by") REFERENCES "users"("id") ON DELETE SET NULL ON UPDATE CASCADE;
  END IF;
END $$;

-- Step 5: Add updated_at trigger
CREATE OR REPLACE FUNCTION update_inventory_sales_updated_at()
RETURNS TRIGGER AS $$
BEGIN
  NEW."updated_at" = CURRENT_TIMESTAMP;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_trigger WHERE tgname = 'inventory_sales_updated_at'
  ) THEN
    CREATE TRIGGER "inventory_sales_updated_at"
      BEFORE UPDATE ON "inventory_sales"
      FOR EACH ROW
      EXECUTE FUNCTION update_inventory_sales_updated_at();
  END IF;
END $$;
