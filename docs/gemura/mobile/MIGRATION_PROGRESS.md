# Mobile App API Migration Progress

## Status: In Progress

Migrating mobile app from PHP API endpoints to NestJS backend API.

**Old Base URL:** `https://api.gemura.rw/v2`  
**New Base URL:** `http://159.198.65.38:3004/api`

## Completed Updates ✅

### Configuration Files
- [x] `app_config.dart` - Updated base URL
- [x] `secure_config.dart` - Updated base URL

### Core Services
- [x] `auth_service.dart` - Updated all endpoints
  - `/auth/forgot-password` (was `/auth/request_reset.php`)
  - `/auth/reset-password` (was `/auth/reset_password.php`)
  - `/profile/get` (was `/profile/get.php`)
  - `/profile/update` (was `/profile/update.php`, now PUT method)
- [x] `feed_service.dart` - Completely updated
  - Uses AuthenticatedDioService
  - All endpoints updated to NestJS format
  - Removed `.php` extensions
  - Changed methods (GET for reads, PATCH for updates, DELETE for deletes)
- [x] `notification_service.dart` - Updated
  - Removed `.php` extensions
  - Changed methods (PUT for update, DELETE for delete)
  - Removed token from body
- [x] `kyc_service.dart` - Updated
  - `/kyc/upload-photo` (was `/kyc/upload_photo.php`)
- [x] `api_keys_service.dart` - Updated
  - `/api-keys` GET (was `/api_keys/get` POST)
- [x] `user_accounts_service.dart` - Updated
  - `/accounts` GET (was `/accounts/get` POST)
  - `/accounts/switch` POST (removed token from body)

### Market Providers
- [x] `products_provider.dart` - Updated base URL and endpoints
- [x] `categories_provider.dart` - Updated base URL and endpoints
- [x] `search_provider.dart` - Updated base URL and endpoints

### Referrals
- [x] `referral_service.dart` - Updated all endpoints
  - Uses AuthenticatedDioService
  - Removed `.php` extensions
  - Changed methods (GET for reads)

## Partially Updated ⚠️

### Services Using AuthenticatedDioService (Need Token Removal)
- [x] `wallets_service.dart` - Updated to remove token from GET
- [ ] `suppliers_service.dart` - Needs token removal from all methods
- [ ] `customers_service.dart` - Needs token removal + endpoint fix (no "get all" in NestJS)
- [ ] `collections_service.dart` - Needs token removal + endpoint fix (no "get all" in NestJS)
- [ ] `sales_service.dart` - Updated to remove token from body

## Issues Found 🔍

### Missing Endpoints in NestJS Backend

1. **Customers - Get All**
   - Mobile calls: `/customers/get` (POST)
   - NestJS has: `/customers` (POST - creates), `/customers/:code` (GET - by code)
   - **Action Needed:** Implement GET `/customers` endpoint in backend OR update mobile to use different approach

2. **Collections - Get All**
   - Mobile calls: `/collections/get` (POST)
   - NestJS has: `/collections/:id` (GET - by ID), `/collections/create` (POST)
   - **Action Needed:** Implement GET `/collections` endpoint in backend OR update mobile logic

3. **Collections - Get Filtered**
   - Mobile calls: `/collections/get` with filters
   - **Action Needed:** Same as above

## Remaining Work 📋

### High Priority
1. [ ] Remove all `token` from request bodies in:
   - `suppliers_service.dart` (all methods)
   - `customers_service.dart` (all methods)
   - `collections_service.dart` (all methods)
   - `sales_service.dart` (remaining methods)
   - `wallets_service.dart` (create, details methods)

2. [ ] Fix customers "get all" - either:
   - Add GET `/customers` endpoint to backend
   - Or update mobile to use different approach

3. [ ] Fix collections "get all" - either:
   - Add GET `/collections` endpoint to backend
   - Or update mobile to use different approach

### Medium Priority
4. [ ] Update response parsing - NestJS response format may differ
5. [ ] Test all endpoints after updates
6. [ ] Update error handling for new response format

### Low Priority
7. [ ] Remove unused SecureStorageService.getAuthToken() calls
8. [ ] Clean up commented code
9. [ ] Update documentation

## Testing Checklist

- [ ] Authentication (login, register, password reset)
- [ ] Profile (get, update)
- [ ] Feed (posts, comments, likes, bookmarks)
- [ ] Notifications (get, create, update, delete)
- [ ] Accounts (get, switch)
- [ ] API Keys (get, create, delete)
- [ ] Wallets (get, create, details)
- [ ] Suppliers (get, create, update, delete)
- [ ] Customers (get, create, update, delete)
- [ ] Collections (get, create, update, cancel)
- [ ] Sales (get, create, update, cancel)
- [ ] Market (products, categories, search)
- [ ] Referrals (get code, use code, stats, points)
- [ ] KYC (upload photo)

## Notes

- All services now use `AuthenticatedDioService` which automatically adds Bearer token to headers
- Token should NOT be in request body anymore
- Some endpoints changed HTTP methods (e.g., profile/update is now PUT instead of POST)
- Response format may need adjustment based on actual NestJS responses
