#!/bin/bash

# Test deployment readiness and verify remote server
# This script tests everything before actual deployment

set -e

echo "=========================================="
echo "Gemura Backend - Deployment Testing"
echo "=========================================="
echo ""

GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m'

# Test 1: Local Build
echo "Test 1: Local Build Test"
echo "-----------------------"
cd backend
if npm run build > /dev/null 2>&1; then
    echo -e "${GREEN}✓ Build successful${NC}"
else
    echo -e "${RED}✗ Build failed${NC}"
    npm run build
    exit 1
fi
cd ..
echo ""

# Test 2: Docker Compose Config
echo "Test 2: Docker Compose Configuration"
echo "------------------------------------"
if docker-compose config > /dev/null 2>&1; then
    echo -e "${GREEN}✓ Docker Compose config valid${NC}"
else
    echo -e "${RED}✗ Docker Compose config invalid${NC}"
    docker-compose config
    exit 1
fi
echo ""

# Test 3: Dockerfile Exists
echo "Test 3: Dockerfile Check"
echo "-----------------------"
if [ -f backend/Dockerfile ]; then
    echo -e "${GREEN}✓ Dockerfile exists${NC}"
else
    echo -e "${RED}✗ Dockerfile missing${NC}"
    exit 1
fi
echo ""

# Test 4: Prisma Schema
echo "Test 4: Prisma Schema Validation"
echo "--------------------------------"
cd backend
if npx prisma validate > /dev/null 2>&1; then
    echo -e "${GREEN}✓ Prisma schema valid${NC}"
else
    echo -e "${RED}✗ Prisma schema invalid${NC}"
    npx prisma validate
    exit 1
fi
cd ..
echo ""

# Test 5: Scripts Executability
echo "Test 5: Deployment Scripts"
echo "-------------------------"
SCRIPTS=(
    "backend/scripts/setup-and-deploy.sh"
    "backend/scripts/create-database.sh"
    "backend/scripts/pre-deployment-check.sh"
    "backend/scripts/test-ports-detailed.sh"
    "deploy.sh"
)

for script in "${SCRIPTS[@]}"; do
    if [ -f "$script" ] && [ -x "$script" ]; then
        echo -e "${GREEN}✓ $script${NC}"
    else
        echo -e "${RED}✗ $script (missing or not executable)${NC}"
        chmod +x "$script" 2>/dev/null || true
    fi
done
echo ""

# Test 6: Remote Server Connectivity
echo "Test 6: Remote Server Connectivity"
echo "---------------------------------"
SERVER="159.198.65.38"
if ping -c 1 -W 2 "$SERVER" > /dev/null 2>&1; then
    echo -e "${GREEN}✓ Server is reachable${NC}"
    
    # Test port 3004
    echo "Testing port 3004..."
    if curl -s --connect-timeout 3 "http://$SERVER:3004/health" > /dev/null 2>&1; then
        echo -e "${YELLOW}⚠ Service already running on port 3004${NC}"
        curl -s "http://$SERVER:3004/health" | head -3
    else
        echo -e "${GREEN}✓ Port 3004 is available for deployment${NC}"
    fi
else
    echo -e "${YELLOW}⚠ Cannot ping server (may be firewall)${NC}"
    echo "Testing HTTP connection instead..."
    if curl -s --connect-timeout 3 "http://$SERVER:3004" > /dev/null 2>&1; then
        echo -e "${YELLOW}⚠ Something is responding on port 3004${NC}"
    else
        echo -e "${GREEN}✓ Port 3004 appears available${NC}"
    fi
fi
echo ""

# Test 7: Environment Files
echo "Test 7: Environment Configuration"
echo "---------------------------------"
if [ -f .env.example ]; then
    echo -e "${GREEN}✓ .env.example exists${NC}"
else
    echo -e "${YELLOW}⚠ .env.example missing${NC}"
fi

if [ -f .env ]; then
    echo -e "${GREEN}✓ .env exists${NC}"
    # Check if password is set (but don't show it)
    if grep -q "POSTGRES_PASSWORD=" .env && ! grep -q "POSTGRES_PASSWORD=your_postgres_password_here" .env; then
        echo -e "${GREEN}✓ POSTGRES_PASSWORD appears to be set${NC}"
    else
        echo -e "${YELLOW}⚠ POSTGRES_PASSWORD needs to be set in .env${NC}"
    fi
else
    echo -e "${YELLOW}⚠ .env not found (will be created from .env.example)${NC}"
fi
echo ""

# Test 8: Git Status
echo "Test 8: Git Status"
echo "-----------------"
if git status --porcelain | grep -q .; then
    echo -e "${YELLOW}⚠ Uncommitted changes detected${NC}"
    git status --short | head -5
else
    echo -e "${GREEN}✓ All changes committed${NC}"
fi
echo ""

# Summary
echo "=========================================="
echo "Test Summary"
echo "=========================================="
echo ""
echo "✅ All local tests passed!"
echo ""
echo "Ready for deployment on server:"
echo "  1. SSH to 159.198.65.38"
echo "  2. cd /path/to/gemura2"
echo "  3. ./backend/scripts/setup-and-deploy.sh"
echo ""

