# 📋 Remaining Endpoints to Implement

**Last Updated**: January 20, 2026  
**Status**: Core Modules Complete ✅ | Endpoints: 28+/80+ (35%+)

---

## ✅ **COMPLETED ENDPOINTS** (28+ endpoints)

### Authentication Module ✅ **COMPLETE** (6/6)
- ✅ `POST /api/auth/login` - User login
- ✅ `POST /api/auth/register` - User registration
- ✅ `POST /api/auth/verify` - Token verification
- ✅ `POST /api/auth/forgot-password` - Password reset request
- ✅ `POST /api/auth/reset-password` - Password reset
- ✅ `GET /api/auth/token` - Token validation (legacy compatibility)

### Accounts Module ✅ **COMPLETE** (3/3)
- ✅ `GET /api/accounts` - Get user accounts
- ✅ `GET /api/accounts/list` - List user accounts
- ✅ `POST /api/accounts/switch` - Switch account

### Profile Module ✅ **COMPLETE** (2/2)
- ✅ `GET /api/profile/get` - Get user profile
- ✅ `PUT /api/profile/update` - Update user profile

### Wallets Module ✅ **COMPLETE** (1/1)
- ✅ `GET /api/wallets/get` - Get wallets

### Sales Module ✅ **COMPLETE** (4/4)
- ✅ `POST /api/sales` - Create new sale
- ✅ `POST /api/sales/sales` - Get sales list
- ✅ `PUT /api/sales/update` - Update sale
- ✅ `POST /api/sales/cancel` - Cancel sale

### Collections Module ✅ **COMPLETE** (11/11)
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

### Suppliers Module ✅ **COMPLETE** (6/6)
- ✅ `POST /api/suppliers/create` - Create supplier
- ✅ `POST /api/suppliers/get` - Get suppliers list
- ✅ `GET /api/suppliers/by-id/:id` - Get supplier by ID (UUID)
- ✅ `GET /api/suppliers/:code` - Get supplier by code
- ✅ `PUT /api/suppliers/update` - Update supplier
- ✅ `DELETE /api/suppliers/:code` - Delete supplier (soft delete)

---

## ❌ **MISSING MODULES** (0 endpoints implemented)

### Customers Module ✅ **COMPLETE** (6/6)
- ✅ `POST /api/customers` - Create customer
- ✅ `POST /api/customers/get` - Get customers list
- ✅ `GET /api/customers/by-id/:id` - Get customer by ID (UUID)
- ✅ `GET /api/customers/:code` - Get customer by code
- ✅ `PUT /api/customers/update` - Update customer
- ✅ `DELETE /api/customers/:code` - Delete customer (soft delete)

### KYC Module ❌ **NOT STARTED** (0/1)
- ❌ `POST /api/kyc/upload-photo` - Upload KYC documents

### Notifications Module ❌ **NOT STARTED** (0/4)
- ❌ `POST /api/notifications` - Create notification
- ❌ `POST /api/notifications/get` - Get notifications
- ❌ `PUT /api/notifications/:id` - Update notification
- ❌ `DELETE /api/notifications/:id` - Delete notification

### Market Module ❌ **NOT STARTED** (0/26)
**Products** (8 endpoints):
- ❌ `POST /api/market/products` - Create product
- ❌ `GET /api/market/products` - List products
- ❌ `GET /api/market/products/:id` - Get product
- ❌ `PUT /api/market/products/:id` - Update product
- ❌ `DELETE /api/market/products/:id` - Delete product
- ❌ `GET /api/market/products/search` - Search products
- ❌ `GET /api/market/products/featured` - Get featured products
- ❌ `GET /api/market/products/recent` - Get recent products

**Categories** (5 endpoints):
- ❌ `POST /api/market/categories` - Create category
- ❌ `GET /api/market/categories` - List categories
- ❌ `GET /api/market/categories/:id` - Get category
- ❌ `PUT /api/market/categories/:id` - Update category
- ❌ `DELETE /api/market/categories/:id` - Delete category

