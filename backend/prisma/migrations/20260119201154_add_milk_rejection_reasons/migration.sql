-- CreateTable
CREATE TABLE "milk_rejection_reasons" (
    "id" UUID NOT NULL,
    "name" TEXT NOT NULL,
    "description" TEXT,
    "is_active" BOOLEAN NOT NULL DEFAULT true,
    "sort_order" INTEGER NOT NULL DEFAULT 0,
    "created_at" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updated_at" TIMESTAMP(3) NOT NULL,

    CONSTRAINT "milk_rejection_reasons_pkey" PRIMARY KEY ("id")
);

-- CreateIndex
CREATE UNIQUE INDEX "milk_rejection_reasons_name_key" ON "milk_rejection_reasons"("name");

-- CreateIndex
CREATE INDEX "milk_rejection_reasons_is_active_idx" ON "milk_rejection_reasons"("is_active");

-- CreateIndex
CREATE INDEX "milk_rejection_reasons_sort_order_idx" ON "milk_rejection_reasons"("sort_order");

-- Insert initial data
INSERT INTO "milk_rejection_reasons" ("id", "name", "description", "is_active", "sort_order", "created_at", "updated_at") VALUES
(gen_random_uuid(), 'Added Water', 'Water was added to the milk', true, 1, NOW(), NOW()),
(gen_random_uuid(), 'Antibiotics', 'Antibiotic residues detected in milk', true, 2, NOW(), NOW()),
(gen_random_uuid(), 'Aflatoxin', 'Aflatoxin contamination detected', true, 3, NOW(), NOW()),
(gen_random_uuid(), 'Adulteration', 'Milk has been adulterated with foreign substances', true, 4, NOW(), NOW()),
(gen_random_uuid(), 'Temperature', 'Temperature issues - milk not stored at proper temperature', true, 5, NOW(), NOW());
