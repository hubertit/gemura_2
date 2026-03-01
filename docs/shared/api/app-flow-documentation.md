# Gemura API - App Flow Documentation

This document describes the user flows for each module in the Gemura mobile application.

**Base URL:** http://159.198.65.38:3004/api

---

## 1. Authentication Flow

### Login
1. User enters phone number or email (`identifier`) and password
2. App calls `POST /api/auth/login`
3. Server validates credentials and returns:
   - User data (id, name, email, phone, account_type)
   - Authentication token
   - List of accounts user has access to
   - Default account information
   - Profile completion percentage
4. App stores token securely
5. App displays account selection screen if multiple accounts available

### Account Switching
1. User selects account from list
2. App calls `POST /api/accounts/switch` with `account_id`
3. Server updates user's `default_account_id`
4. All subsequent API calls are scoped to the selected account
5. App refreshes data for new account context

---

## 2. Collections Flow

### Record Milk Collection
1. User navigates to Collections screen
2. User selects supplier (from list or search)
3. User enters:
   - Quantity (liters)
   - Collection date/time
   - Notes (optional)
4. App calls `POST /api/collections`
5. Server:
   - Creates MilkSale record
   - Updates supplier ledger
   - Calculates total amount
6. App displays success message and collection details
7. App refreshes collections list

### View Collection
1. User taps on collection from list
2. App calls `GET /api/collections/:id`
3. Server returns collection details with supplier/customer info
4. App displays collection details screen

### Update Collection
1. User opens collection details
2. User taps "Edit"
3. User modifies fields (quantity, date, notes)
4. App calls `PUT /api/collections/update`
5. Server validates and updates MilkSale record
6. App displays success message

### Cancel Collection
1. User opens collection details
2. User taps "Cancel"
3. App confirms cancellation
4. App calls `POST /api/collections/cancel`
5. Server marks MilkSale as cancelled
6. App removes from active list

---

## 3. Sales Flow

### View Sales
1. User navigates to Sales screen
2. App calls `GET /api/sales` with optional filters:
   - Date range
   - Supplier filter
   - Status filter
3. Server returns list of milk sales
4. App displays sales list with:
   - Supplier name
   - Quantity
   - Amount
   - Date
   - Status

### Create Sale
1. User taps "New Sale"
2. User selects supplier and customer
3. User enters quantity and price
4. App calls `POST /api/sales`
5. Server creates MilkSale record
6. App displays success and refreshes list

---

## 4. Suppliers Flow

### View Suppliers
1. User navigates to Suppliers screen
2. App calls `GET /api/suppliers`
3. Server returns all suppliers for current account
4. App displays supplier list with:
   - Supplier code
   - Supplier name
   - Relationship status
   - Price per liter

### Add Supplier
1. User taps "Add Supplier"
2. User enters:
   - Supplier account code
   - Price per liter (optional)
   - Notes (optional)
3. App calls `POST /api/suppliers`
4. Server creates SupplierCustomer relationship
5. App displays success and refreshes list

### View Supplier Details
1. User taps on supplier
2. App calls `GET /api/suppliers/:code`
3. Server returns supplier details with:
   - Account information
   - Relationship details
   - Price per liter
   - Collection history summary
4. App displays supplier details screen

### Update Supplier
1. User opens supplier details
2. User taps "Edit"
3. User modifies price per liter or notes
4. App calls `PUT /api/suppliers/update`
5. Server validates and updates relationship
6. App displays success message

### Remove Supplier
1. User opens supplier details
2. User taps "Remove"
3. App confirms removal
4. App calls `DELETE /api/suppliers/:code`
5. Server marks relationship as inactive
6. App removes from active list

---

## 5. Customers Flow

### View Customers
1. User navigates to Customers screen
2. App calls `GET /api/customers` (if endpoint exists) or uses suppliers endpoint with filter
3. Server returns all customers for current account
4. App displays customer list

