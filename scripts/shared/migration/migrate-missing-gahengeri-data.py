#!/usr/bin/env python3
"""
Migrate Missing Sales and Collections for Gahengeri
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

def run_psql(query):
    result = subprocess.run(['psql', CONN_STR, '-t', '-A', '-c', query], capture_output=True, text=True)
    return result.stdout.strip()

def run_mysql(query):
    result = subprocess.run([MYSQL_BIN, '-h', 'localhost', '-u', 'root', '-pmysql', 'gemura', '-N', '-e', query], capture_output=True, text=True)
    return result.stdout.strip()

print("="*80)
print("MIGRATING MISSING SALES AND COLLECTIONS FOR GAHENGERI")
print("="*80)
print("")

# Get account UUIDs
gahengeri_uuid = run_psql("SELECT id FROM accounts WHERE code = 'A_33FDF4' LIMIT 1;")
default_user_uuid = run_psql("SELECT id FROM users ORDER BY created_at LIMIT 1;")
default_account_uuid = run_psql("SELECT id FROM accounts WHERE code = 'A_0B973D' LIMIT 1;")

print(f"Gahengeri UUID: {gahengeri_uuid}")
print(f"Default User UUID: {default_user_uuid}")
print("")

# Get missing sales IDs
mysql_sales = set()
result = run_mysql("SELECT id FROM milk_sales WHERE supplier_account_id = 159 ORDER BY id;")
for line in result.split('\n'):
    if line.strip().isdigit():
        mysql_sales.add(int(line.strip()))

pg_sales = set()
result = run_psql(f"SELECT legacy_id FROM milk_sales WHERE supplier_account_id = '{gahengeri_uuid}' AND status != 'deleted' AND legacy_id IS NOT NULL;")
for line in result.split('\n'):
    if line.strip().isdigit():
        pg_sales.add(int(line.strip()))

missing_sales = sorted(list(mysql_sales - pg_sales))

# Get missing collections IDs
mysql_collections = set()
result = run_mysql("SELECT id FROM milk_sales WHERE customer_account_id = 159 ORDER BY id;")
for line in result.split('\n'):
    if line.strip().isdigit():
        mysql_collections.add(int(line.strip()))

pg_collections = set()
result = run_psql(f"SELECT legacy_id FROM milk_sales WHERE customer_account_id = '{gahengeri_uuid}' AND status != 'deleted' AND legacy_id IS NOT NULL;")
for line in result.split('\n'):
    if line.strip().isdigit():
        pg_collections.add(int(line.strip()))

missing_collections = sorted(list(mysql_collections - pg_collections))

print(f"Missing Sales: {len(missing_sales)}")
print(f"Missing Collections: {len(missing_collections)}")
print("")

# Combine all missing IDs (some might be both sales and collections)
all_missing = sorted(list(set(missing_sales + missing_collections)))

if all_missing:
    print(f"Migrating {len(all_missing)} missing records...")
    ids_str = ','.join(map(str, all_missing))
    
    # Get all sales data from MySQL
    result = run_mysql(f"""SELECT 
        id, supplier_account_id, customer_account_id, quantity, unit_price, 
        COALESCE(status, 'accepted'), sale_at, COALESCE(notes, ''), 
        recorded_by, created_at, updated_at, created_by, updated_by
    FROM milk_sales WHERE id IN ({ids_str}) ORDER BY id;""")
    
    migrated = 0
    for line in result.split('\n'):
        if not line.strip():
            continue
        
        parts = line.split('\t')
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
            supplier_uuid = default_account_uuid
        elif supplier_id == 159:  # Gahengeri
            supplier_uuid = gahengeri_uuid
        else:
            supplier_uuid = run_psql(f"SELECT id FROM accounts WHERE legacy_id = {supplier_id} LIMIT 1;")
            if not supplier_uuid:
                supplier_uuid = default_account_uuid
        
        # Get customer UUID
        if customer_id == 0:
            customer_uuid = default_account_uuid
        elif customer_id == 159:  # Gahengeri
            customer_uuid = gahengeri_uuid
        else:
            customer_uuid = run_psql(f"SELECT id FROM accounts WHERE legacy_id = {customer_id} LIMIT 1;")
            if not customer_uuid:
                customer_uuid = default_account_uuid
        
        # Get recorded_by UUID
        if recorded_by == 0:
            recorded_by_uuid = default_user_uuid
        else:
            recorded_by_uuid = run_psql(f"SELECT id FROM users WHERE legacy_id = {recorded_by} LIMIT 1;")
            if not recorded_by_uuid:
                recorded_by_uuid = default_user_uuid
        
        # Get created_by UUID
        created_by_uuid = 'NULL'
        if created_by > 0:
            created_by_uuid = run_psql(f"SELECT id FROM users WHERE legacy_id = {created_by} LIMIT 1;")
            if not created_by_uuid:
                created_by_uuid = default_user_uuid
            created_by_uuid = f"'{created_by_uuid}'"
        
        # Get updated_by UUID
        updated_by_uuid = 'NULL'
        if updated_by > 0:
            updated_by_uuid = run_psql(f"SELECT id FROM users WHERE legacy_id = {updated_by} LIMIT 1;")
            if not updated_by_uuid:
                updated_by_uuid = default_user_uuid
            updated_by_uuid = f"'{updated_by_uuid}'"
        
        # Escape notes
        notes_escaped = notes.replace("'", "''") if notes else ''
        notes_sql = f"'{notes_escaped}'" if notes_escaped else 'NULL'
        
        # Generate new UUID
        new_id = str(uuid.uuid4())
        
        # Insert into PostgreSQL
        query = f"""INSERT INTO milk_sales (
            id, legacy_id, supplier_account_id, customer_account_id,
            quantity, unit_price, status, sale_at, notes, recorded_by,
            created_at, updated_at, created_by, updated_by
        ) VALUES (
            '{new_id}', {legacy_id}, '{supplier_uuid}', '{customer_uuid}',
            {quantity}, {unit_price}, '{status}', '{sale_at}', {notes_sql}, '{recorded_by_uuid}',
            '{created_at}', '{updated_at}', {created_by_uuid}, {updated_by_uuid}
        ) ON CONFLICT (legacy_id) DO NOTHING;"""
        
        result2 = run_psql(query)
        if 'INSERT 0 1' in result2:
            migrated += 1
        elif 'INSERT 0 0' in result2:
            # Already exists
            pass
    
    print(f"  ✅ Migrated {migrated} records")
    print("")

# Final verification
print("="*80)
print("FINAL VERIFICATION")
print("="*80)
print("")

result = run_psql(f"""SELECT COUNT(*), SUM(quantity), SUM(quantity * unit_price) 
FROM milk_sales WHERE supplier_account_id = '{gahengeri_uuid}' AND status != 'deleted';""")
parts = result.split('|')
print(f"Gahengeri Sales:")
print(f"  Count: {parts[0].strip()}")
print(f"  Volume: {float(parts[1].strip()) if parts[1].strip() else 0:,.2f} L")
print(f"  Value: {float(parts[2].strip()) if len(parts) > 2 and parts[2].strip() else 0:,.0f} Frw")

result = run_psql(f"""SELECT COUNT(*), SUM(quantity), SUM(quantity * unit_price) 
FROM milk_sales WHERE customer_account_id = '{gahengeri_uuid}' AND status != 'deleted';""")
parts = result.split('|')
print(f"\nGahengeri Collections:")
print(f"  Count: {parts[0].strip()}")
print(f"  Volume: {float(parts[1].strip()) if parts[1].strip() else 0:,.2f} L")
print(f"  Value: {float(parts[2].strip()) if len(parts) > 2 and parts[2].strip() else 0:,.0f} Frw")

print("\n✅ Migration complete!")
