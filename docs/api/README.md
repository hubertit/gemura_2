# API Documentation

Complete API documentation for Gemura 2.0 backend.

## 📚 Documentation Files

### Main Documentation
- **[APP_FLOW_DOCUMENTATION.md](./APP_FLOW_DOCUMENTATION.md)** - Application flow and API usage
- **[REMAINING_ENDPOINTS.md](./REMAINING_ENDPOINTS.md)** - Endpoints still to be implemented

### Deployment & Testing
- **[DEPLOYMENT_AND_TESTING_COMPLETE.md](./DEPLOYMENT_AND_TESTING_COMPLETE.md)** - Deployment and testing status
- **[API_TESTING_RESULTS.md](./API_TESTING_RESULTS.md)** - API testing results
- **[ENDPOINT_TESTING_SUMMARY.md](./ENDPOINT_TESTING_SUMMARY.md)** - Endpoint testing summary

### Feature Documentation
- **[FEED_AND_API_KEYS_DEPLOYMENT.md](./FEED_AND_API_KEYS_DEPLOYMENT.md)** - Feed and API keys module
- **[FEED_AND_API_KEYS_TEST_RESULTS.md](./FEED_AND_API_KEYS_TEST_RESULTS.md)** - Feed module test results

## 🌐 API Endpoints

### Base URL
```
http://159.198.65.38:3004/api
```

### Swagger Documentation
```
http://159.198.65.38:3004/api/docs
```

### Health Check
```
http://159.198.65.38:3004/api/health
```

## 📋 API Modules

### Authentication
- `POST /auth/login` - User login
- `POST /auth/register` - User registration
- `GET /auth/token` - Get auth token

### Accounts
- `GET /accounts` - List user accounts
- `POST /accounts/switch` - Switch active account

### Feed
- `GET /feed/posts` - Get feed posts
- `POST /feed/posts` - Create post
- `GET /feed/comments` - Get comments
- `POST /feed/comments` - Create comment

### Market
- `GET /products` - List products
- `POST /products` - Create product
- `GET /orders` - List orders

See [APP_FLOW_DOCUMENTATION.md](./APP_FLOW_DOCUMENTATION.md) for complete API flow.

## 🧪 Testing

### Test Results
- [API_TESTING_RESULTS.md](./API_TESTING_RESULTS.md) - Complete test results
- [ENDPOINT_TESTING_SUMMARY.md](./ENDPOINT_TESTING_SUMMARY.md) - Testing summary

### Running Tests
```bash
# Test backend
./scripts/testing/test-backend-simple.sh

# Test specific endpoints
curl http://159.198.65.38:3004/api/health
```

## 📖 API Usage

### Authentication
All API requests (except auth endpoints) require authentication via Bearer token:

```bash
curl -H "Authorization: Bearer YOUR_TOKEN" \
  http://159.198.65.38:3004/api/accounts
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

## 🔗 Related Documentation

- [Deployment Guide](../deployment/README.md) - API deployment
- [Testing Results](../testing/README.md) - API test results
- [Mobile Integration](../mobile/MOBILE_APP_INTEGRATION.md) - Mobile API usage

---

**Last Updated:** January 18, 2026
