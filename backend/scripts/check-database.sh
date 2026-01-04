#!/bin/bash

# Script to check database connection and verify gemura_db exists
# Run this on the deployment server

echo "=========================================="
echo "Database Connection Check"
echo "=========================================="
echo ""

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

# Default values (should be set in .env)
DB_HOST="${POSTGRES_HOST:-localhost}"
DB_PORT="${POSTGRES_PORT:-5433}"
DB_USER="${POSTGRES_USER:-devslab}"
DB_NAME="${POSTGRES_DB:-gemura_db}"

echo "Database Configuration:"
echo "  Host: $DB_HOST"
echo "  Port: $DB_PORT"
echo "  User: $DB_USER"
echo "  Database: $DB_NAME"
echo ""

# Check if psql is available
if ! command -v psql &> /dev/null; then
    echo -e "${RED}✗ psql is not installed${NC}"
    echo "Install PostgreSQL client: sudo apt-get install postgresql-client"
    exit 1
fi

# Test connection to postgres database first
echo "Testing connection to PostgreSQL server..."
if PGPASSWORD="${POSTGRES_PASSWORD}" psql -h "$DB_HOST" -p "$DB_PORT" -U "$DB_USER" -d postgres -c "SELECT version();" &> /dev/null; then
    echo -e "${GREEN}✓ Successfully connected to PostgreSQL server${NC}"
else
    echo -e "${RED}✗ Failed to connect to PostgreSQL server${NC}"
    echo "Please check:"
    echo "  - PostgreSQL is running"
    echo "  - Host and port are correct"
    echo "  - User credentials are correct"
    echo "  - POSTGRES_PASSWORD environment variable is set"
    exit 1
fi
echo ""

# Check if gemura_db exists
echo "Checking if database '$DB_NAME' exists..."
DB_EXISTS=$(PGPASSWORD="${POSTGRES_PASSWORD}" psql -h "$DB_HOST" -p "$DB_PORT" -U "$DB_USER" -d postgres -tAc "SELECT 1 FROM pg_database WHERE datname='$DB_NAME'" 2>/dev/null)

if [ "$DB_EXISTS" = "1" ]; then
    echo -e "${GREEN}✓ Database '$DB_NAME' exists${NC}"
    
    # Check connection to gemura_db
    echo "Testing connection to '$DB_NAME'..."
    if PGPASSWORD="${POSTGRES_PASSWORD}" psql -h "$DB_HOST" -p "$DB_PORT" -U "$DB_USER" -d "$DB_NAME" -c "SELECT 1;" &> /dev/null; then
        echo -e "${GREEN}✓ Successfully connected to '$DB_NAME'${NC}"
        
        # Check if tables exist
        TABLE_COUNT=$(PGPASSWORD="${POSTGRES_PASSWORD}" psql -h "$DB_HOST" -p "$DB_PORT" -U "$DB_USER" -d "$DB_NAME" -tAc "SELECT COUNT(*) FROM information_schema.tables WHERE table_schema = 'public';" 2>/dev/null)
        if [ -n "$TABLE_COUNT" ]; then
            echo "  Tables in database: $TABLE_COUNT"
            if [ "$TABLE_COUNT" -eq "0" ]; then
                echo -e "${YELLOW}⚠ Database exists but has no tables. Run migrations.${NC}"
            else
                echo -e "${GREEN}✓ Database has tables (migrations may have been run)${NC}"
            fi
        fi
    else
        echo -e "${RED}✗ Cannot connect to '$DB_NAME'${NC}"
        echo "Check database permissions for user '$DB_USER'"
    fi
else
    echo -e "${YELLOW}⚠ Database '$DB_NAME' does not exist${NC}"
    echo "Run: ./create-database.sh to create it"
fi
echo ""

# List all databases
echo "Available databases:"
PGPASSWORD="${POSTGRES_PASSWORD}" psql -h "$DB_HOST" -p "$DB_PORT" -U "$DB_USER" -d postgres -c "\l" | grep -E "Name|gemura|resolveit" || echo "  (Could not list databases)"
echo ""

echo "=========================================="
echo "Summary:"
echo "=========================================="
echo "If database connection works, you can proceed with:"
echo "  1. Create database (if needed): ./create-database.sh"
echo "  2. Run migrations: npx prisma migrate deploy"
echo "  3. Start backend: docker-compose up -d"
echo ""

