-- CreateSchema
CREATE SCHEMA IF NOT EXISTS "public";

-- CreateEnum
CREATE TYPE "public"."AccountType" AS ENUM ('tenant', 'branch');

-- CreateEnum
CREATE TYPE "public"."AccountStatus" AS ENUM ('active', 'inactive');

-- CreateEnum
CREATE TYPE "public"."UserStatus" AS ENUM ('active', 'inactive');

-- CreateEnum
CREATE TYPE "public"."UserAccountType" AS ENUM ('mcc', 'agent', 'collector', 'veterinarian', 'supplier', 'customer', 'farmer', 'owner');

-- CreateEnum
CREATE TYPE "public"."UserAccountRole" AS ENUM ('owner', 'admin', 'manager', 'collector', 'supplier', 'customer', 'agent', 'viewer');

-- CreateEnum
CREATE TYPE "public"."UserAccountStatus" AS ENUM ('active', 'inactive');

-- CreateEnum
CREATE TYPE "public"."KycStatus" AS ENUM ('pending', 'verified', 'rejected');

-- CreateEnum
CREATE TYPE "public"."RegistrationType" AS ENUM ('self', 'referred', 'onboarded');

-- CreateEnum
CREATE TYPE "public"."MilkSaleStatus" AS ENUM ('pending', 'accepted', 'rejected', 'cancelled', 'deleted');

-- CreateEnum
CREATE TYPE "public"."RelationshipStatus" AS ENUM ('active', 'inactive');

-- CreateEnum
CREATE TYPE "public"."WalletType" AS ENUM ('saving', 'regular');

-- CreateEnum
CREATE TYPE "public"."WalletStatus" AS ENUM ('active', 'inactive');

-- CreateEnum
CREATE TYPE "public"."OrderStatus" AS ENUM ('pending', 'processing', 'shipped', 'delivered', 'cancelled', 'returned');

-- CreateEnum
CREATE TYPE "public"."ProductStatus" AS ENUM ('active', 'inactive', 'out_of_stock');

-- CreateEnum
CREATE TYPE "public"."FeedPostStatus" AS ENUM ('active', 'inactive', 'deleted');

-- CreateEnum
CREATE TYPE "public"."FeedStoryStatus" AS ENUM ('active', 'inactive', 'expired');

-- CreateEnum
CREATE TYPE "public"."InteractionType" AS ENUM ('like', 'share', 'comment', 'bookmark');

-- CreateEnum
CREATE TYPE "public"."NotificationType" AS ENUM ('info', 'warning', 'error', 'success');

-- CreateEnum
CREATE TYPE "public"."NotificationStatus" AS ENUM ('unread', 'read', 'archived');

