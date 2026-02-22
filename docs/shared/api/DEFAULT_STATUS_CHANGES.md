# Default Status Changes

**Last Updated**: January 20, 2026  
**Status**: ✅ Implemented

---

## 📋 **OVERVIEW**

The default status for milk sales and collections has been changed from `pending` to `accepted` to streamline the workflow. New records are automatically approved upon creation.

---

## 🎯 **CHANGES**

### **Sales Module**

#### Before
- Default status: `pending`
- Required manual approval

#### After
- Default status: `accepted`
- Automatically approved on creation
- Status can still be explicitly set if needed

**Implementation:**
```typescript
status: (status || 'accepted') as any,
```

**DTO:**
```typescript
@ApiProperty({
  description: 'Sale status',
  enum: ['pending', 'accepted', 'rejected', 'cancelled'],
  example: 'accepted',
  required: false,
  default: 'accepted',
})
status?: MilkSaleStatus;
```

### **Collections Module**

#### Before
- Status was required
- Default was `pending`

#### After
- Status is optional
- Default status: `accepted`
- Automatically approved on creation

**Implementation:**
```typescript
status: (status || 'accepted') as any,
```

**DTO:**
```typescript
@ApiProperty({
  description: 'Collection status',
  example: 'accepted',
  enum: ['pending', 'accepted', 'rejected', 'cancelled'],
  required: false,
  default: 'accepted',
})
status?: string;
```

---

## 📝 **API EXAMPLES**

### Create Sale (Default Status)
```json
POST /api/sales
{
  "customer_account_id": "123e4567-e89b-12d3-a456-426614174000",
  "quantity": 120.5,
  "unit_price": 390.0
}
```

**Response:**
```json
{
  "code": 200,
  "status": "success",
  "data": {
    "id": "sale-uuid",
    "quantity": 120.5,
    "unit_price": 390.0,
    "status": "accepted",  // Automatically set
    ...
  }
}
```

### Create Collection (Default Status)
```json
POST /api/collections/create
{
  "supplier_account_code": "A_ABC123",
  "quantity": 120.5,
  "collection_at": "2025-01-20 10:00:00"
}
```

**Response:**
```json
{
  "code": 200,
  "status": "success",
  "data": {
    "collection_id": "collection-uuid",
    "quantity": 120.5,
    "status": "accepted",  // Automatically set
    ...
  }
}
```

### Explicit Status (Still Supported)
```json
POST /api/sales
{
  "customer_account_id": "123e4567-e89b-12d3-a456-426614174000",
  "quantity": 120.5,
  "status": "pending"  // Can still set explicitly
}
```

---

## 🔄 **WORKFLOW IMPACT**

### Before
1. Record sale/collection → Status: `pending`
2. Manual approval required
3. Update status to `accepted`

### After
1. Record sale/collection → Status: `accepted` (automatic)
2. Ready for processing immediately
3. Rejection/cancellation can be done later if needed

---

## ✅ **BENEFITS**

1. **Streamlined Workflow**: No manual approval step required
2. **Faster Processing**: Records ready immediately
3. **Flexibility**: Status can still be set explicitly
4. **Backward Compatible**: Explicit status setting still works

---

## 🧪 **TESTING**

Default status has been verified:
- ✅ Sales default to `accepted` when status not provided
- ✅ Collections default to `accepted` when status not provided
- ✅ Explicit status setting still works
- ✅ Mobile app compatibility maintained

---

## 📱 **MOBILE APP**

The mobile app already sends `'Accepted'` status, which gets converted to lowercase `'accepted'`:
- No changes needed in mobile app
- Works seamlessly with new defaults

---

## 🔗 **RELATED DOCUMENTATION**

- [API Endpoints](./ENDPOINTS_COMPLETE.md)
- [UUID Consistency](./UUID_CONSISTENCY.md)

---

**Last Updated**: January 20, 2026
