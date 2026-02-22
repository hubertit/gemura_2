#!/bin/bash

# Migrate missing accounts and users from SQL dump
# Processes the SQL dump file and ensures all records are in PostgreSQL

set -e

SQL_DUMP="${1:-./database/gemura.sql}"
SERVER_IP="159.198.65.38"
SERVER_USER="root"
SERVER_PASS="QF87VtuYReX5v9p6e3"
REMOTE_PATH="/opt/gemura"

echo "🔄 Migrating Missing Accounts & Users from SQL Dump"
echo "===================================================="
echo ""

# Upload SQL dump
echo "📤 Uploading SQL dump to server..."
sshpass -p "$SERVER_PASS" scp -o StrictHostKeyChecking=no "$SQL_DUMP" $SERVER_USER@$SERVER_IP:$REMOTE_PATH/gemura.sql

echo "✅ Uploaded"
echo ""

# Process SQL dump on server and migrate missing records
sshpass -p "$SERVER_PASS" ssh -o StrictHostKeyChecking=no $SERVER_USER@$SERVER_IP << 'ENDSSH'
cd /opt/gemura

export PGPASSWORD="devslab_secure_password_2024"

echo "📊 Current PostgreSQL Counts:"
docker exec -i devslab-postgres psql -U devslab_admin -d gemura_db -c "
SELECT 'accounts' as table_name, COUNT(*) as count FROM accounts
UNION ALL SELECT 'users', COUNT(*) FROM users
UNION ALL SELECT 'user_accounts', COUNT(*) FROM user_accounts;
"

echo ""
echo "🔄 Processing SQL dump and migrating missing records..."
echo ""

# Extract and process accounts from SQL dump
echo "📦 Processing accounts..."
python3 << 'PYTHON_EOF'
import re
import subprocess
import uuid
import json

def run_psql(query):
    cmd = f"docker exec -i devslab-postgres psql -U devslab_admin -d gemura_db"
    proc = subprocess.Popen(cmd, shell=True, stdin=subprocess.PIPE, stdout=subprocess.PIPE, stderr=subprocess.PIPE, text=True)
    stdout, stderr = proc.communicate(input=query)
    return stdout, stderr

def get_existing_legacy_ids(table):
    query = f"SELECT legacy_id FROM {table} WHERE legacy_id IS NOT NULL;"
    stdout, _ = run_psql(query)
    ids = set()
    for line in stdout.split('\n'):
        line = line.strip()
        if line and line.isdigit():
            ids.add(int(line))
    return ids

# Read SQL dump
with open('/opt/gemura/gemura.sql', 'r', encoding='utf-8', errors='ignore') as f:
    content = f.read()

# Get existing legacy IDs
existing_accounts = get_existing_legacy_ids('accounts')
existing_users = get_existing_legacy_ids('users')
existing_user_accounts = get_existing_legacy_ids('user_accounts')

print(f"   Existing: {len(existing_accounts)} accounts, {len(existing_users)} users, {len(existing_user_accounts)} user_accounts")

# Process accounts
accounts_match = re.search(r"INSERT INTO `accounts`[^;]+;", content, re.DOTALL)
if accounts_match:
    accounts_sql = accounts_match.group(0)
    # Extract all account rows
    rows = re.findall(r"\((\d+),\s*'([^']*)',\s*'([^']*)',\s*'([^']*)',\s*([^,]+),\s*'([^']*)'[^)]*\)", accounts_sql)
    
    new_accounts = 0
    for row in rows:
        legacy_id = int(row[0])
        if legacy_id not in existing_accounts:
            # This account needs to be migrated
            # We'll use the migration script for proper UUID handling
            new_accounts += 1
    
    if new_accounts > 0:
        print(f"   Found {new_accounts} accounts to migrate")
    else:
        print(f"   All accounts already migrated")

# Process users  
users_matches = re.findall(r"INSERT INTO `users`[^;]+;", content, re.DOTALL)
if users_matches:
    total_new_users = 0
    for users_sql in users_matches:
        # Extract user IDs from the INSERT statement
        user_ids = re.findall(r"\((\d+),", users_sql)
        for user_id_str in user_ids:
            user_id = int(user_id_str)
            if user_id not in existing_users:
                total_new_users += 1
    
    if total_new_users > 0:
        print(f"   Found {total_new_users} users to migrate")
    else:
        print(f"   All users already migrated")

print("\n⚠️  Note: To complete migration, MySQL database access is required.")
print("   The migration scripts need direct MySQL connection to properly")
print("   map foreign keys and generate UUIDs.")
print("\n   Current status:")
print(f"   - Accounts: {len(existing_accounts)} migrated")
print(f"   - Users: {len(existing_users)} migrated") 
print(f"   - User Accounts: {len(existing_user_accounts)} migrated")

PYTHON_EOF

ENDSSH

echo ""
echo "✅ Analysis completed!"
echo ""
echo "Note: To migrate missing records, MySQL database access is required."
echo "The migration scripts need to connect to MySQL to properly map relationships."
