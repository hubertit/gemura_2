# Missing User Accounts Issue

**Date**: January 20, 2026  
**Status**: ⚠️ Critical - Data Loss Detected

---

## 🔴 **CRITICAL ISSUE**

User with phone `0788606765` (user_id = 3 in v1, legacy_id = 1 in v2) is missing **72 out of 75 accounts**.

---

## 📊 **DATA COMPARISON**

### SQL Dump (v1 - Source of Truth)
- **Total user_account entries**: 94
- **Unique accounts**: **75 accounts**
- **User ID**: 3
- **Phone**: 250788606765

### PostgreSQL (v2 - Current State)
- **Current accounts**: **3 accounts only**
- **Account codes**: 
  - ACC_GAHENGERI
  - ACC_KOZAMGI  
  - ACC_HUBERT
- **Missing**: **~72 accounts**

---

## 🔍 **ROOT CAUSE**

1. **Migration Incomplete**: The `migrate-user-accounts.sh` script only migrated 3 accounts instead of 75
2. **Missing Legacy IDs**: All 3 migrated accounts have `NULL` legacy_id, indicating they weren't properly tracked during migration
3. **Possible Issues**:
   - Migration script may have failed partway through
   - Foreign key mapping may have failed for some accounts
   - Accounts may not have been migrated before user_accounts
   - Script may have stopped on first error

---

## 📋 **MISSING ACCOUNT IDs (from SQL dump)**

The user should have access to accounts with legacy_ids:
1, 2, 3, 4, 5, 6, 8, 10, 13, 14, 15, 20, 22, 23, 61, 63, 64, 65, 83, 89, 91, 92, 97, 98, 99, 102, 103, 104, 109, 110, 111, 113, 114, 115, 120, 121, 125, 126, 127, 128, 132, 133, 135, 137, 138, 140, 144, 147, 151, 152, 159, 198, 205, 206, 208, 209, 210, 217, 221, 222, 223, 224, 226, 229, 230, 231, 233, 236, 239, 243, 253, 257, 261, 361459, 961531

---

## ✅ **SOLUTION**

### Option 1: Re-run Migration Script (Recommended)

1. **Verify all accounts are migrated first**:
   ```bash
   # Check if all 75 accounts exist in PostgreSQL
   docker exec -i devslab-postgres psql -U devslab_admin -d gemura_db -c "
   SELECT COUNT(*) FROM accounts WHERE legacy_id IN (1,2,3,4,5,6,8,10,13,14,15,20,22,23,61,63,64,65,83,89,91,92,97,98,99,102,103,104,109,110,111,113,114,115,120,121,125,126,127,128,132,133,135,137,138,140,144,147,151,152,159,198,205,206,208,209,210,217,221,222,223,224,226,229,230,231,233,236,239,243,253,257,261);
   "
   ```

2. **Re-run user_accounts migration**:
   ```bash
   cd /opt/gemura
   ./scripts/migration/tables/migrate-user-accounts.sh \
     localhost 3306 devsvknl_gemura devsvknl_admin ']LdUd=a6{-vq' \
     devslab-postgres 5432 gemura_db devslab_admin devslab_secure_password_2024
   ```

### Option 2: Manual Migration from SQL Dump

Extract missing user_accounts from SQL dump and migrate them manually.

### Option 3: Use Missing User Accounts Script

Run the existing script:
```bash
./scripts/migration/migrate-missing-user-accounts.sh
```

---

## 🔍 **VERIFICATION**

After fixing, verify:
```sql
SELECT COUNT(*) FROM user_accounts 
WHERE user_id = '198ee784-0053-433b-a5f8-470ffaf0123c';
-- Should return: 75 (or close to it)
```

---

## 📝 **NOTES**

- The migration script uses `ON CONFLICT DO NOTHING`, so re-running should be safe
- Need to ensure all accounts are migrated before user_accounts
- Check if other users are also missing accounts

---

**Last Updated**: January 20, 2026
