-- Update the role ENUM in user_accounts table to include 'manager'
-- Current ENUM: ('owner', 'admin', 'collector', 'supplier', 'customer')
-- This script should be run on the database to fix the role constraint issue

-- First, let's check the current ENUM values
SELECT COLUMN_TYPE 
FROM INFORMATION_SCHEMA.COLUMNS 
WHERE TABLE_SCHEMA = 'gemura2' 
  AND TABLE_NAME = 'user_accounts' 
  AND COLUMN_NAME = 'role';

-- Update the ENUM to include 'manager'
ALTER TABLE user_accounts 
MODIFY COLUMN role ENUM('owner', 'admin', 'manager', 'collector', 'supplier', 'customer') NOT NULL DEFAULT 'collector';

-- Verify the change
SELECT COLUMN_TYPE 
FROM INFORMATION_SCHEMA.COLUMNS 
WHERE TABLE_SCHEMA = 'gemura2' 
  AND TABLE_NAME = 'user_accounts' 
  AND COLUMN_NAME = 'role';

-- Update any existing empty roles to 'collector' (temporary fix for existing data)
UPDATE user_accounts 
SET role = 'collector' 
WHERE role = '' OR role IS NULL;
