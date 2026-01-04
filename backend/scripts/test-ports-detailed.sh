#!/bin/bash

# Detailed port testing for ports 3000-3020
SERVER="${1:-159.198.65.38}"

echo "=========================================="
echo "Detailed Port Testing: 3000-3020"
echo "Server: $SERVER"
echo "=========================================="
echo ""

GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m'

IN_USE=()
AVAILABLE=()

for port in {3000..3020}; do
    echo -n "Port $port: "
    
    # Try multiple methods
    # Method 1: HTTP request
    http_code=$(curl -s -o /dev/null -w "%{http_code}" --connect-timeout 2 --max-time 3 http://$SERVER:$port 2>/dev/null)
    curl_exit=$?
    
    # Method 2: Try HTTPS
    https_code=$(curl -s -o /dev/null -w "%{http_code}" --connect-timeout 2 --max-time 3 https://$SERVER:$port 2>/dev/null 2>&1)
    
    # Method 3: Try telnet-style connection (just check if port is open)
    timeout 2 bash -c "echo > /dev/tcp/$SERVER/$port" 2>/dev/null
    tcp_exit=$?
    
    # Determine status
    if [ $curl_exit -eq 0 ] && [ "$http_code" != "000" ] && [ "$http_code" != "" ]; then
        echo -e "${RED}✗ IN USE${NC} (HTTP $http_code)"
        IN_USE+=($port)
    elif [ $tcp_exit -eq 0 ]; then
        echo -e "${RED}✗ IN USE${NC} (TCP connection open)"
        IN_USE+=($port)
    else
        echo -e "${GREEN}✓ AVAILABLE${NC}"
        AVAILABLE+=($port)
    fi
done

echo ""
echo "=========================================="
echo "Summary:"
echo "=========================================="
echo -e "${RED}Ports IN USE: ${IN_USE[*]}${NC}"
echo -e "${GREEN}Ports AVAILABLE: ${AVAILABLE[*]}${NC}"
echo ""

# Show details for in-use ports
if [ ${#IN_USE[@]} -gt 0 ]; then
    echo "Details for ports in use:"
    for port in "${IN_USE[@]}"; do
        echo -n "  Port $port: "
        response=$(curl -s --connect-timeout 2 --max-time 3 http://$SERVER:$port 2>/dev/null | head -c 100)
        if [ -n "$response" ]; then
            echo "$response"
        else
            echo "Port open but no HTTP response"
        fi
    done
fi

echo ""
echo "Recommended ports for Gemura:"
if [[ " ${AVAILABLE[@]} " =~ " 3002 " ]]; then
    echo -e "  ${GREEN}3002: Available for Gemura Backend${NC}"
elif [[ " ${AVAILABLE[@]} " =~ " 3003 " ]]; then
    echo -e "  ${GREEN}3003: Available for Gemura Backend${NC}"
elif [[ " ${AVAILABLE[@]} " =~ " 3004 " ]]; then
    echo -e "  ${GREEN}3004: Available for Gemura Backend${NC}"
else
    echo -e "  ${YELLOW}Check available ports above${NC}"
fi