-- CreateTable
CREATE TABLE "public"."accounts" (
    "id" UUID NOT NULL,
    "legacy_id" BIGINT,
    "code" TEXT,
    "name" TEXT NOT NULL,
    "type" "public"."AccountType" NOT NULL DEFAULT 'tenant',
    "parent_id" UUID,
    "status" "public"."AccountStatus" NOT NULL DEFAULT 'active',
    "created_at" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updated_at" TIMESTAMP(3) NOT NULL,
    "created_by" UUID,
    "updated_by" UUID,

    CONSTRAINT "accounts_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "public"."users" (
    "id" UUID NOT NULL,
    "legacy_id" BIGINT,
    "code" TEXT,
    "name" TEXT NOT NULL,
    "phone" TEXT,
    "email" TEXT,
    "nid" TEXT,
    "address" TEXT,
    "password_hash" TEXT NOT NULL,
    "token" TEXT,
    "last_login" TIMESTAMP(3),
    "last_login_ip" TEXT,
    "last_login_device" TEXT,
    "status" "public"."UserStatus" NOT NULL DEFAULT 'active',
    "default_account_id" UUID,
    "province" TEXT,
    "district" TEXT,
    "sector" TEXT,
    "cell" TEXT,
    "village" TEXT,
    "id_number" TEXT,
    "id_front_photo_url" TEXT,
    "id_back_photo_url" TEXT,
    "selfie_photo_url" TEXT,
    "kyc_status" "public"."KycStatus" NOT NULL DEFAULT 'pending',
    "kyc_verified_at" TIMESTAMP(3),
    "kyc_verified_by" UUID,
    "kyc_rejection_reason" TEXT,
    "account_type" "public"."UserAccountType" NOT NULL DEFAULT 'mcc',
    "referred_by" INTEGER,
    "onboarded_by" INTEGER,
    "referral_code" TEXT,
    "referral_count" INTEGER NOT NULL DEFAULT 0,
    "onboarded_count" INTEGER NOT NULL DEFAULT 0,
    "total_points" INTEGER NOT NULL DEFAULT 0,
    "available_points" INTEGER NOT NULL DEFAULT 0,
    "registration_type" "public"."RegistrationType" NOT NULL DEFAULT 'self',
    "created_at" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updated_at" TIMESTAMP(3) NOT NULL,
    "created_by" UUID,
    "updated_by" UUID,

    CONSTRAINT "users_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "public"."user_accounts" (
    "id" UUID NOT NULL,
    "legacy_id" BIGINT,
    "user_id" UUID NOT NULL,
    "account_id" UUID NOT NULL,
    "role" "public"."UserAccountRole" NOT NULL DEFAULT 'supplier',
    "permissions" JSONB,
    "status" "public"."UserAccountStatus" NOT NULL DEFAULT 'active',
    "created_at" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "created_by" UUID,
    "updated_by" UUID,

    CONSTRAINT "user_accounts_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "public"."suppliers_customers" (
    "id" UUID NOT NULL,
    "legacy_id" BIGINT,
    "supplier_account_id" UUID NOT NULL,
    "customer_account_id" UUID NOT NULL,
    "price_per_liter" DECIMAL(10,2) NOT NULL,
    "average_supply_quantity" DECIMAL(10,2) NOT NULL DEFAULT 0,
    "relationship_status" "public"."RelationshipStatus" NOT NULL DEFAULT 'active',
    "created_at" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updated_at" TIMESTAMP(3) NOT NULL,
    "created_by" UUID,
    "updated_by" UUID,

    CONSTRAINT "suppliers_customers_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "public"."milk_sales" (
    "id" UUID NOT NULL,
    "legacy_id" INTEGER,
    "supplier_account_id" UUID NOT NULL,
    "customer_account_id" UUID NOT NULL,
    "quantity" DECIMAL(10,2) NOT NULL,
    "unit_price" DECIMAL(10,2) NOT NULL,
    "status" "public"."MilkSaleStatus" NOT NULL DEFAULT 'pending',
    "sale_at" TIMESTAMP(3) NOT NULL,
    "notes" TEXT,
    "recorded_by" UUID NOT NULL,
    "created_at" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updated_at" TIMESTAMP(3) NOT NULL,
    "created_by" UUID,
    "updated_by" UUID,

    CONSTRAINT "milk_sales_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "public"."products" (
    "id" UUID NOT NULL,
    "legacy_id" BIGINT,
    "name" TEXT NOT NULL,
    "description" TEXT,
    "price" DECIMAL(10,2) NOT NULL,
    "stock_quantity" INTEGER NOT NULL DEFAULT 0,
    "status" "public"."ProductStatus" NOT NULL DEFAULT 'active',
    "created_at" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updated_at" TIMESTAMP(3) NOT NULL,
    "created_by" UUID,
    "updated_by" UUID,

    CONSTRAINT "products_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "public"."product_categories" (
    "id" UUID NOT NULL,
    "legacy_id" BIGINT,
    "product_id" UUID NOT NULL,
    "category_id" UUID NOT NULL,
    "created_at" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "product_categories_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "public"."product_images" (
    "id" UUID NOT NULL,
    "legacy_id" BIGINT,
    "product_id" UUID NOT NULL,
    "image_url" TEXT NOT NULL,
    "is_primary" BOOLEAN NOT NULL DEFAULT false,
    "sort_order" INTEGER NOT NULL DEFAULT 0,
    "created_at" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "product_images_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "public"."categories" (
    "id" UUID NOT NULL,
    "legacy_id" BIGINT,
    "name" TEXT NOT NULL,
    "description" TEXT,
    "created_at" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updated_at" TIMESTAMP(3) NOT NULL,

    CONSTRAINT "categories_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "public"."orders" (
    "id" UUID NOT NULL,
    "legacy_id" BIGINT,
    "customer_id" UUID,
    "seller_id" UUID,
    "account_id" UUID NOT NULL,
    "total_amount" DECIMAL(10,2) NOT NULL,
    "status" "public"."OrderStatus" NOT NULL DEFAULT 'pending',
    "shipping_address" TEXT,
    "created_at" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updated_at" TIMESTAMP(3) NOT NULL,

    CONSTRAINT "orders_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "public"."order_items" (
    "id" UUID NOT NULL,
    "legacy_id" BIGINT,
    "order_id" UUID NOT NULL,
    "product_id" UUID NOT NULL,
    "quantity" INTEGER NOT NULL,
    "price" DECIMAL(10,2) NOT NULL,
    "created_at" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "order_items_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "public"."wallets" (
    "id" UUID NOT NULL,
    "legacy_id" BIGINT,
    "account_id" UUID NOT NULL,
    "code" TEXT,
    "type" "public"."WalletType" NOT NULL DEFAULT 'regular',
    "is_joint" BOOLEAN NOT NULL DEFAULT false,
    "balance" DECIMAL(15,2) NOT NULL DEFAULT 0,
    "currency" TEXT NOT NULL DEFAULT 'RWF',
    "status" "public"."WalletStatus" NOT NULL DEFAULT 'active',
    "is_default" BOOLEAN NOT NULL DEFAULT false,
    "created_at" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updated_at" TIMESTAMP(3) NOT NULL,
    "created_by" UUID,
    "updated_by" UUID,

    CONSTRAINT "wallets_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "public"."feed_posts" (
    "id" UUID NOT NULL,
    "legacy_id" BIGINT,
    "user_id" UUID NOT NULL,
    "content" TEXT,
    "media_url" TEXT,
    "hashtags" TEXT,
    "location" TEXT,
    "likes_count" INTEGER NOT NULL DEFAULT 0,
    "shares_count" INTEGER NOT NULL DEFAULT 0,
    "bookmarks_count" INTEGER NOT NULL DEFAULT 0,
    "status" "public"."FeedPostStatus" NOT NULL DEFAULT 'active',
    "created_at" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updated_at" TIMESTAMP(3) NOT NULL,
    "created_by" UUID,
    "updated_by" UUID,

    CONSTRAINT "feed_posts_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "public"."feed_stories" (
    "id" UUID NOT NULL,
    "legacy_id" BIGINT,
    "user_id" UUID NOT NULL,
    "media_url" TEXT,
    "content" TEXT,
    "expires_at" TIMESTAMP(3) NOT NULL,
    "views_count" INTEGER NOT NULL DEFAULT 0,
    "status" "public"."FeedStoryStatus" NOT NULL DEFAULT 'active',
    "created_at" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "created_by" UUID,
    "updated_by" UUID,

    CONSTRAINT "feed_stories_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "public"."feed_comments" (
    "id" UUID NOT NULL,
    "legacy_id" BIGINT,
    "post_id" UUID NOT NULL,
    "user_id" UUID NOT NULL,
    "content" TEXT NOT NULL,
    "created_at" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updated_at" TIMESTAMP(3) NOT NULL,

    CONSTRAINT "feed_comments_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "public"."feed_interactions" (
    "id" UUID NOT NULL,
    "legacy_id" BIGINT,
    "user_id" UUID NOT NULL,
    "post_id" UUID,
    "story_id" UUID,
    "interaction_type" "public"."InteractionType" NOT NULL,
    "created_at" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "feed_interactions_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "public"."feed_post_categories" (
    "id" UUID NOT NULL,
    "post_id" UUID NOT NULL,
    "category_id" UUID NOT NULL,
    "created_at" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "feed_post_categories_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "public"."user_bookmarks" (
    "id" UUID NOT NULL,
    "legacy_id" BIGINT,
    "user_id" UUID NOT NULL,
    "post_id" UUID NOT NULL,
    "created_at" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "user_bookmarks_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "public"."user_relationships" (
    "id" UUID NOT NULL,
    "legacy_id" BIGINT,
    "follower_id" UUID NOT NULL,
    "following_id" UUID NOT NULL,
    "created_at" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "user_relationships_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "public"."notifications" (
    "id" UUID NOT NULL,
    "legacy_id" BIGINT,
    "user_id" UUID NOT NULL,
    "title" TEXT NOT NULL,
    "message" TEXT NOT NULL,
    "type" "public"."NotificationType" NOT NULL DEFAULT 'info',
    "status" "public"."NotificationStatus" NOT NULL DEFAULT 'unread',
    "read_at" TIMESTAMP(3),
    "created_at" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "notifications_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "public"."api_keys" (
    "id" UUID NOT NULL,
    "legacy_id" BIGINT,
    "key" TEXT NOT NULL,
    "name" TEXT,
    "is_active" BOOLEAN NOT NULL DEFAULT true,
    "expires_at" TIMESTAMP(3),
    "created_at" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updated_at" TIMESTAMP(3) NOT NULL,

    CONSTRAINT "api_keys_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "public"."password_resets" (
    "id" UUID NOT NULL,
    "legacy_id" BIGINT,
    "user_id" UUID NOT NULL,
    "token" TEXT NOT NULL,
    "expires_at" TIMESTAMP(3) NOT NULL,
    "used_at" TIMESTAMP(3),
    "created_at" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "password_resets_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "public"."user_onboardings" (
    "id" UUID NOT NULL,
    "legacy_id" BIGINT,
    "user_id" UUID NOT NULL,
    "step" TEXT NOT NULL,
    "completed" BOOLEAN NOT NULL DEFAULT false,
    "created_at" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updated_at" TIMESTAMP(3) NOT NULL,

    CONSTRAINT "user_onboardings_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "public"."user_points" (
    "id" UUID NOT NULL,
    "legacy_id" BIGINT,
    "user_id" UUID NOT NULL,
    "points" INTEGER NOT NULL,
    "reason" TEXT,
    "created_at" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "user_points_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "public"."user_referrals" (
    "id" UUID NOT NULL,
    "legacy_id" BIGINT,
    "referrer_id" UUID NOT NULL,
    "referred_id" UUID NOT NULL,
    "created_at" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "user_referrals_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "public"."user_rewards" (
    "id" UUID NOT NULL,
    "legacy_id" BIGINT,
    "user_id" UUID NOT NULL,
    "reward_type" TEXT NOT NULL,
    "amount" DECIMAL(10,2),
    "points" INTEGER,
    "description" TEXT,
    "created_at" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "user_rewards_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "public"."chart_of_accounts" (
    "id" UUID NOT NULL,
    "code" TEXT NOT NULL,
    "name" TEXT NOT NULL,
    "account_type" TEXT NOT NULL,
    "parent_id" UUID,
    "is_active" BOOLEAN NOT NULL DEFAULT true,
    "created_at" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updated_at" TIMESTAMP(3) NOT NULL,

    CONSTRAINT "chart_of_accounts_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "public"."accounting_transactions" (
    "id" UUID NOT NULL,
    "transaction_date" TIMESTAMP(3) NOT NULL,
    "reference_number" TEXT,
    "description" TEXT,
    "total_amount" DECIMAL(15,2) NOT NULL,
    "created_at" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "created_by" UUID,

    CONSTRAINT "accounting_transactions_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "public"."accounting_transaction_entries" (
    "id" UUID NOT NULL,
    "transaction_id" UUID NOT NULL,
    "account_id" UUID NOT NULL,
    "debit_amount" DECIMAL(15,2),
    "credit_amount" DECIMAL(15,2),
    "description" TEXT,
    "created_at" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "accounting_transaction_entries_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "public"."supplier_ledger" (
    "id" UUID NOT NULL,
    "supplier_account_id" UUID NOT NULL,
    "transaction_id" UUID,
    "milk_sale_id" UUID,
    "entry_type" TEXT NOT NULL,
    "amount" DECIMAL(15,2) NOT NULL,
    "balance" DECIMAL(15,2) NOT NULL,
    "description" TEXT,
    "created_at" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "supplier_ledger_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "public"."fee_types" (
    "id" UUID NOT NULL,
    "code" TEXT NOT NULL,
    "name" TEXT NOT NULL,
    "description" TEXT,
    "fee_category" TEXT NOT NULL,
    "calculation_type" TEXT NOT NULL,
    "is_active" BOOLEAN NOT NULL DEFAULT true,
    "created_at" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updated_at" TIMESTAMP(3) NOT NULL,

    CONSTRAINT "fee_types_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "public"."supplier_fee_rules" (
    "id" UUID NOT NULL,
    "supplier_account_id" UUID NOT NULL,
    "fee_type_id" UUID NOT NULL,
    "fixed_amount" DECIMAL(10,2),
    "percentage" DECIMAL(5,2),
    "min_amount" DECIMAL(10,2),
    "max_amount" DECIMAL(10,2),
    "is_active" BOOLEAN NOT NULL DEFAULT true,
    "effective_from" TIMESTAMP(3) NOT NULL,
    "effective_to" TIMESTAMP(3),
    "created_at" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updated_at" TIMESTAMP(3) NOT NULL,

    CONSTRAINT "supplier_fee_rules_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "public"."supplier_deductions" (
    "id" UUID NOT NULL,
    "supplier_account_id" UUID NOT NULL,
    "fee_type_id" UUID NOT NULL,
    "milk_sale_id" UUID,
    "amount" DECIMAL(10,2) NOT NULL,
    "description" TEXT,
    "applied_at" TIMESTAMP(3) NOT NULL,
    "created_at" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "supplier_deductions_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "public"."invoices" (
    "id" UUID NOT NULL,
    "invoice_number" TEXT NOT NULL,
    "supplier_account_id" UUID NOT NULL,
    "issue_date" TIMESTAMP(3) NOT NULL,
    "due_date" TIMESTAMP(3),
    "total_amount" DECIMAL(15,2) NOT NULL,
    "tax_amount" DECIMAL(15,2) DEFAULT 0,
    "status" TEXT NOT NULL,
    "created_at" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updated_at" TIMESTAMP(3) NOT NULL,
    "created_by" UUID,

    CONSTRAINT "invoices_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "public"."invoice_items" (
    "id" UUID NOT NULL,
    "invoice_id" UUID NOT NULL,
    "description" TEXT NOT NULL,
    "quantity" DECIMAL(10,2),
    "unit_price" DECIMAL(10,2) NOT NULL,
    "total_amount" DECIMAL(10,2) NOT NULL,
    "created_at" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "invoice_items_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "public"."receipts" (
    "id" UUID NOT NULL,
    "receipt_number" TEXT NOT NULL,
    "supplier_account_id" UUID,
    "customer_account_id" UUID,
    "payment_date" TIMESTAMP(3) NOT NULL,
    "amount" DECIMAL(15,2) NOT NULL,
    "payment_method" TEXT,
    "reference" TEXT,
    "created_at" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "created_by" UUID,

    CONSTRAINT "receipts_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "public"."audit_logs" (
    "id" UUID NOT NULL,
    "entity_type" TEXT NOT NULL,
    "entity_id" TEXT NOT NULL,
    "action" TEXT NOT NULL,
    "user_id" UUID,
    "changes" JSONB,
    "ip_address" TEXT,
    "user_agent" TEXT,
    "created_at" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "audit_logs_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "public"."payroll_employees" (
    "id" UUID NOT NULL,
    "user_id" UUID,
    "account_id" UUID,
    "employee_number" TEXT NOT NULL,
    "position" TEXT,
    "department" TEXT,
    "salary" DECIMAL(15,2) NOT NULL,
    "employment_type" TEXT NOT NULL,
    "hire_date" TIMESTAMP(3) NOT NULL,
    "is_active" BOOLEAN NOT NULL DEFAULT true,
    "created_at" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updated_at" TIMESTAMP(3) NOT NULL,

    CONSTRAINT "payroll_employees_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "public"."payroll_periods" (
    "id" UUID NOT NULL,
    "period_name" TEXT NOT NULL,
    "start_date" TIMESTAMP(3) NOT NULL,
    "end_date" TIMESTAMP(3) NOT NULL,
    "status" TEXT NOT NULL,
    "created_at" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updated_at" TIMESTAMP(3) NOT NULL,

    CONSTRAINT "payroll_periods_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "public"."payroll_runs" (
    "id" UUID NOT NULL,
    "period_id" UUID NOT NULL,
    "run_date" TIMESTAMP(3) NOT NULL,
    "total_amount" DECIMAL(15,2) NOT NULL,
    "status" TEXT NOT NULL,
    "created_at" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updated_at" TIMESTAMP(3) NOT NULL,
    "created_by" UUID,

    CONSTRAINT "payroll_runs_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "public"."payroll_payslips" (
    "id" UUID NOT NULL,
    "run_id" UUID NOT NULL,
    "employee_id" UUID NOT NULL,
    "gross_salary" DECIMAL(15,2) NOT NULL,
    "total_deductions" DECIMAL(15,2) NOT NULL,
    "net_salary" DECIMAL(15,2) NOT NULL,
    "status" TEXT NOT NULL,
    "created_at" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updated_at" TIMESTAMP(3) NOT NULL,

    CONSTRAINT "payroll_payslips_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "public"."payroll_deductions" (
    "id" UUID NOT NULL,
    "payslip_id" UUID NOT NULL,
    "deduction_type" TEXT NOT NULL,
    "amount" DECIMAL(10,2) NOT NULL,
    "description" TEXT,
    "created_at" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "payroll_deductions_pkey" PRIMARY KEY ("id")
);