### Add Customer
1. User taps "Add Customer"
2. User enters customer account code
3. App calls `POST /api/customers`
4. Server creates SupplierCustomer relationship
5. App displays success

### View/Update/Delete Customer
Similar flow to Suppliers, using customer endpoints

---

## 6. Market Flow

### Products

#### Browse Products
1. User navigates to Market > Products
2. App calls `GET /api/market/products`
3. Server returns all active products
4. App displays product grid/list with:
   - Product image
   - Product name
   - Price
   - Categories

#### View Product Details
1. User taps on product
2. App calls `GET /api/market/products/:id`
3. Server returns product with:
   - Full description
   - All images
   - Categories
   - Stock quantity
4. App displays product details screen

#### Search Products
1. User enters search query
2. App calls `GET /api/market/products/search?q=query`
3. Server returns matching products
4. App displays search results

#### Featured/Recent Products
1. App calls `GET /api/market/products/featured` or `/recent`
2. Server returns top products
3. App displays in carousel or section

### Categories

#### Browse Categories
1. User navigates to Market > Categories
2. App calls `GET /api/market/categories`
3. Server returns all categories
4. App displays category list

#### View Category Products
1. User taps on category
2. App calls `GET /api/market/categories/:id`
3. Server returns category with products
4. App displays products in category

### Orders

#### Create Order
1. User browses products and adds to cart
2. User proceeds to checkout
3. User enters shipping address (optional)
4. App calls `POST /api/market/orders` with:
   - Items (product_id, quantity, price)
   - Customer/seller info
   - Shipping address
5. Server:
   - Calculates total
   - Creates Order and OrderItem records
6. App displays order confirmation

#### View Orders
1. User navigates to Orders screen
2. App calls `GET /api/market/orders`
3. Server returns user's orders
4. App displays order list with status

#### Track Order
1. User taps on order
2. App calls `GET /api/market/orders/:id`
3. Server returns order with items and status
4. App displays order tracking screen

#### Cancel Order
1. User opens order details
2. User taps "Cancel Order"
3. App calls `POST /api/market/orders/customers/cancel-order`
4. Server marks order as cancelled
5. App updates order status

---

## 7. Accounting Flow

### Chart of Accounts

#### View Accounts
1. User navigates to Accounting > Chart of Accounts
2. App calls `GET /api/accounting/chart-of-accounts`
3. Server returns all accounts organized by type
4. App displays hierarchical account tree

#### Add Account
1. User taps "Add Account"
2. User enters:
   - Account code
   - Account name
   - Account type (Asset, Liability, Equity, Revenue, Expense)
   - Parent account (optional)
3. App calls `POST /api/accounting/chart-of-accounts`
4. Server creates account
5. App refreshes account list

### Journal Entries

#### Create Journal Entry
1. User navigates to Accounting > Journal Entries
2. User taps "New Entry"
3. User enters:
   - Transaction date
   - Reference number (optional)
   - Description
   - Entries (account, debit, credit)
4. App validates debits = credits
5. App calls `POST /api/accounting/journal-entries`
6. Server creates transaction and entries
7. App displays success

#### View Journal Entries
1. App calls `GET /api/accounting/journal-entries` with optional date filters
2. Server returns transactions with entries
3. App displays journal entries list

### Supplier Ledger

#### View Supplier Ledger
1. User navigates to supplier details
2. User taps "View Ledger"
3. App calls `GET /api/accounting/supplier-ledger/:supplier_account_id`
4. Server returns all ledger entries
5. App displays ledger with:
   - Entry type (debit/credit)
   - Amount
   - Balance
   - Description
   - Date

### Fees & Deductions

#### Manage Fee Types
1. User navigates to Accounting > Fees
2. App calls `GET /api/accounting/fees/fee-types`
3. User can create new fee types via `POST /api/accounting/fees/fee-types`

