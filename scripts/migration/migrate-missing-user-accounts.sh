#!/bin/bash

# Migrate Missing User Accounts
# Migrates user_accounts that are in MySQL but not in PostgreSQL

set -e

MYSQL_DB="gemura_migration_temp"

echo "🔄 Migrating Missing User Accounts"
echo "==================================="
echo ""

# Helper function to get UUID from legacy_id
get_uuid() {
    local table=$1
    local legacy_id=$2
    docker exec -i devslab-postgres psql -U devslab_admin -d gemura_db -t -A -c \
        "SELECT id FROM $table WHERE legacy_id = $legacy_id LIMIT 1;" 2>/dev/null | head -1
}

# Get list of missing user_account IDs
echo "📊 Finding missing user_accounts..."
mysql -u root $MYSQL_DB -N -e "SELECT id FROM user_accounts ORDER BY id;" > /tmp/mysql_user_account_ids.txt
docker exec -i devslab-postgres psql -U devslab_admin -d gemura_db -t -A -c \
    "SELECT legacy_id FROM user_accounts WHERE legacy_id IS NOT NULL ORDER BY legacy_id;" > /tmp/pg_user_account_ids.txt

missing_ids=$(comm -23 /tmp/mysql_user_account_ids.txt /tmp/pg_user_account_ids.txt)
missing_count=$(echo "$missing_ids" | wc -l | tr -d ' ')

echo "   Found $missing_count missing user_accounts"
echo ""

if [ "$missing_count" = "0" ]; then
    echo "✅ All user_accounts are already migrated!"
    exit 0
fi

# Migrate each missing user_account
migrated=0
failed=0
skipped=0

for id in $missing_ids; do
    # Get user_account data from MySQL
    data=$(mysql -u root $MYSQL_DB -N -e \
        "SELECT user_id, account_id, role, COALESCE(permissions, ''), COALESCE(status, 'active'), created_at
         FROM user_accounts WHERE id = $id;")
    
    if [ -z "$data" ]; then
        echo "   ⚠️  User account $id not found in MySQL"
        failed=$((failed + 1))
        continue
    fi
    
    IFS=$'\t' read -r user_id account_id role permissions status created <<< "$data"
    
    # Check if user_id is 0 (invalid user)
    if [ "$user_id" = "0" ] || [ -z "$user_id" ]; then
        echo "   ⚠️  User account $id has invalid user_id (0), skipping..."
        skipped=$((skipped + 1))
        continue
    fi
    
    # Get UUIDs for user and account
    user_uuid=$(get_uuid "users" "$user_id")
    account_uuid=$(get_uuid "accounts" "$account_id")
    
    if [ -z "$user_uuid" ]; then
        echo "   ⚠️  User account $id: user_id $user_id not found in PostgreSQL, skipping..."
        skipped=$((skipped + 1))
        continue
    fi
    
    if [ -z "$account_uuid" ]; then
        echo "   ⚠️  User account $id: account_id $account_id not found in PostgreSQL, skipping..."
        skipped=$((skipped + 1))
        continue
    fi
    
    # Generate new UUID for user_account
    new_id=$(uuidgen | tr '[:upper:]' '[:lower:]')
    
    # Handle permissions JSON
    permissions_json="NULL"
    if [ ! -z "$permissions" ] && [ "$permissions" != "NULL" ]; then
        permissions_esc=$(echo "$permissions" | sed "s/'/''/g")
        permissions_json="'$permissions_esc'"
    fi
    
    # Insert into PostgreSQL
    result=$(docker exec -i devslab-postgres psql -U devslab_admin -d gemura_db -c \
        "INSERT INTO user_accounts (id, legacy_id, user_id, account_id, role, permissions, status, created_at)
         VALUES ('$new_id', $id, '$user_uuid', '$account_uuid', '$role', $permissions_json, '$status', '$created')
         ON CONFLICT (legacy_id) DO NOTHING
         RETURNING id;" 2>&1)
    
    if echo "$result" | grep -q "INSERT 0 1"; then
        echo "   ✅ Migrated user_account $id (user: $user_id, account: $account_id, role: $role)"
        migrated=$((migrated + 1))
    elif echo "$result" | grep -q "INSERT 0 0"; then
        echo "   ℹ️  User account $id already exists (conflict)"
        skipped=$((skipped + 1))
    else
        echo "   ❌ Failed to migrate user_account $id: $result"
        failed=$((failed + 1))
    fi
done

echo ""
echo "==================================="
echo "✅ Migration Complete!"
echo "==================================="
echo "Migrated: $migrated"
echo "Skipped: $skipped"
echo "Failed: $failed"
echo ""

# Cleanup
rm -f /tmp/mysql_user_account_ids.txt /tmp/pg_user_account_ids.txt
