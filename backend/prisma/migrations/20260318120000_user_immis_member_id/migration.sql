-- Link Gemura users to IMMIS member records (one IMMIS member -> at most one user)
ALTER TABLE "users" ADD COLUMN IF NOT EXISTS "immis_member_id" INTEGER;
ALTER TABLE "users" ADD COLUMN IF NOT EXISTS "immis_linked_at" TIMESTAMP(3);

CREATE UNIQUE INDEX IF NOT EXISTS "users_immis_member_id_key" ON "users" ("immis_member_id");
