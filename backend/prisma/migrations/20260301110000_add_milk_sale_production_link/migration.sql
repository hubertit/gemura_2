-- AlterTable: add optional link from milk_sales to milk_production
ALTER TABLE "milk_sales" ADD COLUMN "milk_production_id" UUID;

-- CreateIndex
CREATE INDEX "milk_sales_milk_production_id_idx" ON "milk_sales"("milk_production_id");

-- AddForeignKey
ALTER TABLE "milk_sales" ADD CONSTRAINT "milk_sales_milk_production_id_fkey" FOREIGN KEY ("milk_production_id") REFERENCES "milk_productions"("id") ON DELETE SET NULL ON UPDATE CASCADE;
