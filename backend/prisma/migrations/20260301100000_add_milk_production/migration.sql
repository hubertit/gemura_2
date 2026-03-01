-- CreateTable
CREATE TABLE "milk_productions" (
    "id" UUID NOT NULL DEFAULT gen_random_uuid(),
    "account_id" UUID NOT NULL,
    "farm_id" UUID,
    "animal_id" UUID,
    "production_date" DATE NOT NULL,
    "quantity_litres" DECIMAL(10,2) NOT NULL,
    "notes" TEXT,
    "created_at" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updated_at" TIMESTAMP(3) NOT NULL,
    "created_by" UUID,

    CONSTRAINT "milk_productions_pkey" PRIMARY KEY ("id")
);

-- CreateIndex
CREATE INDEX "milk_productions_account_id_idx" ON "milk_productions"("account_id");

-- CreateIndex
CREATE INDEX "milk_productions_farm_id_idx" ON "milk_productions"("farm_id");

-- CreateIndex
CREATE INDEX "milk_productions_animal_id_idx" ON "milk_productions"("animal_id");

-- CreateIndex
CREATE INDEX "milk_productions_production_date_idx" ON "milk_productions"("production_date");

-- AddForeignKey
ALTER TABLE "milk_productions" ADD CONSTRAINT "milk_productions_account_id_fkey" FOREIGN KEY ("account_id") REFERENCES "accounts"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "milk_productions" ADD CONSTRAINT "milk_productions_farm_id_fkey" FOREIGN KEY ("farm_id") REFERENCES "farms"("id") ON DELETE SET NULL ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "milk_productions" ADD CONSTRAINT "milk_productions_animal_id_fkey" FOREIGN KEY ("animal_id") REFERENCES "animals"("id") ON DELETE SET NULL ON UPDATE CASCADE;
