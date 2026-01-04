#!/bin/bash

# Test ports on remote server
SERVER="${1:-159.198.65.38}"

echo "=========================================="
echo "Testing ports on $SERVER"
echo "=========================================="
echo ""

GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m'

AVAILABLE=()
IN_USE=()

for port in {3000..3010}; do
    echo -n "Port $port: "
    
    # Try to connect
    http_code=$(curl -s -o /dev/null -w "%{http_code}" --connect-timeout 3 http://$SERVER:$port 2>/dev/null)
    exit_code=$?
    
    if [ $exit_code -eq 0 ] && [ "$http_code" != "000" ] && [ -n "$http_code" ]; then
        echo -e "${RED}✗ IN USE${NC} (HTTP $http_code)"
        IN_USE+=($port)
    else
        echo -e "${GREEN}✓ AVAILABLE${NC} (no response)"
        AVAILABLE+=($port)
    fi
done

echo ""
echo "=========================================="
echo "Summary for $SERVER:"
echo "=========================================="
echo -e "${GREEN}Available Ports: ${AVAILABLE[*]}${NC}"
if [ ${#IN_USE[@]} -gt 0 ]; then
    echo -e "${RED}Ports In Use: ${IN_USE[*]}${NC}"
fi
echo ""

# Check specific ports
if [[ " ${IN_USE[@]} " =~ " 3000 " ]]; then
    echo "Port 3000 is in use (likely ResolveIt Backend)"
    echo "Response: $(curl -s http://$SERVER:3000/ | head -1)"
fi

if [[ " ${AVAILABLE[@]} " =~ " 3002 " ]]; then
    echo -e "${GREEN}✓ Port 3002 is available - Gemura backend can use this port${NC}"
else
    echo -e "${RED}✗ Port 3002 is in use - Need to choose alternative${NC}"
    echo "Available alternatives: ${AVAILABLE[*]}"
fi

