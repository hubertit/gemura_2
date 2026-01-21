# API Architecture & Design Decisions

**Last Updated**: January 20, 2026

---

## 🏗️ **ARCHITECTURE OVERVIEW**

### Technology Stack
- **Framework**: NestJS (TypeScript)
- **Database**: PostgreSQL with Prisma ORM
- **Authentication**: Bearer token (JWT-like)
- **Documentation**: Swagger/OpenAPI
- **Validation**: class-validator, class-transformer

---

## 🎯 **DESIGN PRINCIPLES**

### 1. UUID Consistency
- **Decision**: Use UUIDs as primary identifiers
- **Rationale**: Better data integrity, avoids conflicts, enables reliable relationships
- **Implementation**: All endpoints accept UUIDs, with account codes as fallback
- **Status**: ✅ Implemented across Sales, Suppliers, Customers modules

### 2. Soft Delete Pattern
- **Decision**: Never permanently delete records
- **Rationale**: Preserve data for auditing, maintain referential integrity, enable recovery
- **Implementation**: Set status to 'deleted' or 'inactive' instead of removing records
- **Status**: ✅ Implemented across Collections, Suppliers, Customers, Inventory, Feed, Employees

### 3. Default Status: Accepted
- **Decision**: New sales/collections default to 'accepted' status
- **Rationale**: Streamline workflow, reduce manual approval steps
- **Implementation**: Default status changed from 'pending' to 'accepted'
- **Status**: ✅ Implemented in Sales and Collections modules

### 4. Account IDs in Responses
- **Decision**: Include both UUID and code in all account responses
- **Rationale**: Support both UUID-based and code-based lookups, maintain backward compatibility
- **Implementation**: All responses include `id` (UUID) and `code` for accounts
- **Status**: ✅ Implemented across all modules

---

## 📐 **API DESIGN PATTERNS**

### Response Format
All endpoints follow consistent response structure:

**Success:**
```json
{
  "code": 200,
  "status": "success",
  "message": "Operation completed successfully.",
  "data": { ... }
}
```

**Error:**
```json
{
  "code": 400|401|404|500,
  "status": "error",
  "message": "Error description"
}
```

### Error Handling
- **400**: Bad Request (validation errors, invalid input)
- **401**: Unauthorized (missing/invalid token)
- **403**: Forbidden (insufficient permissions)
- **404**: Not Found (resource doesn't exist)
- **500**: Internal Server Error (server-side issues)

### Validation
- **Input Validation**: class-validator decorators on DTOs
- **UUID Validation**: Regex pattern matching
- **Business Logic**: Service layer validation
- **Database Constraints**: Prisma schema constraints

---

## 🔐 **AUTHENTICATION & AUTHORIZATION**

### Token-Based Authentication
- All endpoints (except `/api/auth/*` and `/api/health`) require Bearer token
- Token passed in `Authorization` header
- Token validation via `TokenGuard`

### Authorization
- User must have valid `default_account_id`
- Resource ownership verified before operations
- Role-based access control for employees module

---

## 🗄️ **DATABASE DESIGN**

### Soft Delete Fields
- `status`: Used for soft delete in milk_sales, feed_posts
- `relationship_status`: Used for soft delete in suppliers_customers
- `updated_by`: Tracks who made the change

### Account Relationships
- All relationships use UUIDs for foreign keys
- Account codes maintained for backward compatibility
- Both UUID and code can be used for lookups

---

## 📦 **MODULE STRUCTURE**

Each module follows this structure:
```
module/
├── module.controller.ts    # API endpoints
├── module.service.ts        # Business logic
├── module.module.ts         # Module definition
└── dto/
    ├── create-module.dto.ts
    ├── update-module.dto.ts
    └── ...
```

### Controller Responsibilities
- Route handling
- Request validation
- Response formatting
- Swagger documentation

### Service Responsibilities
- Business logic
- Database operations
- Data transformation
- Error handling

---

## 🔄 **DATA FLOW**

### Create Operation
1. Client sends request with DTO
2. Controller validates DTO
3. Service validates business rules
4. Service creates record in database
5. Service returns formatted response

### Update Operation
1. Client sends request with DTO
2. Controller validates DTO
3. Service verifies ownership
4. Service updates record
5. Service returns updated data

### Delete Operation (Soft)
1. Client sends DELETE request
2. Controller validates ID
3. Service verifies ownership
4. Service updates status to 'deleted'/'inactive'
5. Service returns success response

---

## 🧪 **TESTING STRATEGY**

### Endpoint Testing
- All endpoints tested with curl/Postman
- Success cases verified
- Error cases verified
- Edge cases handled

### Integration Testing
- Mobile app integration verified
- UUID consistency tested
- Soft delete verified
- Default status tested

---

## 📚 **DOCUMENTATION STANDARDS**

### Swagger Documentation
- All endpoints documented with `@ApiOperation`
- Request/response examples provided
- Error responses documented
- Parameter descriptions included

### Code Documentation
- Inline comments for complex logic
- README files for modules
- Architecture decisions documented

---

## 🔗 **RELATED DOCUMENTATION**

- [Complete Endpoints](./ENDPOINTS_COMPLETE.md)
- [UUID Consistency](./UUID_CONSISTENCY.md)
- [Soft Delete Implementation](./SOFT_DELETE_IMPLEMENTATION.md)
- [Default Status Changes](./DEFAULT_STATUS_CHANGES.md)

---

**Last Updated**: January 20, 2026
