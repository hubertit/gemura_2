#!/bin/bash

# Fix Missing User Accounts for User 0788606765
# This script restores the missing user_account relationships from the SQL dump

set -e

echo "🔧 Fixing Missing User Accounts for 0788606765"
echo "=============================================="
echo ""

# Database connection
PG_HOST="159.198.65.38"
PG_PORT="5433"
PG_DB="gemura_db"
PG_USER="devslab_admin"
PG_PASS="devslab_secure_password_2024"

export PGPASSWORD="$PG_PASS"

# User details
USER_PHONE="250788606765"
USER_LEGACY_ID=1  # user_id = 3 in v1, legacy_id = 1 in v2

# Get user UUID
USER_UUID=$(psql -h "$PG_HOST" -p "$PG_PORT" -U "$PG_USER" -d "$PG_DB" -t -A -c \
    "SELECT id FROM users WHERE phone = '$USER_PHONE' LIMIT 1;" | tr -d ' ')

if [ -z "$USER_UUID" ]; then
    echo "❌ User not found with phone $USER_PHONE"
    exit 1
fi

echo "✅ Found user: $USER_UUID"
echo ""

# Account IDs from SQL dump (user_id = 3 should have access to these)
ACCOUNT_LEGACY_IDS=(1 2 3 4 5 6 8 10 13 14 15 20 22 23 61 63 64 65 83 89 91 92 97 98 99 102 103 104 109 110 111 113 114 115 120 121 125 126 127 128 132 133 135 137 138 140 144 147 151 152 159 198 205 206 208 209 210 217 221 222 223 224 226 229 230 231 233 236 239 243 253 257 261 361459 961531)

echo "📊 Checking existing user_accounts..."
EXISTING_COUNT=$(psql -h "$PG_HOST" -p "$PG_PORT" -U "$PG_USER" -d "$PG_DB" -t -A -c \
    "SELECT COUNT(*) FROM user_accounts WHERE user_id = '$USER_UUID';" | tr -d ' ')

echo "   Current user_accounts: $EXISTING_COUNT"
echo "   Expected: 75"
echo ""

# Get existing account_ids for this user
EXISTING_ACCOUNT_IDS=$(psql -h "$PG_HOST" -p "$PG_PORT" -U "$PG_USER" -d "$PG_DB" -t -A -c \
    "SELECT a.legacy_id FROM user_accounts ua JOIN accounts a ON ua.account_id = a.id WHERE ua.user_id = '$USER_UUID' AND a.legacy_id IS NOT NULL;" | tr '\n' ' ')

echo "📋 Processing accounts..."
migrated=0
skipped=0
failed=0
missing_accounts=0

for account_legacy_id in "${ACCOUNT_LEGACY_IDS[@]}"; do
    # Check if already exists
    if echo "$EXISTING_ACCOUNT_IDS" | grep -q "\b$account_legacy_id\b"; then
        skipped=$((skipped + 1))
        continue
    fi
    
    # Get account UUID
    ACCOUNT_UUID=$(psql -h "$PG_HOST" -p "$PG_PORT" -U "$PG_USER" -d "$PG_DB" -t -A -c \
        "SELECT id FROM accounts WHERE legacy_id = $account_legacy_id LIMIT 1;" | tr -d ' ')
    
    if [ -z "$ACCOUNT_UUID" ]; then
        echo "   ⚠️  Account with legacy_id $account_legacy_id not found, skipping..."
        missing_accounts=$((missing_accounts + 1))
        continue
    fi
    
    # Generate new UUID for user_account
    NEW_UUID=$(uuidgen | tr '[:upper:]' '[:lower:]')
    
    # Get account code for logging
    ACCOUNT_CODE=$(psql -h "$PG_HOST" -p "$PG_PORT" -U "$PG_USER" -d "$PG_DB" -t -A -c \
        "SELECT code FROM accounts WHERE legacy_id = $account_legacy_id LIMIT 1;" | tr -d ' ')
    
    # Insert user_account
    RESULT=$(psql -h "$PG_HOST" -p "$PG_PORT" -U "$PG_USER" -d "$PG_DB" -c \
        "INSERT INTO user_accounts (id, user_id, account_id, role, status, created_at)
         VALUES ('$NEW_UUID', '$USER_UUID', '$ACCOUNT_UUID', 'owner', 'active', NOW())
         ON CONFLICT (user_id, account_id) DO NOTHING
         RETURNING id;" 2>&1)
    
    if echo "$RESULT" | grep -q "INSERT 0 1"; then
        echo "   ✅ Added account: $ACCOUNT_CODE (legacy_id: $account_legacy_id)"
        migrated=$((migrated + 1))
    elif echo "$RESULT" | grep -q "INSERT 0 0"; then
        echo "   ℹ️  Account already linked: $ACCOUNT_CODE (legacy_id: $account_legacy_id)"
        skipped=$((skipped + 1))
    else
        echo "   ❌ Failed to add account legacy_id $account_legacy_id: $RESULT"
        failed=$((failed + 1))
    fi
done

echo ""
echo "=============================================="
echo "✅ Migration Complete!"
echo "=============================================="
echo "Migrated: $migrated"
echo "Skipped: $skipped"
echo "Failed: $failed"
echo "Missing Accounts: $missing_accounts"
echo ""

# Verify final count
FINAL_COUNT=$(psql -h "$PG_HOST" -p "$PG_PORT" -U "$PG_USER" -d "$PG_DB" -t -A -c \
    "SELECT COUNT(*) FROM user_accounts WHERE user_id = '$USER_UUID';" | tr -d ' ')

echo "📊 Final user_accounts count: $FINAL_COUNT"
echo "   Expected: 75"
echo ""

if [ "$FINAL_COUNT" -ge 70 ]; then
    echo "✅ Success! User now has access to $FINAL_COUNT accounts"
else
    echo "⚠️  Warning: Only $FINAL_COUNT accounts linked (expected ~75)"
fi
