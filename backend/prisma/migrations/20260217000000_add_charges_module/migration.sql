-- AlterTable: add charge_id to payroll_deductions
ALTER TABLE "payroll_deductions" ADD COLUMN IF NOT EXISTS "charge_id" UUID;

-- CreateTable: charges
CREATE TABLE "charges" (
    "id" UUID NOT NULL DEFAULT gen_random_uuid(),
    "customer_account_id" UUID NOT NULL,
    "name" TEXT NOT NULL,
    "description" TEXT,
    "kind" TEXT NOT NULL,
    "amount_type" TEXT NOT NULL,
    "amount" DECIMAL(10,2) NOT NULL,
    "recurrence" TEXT,
    "apply_to_all_suppliers" BOOLEAN NOT NULL DEFAULT true,
    "effective_from" TIMESTAMP(3),
    "effective_to" TIMESTAMP(3),
    "is_active" BOOLEAN NOT NULL DEFAULT true,
    "created_at" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updated_at" TIMESTAMP(3) NOT NULL,
    "created_by" UUID,

    CONSTRAINT "charges_pkey" PRIMARY KEY ("id")
);

-- CreateTable: charge_suppliers
CREATE TABLE "charge_suppliers" (
    "id" UUID NOT NULL DEFAULT gen_random_uuid(),
    "charge_id" UUID NOT NULL,
    "supplier_account_id" UUID NOT NULL,
    "created_at" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "charge_suppliers_pkey" PRIMARY KEY ("id")
);

-- CreateTable: charge_applications
CREATE TABLE "charge_applications" (
    "id" UUID NOT NULL DEFAULT gen_random_uuid(),
    "charge_id" UUID NOT NULL,
    "supplier_account_id" UUID NOT NULL,
    "payslip_id" UUID NOT NULL,
    "amount" DECIMAL(10,2) NOT NULL,
    "applied_at" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "charge_applications_pkey" PRIMARY KEY ("id")
);

-- CreateIndex
CREATE INDEX "charges_customer_account_id_idx" ON "charges"("customer_account_id");
CREATE INDEX "charges_is_active_idx" ON "charges"("is_active");
CREATE INDEX "charges_kind_idx" ON "charges"("kind");
CREATE INDEX "charges_effective_from_idx" ON "charges"("effective_from");
CREATE INDEX "charges_effective_to_idx" ON "charges"("effective_to");

CREATE UNIQUE INDEX "charge_suppliers_charge_id_supplier_account_id_key" ON "charge_suppliers"("charge_id", "supplier_account_id");
CREATE INDEX "charge_suppliers_charge_id_idx" ON "charge_suppliers"("charge_id");
CREATE INDEX "charge_suppliers_supplier_account_id_idx" ON "charge_suppliers"("supplier_account_id");

CREATE UNIQUE INDEX "charge_applications_charge_id_supplier_account_id_key" ON "charge_applications"("charge_id", "supplier_account_id");
CREATE INDEX "charge_applications_charge_id_idx" ON "charge_applications"("charge_id");
CREATE INDEX "charge_applications_supplier_account_id_idx" ON "charge_applications"("supplier_account_id");
CREATE INDEX "charge_applications_payslip_id_idx" ON "charge_applications"("payslip_id");

CREATE INDEX "payroll_deductions_charge_id_idx" ON "payroll_deductions"("charge_id");

-- AddForeignKey: charges -> accounts
ALTER TABLE "charges" ADD CONSTRAINT "charges_customer_account_id_fkey" FOREIGN KEY ("customer_account_id") REFERENCES "accounts"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey: charge_suppliers
ALTER TABLE "charge_suppliers" ADD CONSTRAINT "charge_suppliers_charge_id_fkey" FOREIGN KEY ("charge_id") REFERENCES "charges"("id") ON DELETE CASCADE ON UPDATE CASCADE;
ALTER TABLE "charge_suppliers" ADD CONSTRAINT "charge_suppliers_supplier_account_id_fkey" FOREIGN KEY ("supplier_account_id") REFERENCES "accounts"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey: charge_applications
ALTER TABLE "charge_applications" ADD CONSTRAINT "charge_applications_charge_id_fkey" FOREIGN KEY ("charge_id") REFERENCES "charges"("id") ON DELETE CASCADE ON UPDATE CASCADE;
ALTER TABLE "charge_applications" ADD CONSTRAINT "charge_applications_supplier_account_id_fkey" FOREIGN KEY ("supplier_account_id") REFERENCES "accounts"("id") ON DELETE CASCADE ON UPDATE CASCADE;
ALTER TABLE "charge_applications" ADD CONSTRAINT "charge_applications_payslip_id_fkey" FOREIGN KEY ("payslip_id") REFERENCES "payroll_payslips"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey: payroll_deductions.charge_id
ALTER TABLE "payroll_deductions" ADD CONSTRAINT "payroll_deductions_charge_id_fkey" FOREIGN KEY ("charge_id") REFERENCES "charges"("id") ON DELETE SET NULL ON UPDATE CASCADE;
