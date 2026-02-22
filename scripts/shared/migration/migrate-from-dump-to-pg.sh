#!/bin/bash

# Migrate Accounts and Users from SQL Dump to PostgreSQL
# This script parses the SQL dump and ensures all data is migrated

set -e

SQL_DUMP="${1:-./database/gemura.sql}"
SERVER_IP="159.198.65.38"
SERVER_USER="root"
SERVER_PASS="QF87VtuYReX5v9p6e3"
REMOTE_PATH="/opt/gemura"

echo "🔄 Migrating from SQL Dump to PostgreSQL"
echo "========================================"
echo ""

# Upload SQL dump to server
echo "📤 Uploading SQL dump to server..."
sshpass -p "$SERVER_PASS" scp -o StrictHostKeyChecking=no "$SQL_DUMP" $SERVER_USER@$SERVER_IP:$REMOTE_PATH/gemura.sql

echo "✅ Uploaded"
echo ""

# Run migration on server using a Python script
echo "🔄 Running migration on server..."
echo ""

sshpass -p "$SERVER_PASS" ssh -o StrictHostKeyChecking=no $SERVER_USER@$SERVER_IP << 'ENDSSH'
cd /opt/gemura

PG_HOST="devslab-postgres"
PG_PORT="5432"
PG_DB="gemura_db"
PG_USER="devslab_admin"
PG_PASS="devslab_secure_password_2024"

export PGPASSWORD="$PG_PASS"

python3 << 'PYTHON_EOF'
import re
import psycopg2
import uuid
from datetime import datetime

sql_file = '/opt/gemura/gemura.sql'

def get_pg_conn():
    return psycopg2.connect(
        host='devslab-postgres',
        port='5432',
        database='gemura_db',
        user='devslab_admin',
        password='devslab_secure_password_2024'
    )

def parse_value(val):
    val = val.strip()
    if val == 'NULL' or val == '':
        return None
    if val.startswith("'") and val.endswith("'"):
        return val[1:-1]
    return val

# Read SQL file
print("📖 Reading SQL dump file...")
with open(sql_file, 'r', encoding='utf-8', errors='ignore') as f:
    content = f.read()

conn = get_pg_conn()
cur = conn.cursor()

# Migrate Accounts
print("\n📦 Migrating Accounts...")
accounts_match = re.search(r"INSERT INTO `accounts`[^;]+;", content, re.DOTALL)
if accounts_match:
    accounts_sql = accounts_match.group(0)
    values_match = re.search(r"VALUES\s+(.+);", accounts_sql, re.DOTALL)
    if values_match:
        values_str = values_match.group(1)
        rows = re.findall(r"\(([^)]+(?:\([^)]*\)[^)]*)*)\)", values_str)  # Handle nested parentheses
        
        migrated = 0
        skipped = 0
        errors = 0
        
        for row_str in rows:
            # Parse row values (handle quoted strings with commas)
            values = []
            current = ''
            in_quotes = False
            paren_depth = 0
            
            for char in row_str:
                if char == "'" and (not current or current[-1] != '\\'):
                    in_quotes = not in_quotes
                    current += char
                elif char == ',' and not in_quotes:
                    values.append(current.strip())
                    current = ''
                else:
                    current += char
            if current:
                values.append(current.strip())
            
            if len(values) < 6:
                continue
            
            try:
                legacy_id = int(parse_value(values[0]) or 0)
                code = parse_value(values[1])
                name = parse_value(values[2]) or ''
                acc_type = parse_value(values[3]) or 'tenant'
                parent_id_legacy = int(parse_value(values[4])) if parse_value(values[4]) else None
                status = parse_value(values[5]) or 'active'
                created_at = parse_value(values[6]) if len(values) > 6 else None
                updated_at = parse_value(values[7]) if len(values) > 7 else None
                created_by_legacy = int(parse_value(values[8])) if len(values) > 8 and parse_value(values[8]) else None
                updated_by_legacy = int(parse_value(values[9])) if len(values) > 9 and parse_value(values[9]) else None
                
                # Check if already exists
                cur.execute("SELECT id FROM accounts WHERE legacy_id = %s", (legacy_id,))
                if cur.fetchone():
                    skipped += 1
                    continue
                
                new_id = str(uuid.uuid4())
                
                # Map parent_id
                parent_id = None
                if parent_id_legacy:
                    cur.execute("SELECT id FROM accounts WHERE legacy_id = %s", (parent_id_legacy,))
                    parent_row = cur.fetchone()
                    if parent_row:
                        parent_id = parent_row[0]
                
                # Map created_by/updated_by (these are user IDs)
                created_by = None
                updated_by = None
                
                cur.execute("""
                    INSERT INTO accounts (id, legacy_id, code, name, type, status, parent_id,
                                         created_at, updated_at, created_by, updated_by)
                    VALUES (%s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s)
                    ON CONFLICT (legacy_id) DO NOTHING
                """, (new_id, legacy_id, code, name, acc_type, status, parent_id,
                      created_at, updated_at, created_by, updated_by))
                migrated += 1
            except Exception as e:
                errors += 1
                if errors <= 5:  # Only print first 5 errors
                    print(f"   ⚠️  Error migrating account: {e}")
        
        conn.commit()
        print(f"   ✅ Accounts: {migrated} migrated, {skipped} skipped, {errors} errors")