#### Set Fee Rules
1. User selects supplier
2. User creates fee rule via `POST /api/accounting/fees/fee-rules`
3. User specifies:
   - Fee type
   - Calculation method (fixed or percentage)
   - Min/max amounts
   - Effective dates

#### Apply Deductions
1. User navigates to supplier or milk sale
2. User creates deduction via `POST /api/accounting/fees/deductions`
3. System links deduction to milk sale if applicable

### Invoices

#### Create Invoice
1. User navigates to Accounting > Invoices
2. User taps "New Invoice"
3. User enters:
   - Invoice number
   - Supplier
   - Issue date
   - Due date
   - Items (description, quantity, unit price)
4. App calculates total
5. App calls `POST /api/accounting/invoices`
6. Server creates invoice
7. App displays invoice preview

#### View Invoices
1. App calls `GET /api/accounting/invoices`
2. Server returns all invoices
3. App displays invoice list with status

### Receipts

#### Record Receipt
1. User navigates to Accounting > Receipts
2. User taps "New Receipt"
3. User enters:
   - Receipt number
   - Supplier/Customer
   - Payment date
   - Amount
   - Payment method
4. App calls `POST /api/accounting/receipts`
5. Server creates receipt
6. App displays confirmation

### Reports

#### Generate Balance Sheet
1. User navigates to Accounting > Reports
2. User selects "Balance Sheet"
3. User enters "As of" date (optional)
4. App calls `GET /api/accounting/reports/balance-sheet?as_of_date=date`
5. Server calculates and returns financial statement
6. App displays balance sheet

#### Generate Income Statement
1. User selects "Income Statement"
2. User enters date range
3. App calls `GET /api/accounting/reports/income-statement?from_date=X&to_date=Y`
4. Server calculates revenue and expenses
5. App displays income statement

#### Generate Trial Balance
1. User selects "Trial Balance"
2. User enters "As of" date
3. App calls `GET /api/accounting/reports/trial-balance?as_of_date=date`
4. Server calculates account balances
5. App displays trial balance

---

## 8. Payroll Flow

### Setup Suppliers for Payroll

#### Add Supplier to Payroll
1. User navigates to Payroll > Suppliers
2. User taps "Add Supplier"
3. User selects supplier account
4. User sets payment terms (default 15 days, but flexible)
5. App calls `POST /api/payroll/suppliers`
6. Server creates PayrollSupplier record
7. App displays success

#### View Payroll Suppliers
1. App calls `GET /api/payroll/suppliers`
2. Server returns all active suppliers with payment terms
3. App displays supplier list

### Create Payroll Period (Optional)

1. User navigates to Payroll > Periods
2. User taps "New Period"
3. User enters:
   - Period name (e.g., "January 2025")
   - Start date
   - End date
4. App calls `POST /api/payroll/periods`
5. Server creates period
6. App displays period in list

### Generate Payroll Run

#### Create Run
1. User navigates to Payroll > Runs
2. User taps "New Payroll Run"
3. User can optionally:
   - Select period (or leave blank for flexible)
   - Set custom date range (period_start, period_end)
   - Set payment terms (default 15 days)
4. App calls `POST /api/payroll/runs`
5. Server creates PayrollRun in "draft" status
6. App displays run details

#### Process Payroll
1. User opens payroll run
2. User taps "Process Payroll"
3. App calls `POST /api/payroll/runs/:id/process`
4. Server:
   - Finds all suppliers in payroll system
   - For each supplier:
     - Gets unpaid milk sales within date range
     - Calculates gross amount (quantity × price)
     - Applies deductions (fees)
     - Calculates net amount
     - Creates payslip
   - Updates run status to "completed"
5. App displays processing summary:
   - Number of suppliers processed
   - Total payroll amount
   - List of payslips created

### View Payslips

1. User navigates to Payroll > Runs
2. User taps on completed run
3. App displays payslips list with:
   - Supplier name
   - Gross amount
   - Deductions
   - Net amount
   - Milk sales count
   - Period dates

### Payroll Reports

