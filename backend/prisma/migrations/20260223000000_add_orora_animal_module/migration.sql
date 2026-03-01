-- CreateEnum
CREATE TYPE "AnimalGender" AS ENUM ('male', 'female');

-- CreateEnum
CREATE TYPE "AnimalSource" AS ENUM ('born_on_farm', 'purchased', 'donated', 'other');

-- CreateEnum
CREATE TYPE "AnimalStatus" AS ENUM ('active', 'lactating', 'dry', 'pregnant', 'sick', 'sold', 'dead', 'culled');

-- CreateEnum
CREATE TYPE "HealthEventType" AS ENUM ('vaccination', 'treatment', 'deworming', 'examination', 'surgery', 'injury', 'illness', 'other');

-- CreateTable
CREATE TABLE "animals" (
    "id" UUID NOT NULL DEFAULT gen_random_uuid(),
    "account_id" UUID NOT NULL,
    "tag_number" TEXT NOT NULL,
    "name" TEXT,
    "breed" TEXT NOT NULL,
    "gender" "AnimalGender" NOT NULL,
    "date_of_birth" TIMESTAMP(3) NOT NULL,
    "source" "AnimalSource" NOT NULL,
    "purchase_date" TIMESTAMP(3),
    "purchase_price" DECIMAL(10,2),
    "mother_id" UUID,
    "father_id" UUID,
    "status" "AnimalStatus" NOT NULL DEFAULT 'active',
    "photo_url" TEXT,
    "notes" TEXT,
    "created_at" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updated_at" TIMESTAMP(3) NOT NULL,
    "created_by" UUID,

    CONSTRAINT "animals_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "animal_weights" (
    "id" UUID NOT NULL DEFAULT gen_random_uuid(),
    "animal_id" UUID NOT NULL,
    "weight_kg" DECIMAL(6,2) NOT NULL,
    "recorded_at" TIMESTAMP(3) NOT NULL,
    "notes" TEXT,
    "created_at" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "created_by" UUID,

    CONSTRAINT "animal_weights_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "animal_health" (
    "id" UUID NOT NULL DEFAULT gen_random_uuid(),
    "animal_id" UUID NOT NULL,
    "event_type" "HealthEventType" NOT NULL,
    "event_date" TIMESTAMP(3) NOT NULL,
    "description" TEXT NOT NULL,
    "diagnosis" TEXT,
    "treatment" TEXT,
    "medicine_name" TEXT,
    "dosage" TEXT,
    "administered_by" TEXT,
    "next_due_date" TIMESTAMP(3),
    "cost" DECIMAL(10,2),
    "notes" TEXT,
    "created_at" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "created_by" UUID,

    CONSTRAINT "animal_health_pkey" PRIMARY KEY ("id")
);

-- AlterTable
ALTER TABLE "milk_sales" ADD COLUMN "animal_id" UUID;

-- CreateIndex
CREATE UNIQUE INDEX "animals_account_id_tag_number_key" ON "animals"("account_id", "tag_number");

-- CreateIndex
CREATE INDEX "animals_account_id_idx" ON "animals"("account_id");

-- CreateIndex
CREATE INDEX "animals_status_idx" ON "animals"("status");

-- CreateIndex
CREATE INDEX "animals_breed_idx" ON "animals"("breed");

-- CreateIndex
CREATE INDEX "animals_gender_idx" ON "animals"("gender");

-- CreateIndex
CREATE INDEX "animal_weights_animal_id_idx" ON "animal_weights"("animal_id");

-- CreateIndex
CREATE INDEX "animal_weights_recorded_at_idx" ON "animal_weights"("recorded_at");

-- CreateIndex
CREATE INDEX "animal_health_animal_id_idx" ON "animal_health"("animal_id");

-- CreateIndex
CREATE INDEX "animal_health_event_type_idx" ON "animal_health"("event_type");

-- CreateIndex
CREATE INDEX "animal_health_event_date_idx" ON "animal_health"("event_date");

-- CreateIndex
CREATE INDEX "animal_health_next_due_date_idx" ON "animal_health"("next_due_date");

-- CreateIndex
CREATE INDEX "milk_sales_animal_id_idx" ON "milk_sales"("animal_id");

-- AddForeignKey
ALTER TABLE "animals" ADD CONSTRAINT "animals_account_id_fkey" FOREIGN KEY ("account_id") REFERENCES "accounts"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "animals" ADD CONSTRAINT "animals_mother_id_fkey" FOREIGN KEY ("mother_id") REFERENCES "animals"("id") ON DELETE SET NULL ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "animals" ADD CONSTRAINT "animals_father_id_fkey" FOREIGN KEY ("father_id") REFERENCES "animals"("id") ON DELETE SET NULL ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "animal_weights" ADD CONSTRAINT "animal_weights_animal_id_fkey" FOREIGN KEY ("animal_id") REFERENCES "animals"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "animal_health" ADD CONSTRAINT "animal_health_animal_id_fkey" FOREIGN KEY ("animal_id") REFERENCES "animals"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "milk_sales" ADD CONSTRAINT "milk_sales_animal_id_fkey" FOREIGN KEY ("animal_id") REFERENCES "animals"("id") ON DELETE SET NULL ON UPDATE CASCADE;
