-- AlterEnum: add 'admin' to AccountType for admin-only accounts (admin menu/features; else user menu by role/permissions)
ALTER TYPE "AccountType" ADD VALUE IF NOT EXISTS 'admin';
