# Mobile App Integration Guide

**Date:** 2026-01-04  
**Status:** Ready to Start ✅

## ✅ API Status

**All API endpoints are ready:**
- ✅ 110+ endpoints implemented
- ✅ API deployed and running: http://159.198.65.38:3004/api
- ✅ Swagger docs available: http://159.198.65.38:3004/api/docs
- ✅ Authentication working
- ✅ All modules functional

**Migration Status:**
- 🚧 Data migration running in background (doesn't affect API)
- ✅ API is fully functional with existing data
- ✅ Can test with migrated data as it becomes available

---

## 📱 Mobile App Integration Steps

### 1. **Update API Base URL** (15-30 min)
- Find API configuration file (usually `lib/config/api_config.dart` or similar)
- Update base URL to: `http://159.198.65.38:3004/api`
- Test connection

### 2. **Update Authentication** (1-2 hours)
- Review current auth implementation
- Update to use new login endpoint: `POST /api/auth/login`
- Handle new response format (includes accounts, token, profile completion)
- Update token storage/management
- Test login flow

### 3. **Update Account Switching** (1-2 hours)
- Implement account switching: `POST /api/accounts/switch`
- Update UI to show multiple accounts
- Handle account context in all API calls
- Test account switching

### 4. **Update API Calls** (4-8 hours)
- Review all API endpoints used in app
- Update to new endpoint paths
- Update request/response models
- Handle new error formats
- Test each module:
  - Collections
  - Sales
  - Suppliers
  - Customers
  - Wallets
  - Profile
  - etc.

### 5. **Test All Features** (2-4 hours)
- Test complete user flows
- Test with real data
- Fix any compatibility issues
- Verify data sync

### 6. **Handle New Features** (Optional, 2-4 hours)
- Feed module (if used)
- Market module (if used)
- Accounting/Payroll (if used)
- API Keys (if used)

---

## 🔧 Key Changes from V1 to V2

### Authentication
**V1:** Simple token-based  
**V2:** 
- Returns user data, accounts list, default account
- Token in `data.user.token`
- Profile completion percentage
- Account switching support

### Response Format
**V1:** May vary  
**V2:** Consistent format:
```json
{
  "code": 200,
  "status": "success",
  "message": "...",
  "data": { ... }
}
```

### Error Format
**V2:**
```json
{
  "code": 400,
  "status": "error",
  "message": "Error description"
}
```

### Account Context
- All operations scoped to current account
- Use `default_account_id` from login response
- Switch accounts with `POST /api/accounts/switch`

---

## 📋 Checklist

### Phase 1: Basic Integration (4-6 hours)
- [ ] Update API base URL
- [ ] Update authentication
- [ ] Test login/logout
- [ ] Update account switching
- [ ] Test with real credentials

### Phase 2: Core Features (6-10 hours)
- [ ] Update Collections API calls
- [ ] Update Sales API calls
- [ ] Update Suppliers API calls
- [ ] Update Customers API calls
- [ ] Update Wallets API calls
- [ ] Update Profile API calls

### Phase 3: Additional Features (4-8 hours)
- [ ] Update Notifications
- [ ] Update KYC (if used)
- [ ] Update Analytics/Stats
- [ ] Update Reports
- [ ] Update Market (if used)
- [ ] Update Feed (if used)

### Phase 4: Testing & Polish (2-4 hours)
- [ ] End-to-end testing
- [ ] Error handling
- [ ] Loading states
- [ ] Offline handling (if applicable)
- [ ] Performance optimization

---

## 🧪 Testing

### Test Credentials
- Phone: `250788606765`
- Password: `Pass123`
- Has access to multiple accounts (gahengeri, KOPERATIVE KOZAMGI, Hubert)

### Test Endpoints
```bash
# Login
POST http://159.198.65.38:3004/api/auth/login
{
  "identifier": "250788606765",
  "password": "Pass123"
}

# Get Accounts
GET http://159.198.65.38:3004/api/accounts
Authorization: Bearer {token}

# Switch Account
POST http://159.198.65.38:3004/api/accounts/switch
Authorization: Bearer {token}
{
  "account_id": "{account_uuid}"
}
```

---

## 📚 API Documentation

**Swagger UI:** http://159.198.65.38:3004/api/docs

All endpoints are documented with:
- Request/response schemas
- Examples
- Error codes
- Authentication requirements

---

## 🚀 Ready to Start!

**The API is 100% ready** - you can start mobile app integration immediately!

The data migration running in the background doesn't affect the API - it's just moving data. The API works with both existing and newly migrated data.

---

## 💡 Tips

1. **Start with Authentication** - Get login working first
2. **Test Incrementally** - Update one module at a time
3. **Use Swagger** - Reference API docs for exact formats
4. **Handle Errors** - New error format is consistent
5. **Account Context** - Remember all operations are account-scoped

---

**Ready to integrate! The API is waiting! 🎉**

