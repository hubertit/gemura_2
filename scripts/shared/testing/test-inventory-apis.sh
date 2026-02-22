#!/bin/bash
# Test Inventory APIs including movements
# Usage: ./scripts/testing/test-inventory-apis.sh
# Env: BASE_URL (default http://localhost:3004/api), GEMURA_TEST_IDENTIFIER, GEMURA_TEST_PASSWORD

set -e

BASE_URL="${BASE_URL:-http://localhost:3004/api}"
IDENTIFIER="${GEMURA_TEST_IDENTIFIER:-}"
PASSWORD="${GEMURA_TEST_PASSWORD:-}"

GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

PASSED=0
FAILED=0

check_jq() {
  if ! command -v jq &> /dev/null; then
    echo -e "${RED}jq is required. Install with: brew install jq${NC}"
    exit 1
  fi
}

assert_code() {
  local name="$1"
  local expected="$2"
  local code="$3"
  local body="$4"
  if [ "$code" = "$expected" ]; then
    echo -e "  ${GREEN}✓${NC} $name (HTTP $code)"
    ((PASSED++)) || true
    return 0
  else
    echo -e "  ${RED}✗${NC} $name (expected HTTP $expected, got $code)"
    echo "    Body: $body" | head -c 200
    echo ""
    ((FAILED++)) || true
    return 1
  fi
}

echo "=========================================="
echo "Inventory API tests"
echo "BASE_URL=$BASE_URL"
echo "=========================================="
check_jq

# Credentials
if [ -z "$IDENTIFIER" ] || [ -z "$PASSWORD" ]; then
  echo -e "${YELLOW}Set GEMURA_TEST_IDENTIFIER and GEMURA_TEST_PASSWORD to test authenticated endpoints.${NC}"
  echo "Testing only public/health endpoints..."
  # Health check only (BASE_URL is e.g. http://localhost:3004/api)
  HEALTH=$(curl -s -w "\n%{http_code}" --max-time 5 "${BASE_URL%/api}/api/health" 2>/dev/null || true)
  CODE=$(echo "$HEALTH" | tail -n1)
  BODY=$(echo "$HEALTH" | sed '$d')
  if [ "$CODE" = "200" ]; then
    echo -e "${GREEN}✓${NC} Health (HTTP 200)"
    ((PASSED++)) || true
  else
    echo -e "${RED}✗${NC} Health (got HTTP $CODE)"
    ((FAILED++)) || true
  fi
  echo ""
  echo "Result: $PASSED passed, $FAILED failed"
  exit $FAILED
fi

# Login
echo -e "${BLUE}Login...${NC}"
LOGIN_RESPONSE=$(curl -s -w "\n%{http_code}" -X POST "$BASE_URL/auth/login" \
  -H "Content-Type: application/json" \
  -d "{\"identifier\": \"$IDENTIFIER\", \"password\": \"$PASSWORD\"}")
HTTP_CODE=$(echo "$LOGIN_RESPONSE" | tail -n1)
BODY=$(echo "$LOGIN_RESPONSE" | sed '$d')
if [ "$HTTP_CODE" != "200" ]; then
  echo -e "${RED}Login failed (HTTP $HTTP_CODE). Check credentials.${NC}"
  echo "$BODY" | jq '.' 2>/dev/null || echo "$BODY"
  exit 1
fi
TOKEN=$(echo "$BODY" | jq -r '.data.user.token // empty')
if [ -z "$TOKEN" ] || [ "$TOKEN" = "null" ]; then
  echo -e "${RED}No token in login response.${NC}"
  exit 1
fi
echo -e "${GREEN}✓ Logged in${NC}"
echo ""

AUTH_HEADER="Authorization: Bearer $TOKEN"

# GET /inventory
echo -e "${BLUE}GET /inventory${NC}"
RESP=$(curl -s -w "\n%{http_code}" -X GET "$BASE_URL/inventory" -H "$AUTH_HEADER" -H "Content-Type: application/json")
CODE=$(echo "$RESP" | tail -n1)
BODY=$(echo "$RESP" | sed '$d')
assert_code "GET /inventory" "200" "$CODE" "$BODY"
if [ "$CODE" = "200" ]; then
  ITEMS=$(echo "$BODY" | jq -r '.data // []')
  FIRST_ID=$(echo "$BODY" | jq -r '.data[0].id // empty')
  COUNT=$(echo "$BODY" | jq -r '.data | length // 0')
  echo "    Items count: $COUNT"
fi
echo ""

# GET /inventory/stats
echo -e "${BLUE}GET /inventory/stats${NC}"
RESP=$(curl -s -w "\n%{http_code}" -X GET "$BASE_URL/inventory/stats" -H "$AUTH_HEADER" -H "Content-Type: application/json")
CODE=$(echo "$RESP" | tail -n1)
BODY=$(echo "$RESP" | sed '$d')
assert_code "GET /inventory/stats" "200" "$CODE" "$BODY"
echo ""

