#!/bin/bash
# Run payroll migration via Docker container

set -e

echo "🔄 Running Payroll Migration..."

# Database connection details
DB_HOST="${DB_HOST:-devslab-postgres}"
DB_PORT="${DB_PORT:-5432}"
DB_NAME="${DB_NAME:-gemura_db}"
DB_USER="${DB_USER:-devslab_admin}"
DB_PASSWORD="${DB_PASSWORD:-devslab_secure_password_2024}"

# Migration file path
MIGRATION_FILE="/app/prisma/migrations/20260104_change_payroll_to_suppliers/migration.sql"

# Export password for psql
export PGPASSWORD="$DB_PASSWORD"

# Run migration
echo "📝 Executing migration SQL..."
psql -h "$DB_HOST" -p "$DB_PORT" -U "$DB_USER" -d "$DB_NAME" -f "$MIGRATION_FILE"

# Verify migration
echo ""
echo "✅ Verifying migration..."
psql -h "$DB_HOST" -p "$DB_PORT" -U "$DB_USER" -d "$DB_NAME" -c "\d payroll_suppliers" > /dev/null 2>&1 && echo "✅ payroll_suppliers table exists" || echo "⚠️  Table check failed"

echo ""
echo "✅ Migration complete!"

