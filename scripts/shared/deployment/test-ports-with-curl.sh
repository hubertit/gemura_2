#!/bin/bash

# Test ports 3000-3020 with curl to see actual responses
# Shows HTTP status codes and response content

SERVER_IP="${1:-159.198.65.38}"
# Note: This script only tests HTTP responses, doesn't need SSH password

echo "=========================================="
echo "Testing Ports with CURL on $SERVER_IP"
echo "Range: 3000-3020"
echo "=========================================="
echo ""

GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m'

RESPONDING_PORTS=()
NO_RESPONSE_PORTS=()

for port in {3000..3020}; do
    echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${BLUE}Port $port:${NC}"
    echo ""
    
    # Make curl request with timeout
    response=$(curl -s -w "\nHTTP_CODE:%{http_code}\nTIME:%{time_total}" --connect-timeout 3 --max-time 5 "http://$SERVER_IP:$port" 2>&1)
    
    # Extract HTTP code
    http_code=$(echo "$response" | grep "HTTP_CODE:" | cut -d: -f2)
    time_total=$(echo "$response" | grep "TIME:" | cut -d: -f2)
    body=$(echo "$response" | sed '/HTTP_CODE:/d' | sed '/TIME:/d')
    
    if [ -n "$http_code" ] && [ "$http_code" != "000" ]; then
        echo -e "${GREEN}✓ RESPONDING${NC}"
        echo -e "  HTTP Status: ${YELLOW}$http_code${NC}"
        echo -e "  Response Time: ${time_total}s"
        echo ""
        echo -e "  ${CYAN}Response Body (first 200 chars):${NC}"
        echo "$body" | head -c 200
        echo ""
        echo ""
        
        # Try to identify service
        if echo "$body" | grep -qi "resolveit\|resolve"; then
            echo -e "  ${YELLOW}→ Likely: ResolveIt Service${NC}"
        elif echo "$body" | grep -qi "gemura"; then
            echo -e "  ${YELLOW}→ Likely: Gemura Service${NC}"
        elif echo "$http_code" | grep -q "404"; then
            echo -e "  ${YELLOW}→ Service running but endpoint not found${NC}"
        elif echo "$http_code" | grep -q "401\|403"; then
            echo -e "  ${YELLOW}→ Service running but requires authentication${NC}"
        fi
        
        RESPONDING_PORTS+=($port)
    else
        echo -e "${RED}✗ NO RESPONSE${NC}"
        echo -e "  (Connection timeout or refused)"
        NO_RESPONSE_PORTS+=($port)
    fi
    
    echo ""
done

echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""
echo "=========================================="
echo "Summary"
echo "=========================================="
echo ""

if [ ${#RESPONDING_PORTS[@]} -gt 0 ]; then
    echo -e "${RED}Ports Responding (IN USE):${NC}"
    for port in "${RESPONDING_PORTS[@]}"; do
        echo -e "  ${RED}✗ Port $port${NC}"
    done
    echo ""
fi

if [ ${#NO_RESPONSE_PORTS[@]} -gt 0 ]; then
    echo -e "${GREEN}Ports Available (NO RESPONSE):${NC}"
    for port in "${NO_RESPONSE_PORTS[@]}"; do
        echo -e "  ${GREEN}✓ Port $port${NC}"
    done
    echo ""
    echo -e "${BLUE}Recommended: Use port ${NO_RESPONSE_PORTS[0]}${NC}"
fi

echo "=========================================="
