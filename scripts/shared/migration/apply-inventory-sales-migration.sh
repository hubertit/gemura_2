#!/bin/bash

# Apply inventory_sales migration to remote database
# This can be run on the server if the table doesn't exist

set -e

echo "🔄 Applying inventory_sales migration to remote database"
echo "=========================================================="
echo ""

# Server details (if running locally, modify these)
SERVER_IP="${SERVER_IP:-159.198.65.38}"
SERVER_USER="${SERVER_USER:-root}"
SERVER_PASS="${SERVER_PASS:-QF87VtuYReX5v9p6e3}"

# Database connection details
DB_HOST="devslab-postgres"
DB_PORT="5432"
DB_NAME="gemura_db"
DB_USER="devslab_admin"
DB_PASSWORD="devslab_secure_password_2024"

# Migration file path
MIGRATION_FILE="backend/prisma/migrations/20250120000000_add_inventory_sales/migration.sql"

if [ ! -f "$MIGRATION_FILE" ]; then
    echo "❌ Migration file not found: $MIGRATION_FILE"
    exit 1
fi

echo "📤 Uploading migration file to server..."
sshpass -p "$SERVER_PASS" scp -o StrictHostKeyChecking=no "$MIGRATION_FILE" "$SERVER_USER@$SERVER_IP:/tmp/inventory_sales_migration.sql"

echo ""
echo "🔧 Applying migration on server..."
sshpass -p "$SERVER_PASS" ssh -o StrictHostKeyChecking=no $SERVER_USER@$SERVER_IP << EOF
export PGPASSWORD="$DB_PASSWORD"

echo "Checking if inventory_sales table exists..."
docker exec -i $DB_HOST psql -U $DB_USER -d $DB_NAME -c "\d inventory_sales" 2>&1 | head -5 || echo "Table does not exist, will create it"

echo ""
echo "Applying migration..."
docker exec -i $DB_HOST psql -U $DB_USER -d $DB_NAME < /tmp/inventory_sales_migration.sql

echo ""
echo "Verifying table creation..."
docker exec -i $DB_HOST psql -U $DB_USER -d $DB_NAME -c "\d inventory_sales" 2>&1 | head -20

echo ""
echo "Cleaning up..."
rm -f /tmp/inventory_sales_migration.sql

echo ""
echo "✅ Migration complete!"
EOF

echo ""
echo "✅ Migration applied successfully!"
