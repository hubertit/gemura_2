#!/usr/bin/env python3
"""
Fix Incorrectly Linked Sales and Collections for Gahengeri and KOPERATIVE KOZAMGI
This script corrects the migration issues where sales with supplier_account_id = 0
were incorrectly linked to these accounts
"""

import subprocess
import sys

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
    result = subprocess.run(
        ['psql', CONN_STR, '-t', '-A', '-c', query],
        capture_output=True, text=True
    )
    return result.stdout.strip()

def run_mysql(query):
    result = subprocess.run(
        [MYSQL_BIN, '-h', MYSQL_HOST, '-u', MYSQL_USER, f'-p{MYSQL_PASS}', MYSQL_DB,
         '-N', '-e', query],
        capture_output=True, text=True
    )
    return result.stdout.strip()

print("="*80)
print("FIXING SALES AND COLLECTIONS LINKS")
print("="*80)
print("")

# Get account UUIDs
print("Getting account UUIDs...")
GAHENGERI_UUID = run_psql("SELECT id FROM accounts WHERE code = 'A_33FDF4' LIMIT 1;")
KOZAMGI_UUID = run_psql("SELECT id FROM accounts WHERE code = 'A_16C846' LIMIT 1;")
DEFAULT_ACCOUNT_UUID = run_psql("SELECT id FROM accounts WHERE code = 'A_0B973D' LIMIT 1;")

print(f"  Gahengeri UUID: {GAHENGERI_UUID}")
print(f"  KOPERATIVE KOZAMGI UUID: {KOZAMGI_UUID}")
print(f"  Default Account UUID: {DEFAULT_ACCOUNT_UUID}")
print("")

# Get correct sales from MySQL (batch query)
print("Getting correct sales from MySQL...")
MYSQL_GAHENGERI_SALES = set()
result = run_mysql("SELECT id FROM milk_sales WHERE supplier_account_id = 159 ORDER BY id;")
for line in result.split('\n'):
    if line.strip().isdigit():
        MYSQL_GAHENGERI_SALES.add(int(line.strip()))

MYSQL_KOZAMGI_SALES = set()
result = run_mysql("SELECT id FROM milk_sales WHERE supplier_account_id = 91 ORDER BY id;")
for line in result.split('\n'):
    if line.strip().isdigit():
        MYSQL_KOZAMGI_SALES.add(int(line.strip()))

print(f"  Gahengeri should have: {len(MYSQL_GAHENGERI_SALES)} sales")
print(f"  KOPERATIVE KOZAMGI should have: {len(MYSQL_KOZAMGI_SALES)} sales")
print("")

# Get current sales in PostgreSQL
print("Getting current sales in PostgreSQL...")
result = run_psql(f"SELECT legacy_id FROM milk_sales WHERE supplier_account_id = '{GAHENGERI_UUID}' AND status != 'deleted' AND legacy_id IS NOT NULL ORDER BY legacy_id;")
CURRENT_GAHENGERI_SALES = set()
for line in result.split('\n'):
    if line.strip().isdigit():
        CURRENT_GAHENGERI_SALES.add(int(line.strip()))

result = run_psql(f"SELECT legacy_id FROM milk_sales WHERE supplier_account_id = '{KOZAMGI_UUID}' AND status != 'deleted' AND legacy_id IS NOT NULL ORDER BY legacy_id;")
CURRENT_KOZAMGI_SALES = set()
for line in result.split('\n'):
    if line.strip().isdigit():
        CURRENT_KOZAMGI_SALES.add(int(line.strip()))

# Find extra sales
EXTRA_GAHENGERI = sorted(list(CURRENT_GAHENGERI_SALES - MYSQL_GAHENGERI_SALES))
EXTRA_KOZAMGI = sorted(list(CURRENT_KOZAMGI_SALES - MYSQL_KOZAMGI_SALES))

print(f"  Gahengeri currently has: {len(CURRENT_GAHENGERI_SALES)} sales ({len(EXTRA_GAHENGERI)} extra)")
print(f"  KOPERATIVE KOZAMGI currently has: {len(CURRENT_KOZAMGI_SALES)} sales ({len(EXTRA_KOZAMGI)} extra)")
print("")

# Fix Gahengeri sales - batch query MySQL
if EXTRA_GAHENGERI:
    print(f"Fixing {len(EXTRA_GAHENGERI)} incorrectly linked sales for Gahengeri...")
    
    # Get all supplier_account_ids in one query
    ids_str = ','.join(map(str, EXTRA_GAHENGERI))
    result = run_mysql(f"SELECT id, supplier_account_id FROM milk_sales WHERE id IN ({ids_str});")
    
    updates = []
    for line in result.split('\n'):
        if line:
            parts = line.split('\t')
            sale_id = int(parts[0])
            supplier_id = int(parts[1]) if len(parts) > 1 and parts[1] and parts[1].isdigit() else 0
            
            if supplier_id == 0:
                new_supplier_uuid = DEFAULT_ACCOUNT_UUID
            else:
                new_supplier_uuid = run_psql(f"SELECT id FROM accounts WHERE legacy_id = {supplier_id} LIMIT 1;")
                if not new_supplier_uuid:
                    new_supplier_uuid = DEFAULT_ACCOUNT_UUID
            
            updates.append((sale_id, new_supplier_uuid))
    
    # Batch update - group by UUID to minimize queries
    print(f"  Updating {len(updates)} sales...")
    uuid_groups = {}
    for sale_id, new_uuid in updates:
        if new_uuid not in uuid_groups:
            uuid_groups[new_uuid] = []
        uuid_groups[new_uuid].append(sale_id)
    
    for new_uuid, sale_ids in uuid_groups.items():
        ids_str = ','.join(map(str, sale_ids))
        run_psql(f"UPDATE milk_sales SET supplier_account_id = '{new_uuid}' WHERE legacy_id IN ({ids_str});")
    
    print(f"  ✅ Fixed {len(updates)} sales")
    print("")