-- CreateIndex
CREATE UNIQUE INDEX "accounts_legacy_id_key" ON "public"."accounts"("legacy_id");

-- CreateIndex
CREATE UNIQUE INDEX "accounts_code_key" ON "public"."accounts"("code");

-- CreateIndex
CREATE INDEX "accounts_code_idx" ON "public"."accounts"("code");

-- CreateIndex
CREATE INDEX "accounts_type_idx" ON "public"."accounts"("type");

-- CreateIndex
CREATE INDEX "accounts_status_idx" ON "public"."accounts"("status");

-- CreateIndex
CREATE INDEX "accounts_parent_id_idx" ON "public"."accounts"("parent_id");

-- CreateIndex
CREATE INDEX "accounts_created_at_idx" ON "public"."accounts"("created_at");

-- CreateIndex
CREATE UNIQUE INDEX "users_legacy_id_key" ON "public"."users"("legacy_id");

-- CreateIndex
CREATE UNIQUE INDEX "users_code_key" ON "public"."users"("code");

-- CreateIndex
CREATE INDEX "users_code_idx" ON "public"."users"("code");

-- CreateIndex
CREATE INDEX "users_phone_idx" ON "public"."users"("phone");

-- CreateIndex
CREATE INDEX "users_email_idx" ON "public"."users"("email");

