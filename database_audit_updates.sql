-- Database Schema Updates for Audit Trail
-- Add created_by and updated_by fields to all tables

-- Add audit fields to accounts table
ALTER TABLE `accounts` 
ADD COLUMN `created_by` bigint(20) UNSIGNED DEFAULT NULL,
ADD COLUMN `updated_by` bigint(20) UNSIGNED DEFAULT NULL,
ADD INDEX `idx_created_by` (`created_by`),
ADD INDEX `idx_updated_by` (`updated_by`);

-- Add audit fields to users table
ALTER TABLE `users` 
ADD COLUMN `created_by` bigint(20) UNSIGNED DEFAULT NULL,
ADD COLUMN `updated_by` bigint(20) UNSIGNED DEFAULT NULL,
ADD INDEX `idx_created_by` (`created_by`),
ADD INDEX `idx_updated_by` (`updated_by`);

-- Add audit fields to user_accounts table
ALTER TABLE `user_accounts` 
ADD COLUMN `created_by` bigint(20) UNSIGNED DEFAULT NULL,
ADD COLUMN `updated_by` bigint(20) UNSIGNED DEFAULT NULL,
ADD INDEX `idx_created_by` (`created_by`),
ADD INDEX `idx_updated_by` (`updated_by`);

-- Add audit fields to wallets table
ALTER TABLE `wallets` 
ADD COLUMN `created_by` bigint(20) UNSIGNED DEFAULT NULL,
ADD COLUMN `updated_by` bigint(20) UNSIGNED DEFAULT NULL,
ADD INDEX `idx_created_by` (`created_by`),
ADD INDEX `idx_updated_by` (`updated_by`);

-- Add audit fields to suppliers_customers table
ALTER TABLE `suppliers_customers` 
ADD COLUMN `created_by` bigint(20) UNSIGNED DEFAULT NULL,
ADD COLUMN `updated_by` bigint(20) UNSIGNED DEFAULT NULL,
ADD INDEX `idx_created_by` (`created_by`),
ADD INDEX `idx_updated_by` (`updated_by`);

-- Add audit fields to notifications table
ALTER TABLE `notifications` 
ADD COLUMN `created_by` bigint(20) UNSIGNED DEFAULT NULL,
ADD COLUMN `updated_by` bigint(20) UNSIGNED DEFAULT NULL,
ADD INDEX `idx_created_by` (`created_by`),
ADD INDEX `idx_updated_by` (`updated_by`);

-- Add audit fields to milk_sales table (already has recorded_by)
ALTER TABLE `milk_sales` 
ADD COLUMN `created_by` bigint(20) UNSIGNED DEFAULT NULL,
ADD COLUMN `updated_by` bigint(20) UNSIGNED DEFAULT NULL,
ADD INDEX `idx_created_by` (`created_by`),
ADD INDEX `idx_updated_by` (`updated_by`);