# Migrate Users
print("\n📦 Migrating Users...")
users_matches = re.findall(r"INSERT INTO `users`[^;]+;", content, re.DOTALL)
if users_matches:
    migrated = 0
    skipped = 0
    errors = 0
    
    for users_sql in users_matches:
        values_match = re.search(r"VALUES\s+(.+);", users_sql, re.DOTALL)
        if values_match:
            values_str = values_match.group(1)
            rows = re.findall(r"\(([^)]+(?:\([^)]*\)[^)]*)*)\)", values_str)
            
            for row_str in rows:
                # Parse values (simplified - may need more robust parsing)
                values = [v.strip() for v in re.split(r",(?=(?:[^']*'[^']*')*[^']*$)", row_str)]
                
                if len(values) < 10:
                    continue
                
                try:
                    legacy_id = int(parse_value(values[0]) or 0)
                    
                    # Check if already exists
                    cur.execute("SELECT id FROM users WHERE legacy_id = %s", (legacy_id,))
                    if cur.fetchone():
                        skipped += 1
                        continue
                    
                    code = parse_value(values[1])
                    name = parse_value(values[2]) or ''
                    phone = parse_value(values[3])
                    email = parse_value(values[4])
                    password_hash = parse_value(values[7]) or ''
                    token = parse_value(values[8])
                    account_type = parse_value(values[31]) if len(values) > 31 else 'mcc'
                    status = parse_value(values[12]) or 'active'
                    default_account_id_legacy = int(parse_value(values[15])) if len(values) > 15 and parse_value(values[15]) else None
                    kyc_status = parse_value(values[27]) if len(values) > 27 else 'pending'
                    kyc_verified_at = parse_value(values[28]) if len(values) > 28 else None
                    created_at = parse_value(values[13]) if len(values) > 13 else None
                    updated_at = parse_value(values[14]) if len(values) > 14 else None
                    
                    new_id = str(uuid.uuid4())
                    
                    # Map default_account_id
                    default_account_id = None
                    if default_account_id_legacy:
                        cur.execute("SELECT id FROM accounts WHERE legacy_id = %s", (default_account_id_legacy,))
                        account_row = cur.fetchone()
                        if account_row:
                            default_account_id = account_row[0]
                    
                    cur.execute("""
                        INSERT INTO users (id, legacy_id, code, name, email, phone, password_hash, token,
                                          account_type, status, default_account_id, kyc_status, kyc_verified_at,
                                          created_at, updated_at)
                        VALUES (%s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s)
                        ON CONFLICT (legacy_id) DO NOTHING
                    """, (new_id, legacy_id, code, name, email, phone, password_hash, token,
                          account_type, status, default_account_id, kyc_status, kyc_verified_at,
                          created_at, updated_at))
                    migrated += 1
                except Exception as e:
                    errors += 1
                    if errors <= 5:
                        print(f"   ⚠️  Error migrating user: {e}")
    
    conn.commit()
    print(f"   ✅ Users: {migrated} migrated, {skipped} skipped, {errors} errors")

