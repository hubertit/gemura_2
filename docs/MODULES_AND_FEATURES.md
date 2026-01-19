# Gemura 2.0 - Complete Modules and Features Inventory

## Backend Modules (NestJS)

### ✅ **ACTIVELY USED** (Connected to Mobile App)

1. **Auth Module** (`/auth`)
   - Login, logout, registration
   - Password reset, token verification
   - **Status**: ✅ Used by mobile app

2. **Accounts Module** (`/accounts`)
   - Switch default account
   - **Status**: ✅ Used by mobile app

3. **Profile Module** (`/profile`)
   - Get user profile
   - Update profile
   - **Status**: ✅ Used by mobile app

4. **Suppliers Module** (`/suppliers`)
   - Create/update/delete suppliers
   - Get supplier list and details
   - Manage supplier relationships with price_per_liter
   - **Status**: ✅ Used by mobile app

5. **Customers Module** (`/customers`)
   - Create/update/delete customers
   - Get customer list and details
   - Manage customer relationships with price_per_liter
   - **Status**: ✅ Used by mobile app

6. **Collections Module** (`/collections`)
   - Create/update/cancel collections
   - Get collection details
   - Milk rejection reasons CRUD
   - **Status**: ✅ Used by mobile app

7. **Sales Module** (`/sales`)
   - Create/update/cancel sales
   - Get sales list with filters
   - **Status**: ✅ Used by mobile app

8. **Wallets Module** (`/wallets`)
   - Create wallets
   - Get wallet list and details
   - **Status**: ✅ Used by mobile app

9. **Finance/Accounting Module** (`/accounting`)
   - **Transactions** (`/accounting/transactions`)
     - Create revenue/expense transactions
     - Get transactions with filters
     - **Status**: ✅ Used by mobile app
   - **Reports** (`/accounting/reports`)
     - Income statement (revenue vs expenses)
     - **Status**: ✅ Used by mobile app

10. **Feed Module** (`/feed`)
    - Posts (create, update, delete, like, bookmark)
    - Comments (create, update, delete)
    - Interactions (like, share)
    - Stories
    - Follow/unfollow users
    - **Status**: ✅ Used by mobile app

11. **Notifications Module** (`/notifications`)
    - Get notifications
    - Create/update/delete notifications
    - Mark as read/unread
    - **Status**: ✅ Used by mobile app

12. **Stats Module** (`/stats`)
    - Overview statistics
    - **Status**: ✅ Used by mobile app

13. **Employees Module** (`/employees`)
    - Register employees
    - Get account employees
    - Grant/revoke access
    - **Status**: ✅ Used by mobile app

14. **KYC Module** (`/kyc`)
    - Upload KYC photos (ID front/back, selfie)
    - Get KYC status
    - **Status**: ✅ Used by mobile app

15. **API Keys Module** (`/api-keys`)
    - Get API keys (for OpenAI integration)
    - **Status**: ✅ Used by mobile app (for chat/AI features)

16. **Media Module** (`/media`)
    - Media proxy for external images
    - **Status**: ✅ Used by mobile app

17. **Referrals Module** (`/referrals`)
    - Get referral code
    - Get referral stats
    - Use referral code
    - **Status**: ✅ Used by mobile app

18. **Points Module** (`/points`)
    - Points balance
    - **Status**: ✅ Used by mobile app (via referrals feature)

19. **Onboard Module** (`/onboard`)
    - Create user (onboarding)
    - **Status**: ✅ Used by mobile app (via referrals feature)

20. **Market Module** (`/market`)
    - Products (get all, featured, recent)
    - Categories (get all)
    - **Status**: ✅ Used by mobile app
    - **Note**: Uses direct HTTP calls (not AuthenticatedDioService), may need authentication

21. **Reports Module** (`/reports`)
    - Agent reports (`/reports/my-report`)
    - **Status**: ✅ Used by mobile app

### ⚠️ **PARTIALLY USED / BACKEND ONLY** (2 modules)

22. **Payroll Module** (`/payroll`)

    - Payroll runs
    - Payroll suppliers
    - Payroll periods
    - Payroll reports
    - **Status**: ❌ Not used by mobile app (backend only)

23. **Analytics Module** (`/analytics`)
    - Analytics endpoints
    - **Status**: ❌ Not used by mobile app

---

## Mobile App Features

### ✅ **CONNECTED TO BACKEND APIs** (14 features)

1. **Authentication** (`auth/`)
   - Login, register, forgot password, reset password
   - Splash screen, lock screen
   - **Backend**: `/auth/*`

2. **Home/Dashboard** (`home/`)
   - Overview statistics
   - Financial metrics
   - User accounts management
   - Settings, profile editing
   - Notifications
   - **Backend**: `/stats/overview`, `/profile/*`, `/accounts/*`, `/notifications/*`

3. **Finance** (`finance/`)
   - Income statement (revenue vs expenses chart)
   - Record transactions (revenue/expense)
   - View transactions list
   - **Backend**: `/accounting/reports/income-statement`, `/accounting/transactions`

4. **Collections** (`collection/`)
   - Record milk collection
   - View pending collections
   - Approve/reject collections with reasons
   - **Backend**: `/collections/*`, `/collections/rejection-reasons`

5. **Sales** (`sales/`)
   - Record milk sales
   - **Backend**: `/sales/*`

6. **Suppliers** (`suppliers/`)
   - Add/edit suppliers
   - View supplier list and details
   - View collected milk history
   - **Backend**: `/suppliers/*`

7. **Customers** (`customers/`)
   - Add/edit customers
   - View customer list and details
   - View sold milk history
   - **Backend**: `/customers/*`

8. **Wallets** (`wallets/`)
   - View wallets
   - Create wallets
   - **Backend**: `/wallets/*`

