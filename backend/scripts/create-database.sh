#!/bin/bash

# Create Gemura database on shared devslab Postgres instance
# Usage: ./scripts/create-database.sh

set -e

echo "🗄️  Creating Gemura database on devslab Postgres..."

# Database configuration
DB_HOST="${DB_HOST:-localhost}"
DB_PORT="${DB_PORT:-5433}"
DB_USER="${DB_USER:-devslab}"
DB_NAME="${DB_NAME:-gemura_db}"

# Check if database already exists
if psql -h "$DB_HOST" -p "$DB_PORT" -U "$DB_USER" -d postgres -tc "SELECT 1 FROM pg_database WHERE datname = '$DB_NAME'" | grep -q 1; then
    echo "⚠️  Database '$DB_NAME' already exists. Skipping creation."
else
    echo "📦 Creating database '$DB_NAME'..."
    psql -h "$DB_HOST" -p "$DB_PORT" -U "$DB_USER" -d postgres -c "CREATE DATABASE $DB_NAME;"
    echo "✅ Database '$DB_NAME' created successfully!"
fi

# Grant privileges
echo "🔐 Granting privileges..."
psql -h "$DB_HOST" -p "$DB_PORT" -U "$DB_USER" -d postgres -c "GRANT ALL PRIVILEGES ON DATABASE $DB_NAME TO $DB_USER;" || true

echo "✅ Database setup complete!"
echo ""
echo "Next steps:"
echo "1. Set DATABASE_URL in .env: postgresql://$DB_USER:password@$DB_HOST:$DB_PORT/$DB_NAME?schema=public"
echo "2. Run: npm run prisma:migrate"
echo "3. Run: npm run prisma:generate"

