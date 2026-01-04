#!/bin/bash

# Comprehensive port testing script using curl and system tools
# Tests ports 3000-3010 to verify availability

echo "=========================================="
echo "Port Testing with curl and system tools"
echo "=========================================="
echo "Testing ports 3000-3010..."
echo ""

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

AVAILABLE=()
IN_USE=()

for port in {3000..3010}; do
    echo -n "Port $port: "
    
    # Method 1: Try curl connection
    curl_result=$(timeout 2 curl -s -o /dev/null -w "%{http_code}" http://localhost:$port 2>/dev/null)
    curl_exit=$?
    
    # Method 2: Check with lsof
    lsof_result=$(lsof -i :$port 2>/dev/null)
    lsof_exit=$?
    
    # Method 3: Check with netstat/ss
    if command -v netstat &> /dev/null; then
        netstat_result=$(netstat -an 2>/dev/null | grep ":$port " | grep LISTEN)
    elif command -v ss &> /dev/null; then
        netstat_result=$(ss -tuln 2>/dev/null | grep ":$port ")
    else
        netstat_result=""
    fi
    
    # Determine status
    if [ $curl_exit -eq 0 ] && [ "$curl_result" != "000" ] && [ -n "$curl_result" ]; then
        echo -e "${RED}✗ IN USE (HTTP response: $curl_result)${NC}"
        IN_USE+=($port)
        if [ -n "$lsof_result" ]; then
            echo "  Process: $(echo "$lsof_result" | head -1 | awk '{print $1, $2}')"
        fi
    elif [ -n "$lsof_result" ]; then
        echo -e "${RED}✗ IN USE (process found)${NC}"
        IN_USE+=($port)
        echo "  Process: $(echo "$lsof_result" | head -1 | awk '{print $1, $2}')"
    elif [ -n "$netstat_result" ]; then
        echo -e "${RED}✗ IN USE (listening)${NC}"
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
echo -e "${GREEN}Available Ports: ${AVAILABLE[*]}${NC}"
if [ ${#IN_USE[@]} -gt 0 ]; then
    echo -e "${RED}Ports In Use: ${IN_USE[*]}${NC}"
else
    echo -e "${GREEN}No ports in use (all available)${NC}"
fi
echo ""

# Recommendations
echo "Recommended Port Allocation:"
echo "  - 3000: ResolveIt Backend"
echo "  - 3001: ResolveIt Frontend"
if [[ " ${AVAILABLE[@]} " =~ " 3002 " ]]; then
    echo -e "  - 3002: ${GREEN}Gemura Backend API (AVAILABLE)${NC}"
else
    echo -e "  - 3002: ${RED}Gemura Backend API (IN USE - choose alternative)${NC}"
fi
if [[ " ${AVAILABLE[@]} " =~ " 3003 " ]]; then
    echo -e "  - 3003: ${GREEN}Gemura Frontend (AVAILABLE)${NC}"
else
    echo -e "  - 3003: ${RED}Gemura Frontend (IN USE - choose alternative)${NC}"
fi
echo "  - 3004-3010: Available for additional services"
echo ""

# Final check
if [[ " ${AVAILABLE[@]} " =~ " 3002 " ]]; then
    echo -e "${GREEN}✓ Port 3002 is available - Ready for deployment${NC}"
    exit 0
else
    echo -e "${RED}✗ Port 3002 is in use - Please choose an available port${NC}"
    echo "Available alternatives: ${AVAILABLE[*]}"
    exit 1
fi

