#!/bin/bash

# Check and display all available ports on remote server (3000-3020)
# Shows which ports are available and which are in use

SERVER_IP="${1:-159.198.65.38}"
SERVER_USER="${2:-root}"
SERVER_PASS="${3:-QF87VtuYReX5v9p6e3}"

echo "=========================================="
echo "Checking Available Ports on $SERVER_IP"
echo "Range: 3000-3020"
echo "=========================================="
echo ""

GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

AVAILABLE_PORTS=()
IN_USE_PORTS=()

for port in {3000..3020}; do
    echo -n "Port $port: "
    
    # Check if port is listening
    result=$(sshpass -p "$SERVER_PASS" ssh -o StrictHostKeyChecking=no $SERVER_USER@$SERVER_IP \
        "netstat -tuln 2>/dev/null | grep -q ':$port ' || ss -tuln 2>/dev/null | grep -q ':$port ' || echo 'available'" 2>/dev/null)
    
    if [ "$result" = "available" ]; then
        # Double check by trying to connect via HTTP
        http_code=$(curl -s -o /dev/null -w "%{http_code}" --connect-timeout 2 http://$SERVER_IP:$port 2>/dev/null || echo "000")
        
        if [ "$http_code" = "000" ] || [ -z "$http_code" ]; then
            echo -e "${GREEN}✓ AVAILABLE${NC}"
            AVAILABLE_PORTS+=($port)
        else
            echo -e "${RED}✗ IN USE${NC} (HTTP $http_code)"
            IN_USE_PORTS+=($port)
        fi
    else
        echo -e "${RED}✗ IN USE${NC} (listening)"
        IN_USE_PORTS+=($port)
    fi
done

echo ""
echo "=========================================="
echo "Summary"
echo "=========================================="
echo ""

if [ ${#AVAILABLE_PORTS[@]} -gt 0 ]; then
    echo -e "${GREEN}Available Ports: ${AVAILABLE_PORTS[*]}${NC}"
    echo ""
    echo -e "${BLUE}Recommended: Use port ${AVAILABLE_PORTS[0]}${NC}"
    echo ""
    echo "To deploy with a specific port:"
    echo "  ./scripts/deployment/deploy-to-server.sh ${AVAILABLE_PORTS[0]}"
else
    echo -e "${RED}❌ No available ports found in range 3000-3020${NC}"
    exit 1
fi

if [ ${#IN_USE_PORTS[@]} -gt 0 ]; then
    echo -e "${YELLOW}Ports In Use: ${IN_USE_PORTS[*]}${NC}"
fi

echo ""
echo "=========================================="

# Export first available port for use in other scripts
export FIRST_AVAILABLE_PORT=${AVAILABLE_PORTS[0]}
echo "$FIRST_AVAILABLE_PORT"
