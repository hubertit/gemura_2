#!/bin/bash

# Gemura Backend Automated Deployment Script
# Run this on the deployment server

set -e  # Exit on error

echo "=========================================="
echo "Gemura Backend Deployment"
echo "=========================================="
echo ""

# Colors
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m'

# Check if .env exists
if [ ! -f .env ]; then
    echo -e "${YELLOW}⚠ .env file not found.${NC}"
    if [ -f env.example ]; then
        echo -e "${YELLOW}Creating .env from env.example...${NC}"
        cp env.example .env
        echo -e "${YELLOW}⚠ Please edit .env and set POSTGRES_PASSWORD${NC}"
        echo "Press Enter to continue after editing .env..."
        read
    else
        echo -e "${RED}✗ env.example not found. Please create .env manually.${NC}"
        exit 1
    fi
fi

# Load environment variables
export $(cat .env | grep -v '^#' | xargs)

# Step 1: Pre-deployment checks
echo "Step 1: Running pre-deployment checks..."
echo "----------------------------------------"
if [ -f backend/scripts/pre-deployment-check.sh ]; then
    cd backend
    ./scripts/pre-deployment-check.sh
    cd ..
else
    echo -e "${YELLOW}⚠ Pre-deployment script not found, skipping...${NC}"
fi
echo ""

# Step 2: Create database
echo "Step 2: Creating database..."
echo "----------------------------"
if [ -f backend/scripts/create-database.sh ]; then
    cd backend/scripts
    if [ -z "$POSTGRES_PASSWORD" ]; then
        echo -e "${RED}✗ POSTGRES_PASSWORD not set in .env${NC}"
        exit 1
    fi
    export POSTGRES_PASSWORD
    ./create-database.sh
    cd ../..
else
    echo -e "${YELLOW}⚠ Database creation script not found${NC}"
    echo "Creating database manually..."
    PGPASSWORD="$POSTGRES_PASSWORD" psql -h localhost -p ${POSTGRES_PORT:-5433} -U ${POSTGRES_USER:-devslab} -d postgres -c "CREATE DATABASE ${POSTGRES_DB:-gemura_db};" 2>/dev/null || echo "Database may already exist"
    PGPASSWORD="$POSTGRES_PASSWORD" psql -h localhost -p ${POSTGRES_PORT:-5433} -U ${POSTGRES_USER:-devslab} -d ${POSTGRES_DB:-gemura_db} -c "GRANT ALL PRIVILEGES ON DATABASE ${POSTGRES_DB:-gemura_db} TO ${POSTGRES_USER:-devslab};" 2>/dev/null || true
fi
echo ""

# Step 3: Build and deploy
echo "Step 3: Building and deploying with Docker..."
echo "---------------------------------------------"
docker-compose down 2>/dev/null || true
docker-compose build --no-cache
docker-compose up -d

echo ""
echo "Waiting for services to start..."
sleep 10

# Step 4: Verify deployment
echo ""
echo "Step 4: Verifying deployment..."
echo "--------------------------------"

# Check container status
if docker-compose ps | grep -q "gemura-backend.*Up"; then
    echo -e "${GREEN}✓ Backend container is running${NC}"
else
    echo -e "${RED}✗ Backend container is not running${NC}"
    echo "Check logs: docker-compose logs backend"
    exit 1
fi

# Check health endpoint
HEALTH_URL="http://localhost:${BACKEND_PORT:-3004}/api/health"
echo "Testing health endpoint: $HEALTH_URL"
if curl -f -s "$HEALTH_URL" > /dev/null; then
    echo -e "${GREEN}✓ Health endpoint is responding${NC}"
    curl -s "$HEALTH_URL" | head -5
else
    echo -e "${YELLOW}⚠ Health endpoint not responding yet (may need more time)${NC}"
fi

echo ""
echo "=========================================="
echo "Deployment Complete!"
echo "=========================================="
echo ""
echo "Backend API: http://159.198.65.38:${BACKEND_PORT:-3004}"
echo "API Docs: http://159.198.65.38:${BACKEND_PORT:-3004}/api/docs"
echo "Health: http://159.198.65.38:${BACKEND_PORT:-3004}/api/health"
echo ""
echo "View logs: docker-compose logs -f backend"
echo "Stop: docker-compose down"
echo ""

