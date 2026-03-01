-- AlterTable
-- Session already added as VARCHAR(32) by prior run; no change needed for VarChar
ALTER TABLE "milk_productions" ADD COLUMN IF NOT EXISTS "session" VARCHAR(32);
