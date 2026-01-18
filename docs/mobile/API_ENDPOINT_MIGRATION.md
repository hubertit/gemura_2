# API Endpoint Migration Guide
## PHP to NestJS API Mapping

This document maps old PHP endpoints to new NestJS endpoints.

**Old Base URL:** `https://api.gemura.rw/v2`  
**New Base URL:** `http://159.198.65.38:3004/api`

## Authentication Endpoints

| PHP Endpoint | NestJS Endpoint | Method | Notes |
|--------------|----------------|--------|-------|
| `/auth/register` | `/auth/register` | POST | Same |
| `/auth/login` | `/auth/login` | POST | Same |
| `/auth/request_reset.php` | `/auth/forgot-password` | POST | Changed |
| `/auth/reset_password.php` | `/auth/reset-password` | POST | Changed |
| `/auth/token` | `/auth/token` | GET | Same |

## Profile Endpoints

| PHP Endpoint | NestJS Endpoint | Method | Notes |
|--------------|----------------|--------|-------|
| `/profile/get.php` | `/profile/get` | GET | Removed .php |
| `/profile/update.php` | `/profile/update` | PUT | Removed .php, method changed |

## Accounts Endpoints

| PHP Endpoint | NestJS Endpoint | Method | Notes |
|--------------|----------------|--------|-------|
| `/accounts/get` | `/accounts` | GET | Changed |
| `/accounts/switch` | `/accounts/switch` | POST | Same |

## Feed Endpoints

| PHP Endpoint | NestJS Endpoint | Method | Notes |
|--------------|----------------|--------|-------|
| `/feed/get.php` | `/feed/posts` | GET | Changed structure |
| `/feed/create.php` | `/feed/posts` | POST | Changed |
| `/feed/update.php` | `/feed/posts/:id` | PATCH | Changed |
| `/feed/delete.php` | `/feed/posts/:id` | DELETE | Changed |
| `/feed/comments/get.php` | `/feed/comments` | GET | Changed |
| `/feed/comments/create.php` | `/feed/comments` | POST | Changed |
| `/feed/comments/update.php` | `/feed/comments/:id` | PATCH | Changed |
| `/feed/comments/delete.php` | `/feed/comments/:id` | DELETE | Changed |
| `/feed/like.php` | `/feed/interactions` | POST | Changed |
| `/feed/likes.php` | `/feed/interactions` | GET | Changed |
| `/feed/bookmark.php` | `/feed/posts/:id` (bookmark field) | PATCH | Changed |
| `/feed/bookmarks.php` | `/feed/posts?bookmarked=true` | GET | Changed |
| `/feed/follow.php` | `/feed/follow` | POST | Same |

## Notifications Endpoints

| PHP Endpoint | NestJS Endpoint | Method | Notes |
|--------------|----------------|--------|-------|
| `/notifications/get.php` | `/notifications/get` | POST | Removed .php |
| `/notifications/create.php` | `/notifications` | POST | Removed .php |
| `/notifications/update.php` | `/notifications/:id` | PUT | Removed .php |
| `/notifications/delete.php` | `/notifications/:id` | DELETE | Removed .php |

## KYC Endpoints

| PHP Endpoint | NestJS Endpoint | Method | Notes |
|--------------|----------------|--------|-------|
| `/kyc/upload_photo.php` | `/kyc/upload-photo` | POST | Changed format |

## Market Endpoints

| PHP Endpoint | NestJS Endpoint | Method | Notes |
|--------------|----------------|--------|-------|
| `/market/products/list.php` | `/market/products` | GET | Removed .php |
| `/market/products/featured.php` | `/market/products/featured` | GET | Removed .php |
| `/market/products/recent.php` | `/market/products/recent` | GET | Removed .php |
| `/market/products/search.php` | `/market/products/search` | GET | Removed .php |
| `/market/categories/list.php` | `/market/categories` | GET | Removed .php |

## Referrals & Points Endpoints

| PHP Endpoint | NestJS Endpoint | Method | Notes |
|--------------|----------------|--------|-------|
| `/referrals/get-code.php` | `/referrals/get-code` | GET | Removed .php |
| `/referrals/use-code.php` | `/referrals/use-code` | POST | Removed .php |
| `/referrals/stats.php` | `/referrals/stats` | GET | Removed .php |
| `/points/balance.php` | `/points/balance` | GET | Removed .php |
| `/onboard/create-user.php` | `/onboard/create-user` | POST | Removed .php |

## API Keys Endpoints

| PHP Endpoint | NestJS Endpoint | Method | Notes |
|--------------|----------------|--------|-------|
| `/api_keys/get` | `/api-keys` | GET | Changed format |
| `/api_keys/create` | `/api-keys` | POST | Changed format |
| `/api_keys/delete` | `/api-keys/:id` | DELETE | Changed format |

## Other Services

| PHP Endpoint | NestJS Endpoint | Method | Notes |
|--------------|----------------|--------|-------|
| `/collections/create` | `/collections/create` | POST | Same |
| `/collections/update` | `/collections/update` | PUT | Same |
| `/collections/cancel` | `/collections/cancel` | POST | Same |
| `/sales/sales` | `/sales/sales` | POST | Same |
| `/sales/update` | `/sales/update` | PUT | Same |
| `/suppliers/get` | `/suppliers/get` | POST | Same |
| `/suppliers/create` | `/suppliers/create` | POST | Same |
| `/customers/get` | `/customers` | POST | Changed |
| `/wallets/get` | `/wallets/get` | GET | Same |
| `/wallets/create` | `/wallets/create` | POST | Same |
| `/stats/overview` | `/stats/overview` | POST | Same |
| `/reports/my_report.php` | `/reports/my-report` | POST | Changed format |

## Key Changes

1. **Base URL:** Changed from `https://api.gemura.rw/v2` to `http://159.198.65.38:3004/api`
2. **PHP Extension:** All `.php` extensions removed
3. **HTTP Methods:** Some endpoints changed methods (e.g., profile/update is now PUT instead of POST)
4. **Response Format:** NestJS uses standard REST responses, may differ from PHP format
5. **Authentication:** Uses Bearer token in Authorization header (same as before)

## Migration Checklist

- [x] Create endpoint mapping document
- [ ] Update base URL in app_config.dart
- [ ] Update auth_service.dart
- [ ] Update feed_service.dart
- [ ] Update notification_service.dart
- [ ] Update profile endpoints
- [ ] Update market providers
- [ ] Update referrals service
- [ ] Update all other services
- [ ] Test all endpoints
- [ ] Update error handling for new response format