9. **Feed** (`feed/`)
   - View posts feed
   - Create/edit/delete posts
   - Like, comment, bookmark
   - View liked posts, bookmarks
   - **Backend**: `/feed/*`

10. **Chat** (`chat/`)
    - Chat list
    - Bot chat (AI-powered)
    - Contact selection
    - **Backend**: Uses API keys for OpenAI integration

11. **Notifications** (`home/notifications_screen.dart`)
    - View notifications
    - Mark as read
    - **Backend**: `/notifications/*`

12. **KYC** (`kyc/`)
    - Upload ID photos
    - Upload selfie
    - View KYC status
    - **Backend**: `/kyc/*`

13. **Employees/Account Access** (`account_access/`)
    - Register employees
    - Manage account access
    - **Backend**: `/employees/*`

14. **Referrals** (`referrals/`)
    - View referral code
    - View referral stats
    - Onboard users with referral code
    - Points balance
    - **Backend**: `/referrals/*`, `/points/balance`, `/onboard/create-user`

15. **Market** (`market/`)
    - View products (all, featured, recent)
    - Product details
    - Categories
    - Search products
    - Top sellers (hardcoded)
    - **Backend**: `/market/products/*`, `/market/categories/*`

16. **Agent Reports** (`agent_reports/`)
    - Agent report screen
    - **Backend**: `/reports/my-report`

### 🎨 **HARDCODED/MOCK DATA** (No Backend API) (3 features)

17. **Loans** (`loans/`)
    - View loans (cash, device, float, product types)
    - Create loan application
    - Loan details and payment
    - Repayment history
    - **Status**: 🎨 **Hardcoded mock data** - No backend API
    - **Files**: `loans_provider.dart` has `_loadMockData()`

18. **Savings** (`savings/`)
    - View savings goals
    - Create savings goals
    - Add contributions
    - Savings statistics
    - **Status**: 🎨 **Hardcoded mock data** - No backend API
    - **Files**: `savings_provider.dart` has `_loadMockData()`

19. **Insurance** (`insurance/`)
    - View insurance policies
    - Purchase insurance
    - View claims
    - Insurance providers list
    - **Status**: 🎨 **Hardcoded mock data** - No backend API
    - **Files**: `insurance_provider.dart` has `_loadMockData()`

20. **Merchant** (`merchant/`)
    - Merchant dashboard
    - Wallets screen
    - Transactions screen
    - Profile screen
    - **Status**: 🎨 **Partially implemented** - Uses wallets API but has separate UI

21. **Invite** (`invite/`)
    - Invite people screen
    - Contact list widget
    - **Status**: ⚠️ **May use referrals API or hardcoded**

---

## Database Tables

### ✅ **ACTIVELY USED**

**Core Tables:**
- `users` - User accounts
- `accounts` - Business accounts
- `user_accounts` - User-account relationships
- `suppliers_customers` - Supplier-customer relationships (with `price_per_liter`)
- `milk_sales` - Milk collection and sales records
- `wallets` - User wallets
- `notifications` - User notifications

**Feed Tables:**
- `feed_posts` - Social feed posts
- `feed_comments` - Post comments
- `feed_interactions` - Likes, shares, bookmarks
- `feed_stories` - Stories
- `user_relationships` - Follow relationships
- `user_bookmarks` - Bookmarked posts

**Accounting Tables (Internal Use):**
- `chart_of_accounts` - Used internally by transactions service
- `accounting_transactions` - Used internally by transactions service
- `accounting_transaction_entries` - Used internally by transactions service

**Collections:**
- `milk_rejection_reasons` - Rejection reasons for milk collections

**Other:**
- `products` - Market products
- `categories` - Product/feed categories
- `orders` - Market orders
- `order_items` - Order line items
- `password_resets` - Password reset tokens
- `api_keys` - API keys for integrations
- `user_points` - User points/rewards
- `user_referrals` - Referral relationships
- `user_rewards` - User rewards
- `user_onboardings` - Onboarding tracking

**Payroll Tables:**
- `payroll_suppliers` - Suppliers in payroll system
- `payroll_periods` - Payroll periods
- `payroll_runs` - Payroll run executions
- `payroll_payslips` - Generated payslips
- `payroll_deductions` - Payroll deductions

### ❌ **REMOVED** (Not Used)

- `invoices` - Removed (no mobile app usage)
- `invoice_items` - Removed (no mobile app usage)
- `receipts` - Removed (no mobile app usage)
- `supplier_ledger` - Removed (no mobile app usage)
- `fee_types` - Removed (no mobile app usage)
- `supplier_fee_rules` - Removed (no mobile app usage)
- `supplier_deductions` - Removed (no mobile app usage)

---

## Summary

### Backend APIs: 23 modules
- ✅ **21 actively used** by mobile app
- ❌ **2 not used** (payroll, analytics)

### Mobile Features: 21 features
- ✅ **16 connected to backend APIs**
- 🎨 **3 hardcoded** (loans, savings, insurance)
- ⚠️ **2 partially implemented** (merchant, invite)

### Database Tables: ~30+ tables
- ✅ **Most tables actively used**
- ❌ **7 tables removed** (unused accounting features)

---

## Recommendations

1. **Consider removing unused backend modules:**
   - Payroll module (if not planning to use)
   - Analytics module (if not used)

2. **Consider implementing backend for hardcoded features:**
   - Loans API
   - Savings API
   - Insurance API

3. **Verify market module:**
   - Check if market UI actually uses `/market/*` APIs or is hardcoded

4. **Keep:**
   - All actively used modules
   - Chart of accounts (used internally by transactions)
   - Payroll (if planning to use in future)
