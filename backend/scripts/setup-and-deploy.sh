#!/bin/bash

# Complete setup and deployment script for Gemura Backend
# Run this on the deployment server

set -e

echo "=========================================="
echo "Gemura Backend - Complete Setup & Deployment"
echo "=========================================="
echo ""

GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m'

# Get script directory
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
PROJECT_ROOT="$( cd "$SCRIPT_DIR/../.." && pwd )"

cd "$PROJECT_ROOT"

# Check if .env exists
if [ ! -f .env ]; then
    echo -e "${YELLOW}Creating .env from env.example...${NC}"
    if [ -f env.example ]; then
        cp env.example .env
        echo -e "${YELLOW}⚠ Please edit .env and set POSTGRES_PASSWORD${NC}"
        echo "Press Enter after editing .env..."
        read
    else
        echo -e "${RED}✗ env.example not found${NC}"
        exit 1
    fi
fi

# Load environment
export $(cat .env | grep -v '^#' | xargs)

# Step 1: Pre-deployment checks
echo ""
echo "Step 1: Pre-deployment checks..."
echo "--------------------------------"
cd backend
if [ -f scripts/pre-deployment-check.sh ]; then
    ./scripts/pre-deployment-check.sh
fi
cd "$PROJECT_ROOT"
echo ""

# Step 2: Create database
echo "Step 2: Creating database..."
echo "---------------------------"
cd backend/scripts
if [ -z "$POSTGRES_PASSWORD" ]; then
    echo -e "${RED}✗ POSTGRES_PASSWORD not set in .env${NC}"
    exit 1
fi

export POSTGRES_PASSWORD
if [ -f create-database.sh ]; then
    ./create-database.sh
else
    echo "Creating database manually..."
    PGPASSWORD="$POSTGRES_PASSWORD" psql -h localhost -p ${POSTGRES_PORT:-5433} -U ${POSTGRES_USER:-devslab} -d postgres -c "CREATE DATABASE ${POSTGRES_DB:-gemura_db};" 2>/dev/null || echo "Database may already exist"
    PGPASSWORD="$POSTGRES_PASSWORD" psql -h localhost -p ${POSTGRES_PORT:-5433} -U ${POSTGRES_USER:-devslab} -d ${POSTGRES_DB:-gemura_db} -c "GRANT ALL PRIVILEGES ON DATABASE ${POSTGRES_DB:-gemura_db} TO ${POSTGRES_USER:-devslab};" 2>/dev/null || true
fi
cd "$PROJECT_ROOT"
echo ""

# Step 3: Generate Prisma Client (if Node.js available)
echo "Step 3: Generating Prisma Client..."
echo "-----------------------------------"
if command -v node &> /dev/null && [ -f backend/package.json ]; then
    cd backend
    if [ ! -d node_modules ]; then
        echo "Installing dependencies..."
        npm install
    fi
    echo "Generating Prisma Client..."
    npx prisma generate
    cd "$PROJECT_ROOT"
else
    echo -e "${YELLOW}⚠ Node.js not available, Prisma Client will be generated in Docker${NC}"
fi
echo ""

# Step 4: Build and deploy
echo "Step 4: Building and deploying with Docker..."
echo "---------------------------------------------"
docker-compose down 2>/dev/null || true
echo "Building Docker images..."
docker-compose build --no-cache
echo "Starting services..."
docker-compose up -d

echo ""
echo "Waiting for services to start (30 seconds)..."
sleep 30

# Step 5: Verify deployment
echo ""
echo "Step 5: Verifying deployment..."
echo "-------------------------------"

# Check container
if docker-compose ps | grep -q "gemura-backend.*Up"; then
    echo -e "${GREEN}✓ Backend container is running${NC}"
else
    echo -e "${RED}✗ Backend container is not running${NC}"
    echo "Checking logs..."
    docker-compose logs backend | tail -20
    exit 1
fi

# Check health
HEALTH_URL="http://localhost:${BACKEND_PORT:-3004}/api/health"
echo "Testing health endpoint..."
for i in {1..10}; do
    if curl -f -s "$HEALTH_URL" > /dev/null 2>&1; then
        echo -e "${GREEN}✓ Health endpoint is responding${NC}"
        curl -s "$HEALTH_URL" | python3 -m json.tool 2>/dev/null || curl -s "$HEALTH_URL"
        break
    else
        if [ $i -eq 10 ]; then
            echo -e "${YELLOW}⚠ Health endpoint not responding (check logs)${NC}"
        else
            echo "Waiting for service... ($i/10)"
            sleep 3
        fi
    fi
done

# Check migrations
echo ""
echo "Checking database migrations..."
if docker-compose exec -T backend npx prisma migrate status 2>/dev/null | grep -q "Database schema is up to date"; then
    echo -e "${GREEN}✓ Database migrations applied${NC}"
else
    echo -e "${YELLOW}⚠ Checking migration status...${NC}"
    docker-compose exec -T backend npx prisma migrate status || true
fi

# Run post-deployment tests
echo ""
echo "Step 6: Running post-deployment tests..."
echo "---------------------------------------"
if [ -f scripts/test-deployment-remote.sh ]; then
    cd "$PROJECT_ROOT"
    ./backend/scripts/test-deployment-remote.sh localhost ${BACKEND_PORT:-3004} || {
        echo -e "${YELLOW}⚠ Some tests failed, but deployment may still be successful${NC}"
        echo "Check logs: docker-compose logs backend"
    }
else
    echo -e "${YELLOW}⚠ Test script not found, skipping automated tests${NC}"
fi

echo ""
echo "=========================================="
echo -e "${GREEN}Deployment Complete!${NC}"
echo "=========================================="
echo ""
echo "🌐 Access Points:"
echo "  Backend API: http://159.198.65.38:${BACKEND_PORT:-3004}"
echo "  API Docs: http://159.198.65.38:${BACKEND_PORT:-3004}/api/docs"
echo "  Health: http://159.198.65.38:${BACKEND_PORT:-3004}/api/health"
echo ""
echo "📋 Useful Commands:"
echo "  View logs: docker-compose logs -f backend"
echo "  Restart: docker-compose restart backend"
echo "  Stop: docker-compose down"
echo "  Status: docker-compose ps"
echo ""

