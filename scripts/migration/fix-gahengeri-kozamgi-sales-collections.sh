#!/bin/bash
# Fix Incorrectly Linked Sales and Collections for Gahengeri and KOPERATIVE KOZAMGI
# This script corrects the migration issues where sales with supplier_account_id = 0
# were incorrectly linked to these accounts

set -e

echo "=========================================="
echo "FIXING SALES AND COLLECTIONS LINKS"
echo "=========================================="
echo ""

# Database connections
PG_HOST="159.198.65.38"
PG_PORT="5433"
PG_DB="gemura_db"
PG_USER="devslab_admin"
PG_PASS="devslab_secure_password_2024"
export PGPASSWORD="$PG_PASS"

MYSQL_HOST="localhost"
MYSQL_DB="gemura"
MYSQL_USER="root"
MYSQL_PASS="mysql"
MYSQL_BIN="/Applications/AMPPS/apps/mysql/bin/mysql"

# Get account UUIDs
echo "Getting account UUIDs..."
GAHENGERI_UUID=$(psql -h "$PG_HOST" -p "$PG_PORT" -U "$PG_USER" -d "$PG_DB" -t -A -c "SELECT id FROM accounts WHERE code = 'A_33FDF4' LIMIT 1;")
KOZAMGI_UUID=$(psql -h "$PG_HOST" -p "$PG_PORT" -U "$PG_USER" -d "$PG_DB" -t -A -c "SELECT id FROM accounts WHERE code = 'A_16C846' LIMIT 1;")
DEFAULT_ACCOUNT_UUID=$(psql -h "$PG_HOST" -p "$PG_PORT" -U "$PG_USER" -d "$PG_DB" -t -A -c "SELECT id FROM accounts WHERE code = 'A_0B973D' LIMIT 1;")

echo "  Gahengeri UUID: $GAHENGERI_UUID"
echo "  KOPERATIVE KOZAMGI UUID: $KOZAMGI_UUID"
echo "  Default Account UUID: $DEFAULT_ACCOUNT_UUID"
echo ""

# Get correct sales from MySQL
echo "Getting correct sales from MySQL..."
MYSQL_GAHENGERI_SALES=$("$MYSQL_BIN" -h "$MYSQL_HOST" -u "$MYSQL_USER" -p"$MYSQL_PASS" "$MYSQL_DB" -N -e "SELECT id FROM milk_sales WHERE supplier_account_id = 159 ORDER BY id;" | tr '\n' ',' | sed 's/,$//')
MYSQL_KOZAMGI_SALES=$("$MYSQL_BIN" -h "$MYSQL_HOST" -u "$MYSQL_USER" -p"$MYSQL_PASS" "$MYSQL_DB" -N -e "SELECT id FROM milk_sales WHERE supplier_account_id = 91 ORDER BY id;" | tr '\n' ',' | sed 's/,$//')

echo "  Gahengeri should have: $(echo "$MYSQL_GAHENGERI_SALES" | tr ',' '\n' | wc -l | tr -d ' ') sales"
echo "  KOPERATIVE KOZAMGI should have: $(echo "$MYSQL_KOZAMGI_SALES" | tr ',' '\n' | wc -l | tr -d ' ') sales"
echo ""

# Fix Gahengeri sales
echo "Fixing Gahengeri sales..."
# Get all current sales linked to Gahengeri
CURRENT_GAHENGERI_SALES=$(psql -h "$PG_HOST" -p "$PG_PORT" -U "$PG_USER" -d "$PG_DB" -t -A -c "SELECT legacy_id FROM milk_sales WHERE supplier_account_id = '$GAHENGERI_UUID' AND status != 'deleted' AND legacy_id IS NOT NULL ORDER BY legacy_id;" | tr '\n' ',' | sed 's/,$//')

# Find extra sales (in PostgreSQL but not in MySQL)
echo "  Finding incorrectly linked sales..."
FIXED=0
for sale_id in $(echo "$CURRENT_GAHENGERI_SALES" | tr ',' ' '); do
    # Check if this sale should be linked to Gahengeri
    if echo ",$MYSQL_GAHENGERI_SALES," | grep -q ",$sale_id,"; then
        continue  # Correctly linked
    fi
    
    # Get correct supplier from MySQL
    MYSQL_SUPPLIER=$("$MYSQL_BIN" -h "$MYSQL_HOST" -u "$MYSQL_USER" -p"$MYSQL_PASS" "$MYSQL_DB" -N -e "SELECT supplier_account_id FROM milk_sales WHERE id = $sale_id LIMIT 1;")
    
    if [ -z "$MYSQL_SUPPLIER" ] || [ "$MYSQL_SUPPLIER" = "0" ]; then
        NEW_SUPPLIER_UUID="$DEFAULT_ACCOUNT_UUID"
    else
        NEW_SUPPLIER_UUID=$(psql -h "$PG_HOST" -p "$PG_PORT" -U "$PG_USER" -d "$PG_DB" -t -A -c "SELECT id FROM accounts WHERE legacy_id = $MYSQL_SUPPLIER LIMIT 1;")
        if [ -z "$NEW_SUPPLIER_UUID" ]; then
            NEW_SUPPLIER_UUID="$DEFAULT_ACCOUNT_UUID"
        fi
    fi
    
    # Update the sale
    psql -h "$PG_HOST" -p "$PG_PORT" -U "$PG_USER" -d "$PG_DB" -c "UPDATE milk_sales SET supplier_account_id = '$NEW_SUPPLIER_UUID' WHERE legacy_id = $sale_id;" > /dev/null 2>&1
    FIXED=$((FIXED + 1))
    
    if [ $((FIXED % 100)) -eq 0 ]; then
        echo "    Fixed $FIXED sales..."
    fi
