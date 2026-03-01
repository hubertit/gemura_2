-- CreateEnum
CREATE TYPE "BreedingMethod" AS ENUM ('natural', 'artificial_insemination');

-- CreateEnum
CREATE TYPE "BreedingOutcome" AS ENUM ('pregnant', 'not_pregnant', 'unknown');

-- CreateEnum
CREATE TYPE "CalvingOutcome" AS ENUM ('live', 'stillborn', 'aborted');

-- CreateTable
CREATE TABLE "animal_breeding" (
    "id" UUID NOT NULL DEFAULT gen_random_uuid(),
    "animal_id" UUID NOT NULL,
    "breeding_date" DATE NOT NULL,
    "method" "BreedingMethod" NOT NULL,
    "bull_animal_id" UUID,
    "bull_name" VARCHAR(255),
    "semen_code" VARCHAR(255),
    "expected_calving_date" DATE,
    "outcome" "BreedingOutcome" DEFAULT 'unknown',
    "notes" TEXT,
    "created_at" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "created_by" UUID,

    CONSTRAINT "animal_breeding_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "animal_calving" (
    "id" UUID NOT NULL DEFAULT gen_random_uuid(),
    "mother_id" UUID NOT NULL,
    "calving_date" DATE NOT NULL,
    "calf_id" UUID UNIQUE,
    "outcome" "CalvingOutcome" NOT NULL,
    "gender" "AnimalGender",
    "weight_kg" DECIMAL(6,2),
    "notes" TEXT,
    "created_at" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "created_by" UUID,

    CONSTRAINT "animal_calving_pkey" PRIMARY KEY ("id")
);

-- CreateIndex
CREATE INDEX "animal_breeding_animal_id_idx" ON "animal_breeding"("animal_id");
CREATE INDEX "animal_breeding_breeding_date_idx" ON "animal_breeding"("breeding_date");
CREATE INDEX "animal_breeding_expected_calving_date_idx" ON "animal_breeding"("expected_calving_date");

-- CreateIndex
CREATE INDEX "animal_calving_mother_id_idx" ON "animal_calving"("mother_id");
CREATE INDEX "animal_calving_calving_date_idx" ON "animal_calving"("calving_date");
CREATE INDEX "animal_calving_calf_id_idx" ON "animal_calving"("calf_id");

-- AddForeignKey
ALTER TABLE "animal_breeding" ADD CONSTRAINT "animal_breeding_animal_id_fkey" FOREIGN KEY ("animal_id") REFERENCES "animals"("id") ON DELETE CASCADE ON UPDATE CASCADE;
ALTER TABLE "animal_breeding" ADD CONSTRAINT "animal_breeding_bull_animal_id_fkey" FOREIGN KEY ("bull_animal_id") REFERENCES "animals"("id") ON DELETE SET NULL ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "animal_calving" ADD CONSTRAINT "animal_calving_mother_id_fkey" FOREIGN KEY ("mother_id") REFERENCES "animals"("id") ON DELETE CASCADE ON UPDATE CASCADE;
ALTER TABLE "animal_calving" ADD CONSTRAINT "animal_calving_calf_id_fkey" FOREIGN KEY ("calf_id") REFERENCES "animals"("id") ON DELETE SET NULL ON UPDATE CASCADE;
