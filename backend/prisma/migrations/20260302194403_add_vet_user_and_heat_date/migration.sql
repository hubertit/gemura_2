/*
  Warnings:

  - You are about to drop the column `employee_id` on the `payroll_payslips` table. All the data in the column will be lost.
  - You are about to drop the column `gross_salary` on the `payroll_payslips` table. All the data in the column will be lost.
  - You are about to drop the column `net_salary` on the `payroll_payslips` table. All the data in the column will be lost.
  - You are about to drop the `payroll_employees` table. If the table is not empty, all the data it contains will be lost.
  - A unique constraint covering the columns `[phone]` on the table `users` will be added. If there are existing duplicate values, this will fail.
  - A unique constraint covering the columns `[referral_code]` on the table `users` will be added. If there are existing duplicate values, this will fail.
  - Made the column `milk_sales_count` on table `payroll_payslips` required. This step will fail if there are existing NULL values in that column.
  - Made the column `is_listed_in_marketplace` on table `products` required. This step will fail if there are existing NULL values in that column.

*/
-- DropForeignKey
ALTER TABLE "public"."loans" DROP CONSTRAINT "loans_created_by_fkey";

-- DropForeignKey
ALTER TABLE "public"."payroll_employees" DROP CONSTRAINT "payroll_employees_account_id_fkey";

-- DropForeignKey
ALTER TABLE "public"."payroll_employees" DROP CONSTRAINT "payroll_employees_user_id_fkey";

-- DropForeignKey
ALTER TABLE "public"."payroll_runs" DROP CONSTRAINT "payroll_runs_period_id_fkey";

-- DropIndex
DROP INDEX "public"."payroll_payslips_payment_date_idx";

-- DropIndex
DROP INDEX "public"."payroll_payslips_payroll_supplier_id_idx";

-- AlterTable
ALTER TABLE "public"."animal_breeding" ADD COLUMN     "heat_date" DATE,
ALTER COLUMN "id" DROP DEFAULT,
ALTER COLUMN "bull_name" SET DATA TYPE TEXT,
ALTER COLUMN "semen_code" SET DATA TYPE TEXT;

-- AlterTable
ALTER TABLE "public"."animal_calving" ALTER COLUMN "id" DROP DEFAULT;

-- AlterTable
ALTER TABLE "public"."animal_health" ADD COLUMN     "vet_first_name" TEXT,
ADD COLUMN     "vet_last_name" TEXT,
ADD COLUMN     "vet_phone" TEXT,
ADD COLUMN     "vet_user_id" UUID,
ALTER COLUMN "id" DROP DEFAULT;

-- AlterTable
ALTER TABLE "public"."animal_weights" ALTER COLUMN "id" DROP DEFAULT;

-- AlterTable
ALTER TABLE "public"."animals" ALTER COLUMN "id" DROP DEFAULT;

-- AlterTable
ALTER TABLE "public"."api_keys" ADD COLUMN     "account_id" UUID,
ADD COLUMN     "created_by_user_id" UUID,
ADD COLUMN     "description" TEXT,
ADD COLUMN     "key_hash" TEXT,
ADD COLUMN     "last_used_at" TIMESTAMP(3),
ADD COLUMN     "rate_limit" INTEGER NOT NULL DEFAULT 1000,
ADD COLUMN     "request_count" INTEGER NOT NULL DEFAULT 0,
ADD COLUMN     "scopes" TEXT[] DEFAULT ARRAY[]::TEXT[];

-- AlterTable
ALTER TABLE "public"."breeds" ALTER COLUMN "id" DROP DEFAULT,
ALTER COLUMN "name" SET DATA TYPE TEXT,
ALTER COLUMN "code" SET DATA TYPE TEXT;

-- AlterTable
ALTER TABLE "public"."charge_applications" ALTER COLUMN "id" DROP DEFAULT;

-- AlterTable
ALTER TABLE "public"."charge_suppliers" ALTER COLUMN "id" DROP DEFAULT;