# Migrate User Accounts
print("\n📦 Migrating User Accounts...")
user_accounts_match = re.search(r"INSERT INTO `user_accounts`[^;]+;", content, re.DOTALL)
if user_accounts_match:
    user_accounts_sql = user_accounts_match.group(0)
    values_match = re.search(r"VALUES\s+(.+);", user_accounts_sql, re.DOTALL)
    if values_match:
        values_str = values_match.group(1)
        rows = re.findall(r"\(([^)]+)\)", values_str)
        
        migrated = 0
        skipped = 0
        errors = 0
        
        for row_str in rows:
            values = [v.strip() for v in row_str.split(',')]
            if len(values) < 6:
                continue
            
            try:
                legacy_id = int(parse_value(values[0]) or 0)
                user_id_legacy = int(parse_value(values[1]) or 0)
                account_id_legacy = int(parse_value(values[2]) or 0)
                role = parse_value(values[3]) or 'supplier'
                permissions = parse_value(values[4])
                status = parse_value(values[5]) or 'active'
                created_at = parse_value(values[6]) if len(values) > 6 else None
                created_by_legacy = int(parse_value(values[7])) if len(values) > 7 and parse_value(values[7]) else None
                updated_by_legacy = int(parse_value(values[8])) if len(values) > 8 and parse_value(values[8]) else None
                
                # Check if already exists
                cur.execute("SELECT id FROM user_accounts WHERE legacy_id = %s", (legacy_id,))
                if cur.fetchone():
                    skipped += 1
                    continue
                
                # Map user_id and account_id
                cur.execute("SELECT id FROM users WHERE legacy_id = %s", (user_id_legacy,))
                user_row = cur.fetchone()
                if not user_row:
                    skipped += 1
                    continue
                user_id = user_row[0]
                
                cur.execute("SELECT id FROM accounts WHERE legacy_id = %s", (account_id_legacy,))
                account_row = cur.fetchone()
                if not account_row:
                    skipped += 1
                    continue
                account_id = account_row[0]
                
                # Map created_by and updated_by
                created_by = None
                if created_by_legacy:
                    cur.execute("SELECT id FROM users WHERE legacy_id = %s", (created_by_legacy,))
                    created_row = cur.fetchone()
                    if created_row:
                        created_by = created_row[0]
                
                updated_by = None
                if updated_by_legacy:
                    cur.execute("SELECT id FROM users WHERE legacy_id = %s", (updated_by_legacy,))
                    updated_row = cur.fetchone()
                    if updated_row:
                        updated_by = updated_row[0]
                
                new_id = str(uuid.uuid4())
                
                cur.execute("""
                    INSERT INTO user_accounts (id, legacy_id, user_id, account_id, role, permissions, status,
                                             created_at, created_by, updated_by)
                    VALUES (%s, %s, %s, %s, %s, %s::jsonb, %s, %s, %s, %s)
                    ON CONFLICT (legacy_id) DO NOTHING
                """, (new_id, legacy_id, user_id, account_id, role, permissions, status,
                      created_at, created_by, updated_by))
                migrated += 1
            except Exception as e:
                errors += 1
                if errors <= 5:
                    print(f"   ⚠️  Error migrating user_account: {e}")
        
        conn.commit()
        print(f"   ✅ User Accounts: {migrated} migrated, {skipped} skipped, {errors} errors")

# Final counts
print("\n📊 Final Counts:")
cur.execute("SELECT COUNT(*) FROM accounts")
print(f"   Accounts: {cur.fetchone()[0]}")
cur.execute("SELECT COUNT(*) FROM users")
print(f"   Users: {cur.fetchone()[0]}")
cur.execute("SELECT COUNT(*) FROM user_accounts")
print(f"   User Accounts: {cur.fetchone()[0]}")

cur.close()
conn.close()

print("\n✅ Migration completed!")
PYTHON_EOF

ENDSSH

echo ""
echo "✅ Migration from SQL dump completed!"