1. User navigates to Payroll > Reports
2. App calls `GET /api/payroll/reports`
3. Server aggregates all runs and returns:
   - Total runs
   - Total payroll amount
   - Total suppliers
   - Detailed breakdown by run
4. App displays comprehensive payroll report

---

## 9. Analytics Flow

### View Collection Analytics
1. User navigates to Analytics
2. App calls `GET /api/analytics/collections`
3. Server analyzes collection data
4. App displays:
   - Collection trends
   - Volume charts
   - Supplier performance

### View Customer Analytics
1. User selects "Customer Analytics"
2. App calls `GET /api/analytics/customers`
3. Server analyzes customer data
4. App displays customer insights

### View Metrics
1. App calls `GET /api/analytics/metrics`
2. Server returns key metrics
3. App displays dashboard with:
   - Collections count
   - Customers count
   - Suppliers count
   - Sales count

---

## 10. Stats Flow

### View Overview
1. User navigates to Dashboard
2. App calls `POST /api/stats/overview`
3. Server calculates summary statistics
4. App displays:
   - Collections count
   - Sales count
   - Customers count
   - Suppliers count
   - Total wallet balance

### View Detailed Stats
1. User navigates to Stats screen
2. App calls `POST /api/stats`
3. Server returns comprehensive statistics
4. App displays detailed stats with charts

---

## 11. Reports Flow

### Generate Custom Report
1. User navigates to Reports
2. User selects report type
3. User sets filters (date range, accounts, etc.)
4. App calls `POST /api/reports/my-report` with filters
5. Server generates report
6. App displays report data
7. User can export/share report

---

## 12. KYC Flow

### Upload KYC Photo
1. User navigates to Profile > KYC
2. User selects photo type (ID, selfie, etc.)
3. User uploads photo
4. App calls `POST /api/kyc/upload-photo` with:
   - Photo file
   - Photo type
5. Server stores photo and updates KYC status
6. App displays confirmation

---

## 13. Notifications Flow

### View Notifications
1. User navigates to Notifications
2. App calls `POST /api/notifications/get`
3. Server returns user's notifications
4. App displays notification list

### Mark as Read
1. User taps on notification
2. App calls `PUT /api/notifications/:id` with read status
3. Server updates notification
4. App updates UI

### Delete Notification
1. User swipes to delete
2. App calls `DELETE /api/notifications/:id`
3. Server removes notification
4. App removes from list

---

## 14. Employees Flow

### Add Employee
1. User navigates to Settings > Employees
2. User taps "Add Employee"
3. User enters:
   - User account
   - Permissions (JSON or structured)
4. App calls `POST /api/employees`
5. Server creates employee record
6. App displays success

### Manage Employee Access
1. User taps on employee
2. User modifies permissions
3. App calls `PUT /api/employees/:id/access`
4. Server updates permissions
5. App displays success

---

## Common Patterns

### Error Handling
- All endpoints return consistent error format: `{code, status, message}`
- App should check `code` and `status` fields
- Display user-friendly error messages

### Authentication
- Include token in `Authorization: Bearer {token}` header
- Handle 401 errors by redirecting to login
- Refresh token if needed

### Data Refresh
- Refresh lists after create/update/delete operations
- Show loading indicators during API calls
- Cache data when appropriate

### Account Context
- All operations are scoped to user's `default_account_id`
- Switch account when user selects different account
- Refresh all data when account changes

---

## Best Practices

1. **Always validate input** before sending to API
2. **Show loading states** during API calls
3. **Handle errors gracefully** with user-friendly messages
4. **Cache data** when possible to reduce API calls
5. **Refresh data** after mutations (create/update/delete)
6. **Use pagination** for large lists
7. **Implement pull-to-refresh** for lists
8. **Show confirmation dialogs** for destructive actions
9. **Validate forms** before submission
10. **Store authentication token securely**

---

**Last Updated:** 2026-01-04  
**API Version:** 2.0.0

