# API Documentation

Complete API documentation for Gemura 2.0 backend.

## 📚 Documentation Files

### Main Documentation
- **[endpoints-complete.md](./endpoints-complete.md)** - Complete list of implemented endpoints
- **[remaining-endpoints.md](./remaining-endpoints.md)** - Endpoints still to be implemented
- **[app-flow-documentation.md](./app-flow-documentation.md)** - Application flow and API usage

### Implementation Details
- **[uuid-consistency.md](./uuid-consistency.md)** - UUID implementation and usage
- **[soft-delete-implementation.md](./soft-delete-implementation.md)** - Soft delete pattern
- **[default-status-changes.md](./default-status-changes.md)** - Default status changes
- **[api-architecture.md](./api-architecture.md)** - Architecture and design decisions

### Deployment & Testing
- **[deployment-and-testing-complete.md](./deployment-and-testing-complete.md)** - Deployment and testing status
- **[api-testing-results.md](./api-testing-results.md)** - API testing results
- **[endpoint-testing-summary.md](./endpoint-testing-summary.md)** - Endpoint testing summary

### Feature Documentation
- **[feed-and-api-keys-deployment.md](./feed-and-api-keys-deployment.md)** - Feed and API keys module
- **[feed-and-api-keys-test-results.md](./feed-and-api-keys-test-results.md)** - Feed module test results

## 🌐 API Endpoints

### Base URL
```
http://localhost:3004/api        # Local development
http://159.198.65.38:3004/api   # Production
```

### Swagger Documentation
```
http://localhost:3004/api/docs
http://159.198.65.38:3004/api/docs
```

### Health Check
```
GET http://localhost:3004/api/health
```

## 📋 API Modules

### ✅ Completed Modules

#### Authentication (6 endpoints)
- `POST /auth/login` - User login
- `POST /auth/register` - User registration
- `POST /auth/verify` - Token verification
- `POST /auth/forgot-password` - Password reset request
- `POST /auth/reset-password` - Password reset
- `GET /auth/token` - Token validation

#### Accounts (3 endpoints)
- `GET /accounts` - Get user accounts
- `GET /accounts/list` - List user accounts
- `POST /accounts/switch` - Switch account

#### Sales (4 endpoints)
- `POST /sales` - Create new sale
- `POST /sales/sales` - Get sales list
- `PUT /sales/update` - Update sale
- `POST /sales/cancel` - Cancel sale

#### Collections (11 endpoints)
- `GET /collections` - Get all collections
- `GET /collections/:id` - Get collection details
- `POST /collections/create` - Create collection
- `PUT /collections/update` - Update collection
- `DELETE /collections/:id` - Delete collection
- `POST /collections/cancel` - Cancel collection
- Plus 5 rejection reason endpoints

#### Suppliers (6 endpoints)
- `POST /suppliers/create` - Create supplier
- `POST /suppliers/get` - Get suppliers list
- `GET /suppliers/by-id/:id` - Get supplier by ID (UUID)
- `GET /suppliers/:code` - Get supplier by code
- `PUT /suppliers/update` - Update supplier
- `DELETE /suppliers/:code` - Delete supplier

#### Customers (6 endpoints)
- `POST /customers` - Create customer
- `POST /customers/get` - Get customers list
- `GET /customers/by-id/:id` - Get customer by ID (UUID)
- `GET /customers/:code` - Get customer by code
- `PUT /customers/update` - Update customer
- `DELETE /customers/:code` - Delete customer

#### Inventory (5 endpoints)
- `GET /inventory` - Get inventory items
- `POST /inventory` - Create inventory item
- `PUT /inventory/update` - Update inventory item
- `DELETE /inventory/:id` - Delete inventory item
- `POST /inventory/sell` - Sell inventory item

See [endpoints-complete.md](./endpoints-complete.md) for complete list.

## 🔑 Key Features

### UUID Consistency
- All endpoints prioritize UUIDs over account codes
- UUID format validation
- Account IDs included in all responses
- See [uuid-consistency.md](./uuid-consistency.md)

### Soft Delete
- All delete operations use soft delete
- Records preserved for auditing
- See [soft-delete-implementation.md](./soft-delete-implementation.md)

### Default Status
- Sales and collections default to `accepted` status
- See [default-status-changes.md](./default-status-changes.md)

## 🧪 Testing

### Test Results
- [api-testing-results.md](./api-testing-results.md) - Complete test results
- [endpoint-testing-summary.md](./endpoint-testing-summary.md) - Testing summary

### Running Tests
```bash
# Test backend
./scripts/testing/test-backend-simple.sh

# Test specific endpoints
curl http://localhost:3004/api/health
```

## 📖 API Usage

### Authentication
All API requests (except auth endpoints) require authentication via Bearer token:

```bash
curl -H "Authorization: Bearer YOUR_TOKEN" \
  http://localhost:3004/api/accounts
```

### Error Responses
All errors follow this format:
```json
{
  "code": 400,
  "status": "error",
  "message": "Error description"
}
```

### Success Responses
All success responses follow this format:
```json
{
  "code": 200,
  "status": "success",
  "message": "Success message",
  "data": { ... }
}
```

## 📝 Swagger Documentation

All endpoints are fully documented in Swagger UI:
- Visit `http://localhost:3004/api/docs` for interactive API documentation
- All endpoints include:
  - Request/response examples
  - Parameter descriptions
  - Error responses
  - Authentication requirements

## 🔗 Related Documentation

- [Deployment Guide](../deployment/README.md) - API deployment
- [Testing Results](../testing/README.md) - API test results
- [Mobile Integration](../../gemura/mobile/mobile-app-integration.md) - Mobile API usage
- [Architecture Decisions](./api-architecture.md) - Design decisions

---

**Last Updated:** January 20, 2026  
**Total Endpoints:** 50+ endpoints implemented