-- CreateIndex
CREATE INDEX "users_status_idx" ON "public"."users"("status");

-- CreateIndex
CREATE INDEX "users_account_type_idx" ON "public"."users"("account_type");

-- CreateIndex
CREATE INDEX "users_kyc_status_idx" ON "public"."users"("kyc_status");

-- CreateIndex
CREATE INDEX "users_default_account_id_idx" ON "public"."users"("default_account_id");

-- CreateIndex
CREATE INDEX "users_created_at_idx" ON "public"."users"("created_at");

-- CreateIndex
CREATE INDEX "users_last_login_idx" ON "public"."users"("last_login");

-- CreateIndex
CREATE UNIQUE INDEX "user_accounts_legacy_id_key" ON "public"."user_accounts"("legacy_id");

-- CreateIndex
CREATE INDEX "user_accounts_user_id_idx" ON "public"."user_accounts"("user_id");

-- CreateIndex
CREATE INDEX "user_accounts_account_id_idx" ON "public"."user_accounts"("account_id");

-- CreateIndex
CREATE INDEX "user_accounts_role_idx" ON "public"."user_accounts"("role");

-- CreateIndex
CREATE INDEX "user_accounts_status_idx" ON "public"."user_accounts"("status");

-- CreateIndex
CREATE UNIQUE INDEX "user_accounts_user_id_account_id_key" ON "public"."user_accounts"("user_id", "account_id");

-- CreateIndex
CREATE UNIQUE INDEX "suppliers_customers_legacy_id_key" ON "public"."suppliers_customers"("legacy_id");

-- CreateIndex
CREATE INDEX "suppliers_customers_supplier_account_id_idx" ON "public"."suppliers_customers"("supplier_account_id");

-- CreateIndex
CREATE INDEX "suppliers_customers_customer_account_id_idx" ON "public"."suppliers_customers"("customer_account_id");

-- CreateIndex
CREATE INDEX "suppliers_customers_relationship_status_idx" ON "public"."suppliers_customers"("relationship_status");

-- CreateIndex
CREATE UNIQUE INDEX "suppliers_customers_supplier_account_id_customer_account_id_key" ON "public"."suppliers_customers"("supplier_account_id", "customer_account_id");

-- CreateIndex
CREATE UNIQUE INDEX "milk_sales_legacy_id_key" ON "public"."milk_sales"("legacy_id");

-- CreateIndex
CREATE INDEX "milk_sales_supplier_account_id_idx" ON "public"."milk_sales"("supplier_account_id");

-- CreateIndex
CREATE INDEX "milk_sales_customer_account_id_idx" ON "public"."milk_sales"("customer_account_id");

-- CreateIndex
CREATE INDEX "milk_sales_status_idx" ON "public"."milk_sales"("status");

-- CreateIndex
CREATE INDEX "milk_sales_sale_at_idx" ON "public"."milk_sales"("sale_at");

-- CreateIndex
CREATE INDEX "milk_sales_recorded_by_idx" ON "public"."milk_sales"("recorded_by");

-- CreateIndex
CREATE INDEX "milk_sales_created_at_idx" ON "public"."milk_sales"("created_at");

-- CreateIndex
CREATE UNIQUE INDEX "products_legacy_id_key" ON "public"."products"("legacy_id");

-- CreateIndex
CREATE INDEX "products_status_idx" ON "public"."products"("status");

-- CreateIndex
CREATE INDEX "products_created_at_idx" ON "public"."products"("created_at");

-- CreateIndex
CREATE UNIQUE INDEX "product_categories_legacy_id_key" ON "public"."product_categories"("legacy_id");

-- CreateIndex
CREATE INDEX "product_categories_product_id_idx" ON "public"."product_categories"("product_id");

-- CreateIndex
CREATE INDEX "product_categories_category_id_idx" ON "public"."product_categories"("category_id");

-- CreateIndex
CREATE UNIQUE INDEX "product_categories_product_id_category_id_key" ON "public"."product_categories"("product_id", "category_id");

-- CreateIndex
CREATE UNIQUE INDEX "product_images_legacy_id_key" ON "public"."product_images"("legacy_id");

-- CreateIndex
CREATE INDEX "product_images_product_id_idx" ON "public"."product_images"("product_id");

-- CreateIndex
CREATE INDEX "product_images_is_primary_idx" ON "public"."product_images"("is_primary");

-- CreateIndex
CREATE UNIQUE INDEX "categories_legacy_id_key" ON "public"."categories"("legacy_id");

-- CreateIndex
CREATE UNIQUE INDEX "categories_name_key" ON "public"."categories"("name");

-- CreateIndex
CREATE INDEX "categories_name_idx" ON "public"."categories"("name");

