#!/bin/bash

# Run Payroll Migration Script
# This script runs the payroll schema migration on the server

set -e

echo "🔄 Running Payroll Migration..."
echo "=================================="

# Server details
SERVER="root@159.198.65.38"
MIGRATION_FILE="backend/prisma/migrations/20260104_change_payroll_to_suppliers/migration.sql"
REMOTE_PATH="/opt/gemura"

# Database connection details (from docker-compose)
DB_HOST="devslab-postgres"
DB_PORT="5432"
DB_NAME="gemura_db"
DB_USER="devslab_admin"
DB_PASSWORD="devslab_secure_password_2024"

echo "📤 Uploading migration file..."
scp "$MIGRATION_FILE" "$SERVER:$REMOTE_PATH/migration.sql"

echo "🔧 Running migration on server..."
ssh "$SERVER" << EOF
cd $REMOTE_PATH

# Run migration via Docker exec (using the postgres container)
docker exec -i devslab-postgres psql -U $DB_USER -d $DB_NAME < migration.sql

# Verify migration
echo ""
echo "✅ Verifying migration..."
docker exec -i devslab-postgres psql -U $DB_USER -d $DB_NAME -c "\d payroll_suppliers" || echo "⚠️  Table check failed"

# Cleanup
rm -f migration.sql

echo ""
echo "✅ Migration complete!"
EOF

echo ""
echo "🎉 Migration executed successfully!"
echo ""
echo "Next steps:"
echo "1. Test payroll suppliers endpoints"
echo "2. Add suppliers to payroll system"
echo "3. Process payroll runs"

