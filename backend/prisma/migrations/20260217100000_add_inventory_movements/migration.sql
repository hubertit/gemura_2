-- Create InventoryMovement enums and table, then backfill from inventory_sales

-- Step 1: Create enums
DO $$
BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_type WHERE typname = 'InventoryMovementType') THEN
    CREATE TYPE "InventoryMovementType" AS ENUM (
      'sale_out', 'adjustment_in', 'adjustment_out',
      'purchase_in', 'transfer_in', 'transfer_out'
    );
  END IF;
  IF NOT EXISTS (SELECT 1 FROM pg_type WHERE typname = 'InventoryMovementReferenceType') THEN
    CREATE TYPE "InventoryMovementReferenceType" AS ENUM (
      'inventory_sale', 'stock_adjustment', 'purchase', 'transfer'
    );
  END IF;
END $$;

-- Step 2: Create inventory_movements table
CREATE TABLE IF NOT EXISTS "inventory_movements" (
  "id" UUID NOT NULL DEFAULT gen_random_uuid(),
  "product_id" UUID NOT NULL,
  "movement_type" "InventoryMovementType" NOT NULL,
  "quantity" INTEGER NOT NULL,
  "reference_type" "InventoryMovementReferenceType" NOT NULL,
  "reference_id" UUID,
  "description" TEXT,
  "unit_price" DECIMAL(10,2),
  "created_at" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
  "created_by" UUID,

  CONSTRAINT "inventory_movements_pkey" PRIMARY KEY ("id")
);

CREATE INDEX IF NOT EXISTS "inventory_movements_product_id_idx" ON "inventory_movements"("product_id");
CREATE INDEX IF NOT EXISTS "inventory_movements_movement_type_idx" ON "inventory_movements"("movement_type");
CREATE INDEX IF NOT EXISTS "inventory_movements_reference_type_idx" ON "inventory_movements"("reference_type");
CREATE INDEX IF NOT EXISTS "inventory_movements_created_at_idx" ON "inventory_movements"("created_at");

ALTER TABLE "inventory_movements"
  ADD CONSTRAINT "inventory_movements_product_id_fkey"
  FOREIGN KEY ("product_id") REFERENCES "products"("id") ON DELETE CASCADE ON UPDATE CASCADE;

ALTER TABLE "inventory_movements"
  ADD CONSTRAINT "inventory_movements_created_by_fkey"
  FOREIGN KEY ("created_by") REFERENCES "users"("id") ON DELETE SET NULL ON UPDATE CASCADE;

-- Step 3: Backfill movements from existing inventory_sales
INSERT INTO "inventory_movements" (
  "id",
  "product_id",
  "movement_type",
  "quantity",
  "reference_type",
  "reference_id",
  "description",
  "unit_price",
  "created_at",
  "created_by"
)
SELECT
  gen_random_uuid(),
  s."product_id",
  'sale_out'::"InventoryMovementType",
  GREATEST(1, ROUND(s."quantity")::integer),
  'inventory_sale'::"InventoryMovementReferenceType",
  s."id",
  COALESCE(
    TRIM(
      COALESCE(s."buyer_name", a."name", s."buyer_phone", '')::text
    ),
    'Sale (backfilled)'
  ),
  s."unit_price",
  s."created_at",
  s."created_by"
FROM "inventory_sales" s
LEFT JOIN "accounts" a ON a."id" = s."buyer_account_id"
WHERE NOT EXISTS (
  SELECT 1 FROM "inventory_movements" m
  WHERE m."reference_type" = 'inventory_sale' AND m."reference_id" = s."id"
);