-- CreateIndex
CREATE UNIQUE INDEX "orders_legacy_id_key" ON "public"."orders"("legacy_id");

-- CreateIndex
CREATE INDEX "orders_customer_id_idx" ON "public"."orders"("customer_id");

-- CreateIndex
CREATE INDEX "orders_seller_id_idx" ON "public"."orders"("seller_id");

-- CreateIndex
CREATE INDEX "orders_account_id_idx" ON "public"."orders"("account_id");

-- CreateIndex
CREATE INDEX "orders_status_idx" ON "public"."orders"("status");

-- CreateIndex
CREATE INDEX "orders_created_at_idx" ON "public"."orders"("created_at");

-- CreateIndex
CREATE UNIQUE INDEX "order_items_legacy_id_key" ON "public"."order_items"("legacy_id");

-- CreateIndex
CREATE INDEX "order_items_order_id_idx" ON "public"."order_items"("order_id");

-- CreateIndex
CREATE INDEX "order_items_product_id_idx" ON "public"."order_items"("product_id");

-- CreateIndex
CREATE UNIQUE INDEX "wallets_legacy_id_key" ON "public"."wallets"("legacy_id");

-- CreateIndex
CREATE UNIQUE INDEX "wallets_code_key" ON "public"."wallets"("code");

-- CreateIndex
CREATE INDEX "wallets_account_id_idx" ON "public"."wallets"("account_id");

-- CreateIndex
CREATE INDEX "wallets_code_idx" ON "public"."wallets"("code");

-- CreateIndex
CREATE INDEX "wallets_status_idx" ON "public"."wallets"("status");

-- CreateIndex
CREATE INDEX "wallets_is_default_idx" ON "public"."wallets"("is_default");

-- CreateIndex
CREATE UNIQUE INDEX "feed_posts_legacy_id_key" ON "public"."feed_posts"("legacy_id");

-- CreateIndex
CREATE INDEX "feed_posts_user_id_idx" ON "public"."feed_posts"("user_id");

-- CreateIndex
CREATE INDEX "feed_posts_status_idx" ON "public"."feed_posts"("status");

-- CreateIndex
CREATE INDEX "feed_posts_created_at_idx" ON "public"."feed_posts"("created_at");

-- CreateIndex
CREATE UNIQUE INDEX "feed_stories_legacy_id_key" ON "public"."feed_stories"("legacy_id");

-- CreateIndex
CREATE INDEX "feed_stories_user_id_idx" ON "public"."feed_stories"("user_id");

-- CreateIndex
CREATE INDEX "feed_stories_status_idx" ON "public"."feed_stories"("status");

-- CreateIndex
CREATE INDEX "feed_stories_expires_at_idx" ON "public"."feed_stories"("expires_at");

-- CreateIndex
CREATE INDEX "feed_stories_created_at_idx" ON "public"."feed_stories"("created_at");

-- CreateIndex
CREATE UNIQUE INDEX "feed_comments_legacy_id_key" ON "public"."feed_comments"("legacy_id");

-- CreateIndex
CREATE INDEX "feed_comments_post_id_idx" ON "public"."feed_comments"("post_id");

-- CreateIndex
CREATE INDEX "feed_comments_user_id_idx" ON "public"."feed_comments"("user_id");

-- CreateIndex
CREATE INDEX "feed_comments_created_at_idx" ON "public"."feed_comments"("created_at");

-- CreateIndex
CREATE UNIQUE INDEX "feed_interactions_legacy_id_key" ON "public"."feed_interactions"("legacy_id");

-- CreateIndex
CREATE INDEX "feed_interactions_user_id_idx" ON "public"."feed_interactions"("user_id");

-- CreateIndex
CREATE INDEX "feed_interactions_post_id_idx" ON "public"."feed_interactions"("post_id");

-- CreateIndex
CREATE INDEX "feed_interactions_story_id_idx" ON "public"."feed_interactions"("story_id");

-- CreateIndex
CREATE INDEX "feed_interactions_interaction_type_idx" ON "public"."feed_interactions"("interaction_type");

-- CreateIndex
CREATE INDEX "feed_interactions_created_at_idx" ON "public"."feed_interactions"("created_at");

-- CreateIndex
CREATE INDEX "feed_post_categories_post_id_idx" ON "public"."feed_post_categories"("post_id");

-- CreateIndex
CREATE INDEX "feed_post_categories_category_id_idx" ON "public"."feed_post_categories"("category_id");

-- CreateIndex
CREATE UNIQUE INDEX "feed_post_categories_post_id_category_id_key" ON "public"."feed_post_categories"("post_id", "category_id");

-- CreateIndex
CREATE UNIQUE INDEX "user_bookmarks_legacy_id_key" ON "public"."user_bookmarks"("legacy_id");

-- CreateIndex
CREATE INDEX "user_bookmarks_user_id_idx" ON "public"."user_bookmarks"("user_id");

-- CreateIndex
CREATE INDEX "user_bookmarks_post_id_idx" ON "public"."user_bookmarks"("post_id");

-- CreateIndex
CREATE UNIQUE INDEX "user_bookmarks_user_id_post_id_key" ON "public"."user_bookmarks"("user_id", "post_id");

-- CreateIndex
CREATE UNIQUE INDEX "user_relationships_legacy_id_key" ON "public"."user_relationships"("legacy_id");

-- CreateIndex
CREATE INDEX "user_relationships_follower_id_idx" ON "public"."user_relationships"("follower_id");

-- CreateIndex
CREATE INDEX "user_relationships_following_id_idx" ON "public"."user_relationships"("following_id");

-- CreateIndex
CREATE UNIQUE INDEX "user_relationships_follower_id_following_id_key" ON "public"."user_relationships"("follower_id", "following_id");

-- CreateIndex
CREATE UNIQUE INDEX "notifications_legacy_id_key" ON "public"."notifications"("legacy_id");

-- CreateIndex
CREATE INDEX "notifications_user_id_idx" ON "public"."notifications"("user_id");

-- CreateIndex
CREATE INDEX "notifications_status_idx" ON "public"."notifications"("status");

-- CreateIndex
CREATE INDEX "notifications_type_idx" ON "public"."notifications"("type");

-- CreateIndex
CREATE INDEX "notifications_created_at_idx" ON "public"."notifications"("created_at");

-- CreateIndex
CREATE UNIQUE INDEX "api_keys_legacy_id_key" ON "public"."api_keys"("legacy_id");

-- CreateIndex
CREATE UNIQUE INDEX "api_keys_key_key" ON "public"."api_keys"("key");

-- CreateIndex
CREATE INDEX "api_keys_key_idx" ON "public"."api_keys"("key");

-- CreateIndex
CREATE INDEX "api_keys_is_active_idx" ON "public"."api_keys"("is_active");

-- CreateIndex
CREATE UNIQUE INDEX "password_resets_legacy_id_key" ON "public"."password_resets"("legacy_id");

-- CreateIndex
CREATE UNIQUE INDEX "password_resets_token_key" ON "public"."password_resets"("token");

