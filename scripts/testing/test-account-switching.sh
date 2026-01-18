#!/bin/bash

# Test Account Switching for User 250788606765
# This script tests the account switching functionality

set -e

BASE_URL="http://159.198.65.38:3004/api"
USER_IDENTIFIER="250788606765"
PASSWORD="Pass123"

GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo "=========================================="
echo "Testing Account Switching"
echo "User: $USER_IDENTIFIER"
echo "=========================================="
echo ""

# Step 1: Login
echo -e "${BLUE}Step 1: Logging in...${NC}"
LOGIN_RESPONSE=$(curl -s -X POST "$BASE_URL/auth/login" \
  -H "Content-Type: application/json" \
  -d "{\"identifier\": \"$USER_IDENTIFIER\", \"password\": \"$PASSWORD\"}")

if [ $? -ne 0 ]; then
  echo -e "${RED}✗ Failed to connect to server${NC}"
  exit 1
fi

TOKEN=$(echo "$LOGIN_RESPONSE" | jq -r '.data.user.token // empty')
USER_ID=$(echo "$LOGIN_RESPONSE" | jq -r '.data.user.id // empty')
DEFAULT_ACCOUNT_ID=$(echo "$LOGIN_RESPONSE" | jq -r '.data.user.default_account_id // empty')

if [ -z "$TOKEN" ] || [ "$TOKEN" = "null" ]; then
  echo -e "${RED}✗ Login failed${NC}"
  echo "Response: $LOGIN_RESPONSE" | jq '.'
  exit 1
fi

echo -e "${GREEN}✓ Login successful${NC}"
echo "  User ID: $USER_ID"
echo "  Default Account ID: $DEFAULT_ACCOUNT_ID"
echo "  Token: ${TOKEN:0:20}..."
echo ""

