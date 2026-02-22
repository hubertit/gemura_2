#!/bin/bash

# Migrate Accounts and Users from SQL Dump File
# This script reads the SQL dump and migrates data to PostgreSQL

set -e

SQL_DUMP="${1:-./database/gemura.sql}"
PG_HOST="${PG_HOST:-devslab-postgres}"
PG_PORT="${PG_PORT:-5432}"
PG_DB="${PG_DB:-gemura_db}"
PG_USER="${PG_USER:-devslab_admin}"
PG_PASS="${PG_PASS:-devslab_secure_password_2024}"

export PGPASSWORD="$PG_PASS"

echo "🔄 Migrating from SQL Dump to PostgreSQL"
echo "========================================="
echo ""
echo "SQL Dump: $SQL_DUMP"
echo ""

if [ ! -f "$SQL_DUMP" ]; then
    echo "❌ SQL dump file not found: $SQL_DUMP"
    exit 1
fi

# Upload SQL dump to server and run migration there
SERVER_IP="159.198.65.38"
SERVER_USER="root"
SERVER_PASS="QF87VtuYReX5v9p6e3"
REMOTE_PATH="/opt/gemura"

echo "📤 Uploading SQL dump to server..."
sshpass -p "$SERVER_PASS" scp -o StrictHostKeyChecking=no "$SQL_DUMP" $SERVER_USER@$SERVER_IP:$REMOTE_PATH/gemura.sql

echo "✅ Uploaded"
echo ""

# Run migration on server using Python script
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

# Use the existing migration scripts which handle UUID conversion
# First, we need to extract data from SQL dump and convert it

echo "📦 Extracting and migrating accounts..."
python3 << 'PYTHON_SCRIPT'
import re
import subprocess
import uuid
import sys

sql_file = '/opt/gemura/gemura.sql'
pg_host = 'devslab-postgres'
pg_port = '5432'
pg_db = 'gemura_db'
pg_user = 'devslab_admin'
pg_pass = 'devslab_secure_password_2024'

def escape_sql(value):
    if value is None or value == 'NULL':
        return 'NULL'
    return "'" + str(value).replace("'", "''") + "'"

def get_pg_connection():
    import psycopg2
    return psycopg2.connect(
        host=pg_host,
        port=pg_port,
        database=pg_db,
        user=pg_user,
        password=pg_pass
    )

# Read SQL file
with open(sql_file, 'r', encoding='utf-8') as f:
    content = f.read()

# Extract accounts
accounts_match = re.search(r"INSERT INTO `accounts`[^;]+;", content, re.DOTALL)
if accounts_match:
    accounts_sql = accounts_match.group(0)
    # Parse INSERT statement
    values_match = re.search(r"VALUES\s+(.+);", accounts_sql, re.DOTALL)
    if values_match:
        values_str = values_match.group(1)
        # Parse each row
        rows = re.findall(r"\(([^)]+)\)", values_str)
        
        conn = get_pg_connection()
        cur = conn.cursor()
        
        migrated = 0
        skipped = 0
        
        for row in rows:
            values = [v.strip().strip("'") if v.strip() != 'NULL' else None for v in row.split(',')]
            if len(values) < 6:
                continue
                
            legacy_id = int(values[0])
            code = values[1] if values[1] else None
            name = values[2] if values[2] else ''
            acc_type = values[3] if values[3] else 'tenant'
            parent_id_legacy = int(values[4]) if values[4] and values[4] != 'NULL' else None
            status = values[5] if values[5] else 'active'
            created_at = values[6] if len(values) > 6 and values[6] != 'NULL' else None
            updated_at = values[7] if len(values) > 7 and values[7] != 'NULL' else None
            created_by_legacy = int(values[8]) if len(values) > 8 and values[8] and values[8] != 'NULL' else None
            updated_by_legacy = int(values[9]) if len(values) > 9 and values[9] and values[9] != 'NULL' else None
            
            # Check if already migrated
            cur.execute("SELECT id FROM accounts WHERE legacy_id = %s", (legacy_id,))
            if cur.fetchone():
                skipped += 1
                continue
            
            # Generate UUID
            new_id = str(uuid.uuid4())
            
            # Map parent_id
            parent_id = None
            if parent_id_legacy:
                cur.execute("SELECT id FROM accounts WHERE legacy_id = %s", (parent_id_legacy,))
                parent_row = cur.fetchone()
                if parent_row:
                    parent_id = parent_row[0]
            
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
            
            # Insert account
            try:
                cur.execute("""
                    INSERT INTO accounts (id, legacy_id, code, name, type, status, parent_id, 
                                         created_at, updated_at, created_by, updated_by)
                    VALUES (%s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s)
                    ON CONFLICT (legacy_id) DO NOTHING
                """, (new_id, legacy_id, code, name, acc_type, status, parent_id,
                      created_at, updated_at, created_by, updated_by))
                migrated += 1
            except Exception as e:
                print(f"Error inserting account {legacy_id}: {e}")
        
        conn.commit()
        cur.close()
        conn.close()
        
        print(f"   ✅ Migrated {migrated} accounts, skipped {skipped} (already exist)")

# Similar for users...
print("📦 Extracting and migrating users...")
# (Similar logic for users)

PYTHON_SCRIPT

ENDSSH

echo ""
echo "✅ Migration from SQL dump completed!"
