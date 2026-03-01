# UUID Consistency Implementation

**Last Updated**: January 20, 2026  
**Status**: ✅ Implemented

---

## 📋 **OVERVIEW**

The API now consistently uses UUIDs (Universally Unique Identifiers) for account identification across all endpoints. This provides better data integrity, avoids conflicts, and enables more reliable relationships between entities.

---

## 🎯 **IMPLEMENTATION DETAILS**

### **Sales Module**

#### Create Sale (`POST /api/sales`)
- **Preferred**: `customer_account_id` (UUID)
- **Fallback**: `customer_account_code` (account code)
- **Response**: Includes both `id` and `code` for supplier and customer accounts

**Example Request (UUID):**
```json
{
  "customer_account_id": "123e4567-e89b-12d3-a456-426614174000",
  "quantity": 120.5,
  "unit_price": 390.0
}
```

**Example Request (Code - Fallback):**
```json
{
  "customer_account_code": "A_XYZ789",
  "quantity": 120.5,
  "unit_price": 390.0
}
```

#### Update Sale (`PUT /api/sales/update`)
- Supports both `customer_account_id` (UUID) and `customer_account_code`
- UUID is validated before processing

### **Suppliers Module**

#### Get Supplier by ID (`GET /api/suppliers/by-id/:id`)
- Accepts UUID as path parameter
- Validates UUID format (returns 400 if invalid)
- Returns 404 if supplier not found

**Example:**
```
GET /api/suppliers/by-id/123e4567-e89b-12d3-a456-426614174000
```

### **Customers Module**

#### Get Customer by ID (`GET /api/customers/by-id/:id`)
- Accepts UUID as path parameter
- Validates UUID format (returns 400 if invalid)
- Returns 404 if customer not found

**Example:**
```
GET /api/customers/by-id/123e4567-e89b-12d3-a456-426614174000
```

---

## 📤 **RESPONSE FORMAT**

All responses now include account IDs (UUIDs) in addition to codes:

**Example Response:**
```json
{
  "code": 200,
  "status": "success",
  "data": {
    "supplier_account": {
      "id": "123e4567-e89b-12d3-a456-426614174000",
      "code": "A_ABC123",
      "name": "Supplier Name",
      "type": "tenant",
      "status": "active"
    },
    "customer_account": {
      "id": "789e4567-e89b-12d3-a456-426614174000",
      "code": "A_XYZ789",
      "name": "Customer Name",
      "type": "tenant",
      "status": "active"
    }
  }
}
```

---

## ✅ **VALIDATION**

### UUID Format Validation
All UUID parameters are validated using regex:
```typescript
const uuidRegex = /^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/i;
```

**Error Response (Invalid UUID):**
```json
{
  "code": 400,
  "status": "error",
  "message": "Invalid customer account ID format. Must be a valid UUID."
}
```

---

## 🔄 **BACKWARD COMPATIBILITY**

The implementation maintains backward compatibility:
- Account codes are still accepted where UUIDs are preferred
- Existing mobile app code continues to work
- Gradual migration path: use UUIDs when available, fall back to codes

---

## 📱 **MOBILE APP INTEGRATION**

The mobile app has been updated to:
- Send `customer_account_id` (UUID) when available
- Fall back to `customer_account_code` if UUID is not available
- Handle both UUID and code in responses

**Example (Flutter/Dart):**
```dart
await salesService.recordSale(
  customerAccountId: customer.accountId,  // UUID preferred
  customerAccountCode: customer.accountId == null 
    ? customer.accountCode 
    : null,  // Fallback to code
  quantity: 120.5,
  status: 'accepted',
  saleAt: DateTime.now(),
);
```

---

## 🧪 **TESTING**

All UUID functionality has been tested:
- ✅ UUID format validation
- ✅ UUID lookup (by ID)
- ✅ Code fallback
- ✅ Error handling for invalid UUIDs
- ✅ Account IDs in responses

---

## 📝 **BEST PRACTICES**

1. **Always prefer UUIDs** when available
2. **Validate UUID format** before sending to API
3. **Handle both UUID and code** in responses
4. **Use UUIDs for new implementations**
5. **Maintain code support** for legacy compatibility

---

## 🔗 **RELATED DOCUMENTATION**

- [API Endpoints](./ENDPOINTS_COMPLETE.md)
- [Soft Delete Implementation](./SOFT_DELETE_IMPLEMENTATION.md)
- [Default Status Changes](./DEFAULT_STATUS_CHANGES.md)

---

**Last Updated**: January 20, 2026
