# UI Redesign Plan - Modules-Based Home Screen

**Date:** 2026-01-04  
**Status:** Planning Phase

## 📊 Current UI Analysis

### Current Home Screen Structure
- **Quick Actions:** 4 buttons in a row (Collect, Sell, and 2 more)
- **Layout:** Horizontal row with icons and labels
- **Navigation:** Direct navigation to specific screens
- **Issues:**
  - Limited to 4 actions
  - No grouping or categorization
  - Hard to scale with more features
  - Not intuitive for discovering features

### Available Modules/Features
Based on codebase analysis:
1. **Collections** - Milk collection management
2. **Sales** - Milk sales management
3. **Suppliers** - Supplier management
4. **Customers** - Customer management
5. **Wallets** - Wallet management
6. **Feed** - Social feed
7. **Market** - E-commerce/marketplace
8. **Chat** - Messaging
9. **Account Access** - Employee/access management
10. **Reports** - Analytics and reports
11. **Payroll** - Payroll management
12. **Accounting** - Financial management
13. **Notifications** - User notifications
14. **KYC** - Identity verification
15. **API Keys** - API key management

## 🎨 Proposed Design

### Module Card Design
- **Grid Layout:** 2 columns on mobile
- **Card Style:** 
  - Icon (top)
  - Module name (center)
  - Badge for new/updates (optional)
  - Subtle shadow and rounded corners
- **Colors:** Use AppTheme.primaryColor with opacity variations
- **Size:** Consistent card size, responsive

### Module Detail Screen
When user taps a module:
- **Header:** Module name and icon
- **Actions Grid:** Available actions for that module
- **Recent Activity:** Show recent items (if applicable)
- **Quick Stats:** Show key metrics (if applicable)

### Module Actions Examples

#### Collections Module
- Record Collection
- View Collections
- Pending Collections
- Collection History

#### Sales Module
- Record Sale
- View Sales
- Sales History
- Sales Reports

#### Suppliers Module
- Add Supplier
- View Suppliers
- Supplier Details
- Supplier Reports

#### Customers Module
- Add Customer
- View Customers
- Customer Details
- Customer Reports

## 🎯 Implementation Plan

### Phase 1: Module Model & Data Structure
1. Create `Module` model
2. Create `ModuleAction` model
3. Define all modules with their actions
4. Create local storage service

### Phase 2: Home Screen Redesign
1. Replace quick actions with modules grid
2. Create module card widget
3. Implement grid layout
4. Add navigation to module detail

### Phase 3: Module Detail Screen
1. Create module detail screen
2. Display module actions
3. Add recent activity section
4. Add quick stats (if applicable)

### Phase 4: Local Storage
1. Implement local storage for data
2. Preserve posted data
3. Sync when API is connected

### Phase 5: Testing & Polish
1. Test all flows
2. Ensure consistency
3. Run flutter analyze
4. Commit changes

## 🎨 Design Consistency

### Colors
- Primary: `AppTheme.primaryColor` (#004AAD)
- Background: `AppTheme.backgroundColor` (#F5F5F5)
- Surface: `AppTheme.surfaceColor` (white)
- Use opacity variations for backgrounds

### Spacing
- Use `AppTheme.spacing*` constants
- Consistent padding: `AppTheme.spacing16`
- Card margins: `AppTheme.spacing8`

### Typography
- Module names: `AppTheme.titleMedium`
- Action labels: `AppTheme.bodyMedium`
- Descriptions: `AppTheme.bodySmall`

### Border Radius
- Cards: `AppTheme.borderRadius16`
- Buttons: `AppTheme.borderRadius12`

## 📱 Responsive Design

- **Mobile:** 2 columns
- **Tablet:** 3 columns (future)
- **Card Size:** Consistent, responsive to screen width

## ✅ Success Criteria

1. ✅ Modules replace quick actions
2. ✅ All major features accessible
3. ✅ Consistent design language
4. ✅ Smooth navigation
5. ✅ Local data persistence
6. ✅ No breaking changes
7. ✅ Flutter analyze passes

---

**Ready to implement!**

