-- Add account_id to payroll_runs so runs are scoped per account (Kozamgi vs Gahengeri).
-- Backfill: set account_id from creator's default_account_id where possible.

ALTER TABLE "payroll_runs" ADD COLUMN IF NOT EXISTS "account_id" UUID;

UPDATE "payroll_runs" pr
SET "account_id" = u."default_account_id"
FROM "users" u
WHERE pr."created_by" = u."id"
  AND u."default_account_id" IS NOT NULL
  AND pr."account_id" IS NULL;

CREATE INDEX IF NOT EXISTS "payroll_runs_account_id_idx" ON "payroll_runs"("account_id");

ALTER TABLE "payroll_runs"
  ADD CONSTRAINT "payroll_runs_account_id_fkey"
  FOREIGN KEY ("account_id") REFERENCES "accounts"("id") ON DELETE CASCADE ON UPDATE CASCADE;