-- AlterTable
ALTER TABLE "public"."charges" ALTER COLUMN "id" DROP DEFAULT;

-- AlterTable
ALTER TABLE "public"."farms" ALTER COLUMN "id" DROP DEFAULT;

-- AlterTable
ALTER TABLE "public"."feed_comments" ADD COLUMN     "likes_count" INTEGER NOT NULL DEFAULT 0,
ADD COLUMN     "parent_comment_id" UUID,
ADD COLUMN     "status" "public"."FeedPostStatus" NOT NULL DEFAULT 'active';

-- AlterTable
ALTER TABLE "public"."inventory_movements" ALTER COLUMN "id" DROP DEFAULT;

-- AlterTable
ALTER TABLE "public"."inventory_sales" ALTER COLUMN "id" DROP DEFAULT,
ALTER COLUMN "updated_at" DROP DEFAULT;

-- AlterTable
ALTER TABLE "public"."locations" ALTER COLUMN "id" DROP DEFAULT;

-- AlterTable
ALTER TABLE "public"."milk_productions" ALTER COLUMN "id" DROP DEFAULT;

-- AlterTable
ALTER TABLE "public"."milk_sales" ALTER COLUMN "payment_status" SET DATA TYPE TEXT;

-- AlterTable
ALTER TABLE "public"."payroll_payslips" DROP COLUMN "employee_id",
DROP COLUMN "gross_salary",
DROP COLUMN "net_salary",
ALTER COLUMN "milk_sales_count" SET NOT NULL;

-- AlterTable
ALTER TABLE "public"."payroll_suppliers" ALTER COLUMN "id" DROP DEFAULT,
ALTER COLUMN "updated_at" DROP DEFAULT;

-- AlterTable
ALTER TABLE "public"."products" ALTER COLUMN "is_listed_in_marketplace" SET NOT NULL;

-- DropTable
DROP TABLE "public"."payroll_employees";

-- CreateIndex
CREATE INDEX "animal_health_vet_user_id_idx" ON "public"."animal_health"("vet_user_id");

-- CreateIndex
CREATE INDEX "api_keys_key_hash_idx" ON "public"."api_keys"("key_hash");

-- CreateIndex
CREATE INDEX "api_keys_account_id_idx" ON "public"."api_keys"("account_id");

-- CreateIndex
CREATE INDEX "api_keys_created_by_user_id_idx" ON "public"."api_keys"("created_by_user_id");

-- CreateIndex
CREATE INDEX "feed_comments_parent_comment_id_idx" ON "public"."feed_comments"("parent_comment_id");

-- CreateIndex
CREATE UNIQUE INDEX "users_phone_key" ON "public"."users"("phone");

-- CreateIndex
CREATE UNIQUE INDEX "users_referral_code_key" ON "public"."users"("referral_code");

-- AddForeignKey
ALTER TABLE "public"."feed_comments" ADD CONSTRAINT "feed_comments_parent_comment_id_fkey" FOREIGN KEY ("parent_comment_id") REFERENCES "public"."feed_comments"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "public"."api_keys" ADD CONSTRAINT "api_keys_account_id_fkey" FOREIGN KEY ("account_id") REFERENCES "public"."accounts"("id") ON DELETE SET NULL ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "public"."api_keys" ADD CONSTRAINT "api_keys_created_by_user_id_fkey" FOREIGN KEY ("created_by_user_id") REFERENCES "public"."users"("id") ON DELETE SET NULL ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "public"."payroll_runs" ADD CONSTRAINT "payroll_runs_period_id_fkey" FOREIGN KEY ("period_id") REFERENCES "public"."payroll_periods"("id") ON DELETE SET NULL ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "public"."animal_health" ADD CONSTRAINT "animal_health_vet_user_id_fkey" FOREIGN KEY ("vet_user_id") REFERENCES "public"."users"("id") ON DELETE SET NULL ON UPDATE CASCADE;
