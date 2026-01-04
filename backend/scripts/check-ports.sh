#!/bin/bash

# Script to check port availability on the server
# Run this on the deployment server before deploying

echo "=========================================="
echo "Port Availability Check for Gemura"
echo "=========================================="
echo ""

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Function to check if port is in use
check_port() {
    local port=$1
    local service=$2
    
    if command -v netstat &> /dev/null; then
        if netstat -tuln | grep -q ":$port "; then
            echo -e "${RED}✗ Port $port is IN USE${NC} - $service"
            netstat -tuln | grep ":$port " | head -1
            return 1
        else
            echo -e "${GREEN}✓ Port $port is AVAILABLE${NC} - $service"
            return 0
        fi
    elif command -v ss &> /dev/null; then
        if ss -tuln | grep -q ":$port "; then
            echo -e "${RED}✗ Port $port is IN USE${NC} - $service"
            ss -tuln | grep ":$port " | head -1
            return 1
        else
            echo -e "${GREEN}✓ Port $port is AVAILABLE${NC} - $service"
            return 0
        fi
    elif command -v lsof &> /dev/null; then
        if lsof -i :$port &> /dev/null; then
            echo -e "${RED}✗ Port $port is IN USE${NC} - $service"
            lsof -i :$port | head -2
            return 1
        else
            echo -e "${GREEN}✓ Port $port is AVAILABLE${NC} - $service"
            return 0
        fi
    else
        echo -e "${YELLOW}⚠ Cannot check port $port - no port checking tool available${NC}"
        return 2
    fi
}

# Check Gemura ports (3002-3010 range)
echo "Checking Gemura Ports (3002-3010):"
echo "-----------------------------------"
check_port 3002 "Gemura Backend API"
check_port 3003 "Gemura Frontend (future)"
check_port 3004 "Gemura Service (reserved)"
check_port 3005 "Gemura Service (reserved)"
check_port 3006 "Gemura Service (reserved)"
check_port 3007 "Gemura Service (reserved)"
check_port 3008 "Gemura Service (reserved)"
check_port 3009 "Gemura Service (reserved)"
check_port 3010 "Gemura Service (reserved)"
echo ""

# Check ResolveIt ports (should be in use)
echo "Checking ResolveIt Ports (should be in use):"
echo "--------------------------------------------"
check_port 3000 "ResolveIt Backend"
check_port 3001 "ResolveIt Frontend"
check_port 5433 "ResolveIt PostgreSQL"
echo ""

# Check common Docker ports
echo "Checking Common Docker Ports:"
echo "----------------------------"
check_port 5432 "PostgreSQL (default)"
check_port 3306 "MySQL (default)"
check_port 8080 "Common web server"
check_port 80 "HTTP"
check_port 443 "HTTPS"
echo ""

# Check if Docker is running
echo "Docker Status:"
echo "--------------"
if command -v docker &> /dev/null; then
    if docker ps &> /dev/null; then
        echo -e "${GREEN}✓ Docker is running${NC}"
        echo ""
        echo "Running Docker containers:"
        docker ps --format "table {{.Names}}\t{{.Ports}}\t{{.Status}}"
    else
        echo -e "${YELLOW}⚠ Docker is installed but not accessible (may need sudo)${NC}"
    fi
else
    echo -e "${RED}✗ Docker is not installed${NC}"
fi
echo ""

# Summary
echo "=========================================="
echo "Summary:"
echo "=========================================="
echo "If port 3002 is available, Gemura backend can be deployed."
echo "If port 3003 is available, Gemura frontend can be deployed."
echo "Ports 3004-3010 are reserved for future services."
echo ""
echo "Port allocation:"
echo "  - 3000: ResolveIt Backend"
echo "  - 3001: ResolveIt Frontend"
echo "  - 3002: Gemura Backend API"
echo "  - 3003: Gemura Frontend (future)"
echo "  - 3004-3010: Reserved for Gemura services"
echo ""
echo "To use different ports, update:"
echo "  - docker-compose.yml (BACKEND_PORT, FRONTEND_PORT)"
echo "  - .env file (PORT, BACKEND_PORT, FRONTEND_PORT)"
echo ""

