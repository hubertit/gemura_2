# Gemura App - User Flow Documentation

## 🎯 Overview
Gemura is a comprehensive dairy management app designed for the entire milk value chain:

- **MCCs (Milk Collection Centers)** → Manage collections, suppliers, and business operations
- **Suppliers** → Track milk deliveries and payments
- **Customers** → Monitor purchases and transactions
- **Collectors (Abacunda)** → Record collections and manage supplier relationships
- **Farmers** → Track milk production and sales

The app helps streamline milk collection, sales, supplier management, customer relationships, and business operations across the dairy industry.

> **⚠️ Beta Version Notice:** This app is currently in beta development. You may encounter bugs or incomplete features as we continue to improve the app. Please report any issues you find so we can make Gemura better for everyone.

## 🔐 Authentication Flow

### Registration
1. **Launch App** → Splash screen with Gemura logo
2. **Tap "Register"** → Navigate to registration screen
3. **Enter Details** → Full name, phone number, email (optional), password
4. **Business Info** → Business name, location, type of dairy operation:
   - **MCC** → Milk Collection Center
   - **Supplier** → Individual milk supplier
   - **Customer** → Milk buyer/processor
   - **Collector** → Field collector (Abacunda)
   - **Farmer** → Individual farmer
5. **Submit Registration** → App validates information
6. **Account Setup** → App automatically creates:
   - **Default Account** → Your main business account
   - **Default Wallet** → For managing payments and transactions
   - **User Profile** → With appropriate role permissions
7. **Success** → Welcome message, navigate to Home Dashboard
8. **Failure** → Show error message, retry registration

### Login
1. **Launch App** → Splash screen with Gemura logo
2. **Enter Credentials** → Phone number + Password
3. **Authenticate** → Server validates credentials
4. **Success** → Navigate to Home Dashboard
5. **Failure** → Show error message, retry

### Account Switching
1. **Profile Tab** → Tap "Switch Account"
2. **Select Account** → Choose from available accounts
3. **Confirm Switch** → App refreshes with new account data
4. **Success** → Show confirmation snackbar

## 🏠 Home Dashboard Flow

### Quick Actions (Role-Based)
**For MCCs & Collectors:**
1. **View Dashboard** → See overview metrics and quick action buttons
2. **Collect Milk** → Tap "Collect" → Navigate to collection screen
3. **Manage Suppliers** → Tap "Suppliers" → Navigate to suppliers list
4. **View Collections** → See recent milk collections

**For Suppliers:**
1. **View Dashboard** → See account overview and basic information
2. **Profile Management** → Update personal and business information
3. **Settings** → Manage app preferences and notifications
4. **Track Deliveries** → View milk delivery records *(Coming Soon)*
5. **Check Payments** → Monitor payment status *(Coming Soon)*
6. **View Schedule** → See collection schedules *(Coming Soon)*

**For Customers:**
1. **View Dashboard** → See account overview and basic information
2. **Profile Management** → Update personal and business information
3. **Settings** → Manage app preferences and notifications
4. **Buy Milk** → Tap "Buy" → Navigate to purchase screen *(Coming Soon)*
5. **Track Orders** → View order status and history *(Coming Soon)*
6. **Manage Payments** → Handle payment transactions *(Coming Soon)*

**For All Users:**
- **Notifications** → View important updates and alerts
- **Profile** → Manage account settings and preferences

### Notifications
1. **View Badge** → See unread notification count on bell icon
2. **Tap Icon/Badge** → Navigate to notifications screen
3. **View Notifications** → See list of notifications with status
4. **Mark as Read** → Tap notification or read/unread button
5. **Delete** → Swipe notification to delete

## 🥛 Milk Collection Flow

### Record Collection (MCCs & Collectors)
1. **Navigate** → Home → Tap "Collect"
2. **Select Supplier** → Choose from existing suppliers or add new
3. **Enter Details** → Quantity, price per liter, date/time, quality notes
4. **Submit** → Save collection record
5. **Success** → Show confirmation, return to dashboard

### View Collections
1. **Navigate** → Suppliers → Tap supplier → "Collections"
2. **View List** → See all collections for that supplier
3. **Filter/Search** → Use search and filter options
4. **View Details** → Tap collection for detailed view

### Supplier Delivery Tracking *(Coming Soon)*
1. **Navigate** → Home → "My Deliveries"
2. **View History** → See all milk deliveries made
3. **Check Status** → View payment status for each delivery
4. **View Schedule** → See upcoming collection schedules



## 💰 Sales & Purchase Flow

### Record Sale (MCCs)
1. **Navigate** → Home → Tap "Sell"
2. **Select Customer** → Choose from existing customers or add new
3. **Enter Details** → Quantity, price per liter, payment status
4. **Submit** → Save sale record
5. **Success** → Show confirmation, return to dashboard

### View Sales
1. **Navigate** → Customers → Tap customer → "Sales"
2. **View List** → See all sales for that customer
3. **Filter/Search** → Use search and filter options
4. **View Details** → Tap sale for detailed view

