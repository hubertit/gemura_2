-- CreateEnum
CREATE TYPE "LocationType" AS ENUM ('COUNTRY', 'PROVINCE', 'DISTRICT', 'SECTOR', 'CELL', 'VILLAGE');

-- CreateEnum
CREATE TYPE "FarmStatus" AS ENUM ('active', 'inactive', 'archived');

-- CreateTable
CREATE TABLE "locations" (
    "id" UUID NOT NULL DEFAULT gen_random_uuid(),
    "code" VARCHAR(30) NOT NULL,
    "name" VARCHAR(255) NOT NULL,
    "location_type" "LocationType" NOT NULL,
    "parent_id" UUID,

    CONSTRAINT "locations_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "farms" (
    "id" UUID NOT NULL DEFAULT gen_random_uuid(),
    "account_id" UUID NOT NULL,
    "name" TEXT NOT NULL,
    "code" TEXT,
    "description" TEXT,
    "location" TEXT,
    "location_id" UUID,
    "status" "FarmStatus" NOT NULL DEFAULT 'active',
    "created_at" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updated_at" TIMESTAMP(3) NOT NULL,
    "created_by" UUID,

    CONSTRAINT "farms_pkey" PRIMARY KEY ("id")
);

-- AlterTable: add farm_id to animals (table was created in add_orora_animal_module without farm_id)
ALTER TABLE "animals" ADD COLUMN IF NOT EXISTS "farm_id" UUID;

-- CreateIndex
CREATE UNIQUE INDEX "locations_code_key" ON "locations"("code");

-- CreateIndex
CREATE INDEX "locations_location_type_idx" ON "locations"("location_type");

-- CreateIndex
CREATE INDEX "locations_parent_id_idx" ON "locations"("parent_id");

-- CreateIndex
CREATE UNIQUE INDEX "farms_code_key" ON "farms"("code");

-- CreateIndex
CREATE INDEX "farms_account_id_idx" ON "farms"("account_id");

-- CreateIndex
CREATE INDEX "farms_location_id_idx" ON "farms"("location_id");

-- CreateIndex
CREATE INDEX "farms_status_idx" ON "farms"("status");

-- CreateIndex (IF NOT EXISTS in case schema was applied via db push)
CREATE INDEX IF NOT EXISTS "animals_farm_id_idx" ON "animals"("farm_id");

-- AddForeignKey
ALTER TABLE "locations" ADD CONSTRAINT "locations_parent_id_fkey" FOREIGN KEY ("parent_id") REFERENCES "locations"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "farms" ADD CONSTRAINT "farms_account_id_fkey" FOREIGN KEY ("account_id") REFERENCES "accounts"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "farms" ADD CONSTRAINT "farms_location_id_fkey" FOREIGN KEY ("location_id") REFERENCES "locations"("id") ON DELETE SET NULL ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "animals" ADD CONSTRAINT "animals_farm_id_fkey" FOREIGN KEY ("farm_id") REFERENCES "farms"("id") ON DELETE SET NULL ON UPDATE CASCADE;
