#!/bin/bash

# Deploy Gemura Backend to Server
# Run this script on the server (159.198.65.38)

set -e

GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

echo "=========================================="
echo "Deploying Gemura Backend"
echo "=========================================="
echo ""

# Check if we're in the right directory
if [ ! -f "docker-compose.gemura.yml" ]; then
    echo -e "${RED}✗ Error: docker-compose.gemura.yml not found${NC}"
    echo "Please run this script from the project root directory"
    exit 1
fi

# Check if .env.devlabs exists
if [ ! -f ".env.devlabs" ]; then
    echo -e "${YELLOW}⚠ .env.devlabs not found${NC}"
    echo "Creating .env.devlabs with default values..."
    cat > .env.devlabs << EOF
DATABASE_URL=postgresql://devslab_admin:devslab_secure_password_2024@devslab-postgres:5432/gemura_db
NODE_ENV=production
PORT=3004
CORS_ORIGIN=http://localhost:3005,http://localhost:3004,http://159.198.65.38:3005,http://159.198.65.38:3004
EOF
    echo -e "${GREEN}✓ Created .env.devlabs${NC}"
fi

# Step 1: Check if DevLabs PostgreSQL is running
echo -e "${BLUE}Step 1: Checking DevLabs PostgreSQL...${NC}"
if docker ps | grep -q devslab-postgres; then
    echo -e "${GREEN}✓ DevLabs PostgreSQL is running${NC}"
else
    echo -e "${YELLOW}⚠ DevLabs PostgreSQL not running, starting it...${NC}"
    if [ -f "docker-compose.devlabs-db.yml" ]; then
        docker-compose -f docker-compose.devlabs-db.yml up -d
        echo "Waiting for PostgreSQL to be ready..."
        sleep 10
    else
        echo -e "${RED}✗ docker-compose.devlabs-db.yml not found${NC}"
        echo "Please ensure DevLabs PostgreSQL is running"
    fi
fi
echo ""

# Step 2: Stop existing backend if running
echo -e "${BLUE}Step 2: Stopping existing backend...${NC}"
docker-compose -f docker-compose.gemura.yml down 2>/dev/null || true
echo -e "${GREEN}✓ Stopped existing containers${NC}"
echo ""

# Step 3: Build backend image
echo -e "${BLUE}Step 3: Building backend Docker image...${NC}"
docker-compose -f docker-compose.gemura.yml build --no-cache backend
echo -e "${GREEN}✓ Backend image built${NC}"
echo ""

# Step 4: Start backend
echo -e "${BLUE}Step 4: Starting backend container...${NC}"
docker-compose -f docker-compose.gemura.yml up -d backend
echo -e "${GREEN}✓ Backend container started${NC}"
echo ""

# Step 5: Wait for backend to be ready
echo -e "${BLUE}Step 5: Waiting for backend to be ready...${NC}"
sleep 15

# Step 6: Check container status
echo -e "${BLUE}Step 6: Checking container status...${NC}"
if docker ps | grep -q gemura-backend; then
    echo -e "${GREEN}✓ Backend container is running${NC}"
    docker ps | grep gemura-backend
else
    echo -e "${RED}✗ Backend container is not running${NC}"
    echo "Checking logs..."
    docker-compose -f docker-compose.gemura.yml logs backend | tail -20
    exit 1
fi
echo ""

# Step 7: Test health endpoint
echo -e "${BLUE}Step 7: Testing health endpoint...${NC}"
for i in {1..10}; do
    if curl -s --max-time 5 http://localhost:3004/api/health > /dev/null 2>&1; then
        echo -e "${GREEN}✓ Health endpoint is responding${NC}"
        curl -s http://localhost:3004/api/health | head -5
        break
    else
        if [ $i -eq 10 ]; then
            echo -e "${YELLOW}⚠ Health endpoint not responding yet${NC}"
            echo "Checking logs..."
            docker-compose -f docker-compose.gemura.yml logs backend | tail -30
        else
            echo "Waiting for backend... ($i/10)"
            sleep 3
        fi
    fi
done
echo ""

# Summary
echo "=========================================="
echo -e "${GREEN}Deployment Complete!${NC}"
echo "=========================================="
echo ""
echo "Backend API: http://159.198.65.38:3004/api"
echo "API Docs: http://159.198.65.38:3004/api/docs"
echo "Health: http://159.198.65.38:3004/api/health"
echo ""
echo "Useful commands:"
echo "  View logs: docker-compose -f docker-compose.gemura.yml logs -f backend"
echo "  Restart: docker-compose -f docker-compose.gemura.yml restart backend"
echo "  Stop: docker-compose -f docker-compose.gemura.yml down"
echo "  Status: docker-compose -f docker-compose.gemura.yml ps"
echo ""
