-- KYC Database Schema Update
-- Add KYC fields to existing users table

-- Add KYC location and photo fields
ALTER TABLE `users` 
ADD COLUMN IF NOT EXISTS `province` varchar(100) DEFAULT NULL,
ADD COLUMN IF NOT EXISTS `district` varchar(100) DEFAULT NULL,
ADD COLUMN IF NOT EXISTS `sector` varchar(100) DEFAULT NULL,
ADD COLUMN IF NOT EXISTS `cell` varchar(100) DEFAULT NULL,
ADD COLUMN IF NOT EXISTS `village` varchar(100) DEFAULT NULL,
ADD COLUMN IF NOT EXISTS `id_number` varchar(50) DEFAULT NULL,
ADD COLUMN IF NOT EXISTS `id_front_photo_url` varchar(255) DEFAULT NULL,
ADD COLUMN IF NOT EXISTS `id_back_photo_url` varchar(255) DEFAULT NULL,
ADD COLUMN IF NOT EXISTS `selfie_photo_url` varchar(255) DEFAULT NULL,
ADD COLUMN IF NOT EXISTS `kyc_status` ENUM('pending', 'verified', 'rejected') DEFAULT 'pending',
ADD COLUMN IF NOT EXISTS `kyc_verified_at` timestamp NULL DEFAULT NULL,
ADD COLUMN IF NOT EXISTS `kyc_verified_by` bigint(20) UNSIGNED DEFAULT NULL,
ADD COLUMN IF NOT EXISTS `kyc_rejection_reason` text DEFAULT NULL;

-- Add indexes for better performance
ALTER TABLE `users` 
ADD INDEX IF NOT EXISTS `idx_kyc_status` (`kyc_status`),
ADD INDEX IF NOT EXISTS `idx_province` (`province`),
ADD INDEX IF NOT EXISTS `idx_district` (`district`),
ADD INDEX IF NOT EXISTS `idx_kyc_verified_by` (`kyc_verified_by`);

-- Verify the changes
DESCRIBE `users`;