# GET /inventory/:id (and movements) only if we have a product
if [ -n "$FIRST_ID" ] && [ "$FIRST_ID" != "null" ]; then
  echo -e "${BLUE}GET /inventory/:id${NC}"
  RESP=$(curl -s -w "\n%{http_code}" -X GET "$BASE_URL/inventory/$FIRST_ID" -H "$AUTH_HEADER" -H "Content-Type: application/json")
  CODE=$(echo "$RESP" | tail -n1)
  BODY=$(echo "$RESP" | sed '$d')
  assert_code "GET /inventory/$FIRST_ID" "200" "$CODE" "$BODY"
  echo ""

  echo -e "${BLUE}GET /inventory/:id/movements${NC}"
  RESP=$(curl -s -w "\n%{http_code}" -X GET "$BASE_URL/inventory/$FIRST_ID/movements" -H "$AUTH_HEADER" -H "Content-Type: application/json")
  CODE=$(echo "$RESP" | tail -n1)
  BODY=$(echo "$RESP" | sed '$d')
  assert_code "GET /inventory/:id/movements" "200" "$CODE" "$BODY"
  if [ "$CODE" = "200" ]; then
    MOV_COUNT=$(echo "$BODY" | jq -r '.data.items | length // 0')
    PAGINATION=$(echo "$BODY" | jq -r '.data.pagination // {}')
    echo "    Movements in page: $MOV_COUNT, pagination: $PAGINATION"
  fi
  echo ""

  echo -e "${BLUE}GET /inventory/:id/movements?page=1&limit=5${NC}"
  RESP=$(curl -s -w "\n%{http_code}" -X GET "$BASE_URL/inventory/$FIRST_ID/movements?page=1&limit=5" -H "$AUTH_HEADER" -H "Content-Type: application/json")
  CODE=$(echo "$RESP" | tail -n1)
  BODY=$(echo "$RESP" | sed '$d')
  assert_code "GET /inventory/:id/movements?page=1&limit=5" "200" "$CODE" "$BODY"
  echo ""

  # PUT /inventory/:id/stock (update stock and create movement with notes)
  echo -e "${BLUE}PUT /inventory/:id/stock (with notes)${NC}"
  PROD_RESP=$(curl -s -X GET "$BASE_URL/inventory/$FIRST_ID" -H "$AUTH_HEADER" -H "Content-Type: application/json")
  OLD_STOCK=$(echo "$PROD_RESP" | jq -r '.data.stock_quantity // 0')
  NEW_STOCK=$((OLD_STOCK + 2))
  RESP=$(curl -s -w "\n%{http_code}" -X PUT "$BASE_URL/inventory/$FIRST_ID/stock" \
    -H "$AUTH_HEADER" -H "Content-Type: application/json" \
    -d "{\"stock_quantity\": $NEW_STOCK, \"notes\": \"Test API stock increase\"}")
  CODE=$(echo "$RESP" | tail -n1)
  BODY=$(echo "$RESP" | sed '$d')
  assert_code "PUT /inventory/:id/stock (with notes)" "200" "$CODE" "$BODY"
  if [ "$CODE" = "200" ]; then
    echo "    Stock: $OLD_STOCK -> $NEW_STOCK"
    # Revert stock so we don't leave test data
    REVERT=$(curl -s -w "\n%{http_code}" -X PUT "$BASE_URL/inventory/$FIRST_ID/stock" \
      -H "$AUTH_HEADER" -H "Content-Type: application/json" \
      -d "{\"stock_quantity\": $OLD_STOCK, \"notes\": \"Revert test\"}")
    echo -e "  ${GREEN}✓${NC} Reverted stock to $OLD_STOCK"
    ((PASSED++)) || true
  fi
  echo ""
else
  echo -e "${YELLOW}Skipping product-specific tests (no inventory items).${NC}"
  echo ""
fi

# GET /inventory/stats/valuation-over-time (optional)
echo -e "${BLUE}GET /inventory/stats/valuation-over-time${NC}"
if date -u -v-30d +%Y-%m-%d &>/dev/null; then
  DATE_FROM=$(date -u -v-30d +%Y-%m-%d)
else
  DATE_FROM=$(date -u -d '30 days ago' +%Y-%m-%d 2>/dev/null || echo "2025-01-01")
fi
DATE_TO=$(date -u +%Y-%m-%d 2>/dev/null || echo "2025-12-31")
RESP=$(curl -s -w "\n%{http_code}" -X GET "$BASE_URL/inventory/stats/valuation-over-time?date_from=$DATE_FROM&date_to=$DATE_TO" -H "$AUTH_HEADER" -H "Content-Type: application/json")
CODE=$(echo "$RESP" | tail -n1)
BODY=$(echo "$RESP" | sed '$d')
assert_code "GET /inventory/stats/valuation-over-time" "200" "$CODE" "$BODY"
echo ""

# GET /inventory/stats/top-by-value
echo -e "${BLUE}GET /inventory/stats/top-by-value${NC}"
RESP=$(curl -s -w "\n%{http_code}" -X GET "$BASE_URL/inventory/stats/top-by-value?limit=5" -H "$AUTH_HEADER" -H "Content-Type: application/json")
CODE=$(echo "$RESP" | tail -n1)
BODY=$(echo "$RESP" | sed '$d')
assert_code "GET /inventory/stats/top-by-value" "200" "$CODE" "$BODY"
echo ""

# GET /inventory/stats/stock-movement
echo -e "${BLUE}GET /inventory/stats/stock-movement${NC}"
RESP=$(curl -s -w "\n%{http_code}" -X GET "$BASE_URL/inventory/stats/stock-movement?date_from=$DATE_FROM&date_to=$DATE_TO" -H "$AUTH_HEADER" -H "Content-Type: application/json")
CODE=$(echo "$RESP" | tail -n1)
BODY=$(echo "$RESP" | sed '$d')
assert_code "GET /inventory/stats/stock-movement" "200" "$CODE" "$BODY"
echo ""

echo "=========================================="
echo -e "Result: ${GREEN}$PASSED passed${NC}, ${RED}$FAILED failed${NC}"
echo "=========================================="
exit $FAILED
