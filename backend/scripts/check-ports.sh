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

# Check all ports from 3000 to 3010
echo "Checking Ports 3000-3010:"
echo "------------------------"
for port in {3000..3010}; do
    case $port in
        3000)
            check_port $port "ResolveIt Backend (expected in use)"
            ;;
        3001)
            check_port $port "ResolveIt Frontend (expected in use)"
            ;;
        3002)
            check_port $port "Gemura Backend API (should be available)"
            ;;
        3003)
            check_port $port "Gemura Frontend (should be available)"
            ;;
        *)
            check_port $port "Available for Gemura services"
            ;;
    esac
done
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

# Summary with availability status
echo "=========================================="
echo "Port Availability Summary (3000-3010):"
echo "=========================================="
echo ""
echo "Port Status:"
AVAILABLE_PORTS=()
IN_USE_PORTS=()

for port in {3000..3010}; do
    if check_port $port "Port $port" &>/dev/null; then
        AVAILABLE_PORTS+=($port)
    else
        IN_USE_PORTS+=($port)
    fi
done

echo ""
echo "Available Ports: ${AVAILABLE_PORTS[*]}"
echo "Ports In Use: ${IN_USE_PORTS[*]}"
echo ""
echo "Recommended Allocation:"
echo "  - 3000: ResolveIt Backend (expected in use)"
echo "  - 3001: ResolveIt Frontend (expected in use)"
echo "  - 3002: Gemura Backend API (should be available)"
echo "  - 3003: Gemura Frontend (should be available)"
echo "  - 3004-3010: Available for Gemura additional services"
echo ""
if [[ " ${AVAILABLE_PORTS[@]} " =~ " 3002 " ]]; then
    echo -e "${GREEN}✓ Port 3002 is available - Gemura backend can be deployed${NC}"
else
    echo -e "${RED}✗ Port 3002 is in use - Choose alternative port from available list${NC}"
fi
echo ""