-- CreateIndex
CREATE INDEX "password_resets_user_id_idx" ON "public"."password_resets"("user_id");

-- CreateIndex
CREATE INDEX "password_resets_token_idx" ON "public"."password_resets"("token");

-- CreateIndex
CREATE INDEX "password_resets_expires_at_idx" ON "public"."password_resets"("expires_at");

-- CreateIndex
CREATE UNIQUE INDEX "user_onboardings_legacy_id_key" ON "public"."user_onboardings"("legacy_id");

-- CreateIndex
CREATE INDEX "user_onboardings_user_id_idx" ON "public"."user_onboardings"("user_id");

-- CreateIndex
CREATE INDEX "user_onboardings_step_idx" ON "public"."user_onboardings"("step");

-- CreateIndex
CREATE UNIQUE INDEX "user_points_legacy_id_key" ON "public"."user_points"("legacy_id");

-- CreateIndex
CREATE INDEX "user_points_user_id_idx" ON "public"."user_points"("user_id");

-- CreateIndex
CREATE INDEX "user_points_created_at_idx" ON "public"."user_points"("created_at");

-- CreateIndex
CREATE UNIQUE INDEX "user_referrals_legacy_id_key" ON "public"."user_referrals"("legacy_id");

-- CreateIndex
CREATE INDEX "user_referrals_referrer_id_idx" ON "public"."user_referrals"("referrer_id");

-- CreateIndex
CREATE INDEX "user_referrals_referred_id_idx" ON "public"."user_referrals"("referred_id");

-- CreateIndex
CREATE UNIQUE INDEX "user_referrals_referrer_id_referred_id_key" ON "public"."user_referrals"("referrer_id", "referred_id");

-- CreateIndex
CREATE UNIQUE INDEX "user_rewards_legacy_id_key" ON "public"."user_rewards"("legacy_id");

-- CreateIndex
CREATE INDEX "user_rewards_user_id_idx" ON "public"."user_rewards"("user_id");

-- CreateIndex
CREATE INDEX "user_rewards_reward_type_idx" ON "public"."user_rewards"("reward_type");

-- CreateIndex
CREATE INDEX "user_rewards_created_at_idx" ON "public"."user_rewards"("created_at");

-- CreateIndex
CREATE UNIQUE INDEX "chart_of_accounts_code_key" ON "public"."chart_of_accounts"("code");

-- CreateIndex
CREATE INDEX "chart_of_accounts_code_idx" ON "public"."chart_of_accounts"("code");

-- CreateIndex
CREATE INDEX "chart_of_accounts_account_type_idx" ON "public"."chart_of_accounts"("account_type");

-- CreateIndex
CREATE INDEX "chart_of_accounts_parent_id_idx" ON "public"."chart_of_accounts"("parent_id");

-- CreateIndex
CREATE UNIQUE INDEX "accounting_transactions_reference_number_key" ON "public"."accounting_transactions"("reference_number");

-- CreateIndex
CREATE INDEX "accounting_transactions_transaction_date_idx" ON "public"."accounting_transactions"("transaction_date");

-- CreateIndex
CREATE INDEX "accounting_transactions_reference_number_idx" ON "public"."accounting_transactions"("reference_number");

-- CreateIndex
CREATE INDEX "accounting_transactions_created_at_idx" ON "public"."accounting_transactions"("created_at");

-- CreateIndex
CREATE INDEX "accounting_transaction_entries_transaction_id_idx" ON "public"."accounting_transaction_entries"("transaction_id");

-- CreateIndex
CREATE INDEX "accounting_transaction_entries_account_id_idx" ON "public"."accounting_transaction_entries"("account_id");

-- CreateIndex
CREATE INDEX "supplier_ledger_supplier_account_id_idx" ON "public"."supplier_ledger"("supplier_account_id");

-- CreateIndex
CREATE INDEX "supplier_ledger_transaction_id_idx" ON "public"."supplier_ledger"("transaction_id");

-- CreateIndex
CREATE INDEX "supplier_ledger_milk_sale_id_idx" ON "public"."supplier_ledger"("milk_sale_id");

-- CreateIndex
CREATE INDEX "supplier_ledger_entry_type_idx" ON "public"."supplier_ledger"("entry_type");

-- CreateIndex
CREATE INDEX "supplier_ledger_created_at_idx" ON "public"."supplier_ledger"("created_at");

-- CreateIndex
CREATE UNIQUE INDEX "fee_types_code_key" ON "public"."fee_types"("code");

-- CreateIndex
CREATE INDEX "fee_types_code_idx" ON "public"."fee_types"("code");

-- CreateIndex
CREATE INDEX "fee_types_fee_category_idx" ON "public"."fee_types"("fee_category");

-- CreateIndex
CREATE INDEX "fee_types_is_active_idx" ON "public"."fee_types"("is_active");

-- CreateIndex
CREATE INDEX "supplier_fee_rules_supplier_account_id_idx" ON "public"."supplier_fee_rules"("supplier_account_id");

-- CreateIndex
CREATE INDEX "supplier_fee_rules_fee_type_id_idx" ON "public"."supplier_fee_rules"("fee_type_id");

-- CreateIndex
CREATE INDEX "supplier_fee_rules_is_active_idx" ON "public"."supplier_fee_rules"("is_active");

-- CreateIndex
CREATE INDEX "supplier_fee_rules_effective_from_idx" ON "public"."supplier_fee_rules"("effective_from");

-- CreateIndex
CREATE INDEX "supplier_deductions_supplier_account_id_idx" ON "public"."supplier_deductions"("supplier_account_id");

-- CreateIndex
CREATE INDEX "supplier_deductions_fee_type_id_idx" ON "public"."supplier_deductions"("fee_type_id");

-- CreateIndex
CREATE INDEX "supplier_deductions_milk_sale_id_idx" ON "public"."supplier_deductions"("milk_sale_id");

-- CreateIndex
CREATE INDEX "supplier_deductions_applied_at_idx" ON "public"."supplier_deductions"("applied_at");

-- CreateIndex
CREATE UNIQUE INDEX "invoices_invoice_number_key" ON "public"."invoices"("invoice_number");

-- CreateIndex
CREATE INDEX "invoices_invoice_number_idx" ON "public"."invoices"("invoice_number");

-- CreateIndex
CREATE INDEX "invoices_supplier_account_id_idx" ON "public"."invoices"("supplier_account_id");

-- CreateIndex
CREATE INDEX "invoices_status_idx" ON "public"."invoices"("status");

-- CreateIndex
CREATE INDEX "invoices_issue_date_idx" ON "public"."invoices"("issue_date");

-- CreateIndex
CREATE INDEX "invoice_items_invoice_id_idx" ON "public"."invoice_items"("invoice_id");

-- CreateIndex
CREATE UNIQUE INDEX "receipts_receipt_number_key" ON "public"."receipts"("receipt_number");

-- CreateIndex
CREATE INDEX "receipts_receipt_number_idx" ON "public"."receipts"("receipt_number");

