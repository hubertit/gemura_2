#!/bin/bash

# Test deployment on remote server
# Run this after deployment to verify everything works

set -e

SERVER="${1:-159.198.65.38}"
PORT="${2:-3004}"

echo "=========================================="
echo "Testing Gemura Backend Deployment"
echo "Server: $SERVER:$PORT"
echo "=========================================="
echo ""

GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m'

BASE_URL="http://$SERVER:$PORT"

# Test 1: Health Endpoint
echo "Test 1: Health Endpoint"
echo "----------------------"
HEALTH_RESPONSE=$(curl -s -w "\n%{http_code}" "$BASE_URL/api/health" 2>/dev/null || echo -e "\n000")
HTTP_CODE=$(echo "$HEALTH_RESPONSE" | tail -1)
BODY=$(echo "$HEALTH_RESPONSE" | sed '$d')

if [ "$HTTP_CODE" = "200" ]; then
    echo -e "${GREEN}✓ Health endpoint responding (HTTP $HTTP_CODE)${NC}"
    echo "Response: $BODY" | head -3
else
    echo -e "${RED}✗ Health endpoint failed (HTTP $HTTP_CODE)${NC}"
    if [ -n "$BODY" ]; then
        echo "Response: $BODY"
    fi
    exit 1
fi
echo ""

# Test 2: API Root
echo "Test 2: API Root"
echo "---------------"
API_RESPONSE=$(curl -s -w "\n%{http_code}" "$BASE_URL/api" 2>/dev/null || echo -e "\n000")
HTTP_CODE=$(echo "$API_RESPONSE" | tail -1)
API_BODY=$(echo "$API_RESPONSE" | sed '$d')

if [ "$HTTP_CODE" = "200" ] || [ "$HTTP_CODE" = "404" ]; then
    echo -e "${GREEN}✓ API root accessible (HTTP $HTTP_CODE)${NC}"
else
    echo -e "${YELLOW}⚠ API root returned HTTP $HTTP_CODE${NC}"
fi
echo ""

# Test 3: Swagger Documentation
echo "Test 3: Swagger Documentation"
echo "---------------------------"
SWAGGER_RESPONSE=$(curl -s -w "\n%{http_code}" "$BASE_URL/api/docs" 2>/dev/null || echo -e "\n000")
HTTP_CODE=$(echo "$SWAGGER_RESPONSE" | tail -1)
SWAGGER_BODY=$(echo "$SWAGGER_RESPONSE" | sed '$d')

if [ "$HTTP_CODE" = "200" ]; then
    echo -e "${GREEN}✓ Swagger docs accessible (HTTP $HTTP_CODE)${NC}"
    if echo "$SWAGGER_RESPONSE" | grep -q "swagger"; then
        echo -e "${GREEN}✓ Swagger UI detected${NC}"
    fi
else
    echo -e "${RED}✗ Swagger docs not accessible (HTTP $HTTP_CODE)${NC}"
fi
echo ""

# Test 4: Swagger JSON
echo "Test 4: Swagger JSON API"
echo "----------------------"
SWAGGER_JSON=$(curl -s -w "\n%{http_code}" "$BASE_URL/api/docs-json" 2>/dev/null || echo -e "\n000")
HTTP_CODE=$(echo "$SWAGGER_JSON" | tail -1)
SWAGGER_JSON_BODY=$(echo "$SWAGGER_JSON" | sed '$d')

if [ "$HTTP_CODE" = "200" ]; then
    echo -e "${GREEN}✓ Swagger JSON accessible (HTTP $HTTP_CODE)${NC}"
    # Count endpoints
    ENDPOINT_COUNT=$(echo "$SWAGGER_JSON_BODY" | grep -o '"/api/[^"]*"' | sort -u | wc -l | tr -d ' ')
    echo "  Found $ENDPOINT_COUNT API endpoints"
else
    echo -e "${YELLOW}⚠ Swagger JSON not accessible (HTTP $HTTP_CODE)${NC}"
fi
echo ""

# Test 5: Login Endpoint (without auth - should fail gracefully)
echo "Test 5: Login Endpoint Structure"
echo "-------------------------------"
LOGIN_RESPONSE=$(curl -s -X POST -H "Content-Type: application/json" \
    -d '{"identifier":"test","password":"test"}' \
    -w "\n%{http_code}" \
    "$BASE_URL/api/auth/login" 2>/dev/null || echo -e "\n000")
HTTP_CODE=$(echo "$LOGIN_RESPONSE" | tail -1)
LOGIN_BODY=$(echo "$LOGIN_RESPONSE" | sed '$d')

if [ "$HTTP_CODE" = "401" ] || [ "$HTTP_CODE" = "400" ]; then
    echo -e "${GREEN}✓ Login endpoint responding correctly (HTTP $HTTP_CODE)${NC}"
    if echo "$LOGIN_BODY" | grep -q "code"; then
        echo -e "${GREEN}✓ Response format matches API structure${NC}"
    fi
else
    echo -e "${YELLOW}⚠ Login endpoint returned HTTP $HTTP_CODE${NC}"
fi
echo ""

# Test 6: CORS Headers
echo "Test 6: CORS Configuration"
echo "------------------------"
CORS_HEADERS=$(curl -s -I -H "Origin: http://159.198.65.38:3005" "$BASE_URL/api/health" 2>/dev/null | grep -i "access-control" || echo "")

if [ -n "$CORS_HEADERS" ]; then
    echo -e "${GREEN}✓ CORS headers present${NC}"
    echo "$CORS_HEADERS" | head -2
else
    echo -e "${YELLOW}⚠ CORS headers not detected${NC}"
fi
echo ""

# Summary
echo "=========================================="
echo "Deployment Test Summary"
echo "=========================================="
echo ""
echo "✅ All critical endpoints tested"
echo ""
echo "🌐 Access Points:"
echo "  API: $BASE_URL"
echo "  Docs: $BASE_URL/api/docs"
echo "  Health: $BASE_URL/api/health"
echo ""
echo "📋 Next Steps:"
echo "  1. Test login with real credentials"
echo "  2. Test all endpoints via Swagger UI"
echo "  3. Verify database migrations"
echo "  4. Test with mobile app"
echo ""

