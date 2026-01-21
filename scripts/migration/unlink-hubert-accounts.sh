#!/bin/bash

# Script to unlink Hubert (hubert@devslab.io) from all accounts except:
# 1. His own accounts (where he is the owner)
# 2. KOPERATIVE KOZAMGI (A_16C846) - the real one with data
# 3. Gahengeri (A_33FDF4) - the real one with data

set -e

DB_HOST="159.198.65.38"
DB_PORT="5433"
DB_USER="devslab_admin"
DB_NAME="gemura_db"
DB_PASSWORD="devslab_secure_password_2024"

HUBERT_USER_ID="4fc3447d-6ce6-49c8-9cf6-64eaffbe1a96"

# Accounts to KEEP
KEEP_ACCOUNTS=(
  "49191126-d4e3-46cc-9084-afb952136422"  # Hubert (his own account)
  "870e3ec0-3225-4a21-af07-7a9552a9bec3"  # KOPERATIVE KOZAMGI (A_16C846) - real one with data
  "d0fd05c3-868f-42df-b0a9-f51257cba91c"  # Gahengeri (A_33FDF4) - real one with data
)

echo "🔍 Finding all accounts linked to Hubert (hubert@devslab.io)..."
echo ""

# Get all current links
PGPASSWORD="$DB_PASSWORD" psql -h "$DB_HOST" -p "$DB_PORT" -U "$DB_USER" -d "$DB_NAME" -c "
SELECT 
  ua.id as access_id,
  a.name as account_name,
  a.code as account_code,
  ua.role,
  CASE 
    WHEN a.id = ANY(ARRAY['49191126-d4e3-46cc-9084-afb952136422', '870e3ec0-3225-4a21-af07-7a9552a9bec3', 'd0fd05c3-868f-42df-b0a9-f51257cba91c'])
    THEN 'KEEP'
    ELSE 'REMOVE'
  END as action
FROM user_accounts ua
JOIN accounts a ON ua.account_id = a.id
WHERE ua.user_id = '$HUBERT_USER_ID'
ORDER BY action, a.name;
"

echo ""
echo "⚠️  This will DELETE all user_accounts links for Hubert except:"
echo "   - Hubert (A798A0A) - his own account"
echo "   - KOPERATIVE KOZAMGI (A_16C846) - real account with data"
echo "   - Gahengeri (A_33FDF4) - real account with data"
echo ""
read -p "Continue? (yes/no): " confirm

if [ "$confirm" != "yes" ]; then
  echo "❌ Cancelled."
  exit 1
fi

echo ""
echo "🗑️  Removing links..."

# Build the SQL to delete all except the keep accounts
KEEP_ACCOUNTS_STRING=$(IFS=','; echo "${KEEP_ACCOUNTS[*]}")

PGPASSWORD="$DB_PASSWORD" psql -h "$DB_HOST" -p "$DB_PORT" -U "$DB_USER" -d "$DB_NAME" <<EOF
BEGIN;

-- Delete user_accounts links for Hubert except the ones we want to keep
DELETE FROM user_accounts
WHERE user_id = '$HUBERT_USER_ID'
  AND account_id NOT IN ($KEEP_ACCOUNTS_STRING);

-- Show remaining links
SELECT 
  ua.id as access_id,
  a.name as account_name,
  a.code as account_code,
  ua.role
FROM user_accounts ua
JOIN accounts a ON ua.account_id = a.id
WHERE ua.user_id = '$HUBERT_USER_ID'
ORDER BY a.name;

COMMIT;
EOF

echo ""
echo "✅ Done! Hubert now only has access to:"
echo "   - His own accounts"
echo "   - KOPERATIVE KOZAMGI (A_16C846)"
echo "   - Gahengeri (A_33FDF4)"
