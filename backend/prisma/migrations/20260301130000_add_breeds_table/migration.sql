-- CreateTable
CREATE TABLE "breeds" (
    "id" UUID NOT NULL DEFAULT gen_random_uuid(),
    "name" VARCHAR(255) NOT NULL,
    "code" VARCHAR(50) NOT NULL,
    "description" TEXT,
    "created_at" TIMESTAMPTZ(6) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "breeds_pkey" PRIMARY KEY ("id")
);

CREATE UNIQUE INDEX "breeds_code_key" ON "breeds"("code");
CREATE INDEX "breeds_code_idx" ON "breeds"("code");

-- Seed default cattle breeds (Rwanda / East Africa common)
INSERT INTO "breeds" (id, name, code, description) VALUES
  (gen_random_uuid(), 'Ankole', 'ANKOLE', 'Ankole-Watusi, indigenous longhorn'),
  (gen_random_uuid(), 'Holstein', 'HOLSTEIN', 'Holstein Friesian, dairy'),
  (gen_random_uuid(), 'Jersey', 'JERSEY', 'Jersey, dairy'),
  (gen_random_uuid(), 'Guernsey', 'GUERNSEY', 'Guernsey, dairy'),
  (gen_random_uuid(), 'Simmental', 'SIMMENTAL', 'Simmental, dual-purpose'),
  (gen_random_uuid(), 'Hereford', 'HEREFORD', 'Hereford, beef'),
  (gen_random_uuid(), 'Angus', 'ANGUS', 'Angus, beef'),
  (gen_random_uuid(), 'Brahman', 'BRAHMAN', 'Brahman, zebu'),
  (gen_random_uuid(), 'Crossbreed', 'CROSSBREED', 'Crossbreed / mixed'),
  (gen_random_uuid(), 'Other', 'OTHER', 'Other / unspecified');

-- Add breed_id to animals (nullable first for backfill)
ALTER TABLE "animals" ADD COLUMN "breed_id" UUID;

-- Backfill: create breed from any distinct animal.breed not already in breeds
INSERT INTO "breeds" (id, name, code, description)
SELECT gen_random_uuid(), d.breed, UPPER(REGEXP_REPLACE(TRIM(d.breed), '\s+', '_', 'g'))
     , NULL
FROM (SELECT DISTINCT TRIM(breed) AS breed FROM "animals" WHERE breed IS NOT NULL AND TRIM(breed) <> '') d
WHERE NOT EXISTS (SELECT 1 FROM "breeds" b WHERE b.name = d.breed);

-- Set breed_id from matching breed name
UPDATE "animals" a
SET breed_id = (SELECT id FROM "breeds" b WHERE b.name = TRIM(a.breed) LIMIT 1)
WHERE a.breed IS NOT NULL AND TRIM(a.breed) <> '';

-- Set remaining nulls to Other
UPDATE "animals"
SET breed_id = (SELECT id FROM "breeds" WHERE code = 'OTHER' LIMIT 1)
WHERE breed_id IS NULL;

-- Now enforce not null and add FK
ALTER TABLE "animals" ALTER COLUMN "breed_id" SET NOT NULL;
ALTER TABLE "animals" ADD CONSTRAINT "animals_breed_id_fkey" FOREIGN KEY ("breed_id") REFERENCES "breeds"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- Drop old breed column
ALTER TABLE "animals" DROP COLUMN "breed";

-- Index
CREATE INDEX "animals_breed_id_idx" ON "animals"("breed_id");