### Purchase Milk (Customers) *(Coming Soon)*
1. **Navigate** → Home → Tap "Buy"
2. **Select Supplier/MCC** → Choose milk source
3. **Enter Details** → Quantity needed, delivery preferences
4. **Submit Order** → Place milk order
5. **Track Order** → Monitor order status and delivery



## 👥 Supplier Management Flow

### Add Supplier
1. **Navigate** → Suppliers → Tap "+" button
2. **Enter Details** → Name, phone, location, etc.
3. **Submit** → Save supplier record
4. **Success** → Show confirmation, return to suppliers list

### Manage Suppliers
1. **View List** → See all suppliers with status
2. **Search/Filter** → Find specific suppliers
3. **View Details** → Tap supplier for detailed view
4. **Edit** → Modify supplier information
5. **Collections** → View supplier's collection history

## 👤 Customer Management Flow

### Add Customer
1. **Navigate** → Customers → Tap "+" button
2. **Enter Details** → Name, phone, location, etc.
3. **Submit** → Save customer record
4. **Success** → Show confirmation, return to customers list

### Manage Customers
1. **View List** → See all customers with status
2. **Search/Filter** → Find specific customers
3. **View Details** → Tap customer for detailed view
4. **Edit** → Modify customer information
5. **Sales** → View customer's purchase history

## 👨‍💼 Employee Management Flow

### Add Employee
1. **Navigate** → Profile → "Manage Employees"
2. **Tap "+"** → Add new employee
3. **Enter Details** → Name, phone, email, role
4. **Set Permissions** → Choose role and access level
5. **Submit** → Save employee record
6. **Success** → Show confirmation

### Manage Employees
1. **View List** → See all employees with roles
2. **Tap Employee** → View employee details
3. **Edit Role** → Change employee permissions
4. **Revoke Access** → Remove employee access
5. **Delete** → Remove employee from system

## 💳 Wallet & Payments Flow

### View Wallets
1. **Navigate** → Home → "Wallets" tab
2. **View Balance** → See current wallet balance
3. **View Transactions** → See transaction history
4. **Filter** → Filter by date, type, status

### Request Payment
1. **Navigate** → Home → "Request Payment"
2. **Enter Amount** → Specify payment amount
3. **Add Note** → Optional payment description
4. **Submit** → Send payment request
5. **Success** → Show confirmation

## 🔧 Settings & Profile Flow

### Language Settings
1. **Navigate** → Settings → "Language"
2. **Select Language** → Choose English or Kinyarwanda
3. **Confirm** → App restarts with new language
4. **Success** → Show confirmation snackbar

### Profile Management
1. **Navigate** → Profile → "Edit Profile"
2. **Update Info** → Modify name, phone, email
3. **Save Changes** → Update profile information
4. **Success** → Show confirmation

### Change Password
1. **Navigate** → Profile → "Change Password"
2. **Enter Current** → Current password
3. **Enter New** → New password
4. **Confirm New** → Confirm new password
5. **Submit** → Update password
6. **Success** → Show confirmation

## 📊 Reports & Analytics Flow

### View Overview
1. **Home Dashboard** → See key metrics
2. **Chart Data** → View collection/sales trends
3. **Period Filter** → Select daily/weekly/monthly
4. **Export** → Download reports (if available)

### Transaction History
1. **Navigate** → Home → "Transactions" tab
2. **View List** → See recent transactions
3. **Filter** → Filter by type, date, amount
4. **View Details** → Tap transaction for details

## 🆘 Support Flow

### Help & Support
1. **Navigate** → Profile → "Help & Support"
2. **Browse Topics** → Find relevant help articles
3. **Contact Support** → Send support request
4. **FAQ** → View frequently asked questions

### About App
1. **Navigate** → Profile → "About"
2. **View Info** → App version, developer info
3. **Terms/Privacy** → View legal information

## 🔄 Data Sync Flow

### Automatic Sync
1. **App Launch** → Automatically sync data
2. **Background Sync** → Sync when app is active
3. **Manual Refresh** → Pull to refresh in lists
4. **Error Handling** → Show sync errors with retry option

### Offline Mode
1. **No Connection** → App shows offline indicator
2. **Cached Data** → Display last synced data
3. **Queue Actions** → Queue changes for later sync
4. **Reconnect** → Sync queued changes when online

---

## 📱 Key User Experience Principles

- **Simple Navigation** → Clear tab structure and intuitive flow
- **Quick Actions** → Common tasks accessible from home screen
- **Real-time Updates** → Live data and notifications
- **Offline Support** → Basic functionality without internet
- **Multi-language** → English and Kinyarwanda support
- **Role-based Access** → Different permissions for different user types
- **Error Recovery** → Clear error messages with retry options

## 🆘 Getting Help

### Report Issues
- **In-App Feedback** → Use the "Help & Support" section
- **Email Support** → Contact our support team
- **Bug Reports** → Include screenshots and steps to reproduce

### Known Limitations (Beta)
- Some features may be incomplete or in development
- Performance may vary on older devices
- Offline functionality is limited
- Advanced reporting features coming soon

### What's Coming Next
- Enhanced analytics and reporting
- Mobile money integration
- Advanced inventory management
- Multi-location support
- Export functionality for reports
- Supplier delivery tracking and management *(In Development)*
- Customer purchase and order management *(In Development)*
