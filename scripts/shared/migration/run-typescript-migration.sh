#!/bin/bash

# Run TypeScript Migration Service on Server
# This uses the NestJS migration service which handles MySQL connection properly

set -e

SERVER_IP="159.198.65.38"
SERVER_USER="root"
SERVER_PASS="QF87VtuYReX5v9p6e3"
REMOTE_PATH="/opt/gemura"

echo "🔄 Running TypeScript Migration Service"
echo "========================================"
echo ""

# Run migration on server
sshpass -p "$SERVER_PASS" ssh -o StrictHostKeyChecking=no $SERVER_USER@$SERVER_IP << 'ENDSSH'
cd /opt/gemura/backend

# Set environment variables
export DATABASE_URL="postgresql://devslab_admin:devslab_secure_password_2024@devslab-postgres:5432/gemura_db"
export V1_DB_HOST="localhost"
export V1_DB_PORT="3306"
export V1_DB_USER="devsvknl_admin"
export V1_DB_PASSWORD="]LdUd=a6{-vq"
export V1_DB_NAME="devsvknl_gemura"

echo "📊 Current PostgreSQL Counts:"
docker exec -i devslab-postgres psql -U devslab_admin -d gemura_db -c "
SELECT 
    'accounts' as table_name, COUNT(*) as count FROM accounts
UNION ALL
SELECT 'users', COUNT(*) FROM users
UNION ALL
SELECT 'user_accounts', COUNT(*) FROM user_accounts;
"

echo ""
echo "🔄 Running migration..."
echo ""

# Run the TypeScript migration
npm run migrate 2>&1 | tee /tmp/migration.log

echo ""
echo "📊 Final PostgreSQL Counts:"
docker exec -i devslab-postgres psql -U devslab_admin -d gemura_db -c "
SELECT 
    'accounts' as table_name, COUNT(*) as count FROM accounts
UNION ALL
SELECT 'users', COUNT(*) FROM users
UNION ALL
SELECT 'user_accounts', COUNT(*) FROM user_accounts;
"

echo ""
echo "✅ Migration completed!"
ENDSSH

echo ""
echo "✅ Migration process finished!"
