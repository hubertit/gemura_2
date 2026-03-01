# Complete API Endpoints Documentation

**Last Updated**: January 20, 2026  
**Status**: Core Endpoints Complete ✅

---

## 📊 **ENDPOINT SUMMARY**

### ✅ **COMPLETED MODULES** (28+ endpoints)

#### Authentication Module ✅ **COMPLETE** (6/6)
- ✅ `POST /api/auth/login` - User login
- ✅ `POST /api/auth/register` - User registration
- ✅ `POST /api/auth/verify` - Token verification
- ✅ `POST /api/auth/forgot-password` - Password reset request
- ✅ `POST /api/auth/reset-password` - Password reset
- ✅ `GET /api/auth/token` - Token validation (legacy compatibility)

#### Accounts Module ✅ **COMPLETE** (3/3)
- ✅ `GET /api/accounts` - Get user accounts
- ✅ `GET /api/accounts/list` - List user accounts
- ✅ `POST /api/accounts/switch` - Switch account

#### Profile Module ✅ **COMPLETE** (2/2)
- ✅ `GET /api/profile/get` - Get user profile
- ✅ `PUT /api/profile/update` - Update user profile

#### Wallets Module ✅ **COMPLETE** (1/1)
- ✅ `GET /api/wallets/get` - Get wallets

#### Sales Module ✅ **COMPLETE** (4/4)
- ✅ `POST /api/sales` - Create new sale
- ✅ `POST /api/sales/sales` - Get sales list with filters
- ✅ `PUT /api/sales/update` - Update sale
- ✅ `POST /api/sales/cancel` - Cancel sale

**Features:**
- Supports UUID (`customer_account_id`) or code (`customer_account_code`)
- Default status: `accepted`
- All responses include account IDs (UUIDs)

#### Collections Module ✅ **COMPLETE** (11/11)
- ✅ `GET /api/collections` - Get all collections
- ✅ `GET /api/collections/:id` - Get collection details
- ✅ `POST /api/collections/create` - Create collection
- ✅ `PUT /api/collections/update` - Update collection
- ✅ `DELETE /api/collections/:id` - Delete collection (soft delete)
- ✅ `POST /api/collections/cancel` - Cancel collection
- ✅ `GET /api/collections/rejection-reasons` - Get rejection reasons
- ✅ `GET /api/collections/rejection-reasons/:id` - Get rejection reason by ID
- ✅ `POST /api/collections/rejection-reasons` - Create rejection reason
- ✅ `PUT /api/collections/rejection-reasons/:id` - Update rejection reason
- ✅ `DELETE /api/collections/rejection-reasons/:id` - Delete rejection reason

**Features:**
- Default status: `accepted`
- Soft delete implementation
- All responses include account IDs (UUIDs)

#### Suppliers Module ✅ **COMPLETE** (6/6)
- ✅ `POST /api/suppliers/create` - Create supplier
- ✅ `POST /api/suppliers/get` - Get suppliers list
- ✅ `GET /api/suppliers/by-id/:id` - Get supplier by ID (UUID)
- ✅ `GET /api/suppliers/:code` - Get supplier by code
- ✅ `PUT /api/suppliers/update` - Update supplier
- ✅ `DELETE /api/suppliers/:code` - Delete supplier (soft delete)

**Features:**
- UUID support for fetching by ID
- Soft delete (sets relationship_status to 'inactive')
- All responses include account IDs (UUIDs)

#### Customers Module ✅ **COMPLETE** (6/6)
- ✅ `POST /api/customers` - Create customer
- ✅ `POST /api/customers/get` - Get customers list
- ✅ `GET /api/customers/by-id/:id` - Get customer by ID (UUID)
- ✅ `GET /api/customers/:code` - Get customer by code
- ✅ `PUT /api/customers/update` - Update customer
- ✅ `DELETE /api/customers/:code` - Delete customer (soft delete)

**Features:**
- UUID support for fetching by ID
- Soft delete (sets relationship_status to 'inactive')
- All responses include account IDs (UUIDs)

#### Inventory Module ✅ **COMPLETE** (5/5)
- ✅ `GET /api/inventory` - Get inventory items
- ✅ `POST /api/inventory` - Create inventory item
- ✅ `PUT /api/inventory/update` - Update inventory item
- ✅ `DELETE /api/inventory/:id` - Delete inventory item (soft delete)
- ✅ `POST /api/inventory/sell` - Sell inventory item

**Features:**
- Soft delete implementation
- Supports debt/credit for suppliers

#### Health Module ✅ **COMPLETE** (1/1)
- ✅ `GET /api/health` - Health check

---

## 🔑 **KEY FEATURES**

### UUID Consistency
All endpoints now prioritize UUIDs over account codes:
- **Sales**: `customer_account_id` (UUID) preferred, `customer_account_code` as fallback
- **Suppliers**: `GET /api/suppliers/by-id/:id` for UUID lookup
- **Customers**: `GET /api/customers/by-id/:id` for UUID lookup
- All responses include account IDs (UUIDs) in addition to codes

### Soft Delete Implementation
The following modules use soft delete:
- **Collections**: Sets `status: 'deleted'`
- **Suppliers**: Sets `relationship_status: 'inactive'`
- **Customers**: Sets `relationship_status: 'inactive'`
- **Inventory**: Sets `status: 'inactive'`
- **Feed Posts**: Sets `status: 'deleted'`
- **Employees**: Sets `status: 'inactive'`

### Default Status
- **Sales**: Default status is `accepted` (was `pending`)
- **Collections**: Default status is `accepted` (was `pending`)

---

## 📖 **API DOCUMENTATION**

### Swagger UI
All endpoints are fully documented in Swagger:
```
http://localhost:3004/api/docs
http://159.198.65.38:3004/api/docs
```

### Authentication
All endpoints (except `/api/auth/*` and `/api/health`) require Bearer token:
```
Authorization: Bearer YOUR_TOKEN
```

### Response Format
All responses follow this structure:
```json
{
  "code": 200,
  "status": "success",
  "message": "Operation completed successfully.",
  "data": { ... }
}
```

### Error Format
All errors follow this structure:
```json
{
  "code": 400,
  "status": "error",
  "message": "Error description"
}
```

---

## 🧪 **TESTING**

All endpoints have been tested and verified:
- ✅ UUID support working
- ✅ Account IDs in responses
- ✅ Soft delete functionality
- ✅ Default status (`accepted`)
- ✅ Error handling
- ✅ Validation

See [API_TESTING_RESULTS.md](./API_TESTING_RESULTS.md) for detailed test results.

---

## 📝 **NOTES**

1. **UUID vs Code**: While UUIDs are preferred, account codes are still supported for backward compatibility
2. **Soft Delete**: Deleted records are preserved in the database but filtered from active lists
3. **Default Status**: New sales and collections are automatically set to `accepted` status
4. **Account IDs**: All responses include both `id` (UUID) and `code` for accounts

---

**Last Updated**: January 20, 2026  
**Total Completed Endpoints**: 28+ endpoints