-- CreateIndex
CREATE INDEX "receipts_supplier_account_id_idx" ON "public"."receipts"("supplier_account_id");

-- CreateIndex
CREATE INDEX "receipts_customer_account_id_idx" ON "public"."receipts"("customer_account_id");

-- CreateIndex
CREATE INDEX "receipts_payment_date_idx" ON "public"."receipts"("payment_date");

-- CreateIndex
CREATE INDEX "audit_logs_entity_type_entity_id_idx" ON "public"."audit_logs"("entity_type", "entity_id");

-- CreateIndex
CREATE INDEX "audit_logs_user_id_idx" ON "public"."audit_logs"("user_id");

-- CreateIndex
CREATE INDEX "audit_logs_action_idx" ON "public"."audit_logs"("action");

-- CreateIndex
CREATE INDEX "audit_logs_created_at_idx" ON "public"."audit_logs"("created_at");

-- CreateIndex
CREATE UNIQUE INDEX "payroll_employees_employee_number_key" ON "public"."payroll_employees"("employee_number");

-- CreateIndex
CREATE INDEX "payroll_employees_user_id_idx" ON "public"."payroll_employees"("user_id");

-- CreateIndex
CREATE INDEX "payroll_employees_account_id_idx" ON "public"."payroll_employees"("account_id");

-- CreateIndex
CREATE INDEX "payroll_employees_employee_number_idx" ON "public"."payroll_employees"("employee_number");

-- CreateIndex
CREATE INDEX "payroll_employees_is_active_idx" ON "public"."payroll_employees"("is_active");

-- CreateIndex
CREATE INDEX "payroll_periods_start_date_idx" ON "public"."payroll_periods"("start_date");

-- CreateIndex
CREATE INDEX "payroll_periods_end_date_idx" ON "public"."payroll_periods"("end_date");

-- CreateIndex
CREATE INDEX "payroll_periods_status_idx" ON "public"."payroll_periods"("status");

-- CreateIndex
CREATE INDEX "payroll_runs_period_id_idx" ON "public"."payroll_runs"("period_id");

-- CreateIndex
CREATE INDEX "payroll_runs_status_idx" ON "public"."payroll_runs"("status");

-- CreateIndex
CREATE INDEX "payroll_runs_run_date_idx" ON "public"."payroll_runs"("run_date");

-- CreateIndex
CREATE INDEX "payroll_payslips_run_id_idx" ON "public"."payroll_payslips"("run_id");

-- CreateIndex
CREATE INDEX "payroll_payslips_employee_id_idx" ON "public"."payroll_payslips"("employee_id");

-- CreateIndex
CREATE INDEX "payroll_payslips_status_idx" ON "public"."payroll_payslips"("status");

-- CreateIndex
CREATE INDEX "payroll_deductions_payslip_id_idx" ON "public"."payroll_deductions"("payslip_id");

-- CreateIndex
CREATE INDEX "payroll_deductions_deduction_type_idx" ON "public"."payroll_deductions"("deduction_type");

