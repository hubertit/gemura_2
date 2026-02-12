-- CreateTable
CREATE TABLE "loan_repayments" (
    "id" UUID NOT NULL,
    "loan_id" UUID NOT NULL,
    "amount" DECIMAL(15,2) NOT NULL,
    "repayment_date" TIMESTAMP(3) NOT NULL,
    "notes" TEXT,
    "source" TEXT NOT NULL DEFAULT 'direct',
    "created_at" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "loan_repayments_pkey" PRIMARY KEY ("id")
);

-- CreateIndex
CREATE INDEX "loan_repayments_loan_id_idx" ON "loan_repayments"("loan_id");

-- CreateIndex
CREATE INDEX "loan_repayments_repayment_date_idx" ON "loan_repayments"("repayment_date");

-- AddForeignKey
ALTER TABLE "loan_repayments" ADD CONSTRAINT "loan_repayments_loan_id_fkey" FOREIGN KEY ("loan_id") REFERENCES "loans"("id") ON DELETE CASCADE ON UPDATE CASCADE;