# Step 2: Get Accounts List
echo -e "${BLUE}Step 2: Fetching user accounts...${NC}"
ACCOUNTS_RESPONSE=$(curl -s -X GET "$BASE_URL/accounts" \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json")

ACCOUNTS_COUNT=$(echo "$ACCOUNTS_RESPONSE" | jq -r '.data.total_accounts // 0')
ACCOUNTS=$(echo "$ACCOUNTS_RESPONSE" | jq -r '.data.accounts // []')

if [ "$ACCOUNTS_COUNT" = "0" ]; then
  echo -e "${YELLOW}⚠ User has no accounts or only one account${NC}"
  echo "Response: $ACCOUNTS_RESPONSE" | jq '.'
  exit 0
fi

echo -e "${GREEN}✓ Found $ACCOUNTS_COUNT account(s)${NC}"
echo ""

# Display accounts
echo "Available Accounts:"
echo "$ACCOUNTS" | jq -r '.[] | "  - \(.account_name) (ID: \(.account_id), Default: \(.is_default))"'
echo ""

# Find accounts to switch between
ACCOUNT_IDS=($(echo "$ACCOUNTS" | jq -r '.[].account_id'))
ACCOUNT_NAMES=($(echo "$ACCOUNTS" | jq -r '.[].account_name'))
CURRENT_DEFAULT=$(echo "$ACCOUNTS" | jq -r '.[] | select(.is_default == true) | .account_id')

if [ ${#ACCOUNT_IDS[@]} -lt 2 ]; then
  echo -e "${YELLOW}⚠ User needs at least 2 accounts to test switching${NC}"
  echo "Current accounts: ${#ACCOUNT_IDS[@]}"
  exit 0
fi

# Find a different account to switch to
SWITCH_TO_ACCOUNT_ID=""
SWITCH_TO_ACCOUNT_NAME=""
for i in "${!ACCOUNT_IDS[@]}"; do
  if [ "${ACCOUNT_IDS[$i]}" != "$CURRENT_DEFAULT" ]; then
    SWITCH_TO_ACCOUNT_ID="${ACCOUNT_IDS[$i]}"
    SWITCH_TO_ACCOUNT_NAME="${ACCOUNT_NAMES[$i]}"
    break
  fi
done

if [ -z "$SWITCH_TO_ACCOUNT_ID" ]; then
  echo -e "${YELLOW}⚠ Could not find a different account to switch to${NC}"
  exit 0
fi

echo -e "${BLUE}Current Default Account:${NC}"
echo "$ACCOUNTS" | jq -r ".[] | select(.account_id == \"$CURRENT_DEFAULT\") | \"  - \(.account_name) (ID: \(.account_id))\""
echo ""
echo -e "${BLUE}Switching to:${NC}"
echo "  - $SWITCH_TO_ACCOUNT_NAME (ID: $SWITCH_TO_ACCOUNT_ID)"
echo ""

# Step 3: Switch Account
echo -e "${BLUE}Step 3: Switching account...${NC}"
SWITCH_RESPONSE=$(curl -s -X POST "$BASE_URL/accounts/switch" \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" \
  -d "{\"account_id\": \"$SWITCH_TO_ACCOUNT_ID\"}")

SWITCH_CODE=$(echo "$SWITCH_RESPONSE" | jq -r '.code // 0')
SWITCH_STATUS=$(echo "$SWITCH_RESPONSE" | jq -r '.status // "error"')
SWITCH_MESSAGE=$(echo "$SWITCH_RESPONSE" | jq -r '.message // ""')
NEW_DEFAULT_ACCOUNT_ID=$(echo "$SWITCH_RESPONSE" | jq -r '.data.user.default_account_id // ""')

if [ "$SWITCH_CODE" = "200" ] && [ "$SWITCH_STATUS" = "success" ]; then
  echo -e "${GREEN}✓ Account switch successful${NC}"
  echo "  Message: $SWITCH_MESSAGE"
  echo "  New Default Account ID: $NEW_DEFAULT_ACCOUNT_ID"
  echo ""
  
  # Verify the switch
  if [ "$NEW_DEFAULT_ACCOUNT_ID" = "$SWITCH_TO_ACCOUNT_ID" ]; then
    echo -e "${GREEN}✓ Verification: Default account ID matches switched account${NC}"
  else
    echo -e "${RED}✗ Verification failed: Default account ID mismatch${NC}"
    echo "  Expected: $SWITCH_TO_ACCOUNT_ID"
    echo "  Got: $NEW_DEFAULT_ACCOUNT_ID"
  fi
else
  echo -e "${RED}✗ Account switch failed${NC}"
  echo "  Code: $SWITCH_CODE"
  echo "  Status: $SWITCH_STATUS"
  echo "  Message: $SWITCH_MESSAGE"
  echo "  Full Response:"
  echo "$SWITCH_RESPONSE" | jq '.'
  exit 1
fi

echo ""

# Step 4: Verify by fetching accounts again
echo -e "${BLUE}Step 4: Verifying switch by fetching accounts again...${NC}"
ACCOUNTS_RESPONSE_AFTER=$(curl -s -X GET "$BASE_URL/accounts" \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json")

NEW_DEFAULT_VERIFY=$(echo "$ACCOUNTS_RESPONSE_AFTER" | jq -r '.data.user.default_account_id // ""')
IS_DEFAULT=$(echo "$ACCOUNTS_RESPONSE_AFTER" | jq -r ".data.accounts[] | select(.account_id == \"$SWITCH_TO_ACCOUNT_ID\") | .is_default")

if [ "$NEW_DEFAULT_VERIFY" = "$SWITCH_TO_ACCOUNT_ID" ] && [ "$IS_DEFAULT" = "true" ]; then
  echo -e "${GREEN}✓ Verification successful: Account is now default${NC}"
  echo "  Default Account ID: $NEW_DEFAULT_VERIFY"
  echo ""
  
  echo "Updated Accounts List:"
  echo "$ACCOUNTS_RESPONSE_AFTER" | jq -r '.data.accounts[] | "  - \(.account_name) (ID: \(.account_id), Default: \(.is_default))"'
else
  echo -e "${RED}✗ Verification failed${NC}"
  echo "  Expected default: $SWITCH_TO_ACCOUNT_ID"
  echo "  Got default: $NEW_DEFAULT_VERIFY"
  echo "  Is default flag: $IS_DEFAULT"
fi

echo ""
echo "=========================================="
echo -e "${GREEN}Account Switching Test Complete${NC}"
echo "=========================================="