-- AddForeignKey
ALTER TABLE "public"."accounts" ADD CONSTRAINT "accounts_parent_id_fkey" FOREIGN KEY ("parent_id") REFERENCES "public"."accounts"("id") ON DELETE SET NULL ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "public"."accounts" ADD CONSTRAINT "accounts_created_by_fkey" FOREIGN KEY ("created_by") REFERENCES "public"."users"("id") ON DELETE SET NULL ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "public"."accounts" ADD CONSTRAINT "accounts_updated_by_fkey" FOREIGN KEY ("updated_by") REFERENCES "public"."users"("id") ON DELETE SET NULL ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "public"."users" ADD CONSTRAINT "users_default_account_id_fkey" FOREIGN KEY ("default_account_id") REFERENCES "public"."accounts"("id") ON DELETE SET NULL ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "public"."users" ADD CONSTRAINT "users_created_by_fkey" FOREIGN KEY ("created_by") REFERENCES "public"."users"("id") ON DELETE SET NULL ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "public"."users" ADD CONSTRAINT "users_updated_by_fkey" FOREIGN KEY ("updated_by") REFERENCES "public"."users"("id") ON DELETE SET NULL ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "public"."user_accounts" ADD CONSTRAINT "user_accounts_user_id_fkey" FOREIGN KEY ("user_id") REFERENCES "public"."users"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "public"."user_accounts" ADD CONSTRAINT "user_accounts_account_id_fkey" FOREIGN KEY ("account_id") REFERENCES "public"."accounts"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "public"."suppliers_customers" ADD CONSTRAINT "suppliers_customers_supplier_account_id_fkey" FOREIGN KEY ("supplier_account_id") REFERENCES "public"."accounts"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "public"."suppliers_customers" ADD CONSTRAINT "suppliers_customers_customer_account_id_fkey" FOREIGN KEY ("customer_account_id") REFERENCES "public"."accounts"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "public"."milk_sales" ADD CONSTRAINT "milk_sales_supplier_account_id_fkey" FOREIGN KEY ("supplier_account_id") REFERENCES "public"."accounts"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "public"."milk_sales" ADD CONSTRAINT "milk_sales_customer_account_id_fkey" FOREIGN KEY ("customer_account_id") REFERENCES "public"."accounts"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "public"."milk_sales" ADD CONSTRAINT "milk_sales_recorded_by_fkey" FOREIGN KEY ("recorded_by") REFERENCES "public"."users"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "public"."product_categories" ADD CONSTRAINT "product_categories_product_id_fkey" FOREIGN KEY ("product_id") REFERENCES "public"."products"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "public"."product_categories" ADD CONSTRAINT "product_categories_category_id_fkey" FOREIGN KEY ("category_id") REFERENCES "public"."categories"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "public"."product_images" ADD CONSTRAINT "product_images_product_id_fkey" FOREIGN KEY ("product_id") REFERENCES "public"."products"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "public"."orders" ADD CONSTRAINT "orders_account_id_fkey" FOREIGN KEY ("account_id") REFERENCES "public"."accounts"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "public"."order_items" ADD CONSTRAINT "order_items_order_id_fkey" FOREIGN KEY ("order_id") REFERENCES "public"."orders"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "public"."order_items" ADD CONSTRAINT "order_items_product_id_fkey" FOREIGN KEY ("product_id") REFERENCES "public"."products"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "public"."wallets" ADD CONSTRAINT "wallets_account_id_fkey" FOREIGN KEY ("account_id") REFERENCES "public"."accounts"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "public"."feed_posts" ADD CONSTRAINT "feed_posts_user_id_fkey" FOREIGN KEY ("user_id") REFERENCES "public"."users"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "public"."feed_stories" ADD CONSTRAINT "feed_stories_user_id_fkey" FOREIGN KEY ("user_id") REFERENCES "public"."users"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "public"."feed_comments" ADD CONSTRAINT "feed_comments_post_id_fkey" FOREIGN KEY ("post_id") REFERENCES "public"."feed_posts"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "public"."feed_comments" ADD CONSTRAINT "feed_comments_user_id_fkey" FOREIGN KEY ("user_id") REFERENCES "public"."users"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "public"."feed_interactions" ADD CONSTRAINT "feed_interactions_user_id_fkey" FOREIGN KEY ("user_id") REFERENCES "public"."users"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "public"."feed_interactions" ADD CONSTRAINT "feed_interactions_post_id_fkey" FOREIGN KEY ("post_id") REFERENCES "public"."feed_posts"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "public"."feed_interactions" ADD CONSTRAINT "feed_interactions_story_id_fkey" FOREIGN KEY ("story_id") REFERENCES "public"."feed_stories"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "public"."feed_post_categories" ADD CONSTRAINT "feed_post_categories_post_id_fkey" FOREIGN KEY ("post_id") REFERENCES "public"."feed_posts"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "public"."feed_post_categories" ADD CONSTRAINT "feed_post_categories_category_id_fkey" FOREIGN KEY ("category_id") REFERENCES "public"."categories"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "public"."user_bookmarks" ADD CONSTRAINT "user_bookmarks_user_id_fkey" FOREIGN KEY ("user_id") REFERENCES "public"."users"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "public"."user_bookmarks" ADD CONSTRAINT "user_bookmarks_post_id_fkey" FOREIGN KEY ("post_id") REFERENCES "public"."feed_posts"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "public"."user_relationships" ADD CONSTRAINT "user_relationships_follower_id_fkey" FOREIGN KEY ("follower_id") REFERENCES "public"."users"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "public"."user_relationships" ADD CONSTRAINT "user_relationships_following_id_fkey" FOREIGN KEY ("following_id") REFERENCES "public"."users"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "public"."notifications" ADD CONSTRAINT "notifications_user_id_fkey" FOREIGN KEY ("user_id") REFERENCES "public"."users"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "public"."password_resets" ADD CONSTRAINT "password_resets_user_id_fkey" FOREIGN KEY ("user_id") REFERENCES "public"."users"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "public"."user_onboardings" ADD CONSTRAINT "user_onboardings_user_id_fkey" FOREIGN KEY ("user_id") REFERENCES "public"."users"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "public"."user_points" ADD CONSTRAINT "user_points_user_id_fkey" FOREIGN KEY ("user_id") REFERENCES "public"."users"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "public"."user_referrals" ADD CONSTRAINT "user_referrals_referrer_id_fkey" FOREIGN KEY ("referrer_id") REFERENCES "public"."users"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "public"."user_referrals" ADD CONSTRAINT "user_referrals_referred_id_fkey" FOREIGN KEY ("referred_id") REFERENCES "public"."users"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "public"."user_rewards" ADD CONSTRAINT "user_rewards_user_id_fkey" FOREIGN KEY ("user_id") REFERENCES "public"."users"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "public"."chart_of_accounts" ADD CONSTRAINT "chart_of_accounts_parent_id_fkey" FOREIGN KEY ("parent_id") REFERENCES "public"."chart_of_accounts"("id") ON DELETE SET NULL ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "public"."accounting_transaction_entries" ADD CONSTRAINT "accounting_transaction_entries_transaction_id_fkey" FOREIGN KEY ("transaction_id") REFERENCES "public"."accounting_transactions"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "public"."accounting_transaction_entries" ADD CONSTRAINT "accounting_transaction_entries_account_id_fkey" FOREIGN KEY ("account_id") REFERENCES "public"."chart_of_accounts"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "public"."supplier_ledger" ADD CONSTRAINT "supplier_ledger_supplier_account_id_fkey" FOREIGN KEY ("supplier_account_id") REFERENCES "public"."accounts"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "public"."supplier_ledger" ADD CONSTRAINT "supplier_ledger_transaction_id_fkey" FOREIGN KEY ("transaction_id") REFERENCES "public"."accounting_transactions"("id") ON DELETE SET NULL ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "public"."supplier_ledger" ADD CONSTRAINT "supplier_ledger_milk_sale_id_fkey" FOREIGN KEY ("milk_sale_id") REFERENCES "public"."milk_sales"("id") ON DELETE SET NULL ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "public"."supplier_fee_rules" ADD CONSTRAINT "supplier_fee_rules_supplier_account_id_fkey" FOREIGN KEY ("supplier_account_id") REFERENCES "public"."accounts"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "public"."supplier_fee_rules" ADD CONSTRAINT "supplier_fee_rules_fee_type_id_fkey" FOREIGN KEY ("fee_type_id") REFERENCES "public"."fee_types"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "public"."supplier_deductions" ADD CONSTRAINT "supplier_deductions_supplier_account_id_fkey" FOREIGN KEY ("supplier_account_id") REFERENCES "public"."accounts"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "public"."supplier_deductions" ADD CONSTRAINT "supplier_deductions_fee_type_id_fkey" FOREIGN KEY ("fee_type_id") REFERENCES "public"."fee_types"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "public"."supplier_deductions" ADD CONSTRAINT "supplier_deductions_milk_sale_id_fkey" FOREIGN KEY ("milk_sale_id") REFERENCES "public"."milk_sales"("id") ON DELETE SET NULL ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "public"."invoices" ADD CONSTRAINT "invoices_supplier_account_id_fkey" FOREIGN KEY ("supplier_account_id") REFERENCES "public"."accounts"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "public"."invoice_items" ADD CONSTRAINT "invoice_items_invoice_id_fkey" FOREIGN KEY ("invoice_id") REFERENCES "public"."invoices"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "public"."receipts" ADD CONSTRAINT "receipts_supplier_account_id_fkey" FOREIGN KEY ("supplier_account_id") REFERENCES "public"."accounts"("id") ON DELETE SET NULL ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "public"."receipts" ADD CONSTRAINT "receipts_customer_account_id_fkey" FOREIGN KEY ("customer_account_id") REFERENCES "public"."accounts"("id") ON DELETE SET NULL ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "public"."payroll_employees" ADD CONSTRAINT "payroll_employees_user_id_fkey" FOREIGN KEY ("user_id") REFERENCES "public"."users"("id") ON DELETE SET NULL ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "public"."payroll_employees" ADD CONSTRAINT "payroll_employees_account_id_fkey" FOREIGN KEY ("account_id") REFERENCES "public"."accounts"("id") ON DELETE SET NULL ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "public"."payroll_runs" ADD CONSTRAINT "payroll_runs_period_id_fkey" FOREIGN KEY ("period_id") REFERENCES "public"."payroll_periods"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "public"."payroll_payslips" ADD CONSTRAINT "payroll_payslips_run_id_fkey" FOREIGN KEY ("run_id") REFERENCES "public"."payroll_runs"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "public"."payroll_payslips" ADD CONSTRAINT "payroll_payslips_employee_id_fkey" FOREIGN KEY ("employee_id") REFERENCES "public"."payroll_employees"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "public"."payroll_deductions" ADD CONSTRAINT "payroll_deductions_payslip_id_fkey" FOREIGN KEY ("payslip_id") REFERENCES "public"."payroll_payslips"("id") ON DELETE CASCADE ON UPDATE CASCADE;

