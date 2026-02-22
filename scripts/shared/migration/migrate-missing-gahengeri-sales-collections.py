#!/usr/bin/env python3
"""
Migrate Missing Sales and Collections for Gahengeri
These sales/collections exist in MySQL but were never migrated to PostgreSQL
"""

import subprocess
import uuid
from datetime import datetime

PG_PASS = 'devslab_secure_password_2024'
PG_HOST = '159.198.65.38'
PG_PORT = '5433'
PG_DB = 'gemura_db'
PG_USER = 'devslab_admin'
CONN_STR = f'postgresql://{PG_USER}:{PG_PASS}@{PG_HOST}:{PG_PORT}/{PG_DB}'

MYSQL_BIN = '/Applications/AMPPS/apps/mysql/bin/mysql'
MYSQL_HOST = 'localhost'
MYSQL_DB = 'gemura'
MYSQL_USER = 'root'
MYSQL_PASS = 'mysql'

def run_psql(query):
    result = subprocess.run(['psql', CONN_STR, '-t', '-A', '-c', query], capture_output=True, text=True)
    return result.stdout.strip()

def run_mysql(query):
    result = subprocess.run([MYSQL_BIN, '-h', MYSQL_HOST, '-u', MYSQL_USER, f'-p{MYSQL_PASS}', MYSQL_DB, '-N', '-e', query], capture_output=True, text=True)
    return result.stdout.strip()

print("="*80)
print("MIGRATING MISSING SALES AND COLLECTIONS FOR GAHENGERI")
print("="*80)
print("")

# Get account UUIDs
print("Getting account UUIDs...")
GAHENGERI_UUID = run_psql("SELECT id FROM accounts WHERE code = 'A_33FDF4' LIMIT 1;")
DEFAULT_ACCOUNT_UUID = run_psql("SELECT id FROM accounts WHERE code = 'A_0B973D' LIMIT 1;")
DEFAULT_USER_UUID = run_psql("SELECT id FROM users ORDER BY created_at LIMIT 1;")

print(f"  Gahengeri UUID: {GAHENGERI_UUID}")
print(f"  Default Account UUID: {DEFAULT_ACCOUNT_UUID}")
print(f"  Default User UUID: {DEFAULT_USER_UUID}")
print("")

# Get missing sales (should be supplier_account_id = 159)
print("Finding missing sales...")
mysql_sales = set()
result = run_mysql("SELECT id FROM milk_sales WHERE supplier_account_id = 159 ORDER BY id;")
for line in result.split('\n'):
    if line.strip().isdigit():
        mysql_sales.add(int(line.strip()))

pg_sales = set()
result = run_psql(f"SELECT legacy_id FROM milk_sales WHERE supplier_account_id = '{GAHENGERI_UUID}' AND status != 'deleted' AND legacy_id IS NOT NULL;")
for line in result.split('\n'):
    if line.strip().isdigit():
        pg_sales.add(int(line.strip()))

missing_sales = sorted(list(mysql_sales - pg_sales))
print(f"  Found {len(missing_sales)} missing sales")
print(f"  IDs: {missing_sales}")
print("")

# Get missing collections (should be customer_account_id = 159)
print("Finding missing collections...")
mysql_collections = set()
result = run_mysql("SELECT id FROM milk_sales WHERE customer_account_id = 159 ORDER BY id;")
for line in result.split('\n'):
    if line.strip().isdigit():
        mysql_collections.add(int(line.strip()))

pg_collections = set()
result = run_psql(f"SELECT legacy_id FROM milk_sales WHERE customer_account_id = '{GAHENGERI_UUID}' AND status != 'deleted' AND legacy_id IS NOT NULL;")
for line in result.split('\n'):
    if line.strip().isdigit():
        pg_collections.add(int(line.strip()))

missing_collections = sorted(list(mysql_collections - pg_collections))
print(f"  Found {len(missing_collections)} missing collections")
print(f"  IDs: {missing_collections}")
print("")

# Combine all missing IDs
all_missing = sorted(list(set(missing_sales + missing_collections)))
print(f"Total missing sales/collections to migrate: {len(all_missing)}")
print("")