**Orders** (13 endpoints):
- ❌ `POST /api/market/orders` - Create order
- ❌ `GET /api/market/orders` - List orders
- ❌ `GET /api/market/orders/:id` - Get order
- ❌ `PUT /api/market/orders/:id/status` - Update order status
- ❌ `GET /api/market/orders/admin/list` - Admin order list
- ❌ `GET /api/market/orders/admin/:id` - Admin order details
- ❌ `GET /api/market/orders/customers/my-orders` - Customer orders
- ❌ `GET /api/market/orders/customers/my-order-details` - Customer order details
- ❌ `POST /api/market/orders/customers/place-order` - Place order
- ❌ `POST /api/market/orders/customers/cancel-order` - Cancel order
- ❌ `GET /api/market/orders/sellers/orders` - Seller orders
- ❌ `GET /api/market/orders/sellers/order-details` - Seller order details
- ❌ `POST /api/market/orders/sellers/update-status` - Update order status

### Analytics Module ❌ **NOT STARTED** (0/3)
- ❌ `GET /api/analytics/collections` - Collection analytics
- ❌ `GET /api/analytics/customers` - Customer analytics
- ❌ `GET /api/analytics/metrics` - General metrics

### Stats Module ❌ **NOT STARTED** (0/2)
- ❌ `POST /api/stats/overview` - Overview stats
- ❌ `POST /api/stats` - General stats

### Reports Module ❌ **NOT STARTED** (0/1)
- ❌ `POST /api/reports/my-report` - User reports

### Employees Module ❌ **NOT STARTED** (0/4)
- ❌ `POST /api/employees` - Create employee
- ❌ `GET /api/employees` - Get employees
- ❌ `PUT /api/employees/:id/access` - Update access
- ❌ `DELETE /api/employees/:id` - Delete employee

### API Keys Module ❌ **NOT STARTED** (0/1)
- ❌ `POST /api/api-keys` - Get API keys

### Feed Module ❌ **NOT STARTED** (0/~15+)
**Posts**:
- ❌ `POST /api/feed/posts` - Create post
- ❌ `GET /api/feed/posts` - List posts
- ❌ `GET /api/feed/posts/:id` - Get post
- ❌ `PUT /api/feed/posts/:id` - Update post
- ❌ `DELETE /api/feed/posts/:id` - Delete post

**Stories**:
- ❌ `POST /api/feed/stories` - Create story
- ❌ `GET /api/feed/stories` - List stories
- ❌ `GET /api/feed/stories/:id` - Get story

**Comments**:
- ❌ `POST /api/feed/comments` - Create comment
- ❌ `GET /api/feed/comments` - List comments
- ❌ `PUT /api/feed/comments/:id` - Update comment
- ❌ `DELETE /api/feed/comments/:id` - Delete comment

**Interactions**:
- ❌ `POST /api/feed/interactions` - Like/share/bookmark
- ❌ `GET /api/feed/interactions` - Get interactions

### Accounting Module ❌ **NOT STARTED** (0/~15-20)
- ❌ Chart of Accounts CRUD (4 endpoints)
- ❌ Journal Entries (3 endpoints)
- ❌ Financial Reports (3 endpoints)
- ❌ Supplier Ledger management
- ❌ Fee/Deduction management
- ❌ Invoices & Receipts

### Payroll Module ❌ **NOT STARTED** (0/~11)
- ❌ Employee management (4 endpoints)
- ❌ Payroll periods (2 endpoints)
- ❌ Payroll entries (3 endpoints)
- ❌ Process payroll (1 endpoint)
- ❌ Reports (1 endpoint)

---

## 📊 **SUMMARY**

### By Priority

#### 🔴 **PRIORITY 1: Critical for Mobile App** (11 endpoints)
1. **Complete Sales Module** (1 endpoint)
   - ❌ `POST /api/sales` - Create sale

2. **Complete Collections Module** (3 endpoints)
   - ❌ `GET /api/collections/:id`
   - ❌ `PUT /api/collections/:id`
   - ❌ `POST /api/collections/:id/cancel`

