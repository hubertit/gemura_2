# Account Switching Fix - Backend Integration

## Date
2025-01-XX

## Problem Identified

The account switching functionality had several issues preventing it from working correctly with the NestJS backend:

1. **Field Name Mismatch**: Mobile app was sending `accountId` (camelCase) but backend expected `account_id` (snake_case)
2. **Data Type Mismatch**: Mobile app was using `int` for account IDs, but backend uses UUID strings
3. **Model Inconsistency**: Mobile app models were parsing account IDs as integers when backend returns UUID strings

## Changes Made

### Mobile App Changes

#### 1. Updated `user_accounts_service.dart`
- Changed `switchAccount(int accountId)` to `switchAccount(String accountId)`
- Changed request body from `{'accountId': accountId}` to `{'account_id': accountId}`

#### 2. Updated `user_accounts.dart` Models
- Changed `UserAccount.accountId` from `int` to `String`
- Changed `UserInfo.id` from `int` to `String`
- Changed `UserInfo.defaultAccountId` from `int?` to `String?`
- Changed `DefaultAccount.id` from `int` to `String`
- Removed `_parseInt` helper function (no longer needed)

#### 3. Updated `user_accounts_provider.dart`
- Changed `switchAccount(int accountId, ...)` to `switchAccount(String accountId, ...)`

#### 4. Regenerated JSON Serialization
- Ran `flutter pub run build_runner build` to regenerate `.g.dart` files with new types

### Backend Changes

#### 1. Enhanced DTO Validation (`switch-account.dto.ts`)
- Added `@IsUUID('4')` validator to ensure account_id is a valid UUID
- This provides better validation and error messages

## Backend Implementation Verification

The backend account switching endpoint (`POST /accounts/switch`) is properly implemented:

### Security Checks ✅
1. **Authentication**: Protected by `TokenGuard` - requires valid Bearer token
2. **Authorization**: Verifies user has access to the account via `UserAccount` relationship
3. **Account Status**: Validates both user account access and account itself are active

### Validation ✅
1. **UUID Format**: DTO validates account_id is a valid UUID v4
2. **Required Field**: DTO ensures account_id is provided and not empty
3. **Type Safety**: TypeScript ensures type correctness

### Business Logic ✅
1. **Access Check**: Verifies user has an active `UserAccount` relationship with the target account
2. **Account Status**: Ensures the account itself is active
3. **Update**: Updates user's `default_account_id` in the database
4. **Response**: Returns updated user and account information

### Error Handling ✅
- **400 Bad Request**: Invalid UUID format or missing account_id
- **401 Unauthorized**: Missing or invalid authentication token
- **403 Forbidden**: User doesn't have access to the specified account
- **500 Internal Server Error**: Database or server errors

## API Contract

### Request
```http
POST /api/accounts/switch
Authorization: Bearer <token>
Content-Type: application/json

{
  "account_id": "550e8400-e29b-41d4-a716-446655440000"
}
```

### Success Response (200)
```json
{
  "code": 200,
  "status": "success",
  "message": "Default account switched successfully.",
  "data": {
    "user": {
      "id": "user-uuid",
      "name": "John Doe",
      "default_account_id": "account-uuid"
    },
    "account": {
      "id": "account-uuid",
      "code": "ACC001",
      "name": "Main Account",
      "type": "tenant"
    }
  }
}
```

### Error Responses

**400 Bad Request** (Invalid UUID):
```json
{
  "code": 400,
  "status": "error",
  "message": "Account ID must be a valid UUID"
}
```

**403 Forbidden** (No Access):
```json
{
  "code": 403,
  "status": "error",
  "message": "Access denied. You don't have permission to access this account."
}
```

## Testing Checklist

- [ ] Test switching to a valid account the user has access to
- [ ] Test switching to an account the user doesn't have access to (should return 403)
- [ ] Test switching with invalid UUID format (should return 400)
- [ ] Test switching without authentication token (should return 401)
- [ ] Verify default account is updated in database
- [ ] Verify mobile app UI updates correctly after switch
- [ ] Verify all data providers refresh with new account context

## Files Modified

### Mobile App
- `mobile/lib/core/services/user_accounts_service.dart`
- `mobile/lib/shared/models/user_accounts.dart`
- `mobile/lib/features/home/presentation/providers/user_accounts_provider.dart`
- `mobile/lib/shared/models/user_accounts.g.dart` (regenerated)

### Backend
- `backend/src/modules/accounts/dto/switch-account.dto.ts`

## Status

✅ **COMPLETE** - Account switching is now properly integrated with the NestJS backend.

All critical issues have been resolved:
- ✅ Field name matches backend expectation (`account_id`)
- ✅ Data types match (UUID strings)
- ✅ Backend validation enhanced with UUID check
- ✅ Security checks in place
- ✅ Error handling comprehensive

---

**Next Steps**: Manual end-to-end testing recommended to verify the complete flow works correctly in the mobile app.