# Migrate missing sales/collections
if all_missing:
    print("Migrating missing sales/collections...")
    migrated = 0
    failed = 0
    
    # Process in batches
    for i in range(0, len(all_missing), 50):
        batch = all_missing[i:i+50]
        ids_str = ','.join(map(str, batch))
        
        # Get data from MySQL
        result = run_mysql(f"""
            SELECT 
                id, supplier_account_id, customer_account_id, quantity, unit_price,
                COALESCE(status, 'accepted'), sale_at, COALESCE(notes, ''),
                recorded_by, created_at, updated_at, created_by, updated_by
            FROM milk_sales 
            WHERE id IN ({ids_str})
            ORDER BY id;
        """)
        
        for line in result.split('\n'):
            if not line.strip():
                continue
            
            parts = line.split('\t')
            if len(parts) < 11:
                continue
            
            legacy_id = int(parts[0])
            supplier_id = int(parts[1]) if parts[1] and parts[1].isdigit() else 0
            customer_id = int(parts[2]) if len(parts) > 2 and parts[2] and parts[2].isdigit() else 0
            quantity = parts[3] if len(parts) > 3 else '0'
            unit_price = parts[4] if len(parts) > 4 else '0'
            status = parts[5] if len(parts) > 5 else 'accepted'
            sale_at = parts[6] if len(parts) > 6 else datetime.now().isoformat()
            notes = parts[7] if len(parts) > 7 else ''
            recorded_by = int(parts[8]) if len(parts) > 8 and parts[8] and parts[8].isdigit() else 0
            created_at = parts[9] if len(parts) > 9 else datetime.now().isoformat()
            updated_at = parts[10] if len(parts) > 10 else datetime.now().isoformat()
            created_by = int(parts[11]) if len(parts) > 11 and parts[11] and parts[11].isdigit() else 0
            updated_by = int(parts[12]) if len(parts) > 12 and parts[12] and parts[12].isdigit() else 0
            
            # Get supplier UUID
            if supplier_id == 0:
                supplier_uuid = DEFAULT_ACCOUNT_UUID
            else:
                supplier_uuid = run_psql(f"SELECT id FROM accounts WHERE legacy_id = {supplier_id} LIMIT 1;")
                if not supplier_uuid:
                    supplier_uuid = DEFAULT_ACCOUNT_UUID
            
            # Get customer UUID
            if customer_id == 0:
                customer_uuid = DEFAULT_ACCOUNT_UUID
            else:
                customer_uuid = run_psql(f"SELECT id FROM accounts WHERE legacy_id = {customer_id} LIMIT 1;")
                if not customer_uuid:
                    customer_uuid = DEFAULT_ACCOUNT_UUID
            
            # Get recorded_by UUID
            if recorded_by == 0:
                recorded_by_uuid = DEFAULT_USER_UUID
            else:
                recorded_by_uuid = run_psql(f"SELECT id FROM users WHERE legacy_id = {recorded_by} LIMIT 1;")
                if not recorded_by_uuid:
                    recorded_by_uuid = DEFAULT_USER_UUID
            
            # Generate new UUID
            new_id = str(uuid.uuid4())
            
            # Escape notes
            notes_escaped = notes.replace("'", "''") if notes else ''
            notes_sql = f"'{notes_escaped}'" if notes_escaped else 'NULL'
            
            # Handle dates
            try:
                sale_at_dt = datetime.strptime(sale_at, '%Y-%m-%d %H:%M:%S')
                sale_at_sql = f"'{sale_at_dt.isoformat()}'"
            except:
                sale_at_sql = f"'{datetime.now().isoformat()}'"
            
            try:
                created_at_dt = datetime.strptime(created_at, '%Y-%m-%d %H:%M:%S')
                created_at_sql = f"'{created_at_dt.isoformat()}'"
            except:
                created_at_sql = f"'{datetime.now().isoformat()}'"
            
            try:
                updated_at_dt = datetime.strptime(updated_at, '%Y-%m-%d %H:%M:%S')
                updated_at_sql = f"'{updated_at_dt.isoformat()}'"
            except:
                updated_at_sql = f"'{datetime.now().isoformat()}'"
            
            # Insert into PostgreSQL
            insert_query = f"""
                INSERT INTO milk_sales (
                    id, legacy_id, supplier_account_id, customer_account_id,
                    quantity, unit_price, status, sale_at, notes, recorded_by,
                    created_at, updated_at, created_by, updated_by
                ) VALUES (
                    '{new_id}',
                    {legacy_id},
                    '{supplier_uuid}',
                    '{customer_uuid}',
                    {quantity},
                    {unit_price},
                    '{status}',
                    {sale_at_sql}::timestamp,
                    {notes_sql},
                    '{recorded_by_uuid}',
                    {created_at_sql}::timestamp,
                    {updated_at_sql}::timestamp,
                    NULL,
                    NULL
                ) ON CONFLICT (legacy_id) DO NOTHING;
            """
            
            result = run_psql(insert_query)
            if 'INSERT 0 1' in result or 'INSERT 0 0' in result:
                migrated += 1
            else:
                failed += 1
                print(f"  ⚠️  Failed to migrate sale {legacy_id}: {result[:100]}")
        
        print(f"  Processed {min(i+50, len(all_missing))}/{len(all_missing)}...")
    
    print(f"\n  ✅ Migrated {migrated} sales/collections")
    if failed > 0:
        print(f"  ⚠️  Failed: {failed}")

