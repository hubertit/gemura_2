# 🚀 KYC System Deployment Checklist

## ✅ **Files Ready for Deployment**

### **1. Database Schema Update**
- **File:** `kyc_database_update.sql`
- **Action:** Run this SQL to add KYC fields to users table
- **Status:** ✅ Ready

### **2. API Files**
- **File:** `/Applications/AMPPS/www/gemura2/api/v2/kyc/upload_photo.php`
- **Action:** Deploy to server
- **Status:** ✅ Ready

- **File:** `/Applications/AMPPS/www/gemura2/api/v2/profile/update.php` (Updated)
- **Action:** Deploy to server
- **Status:** ✅ Ready

## 🔧 **Deployment Steps**

### **Step 1: Database Update**
```sql
-- Run this SQL query first
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
```

### **Step 2: Deploy API Files**
1. **Deploy:** `/Applications/AMPPS/www/gemura2/api/v2/kyc/upload_photo.php`
2. **Deploy:** `/Applications/AMPPS/www/gemura2/api/v2/profile/update.php` (Updated version)

### **Step 3: Test APIs**
```bash
# Test Photo Upload
curl -X POST http://localhost/gemura2/api/v2/kyc/upload_photo.php \
  -F "token=7f7b3894faba7e3316041aed9739cd36c7ccf11a25c9cbb56c1d732cb190f3f0" \
  -F "photo_type=id_front" \
  -F "photo=@/Users/macbookpro/Desktop/Teta's  NID.png"

# Test Profile Update with KYC
curl -X POST http://localhost/gemura2/api/v2/profile/update.php \
  -H "Content-Type: application/json" \
  -d '{
    "token": "7f7b3894faba7e3316041aed9739cd36c7ccf11a25c9cbb56c1d732cb190f3f0",
    "name": "Hubert IT",
    "phone": "250788606765",
    "province": "Northern Province",
    "district": "Gicumbi",
    "sector": "Gicumbi",
    "cell": "Gicumbi",
    "village": "Gicumbi Town",
    "id_number": "119908457694884870"
  }'
```

## 🎯 **What's Included**

### **✅ KYC Photo Upload API**
- **Endpoint:** `POST /kyc/upload_photo.php`
- **Features:**
  - Token authentication
  - Photo type validation (id_front, id_back, selfie)
  - Cloudinary upload with preset "expo_rwanda"
  - Database update with photo URL
  - KYC status update to 'pending'

### **✅ Enhanced Profile Update API**
- **Endpoint:** `POST /profile/update.php` (Updated)
- **New KYC Fields:**
  - Location: province, district, sector, cell, village
  - ID: id_number
  - Photos: id_front_photo_url, id_back_photo_url, selfie_photo_url
  - Status: kyc_status, kyc_verified_at

### **✅ Database Schema**
- **Table:** `users` (Enhanced)
- **New Fields:** 13 KYC-related fields
- **Indexes:** Performance optimization
- **Status Tracking:** pending/verified/rejected

## 🔍 **Testing Checklist**

### **After Deployment:**
- [ ] Database schema updated successfully
- [ ] Photo upload API responds correctly
- [ ] Profile update API includes KYC fields in response
- [ ] Cloudinary uploads work
- [ ] Database updates work
- [ ] Error handling works

## 🚀 **Ready to Deploy!**

**All files are prepared and ready for deployment.**
**Follow the steps above in order.**