# Fix KOPERATIVE KOZAMGI sales
if EXTRA_KOZAMGI:
    print(f"Fixing {len(EXTRA_KOZAMGI)} incorrectly linked sales for KOPERATIVE KOZAMGI...")
    
    ids_str = ','.join(map(str, EXTRA_KOZAMGI))
    result = run_mysql(f"SELECT id, supplier_account_id FROM milk_sales WHERE id IN ({ids_str});")
    
    updates = []
    for line in result.split('\n'):
        if line:
            parts = line.split('\t')
            sale_id = int(parts[0])
            supplier_id = int(parts[1]) if len(parts) > 1 and parts[1] and parts[1].isdigit() else 0
            
            if supplier_id == 0:
                new_supplier_uuid = DEFAULT_ACCOUNT_UUID
            else:
                new_supplier_uuid = run_psql(f"SELECT id FROM accounts WHERE legacy_id = {supplier_id} LIMIT 1;")
                if not new_supplier_uuid:
                    new_supplier_uuid = DEFAULT_ACCOUNT_UUID
            
            updates.append((sale_id, new_supplier_uuid))
    
    # Batch update - group by UUID
    print(f"  Updating {len(updates)} sales...")
    uuid_groups = {}
    for sale_id, new_uuid in updates:
        if new_uuid not in uuid_groups:
            uuid_groups[new_uuid] = []
        uuid_groups[new_uuid].append(sale_id)
    
    for new_uuid, sale_ids in uuid_groups.items():
        ids_str = ','.join(map(str, sale_ids))
        run_psql(f"UPDATE milk_sales SET supplier_account_id = '{new_uuid}' WHERE legacy_id IN ({ids_str});")
    
    print(f"  ✅ Fixed {len(updates)} sales")
    print("")

# Fix missing collections for Gahengeri
print("Fixing missing collections for Gahengeri...")
MYSQL_GAHENGERI_COLLECTIONS = set()
result = run_mysql("SELECT id FROM milk_sales WHERE customer_account_id = 159 ORDER BY id;")
for line in result.split('\n'):
    if line.strip().isdigit():
        MYSQL_GAHENGERI_COLLECTIONS.add(int(line.strip()))

result = run_psql(f"SELECT legacy_id FROM milk_sales WHERE customer_account_id = '{GAHENGERI_UUID}' AND status != 'deleted' AND legacy_id IS NOT NULL ORDER BY legacy_id;")
CURRENT_GAHENGERI_COLLECTIONS = set()
for line in result.split('\n'):
    if line.strip().isdigit():
        CURRENT_GAHENGERI_COLLECTIONS.add(int(line.strip()))

MISSING_COLLECTIONS = sorted(list(MYSQL_GAHENGERI_COLLECTIONS - CURRENT_GAHENGERI_COLLECTIONS))

if MISSING_COLLECTIONS:
    print(f"  Found {len(MISSING_COLLECTIONS)} missing collections")
    ids_str = ','.join(map(str, MISSING_COLLECTIONS))
    
    # Batch update all at once
    print(f"  Updating {len(MISSING_COLLECTIONS)} collections...")
    ids_str = ','.join(map(str, MISSING_COLLECTIONS))
    run_psql(f"UPDATE milk_sales SET customer_account_id = '{GAHENGERI_UUID}' WHERE legacy_id IN ({ids_str});")
    
    print(f"  ✅ Fixed {len(MISSING_COLLECTIONS)} collections")
else:
    print("  ✅ No missing collections")
print("")

# Verify
print("="*80)
print("VERIFICATION")
print("="*80)
print("")

for account_code, account_uuid, account_name in [
    ('A_33FDF4', GAHENGERI_UUID, 'Gahengeri'),
    ('A_16C846', KOZAMGI_UUID, 'KOPERATIVE KOZAMGI')
]:
    # Sales
    result = run_psql(f"SELECT COUNT(*), SUM(quantity), SUM(quantity * unit_price) FROM milk_sales WHERE supplier_account_id = '{account_uuid}' AND status != 'deleted';")
    parts = result.split('|')
    sales_count = int(parts[0].strip()) if parts[0].strip() else 0
    sales_volume = float(parts[1].strip()) if len(parts) > 1 and parts[1].strip() else 0
    sales_value = float(parts[2].strip()) if len(parts) > 2 and parts[2].strip() else 0
    
    # Collections
    result = run_psql(f"SELECT COUNT(*), SUM(quantity), SUM(quantity * unit_price) FROM milk_sales WHERE customer_account_id = '{account_uuid}' AND status != 'deleted';")
    parts = result.split('|')
    coll_count = int(parts[0].strip()) if parts[0].strip() else 0
    coll_volume = float(parts[1].strip()) if len(parts) > 1 and parts[1].strip() else 0
    coll_value = float(parts[2].strip()) if len(parts) > 2 and parts[2].strip() else 0
    
    print(f"{account_name} ({account_code}):")
    print(f"  Sales:      {sales_count:>6} sales, {sales_volume:>12,.2f} L, {sales_value:>15,.0f} Frw")
    print(f"  Collections: {coll_count:>6} collections, {coll_volume:>12,.2f} L, {coll_value:>15,.0f} Frw")
    print("")

print("✅ Fix complete!")
