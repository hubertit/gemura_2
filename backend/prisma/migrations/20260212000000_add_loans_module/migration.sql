-- CreateTable
CREATE TABLE "loans" (
    "id" UUID NOT NULL,
    "lender_account_id" UUID NOT NULL,
    "borrower_type" TEXT NOT NULL,
    "borrower_account_id" UUID,
    "borrower_name" TEXT,
    "principal" DECIMAL(15,2) NOT NULL,
    "amount_repaid" DECIMAL(15,2) NOT NULL DEFAULT 0,
    "currency" TEXT NOT NULL DEFAULT 'RWF',
    "status" TEXT NOT NULL DEFAULT 'active',
    "disbursement_date" TIMESTAMP(3) NOT NULL,
    "due_date" TIMESTAMP(3),
    "notes" TEXT,
    "created_at" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updated_at" TIMESTAMP(3) NOT NULL,
    "created_by" UUID,

    CONSTRAINT "loans_pkey" PRIMARY KEY ("id")
);

-- Add loan_id to payroll_deductions
ALTER TABLE "payroll_deductions" ADD COLUMN "loan_id" UUID;

-- CreateIndex
CREATE INDEX "loans_lender_account_id_idx" ON "loans"("lender_account_id");
CREATE INDEX "loans_borrower_account_id_idx" ON "loans"("borrower_account_id");
CREATE INDEX "loans_borrower_type_idx" ON "loans"("borrower_type");
CREATE INDEX "loans_status_idx" ON "loans"("status");
CREATE INDEX "loans_disbursement_date_idx" ON "loans"("disbursement_date");
CREATE INDEX "payroll_deductions_loan_id_idx" ON "payroll_deductions"("loan_id");

-- AddForeignKey
ALTER TABLE "loans" ADD CONSTRAINT "loans_lender_account_id_fkey" FOREIGN KEY ("lender_account_id") REFERENCES "accounts"("id") ON DELETE CASCADE ON UPDATE CASCADE;
ALTER TABLE "loans" ADD CONSTRAINT "loans_borrower_account_id_fkey" FOREIGN KEY ("borrower_account_id") REFERENCES "accounts"("id") ON DELETE SET NULL ON UPDATE CASCADE;
ALTER TABLE "loans" ADD CONSTRAINT "loans_created_by_fkey" FOREIGN KEY ("created_by") REFERENCES "users"("id") ON DELETE SET NULL ON UPDATE CASCADE;
ALTER TABLE "payroll_deductions" ADD CONSTRAINT "payroll_deductions_loan_id_fkey" FOREIGN KEY ("loan_id") REFERENCES "loans"("id") ON DELETE SET NULL ON UPDATE CASCADE;