done

echo "  ✅ Fixed $FIXED incorrectly linked sales for Gahengeri"
echo ""

# Fix KOPERATIVE KOZAMGI sales
echo "Fixing KOPERATIVE KOZAMGI sales..."
CURRENT_KOZAMGI_SALES=$(psql -h "$PG_HOST" -p "$PG_PORT" -U "$PG_USER" -d "$PG_DB" -t -A -c "SELECT legacy_id FROM milk_sales WHERE supplier_account_id = '$KOZAMGI_UUID' AND status != 'deleted' AND legacy_id IS NOT NULL ORDER BY legacy_id;" | tr '\n' ',' | sed 's/,$//')

FIXED=0
for sale_id in $(echo "$CURRENT_KOZAMGI_SALES" | tr ',' ' '); do
    if echo ",$MYSQL_KOZAMGI_SALES," | grep -q ",$sale_id,"; then
        continue
    fi
    
    MYSQL_SUPPLIER=$("$MYSQL_BIN" -h "$MYSQL_HOST" -u "$MYSQL_USER" -p"$MYSQL_PASS" "$MYSQL_DB" -N -e "SELECT supplier_account_id FROM milk_sales WHERE id = $sale_id LIMIT 1;")
    
    if [ -z "$MYSQL_SUPPLIER" ] || [ "$MYSQL_SUPPLIER" = "0" ]; then
        NEW_SUPPLIER_UUID="$DEFAULT_ACCOUNT_UUID"
    else
        NEW_SUPPLIER_UUID=$(psql -h "$PG_HOST" -p "$PG_PORT" -U "$PG_USER" -d "$PG_DB" -t -A -c "SELECT id FROM accounts WHERE legacy_id = $MYSQL_SUPPLIER LIMIT 1;")
        if [ -z "$NEW_SUPPLIER_UUID" ]; then
            NEW_SUPPLIER_UUID="$DEFAULT_ACCOUNT_UUID"
        fi
    fi
    
    psql -h "$PG_HOST" -p "$PG_PORT" -U "$PG_USER" -d "$PG_DB" -c "UPDATE milk_sales SET supplier_account_id = '$NEW_SUPPLIER_UUID' WHERE legacy_id = $sale_id;" > /dev/null 2>&1
    FIXED=$((FIXED + 1))
done

echo "  ✅ Fixed $FIXED incorrectly linked sales for KOPERATIVE KOZAMGI"
echo ""

# Fix missing collections for Gahengeri
echo "Fixing missing collections for Gahengeri..."
MYSQL_GAHENGERI_COLLECTIONS=$("$MYSQL_BIN" -h "$MYSQL_HOST" -u "$MYSQL_USER" -p"$MYSQL_PASS" "$MYSQL_DB" -N -e "SELECT id FROM milk_sales WHERE customer_account_id = 159 ORDER BY id;" | tr '\n' ',' | sed 's/,$//')
CURRENT_GAHENGERI_COLLECTIONS=$(psql -h "$PG_HOST" -p "$PG_PORT" -U "$PG_USER" -d "$PG_DB" -t -A -c "SELECT legacy_id FROM milk_sales WHERE customer_account_id = '$GAHENGERI_UUID' AND status != 'deleted' AND legacy_id IS NOT NULL ORDER BY legacy_id;" | tr '\n' ',' | sed 's/,$//')

FIXED=0
for sale_id in $(echo "$MYSQL_GAHENGERI_COLLECTIONS" | tr ',' ' '); do
    if echo ",$CURRENT_GAHENGERI_COLLECTIONS," | grep -q ",$sale_id,"; then
        continue
    fi
    
    # This collection should be linked to Gahengeri
    psql -h "$PG_HOST" -p "$PG_PORT" -U "$PG_USER" -d "$PG_DB" -c "UPDATE milk_sales SET customer_account_id = '$GAHENGERI_UUID' WHERE legacy_id = $sale_id;" > /dev/null 2>&1
    FIXED=$((FIXED + 1))
done

echo "  ✅ Fixed $FIXED missing collections for Gahengeri"
echo ""

# Verify
echo "=========================================="
echo "VERIFICATION"
echo "=========================================="
echo ""

psql -h "$PG_HOST" -p "$PG_PORT" -U "$PG_USER" -d "$PG_DB" << EOF
SELECT 
    'Gahengeri Sales' as metric,
    COUNT(*) as count,
    SUM(quantity) as volume_liters,
    SUM(quantity * unit_price) as value_frw
FROM milk_sales 
WHERE supplier_account_id = '$GAHENGERI_UUID' AND status != 'deleted';

SELECT 
    'Gahengeri Collections' as metric,
    COUNT(*) as count,
    SUM(quantity) as volume_liters,
    SUM(quantity * unit_price) as value_frw
FROM milk_sales 
WHERE customer_account_id = '$GAHENGERI_UUID' AND status != 'deleted';

SELECT 
    'KOPERATIVE KOZAMGI Sales' as metric,
    COUNT(*) as count,
    SUM(quantity) as volume_liters,
    SUM(quantity * unit_price) as value_frw
FROM milk_sales 
WHERE supplier_account_id = '$KOZAMGI_UUID' AND status != 'deleted';

SELECT 
    'KOPERATIVE KOZAMGI Collections' as metric,
    COUNT(*) as count,
    SUM(quantity) as volume_liters,
    SUM(quantity * unit_price) as value_frw
FROM milk_sales 
WHERE customer_account_id = '$KOZAMGI_UUID' AND status != 'deleted';
EOF

echo ""
echo "✅ Fix complete!"
echo ""