# Verify
print("\n" + "="*80)
print("VERIFICATION")
print("="*80)
print("")

# Check sales
result = run_psql(f"SELECT COUNT(*), SUM(quantity), SUM(quantity * unit_price) FROM milk_sales WHERE supplier_account_id = '{GAHENGERI_UUID}' AND status != 'deleted';")
parts = result.split('|')
sales_count = int(parts[0].strip()) if parts[0].strip() else 0
sales_vol = float(parts[1].strip()) if len(parts) > 1 and parts[1].strip() else 0
sales_val = float(parts[2].strip()) if len(parts) > 2 and parts[2].strip() else 0

# Check collections
result = run_psql(f"SELECT COUNT(*), SUM(quantity), SUM(quantity * unit_price) FROM milk_sales WHERE customer_account_id = '{GAHENGERI_UUID}' AND status != 'deleted';")
parts = result.split('|')
coll_count = int(parts[0].strip()) if parts[0].strip() else 0
coll_vol = float(parts[1].strip()) if len(parts) > 1 and parts[1].strip() else 0
coll_val = float(parts[2].strip()) if len(parts) > 2 and parts[2].strip() else 0

# Compare with MySQL
mysql_sales_result = run_mysql("SELECT COUNT(*), SUM(quantity), SUM(quantity * unit_price) FROM milk_sales WHERE supplier_account_id = 159;")
mysql_sales_parts = mysql_sales_result.split('\t')
mysql_sales_count = int(mysql_sales_parts[0]) if mysql_sales_parts[0] else 0
mysql_sales_vol = float(mysql_sales_parts[1]) if len(mysql_sales_parts) > 1 and mysql_sales_parts[1] else 0
mysql_sales_val = float(mysql_sales_parts[2]) if len(mysql_sales_parts) > 2 and mysql_sales_parts[2] else 0

mysql_coll_result = run_mysql("SELECT COUNT(*), SUM(quantity), SUM(quantity * unit_price) FROM milk_sales WHERE customer_account_id = 159;")
mysql_coll_parts = mysql_coll_result.split('\t')
mysql_coll_count = int(mysql_coll_parts[0]) if mysql_coll_parts[0] else 0
mysql_coll_vol = float(mysql_coll_parts[1]) if len(mysql_coll_parts) > 1 and mysql_coll_parts[1] else 0
mysql_coll_val = float(mysql_coll_parts[2]) if len(mysql_coll_parts) > 2 and mysql_coll_parts[2] else 0

print("Gahengeri (A_33FDF4):")
print(f"  SALES:")
print(f"    MySQL (V1):   {mysql_sales_count:>6} sales, {mysql_sales_vol:>12,.2f} L, {mysql_sales_val:>15,.0f} Frw")
print(f"    PostgreSQL:   {sales_count:>6} sales, {sales_vol:>12,.2f} L, {sales_val:>15,.0f} Frw")
if mysql_sales_count == sales_count and abs(mysql_sales_vol - sales_vol) < 0.01:
    print(f"    ✅ MATCH")
else:
    print(f"    ⚠️  MISMATCH: Count diff: {sales_count - mysql_sales_count}, Volume diff: {sales_vol - mysql_sales_vol:,.2f} L")

print(f"  COLLECTIONS:")
print(f"    MySQL (V1):   {mysql_coll_count:>6} collections, {mysql_coll_vol:>12,.2f} L, {mysql_coll_val:>15,.0f} Frw")
print(f"    PostgreSQL:   {coll_count:>6} collections, {coll_vol:>12,.2f} L, {coll_val:>15,.0f} Frw")
if mysql_coll_count == coll_count and abs(mysql_coll_vol - coll_vol) < 0.01:
    print(f"    ✅ MATCH")
else:
    print(f"    ⚠️  MISMATCH: Count diff: {coll_count - mysql_coll_count}, Volume diff: {coll_vol - mysql_coll_vol:,.2f} L")

print("\n✅ Migration complete!")