3. **Complete Suppliers Module** (3 endpoints)
   - ❌ `GET /api/suppliers/:id`
   - ❌ `PUT /api/suppliers/:id`
   - ❌ `DELETE /api/suppliers/:id`

4. **Customers Module** (4 endpoints)
   - ❌ Full CRUD operations

**Total**: 11 endpoints | **Estimated Time**: 12-15 hours

---

#### 🟡 **PRIORITY 2: Important Features** (8 endpoints)
1. **KYC Module** (1 endpoint)
   - ❌ `POST /api/kyc/upload-photo`

2. **Notifications Module** (4 endpoints)
   - ❌ Full CRUD operations

3. **Employees Module** (4 endpoints)
   - ❌ Full CRUD operations

**Total**: 9 endpoints | **Estimated Time**: 10-13 hours

---

#### 🟢 **PRIORITY 3: Market & E-commerce** (26 endpoints)
- **Market Module** (26 endpoints)
  - Products (8), Categories (5), Orders (13)

**Total**: 26 endpoints | **Estimated Time**: 12-16 hours

---

#### 🔵 **PRIORITY 4: Analytics & Reporting** (6 endpoints)
- Analytics (3), Stats (2), Reports (1)

**Total**: 6 endpoints | **Estimated Time**: 8-12 hours

---

#### 🆕 **PRIORITY 5: New Modules** (~30 endpoints)
- Accounting (~15-20 endpoints)
- Payroll (~11 endpoints)

**Total**: ~30 endpoints | **Estimated Time**: 35-45 hours

---

#### 🔵 **PRIORITY 6: Feed Module** (~15 endpoints)
- Social feed features

**Total**: ~15 endpoints | **Estimated Time**: 10-12 hours

---

## 📈 **PROGRESS STATISTICS**

- **Completed**: 17 endpoints (21%)
- **Remaining**: ~65+ endpoints (79%)
- **Critical (Priority 1)**: 11 endpoints
- **Important (Priority 2)**: 9 endpoints
- **Market (Priority 3)**: 26 endpoints
- **Analytics (Priority 4)**: 6 endpoints
- **New Modules (Priority 5)**: ~30 endpoints
- **Feed (Priority 6)**: ~15 endpoints

---

## 🎯 **RECOMMENDED NEXT STEPS**

### Immediate (Week 1): Complete Core Functionality
1. ✅ Complete Sales Module (1 endpoint) - **1-2 hours**
2. ✅ Complete Collections Module (3 endpoints) - **3-4 hours**
3. ✅ Complete Suppliers Module (3 endpoints) - **3-4 hours**
4. ✅ Complete Customers Module (4 endpoints) - **4-5 hours**

**Total**: 11 endpoints | **Time**: 11-15 hours

### Short-term (Week 2): Important Features
1. ✅ KYC Module (1 endpoint) - **2-3 hours**
2. ✅ Notifications Module (4 endpoints) - **4-5 hours**
3. ✅ Employees Module (4 endpoints) - **4-5 hours**

**Total**: 9 endpoints | **Time**: 10-13 hours

### Medium-term (Week 3-4): Market & Analytics
1. ✅ Market Module (26 endpoints) - **12-16 hours**
2. ✅ Analytics/Stats/Reports (6 endpoints) - **8-12 hours**

**Total**: 32 endpoints | **Time**: 20-28 hours

---

## 💡 **QUICK REFERENCE**

### To implement a new endpoint:
1. Create/update controller in `backend/src/modules/[module]/[module].controller.ts`
2. Create/update service in `backend/src/modules/[module]/[module].service.ts`
3. Create DTOs in `backend/src/modules/[module]/dto/`
4. Add Swagger documentation
5. Test in Swagger UI: http://159.198.65.38:3004/api/docs
6. Deploy: `./scripts/deployment/deploy-to-server.sh`

---

**Current Status**: 28+/80+ endpoints (35%+) ✅  
**Next Milestone**: Complete Priority 2 modules (KYC, Notifications, Employees)

