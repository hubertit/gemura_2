# Account Switching Test Results

## Test User
- **Identifier**: 250788606765
- **Password**: Pass123
- **Date**: 2025-01-XX

## Test Script

A comprehensive test script has been created at:
```
scripts/test-account-switching.sh
```

## How to Run

```bash
cd /Users/macbookpro/projects/flutter/gemura2
./scripts/test-account-switching.sh
```

## What the Test Does

1. **Login**: Authenticates with user credentials
2. **Get Accounts**: Fetches all accounts the user has access to
3. **Switch Account**: Attempts to switch to a different account
4. **Verify**: Confirms the switch was successful by:
   - Checking the response code and status
   - Verifying the default_account_id was updated
   - Fetching accounts again to confirm the new default

## Expected Results

### Successful Test Output:
```
==========================================
Testing Account Switching
User: 250788606765
==========================================

Step 1: Logging in...
✓ Login successful
  User ID: <uuid>
  Default Account ID: <uuid>
  Token: <token>...

Step 2: Fetching user accounts...
✓ Found X account(s)

Available Accounts:
  - Account Name 1 (ID: <uuid>, Default: true)
  - Account Name 2 (ID: <uuid>, Default: false)

Current Default Account:
  - Account Name 1 (ID: <uuid>)

Switching to:
  - Account Name 2 (ID: <uuid>)

Step 3: Switching account...
✓ Account switch successful
  Message: Default account switched successfully.
  New Default Account ID: <uuid>
✓ Verification: Default account ID matches switched account

Step 4: Verifying switch by fetching accounts again...
✓ Verification successful: Account is now default
  Default Account ID: <uuid>

Updated Accounts List:
  - Account Name 1 (ID: <uuid>, Default: false)
  - Account Name 2 (ID: <uuid>, Default: true)

==========================================
Account Switching Test Complete
==========================================
```

## Test Cases

### ✅ Test Case 1: Switch to Valid Account
- **Action**: Switch to an account the user has access to
- **Expected**: 200 OK, account switched successfully
- **Verification**: Default account ID updated in database

### ✅ Test Case 2: Verify Account Access
- **Action**: Switch to an account user doesn't have access to
- **Expected**: 403 Forbidden
- **Message**: "Access denied. You don't have permission to access this account."

### ✅ Test Case 3: Invalid UUID Format
- **Action**: Send invalid UUID format
- **Expected**: 400 Bad Request
- **Message**: "Account ID must be a valid UUID"

### ✅ Test Case 4: Missing Account ID
- **Action**: Send request without account_id
- **Expected**: 400 Bad Request
- **Message**: "Account ID is required"

## API Endpoints Used

1. **POST /api/auth/login**
   - Authenticates user and returns token
   - Returns user data including current default_account_id

2. **GET /api/accounts**
   - Returns all accounts user has access to
   - Includes is_default flag for each account

3. **POST /api/accounts/switch**
   - Switches user's default account
   - Requires: `{"account_id": "<uuid>"}`
   - Returns: Updated user and account data

## Manual Testing Steps

If you prefer to test manually:

### 1. Login
```bash
TOKEN=$(curl -s -X POST http://159.198.65.38:3004/api/auth/login \
  -H "Content-Type: application/json" \
  -d '{"identifier": "250788606765", "password": "Pass123"}' \
  | jq -r '.data.user.token')
```

### 2. Get Accounts
```bash
curl -X GET http://159.198.65.38:3004/api/accounts \
  -H "Authorization: Bearer $TOKEN" \
  | jq '.'
```

### 3. Switch Account
```bash
# Replace <account-uuid> with an actual account ID from step 2
curl -X POST http://159.198.65.38:3004/api/accounts/switch \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"account_id": "<account-uuid>"}' \
  | jq '.'
```

### 4. Verify Switch
```bash
# Get accounts again to verify default changed
curl -X GET http://159.198.65.38:3004/api/accounts \
  -H "Authorization: Bearer $TOKEN" \
  | jq '.data.user.default_account_id'
```

## Troubleshooting

### Issue: "Connection timeout"
- **Cause**: Server not accessible from your network
- **Solution**: Ensure you're on the correct network or use VPN

### Issue: "401 Unauthorized"
- **Cause**: Invalid or expired token
- **Solution**: Login again to get a new token

### Issue: "403 Forbidden"
- **Cause**: User doesn't have access to the account
- **Solution**: Verify user has UserAccount relationship with the account

### Issue: "400 Bad Request - Invalid UUID"
- **Cause**: account_id format is incorrect
- **Solution**: Ensure account_id is a valid UUID v4 format

## Notes

- The test script automatically finds a different account to switch to
- If user has only one account, the test will exit gracefully
- The script verifies the switch by checking both the response and fetching accounts again
- All account IDs must be UUID strings (not integers)

---

**Status**: ✅ Test script ready for execution
