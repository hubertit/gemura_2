#!/bin/bash

# Check Backend Status Script
# This script checks if the Gemura NestJS backend is running

set -e

SERVER="${1:-159.198.65.38}"
PORT="${2:-3004}"
BASE_URL="http://$SERVER:$PORT/api"

GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo "=========================================="
echo "Checking Gemura Backend Status"
echo "Server: $SERVER:$PORT"
echo "=========================================="
echo ""

# Test 1: Basic Connectivity (Ping)
echo -e "${BLUE}Test 1: Server Connectivity (Ping)${NC}"
if ping -c 2 -W 2 "$SERVER" > /dev/null 2>&1; then
    echo -e "${GREEN}✓ Server is reachable${NC}"
else
    echo -e "${RED}✗ Server is NOT reachable${NC}"
    echo "  The server may be down or unreachable from your network"
    exit 1
fi
echo ""

# Test 2: Port Check
echo -e "${BLUE}Test 2: Port $PORT Check${NC}"
if command -v nc > /dev/null 2>&1; then
    if nc -zv -w 3 "$SERVER" "$PORT" 2>&1 | grep -q "succeeded"; then
        echo -e "${GREEN}✓ Port $PORT is open${NC}"
    else
        echo -e "${RED}✗ Port $PORT is closed or unreachable${NC}"
        echo "  The backend service may not be running"
    fi
else
    echo -e "${YELLOW}⚠ netcat (nc) not available, skipping port check${NC}"
fi
echo ""

# Test 3: Health Endpoint
echo -e "${BLUE}Test 3: Health Endpoint${NC}"
HEALTH_RESPONSE=$(curl -s -w "\n%{http_code}" --max-time 5 "$BASE_URL/health" 2>&1 || echo -e "\n000")
HTTP_CODE=$(echo "$HEALTH_RESPONSE" | tail -1)
BODY=$(echo "$HEALTH_RESPONSE" | sed '$d')

if [ "$HTTP_CODE" = "200" ]; then
    echo -e "${GREEN}✓ Health endpoint responding (HTTP $HTTP_CODE)${NC}"
    if [ -n "$BODY" ]; then
        echo "  Response: $BODY" | head -3
    fi
elif [ "$HTTP_CODE" = "000" ]; then
    echo -e "${RED}✗ Health endpoint not responding (Connection failed)${NC}"
    echo "  The backend service is likely down"
else
    echo -e "${YELLOW}⚠ Health endpoint returned HTTP $HTTP_CODE${NC}"
    if [ -n "$BODY" ]; then
        echo "  Response: $BODY" | head -3
    fi
fi
echo ""

# Test 4: API Root
echo -e "${BLUE}Test 4: API Root${NC}"
API_RESPONSE=$(curl -s -w "\n%{http_code}" --max-time 5 "$BASE_URL" 2>&1 || echo -e "\n000")
HTTP_CODE=$(echo "$API_RESPONSE" | tail -1)

if [ "$HTTP_CODE" = "200" ] || [ "$HTTP_CODE" = "404" ]; then
    echo -e "${GREEN}✓ API root accessible (HTTP $HTTP_CODE)${NC}"
else
    echo -e "${RED}✗ API root not accessible (HTTP $HTTP_CODE)${NC}"
fi
echo ""

# Test 5: Swagger Documentation
echo -e "${BLUE}Test 5: Swagger Documentation${NC}"
SWAGGER_RESPONSE=$(curl -s -w "\n%{http_code}" --max-time 5 "$BASE_URL/docs" 2>&1 || echo -e "\n000")
HTTP_CODE=$(echo "$SWAGGER_RESPONSE" | tail -1)

if [ "$HTTP_CODE" = "200" ]; then
    echo -e "${GREEN}✓ Swagger docs accessible (HTTP $HTTP_CODE)${NC}"
    echo "  URL: $BASE_URL/docs"
else
    echo -e "${RED}✗ Swagger docs not accessible (HTTP $HTTP_CODE)${NC}"
fi
echo ""

# Summary
echo "=========================================="
echo "Summary"
echo "=========================================="

if [ "$HTTP_CODE" = "200" ] || [ "$HTTP_CODE" = "404" ]; then
    echo -e "${GREEN}✓ Backend appears to be RUNNING${NC}"
    echo ""
    echo "Next steps:"
    echo "  1. Test login endpoint manually"
    echo "  2. Check server logs for any errors"
    echo "  3. Verify database connection"
else
    echo -e "${RED}✗ Backend appears to be DOWN${NC}"
    echo ""
    echo "Troubleshooting steps:"
    echo "  1. SSH into the server: ssh user@$SERVER"
    echo "  2. Check if Docker container is running:"
    echo "     docker ps | grep gemura"
    echo "  3. Check container logs:"
    echo "     docker logs <container-name>"
    echo "  4. Restart the backend service:"
    echo "     cd /path/to/gemura2"
    echo "     docker-compose -f docker-compose.gemura.yml restart"
    echo "  5. Or restart the entire stack:"
    echo "     docker-compose -f docker-compose.gemura.yml down"
    echo "     docker-compose -f docker-compose.gemura.yml up -d"
fi

echo ""
echo "=========================================="
