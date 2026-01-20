# Inventory Sales Feature - Implementation Plan

## Overview
Add ability to sell inventory items that are listed in the marketplace. Track sales, payments, and link to finance module.

## Database Schema Changes

### New Enum: `InventorySaleBuyerType`
- `supplier` - Existing supplier from suppliers list (ONLY type that can take debt)
- `customer` - Existing customer from customers list (must pay upfront)
- `other` - New client (must pay upfront, no credit)

**IMPORTANT**: Only suppliers can take items on debt because they have payroll payments that can offset the debt.

### New Enum: `InventorySalePaymentStatus`
- `paid` - Fully paid
- `partial` - Partially paid
- `unpaid` - Not paid (only allowed for customers/suppliers)

### New Model: `InventorySale`
**Design Note**: This model supports both manual sales and future online marketplace orders. When an online order is fulfilled, an InventorySale can be linked to the Order via `order_id`.

```prisma
model InventorySale {
  id              String                      @id @default(uuid()) @db.Uuid
  product_id      String                      @map("product_id") @db.Uuid
  order_id        String?                     @map("order_id") @db.Uuid // Nullable: Links to Order if from online marketplace
  buyer_type      InventorySaleBuyerType      @map("buyer_type")
  buyer_account_id String?                    @map("buyer_account_id") @db.Uuid // Required for 'supplier', nullable for 'customer'/'other'
  buyer_name      String?                     @map("buyer_name") // Optional for new clients
  buyer_phone     String?                     @map("buyer_phone") // Optional for new clients
  quantity        Decimal                     @db.Decimal(10, 2)
  unit_price      Decimal                     @map("unit_price") @db.Decimal(10, 2)
  total_amount    Decimal                     @map("total_amount") @db.Decimal(10, 2)
  amount_paid     Decimal                     @default(0) @map("amount_paid") @db.Decimal(10, 2)
  payment_status  InventorySalePaymentStatus  @default(unpaid) @map("payment_status")
  sale_date       DateTime                    @map("sale_date")
  notes           String?                     @db.Text
  created_at      DateTime                    @default(now()) @map("created_at")
  updated_at      DateTime                    @updatedAt @map("updated_at")
  created_by      String?                     @map("created_by") @db.Uuid

  // Relations
  product         Product                     @relation("InventorySaleProduct", fields: [product_id], references: [id], onDelete: Restrict)
  order           Order?                      @relation("InventorySaleOrder", fields: [order_id], references: [id], onDelete: SetNull) // Link to marketplace order
  buyer_account   Account?                    @relation("InventorySaleBuyer", fields: [buyer_account_id], references: [id], onDelete: SetNull)
  supplier_account Account?                   @relation("InventorySaleSupplierDebt", fields: [buyer_account_id], references: [id], onDelete: SetNull) // For supplier debt tracking
  created_by_user User?                       @relation("InventorySaleCreatedBy", fields: [created_by], references: [id], onDelete: SetNull)

  @@index([product_id])
  @@index([order_id]) // For linking to marketplace orders
  @@index([buyer_account_id])
  @@index([buyer_type])
  @@index([payment_status])
  @@index([sale_date])
  @@map("inventory_sales")
}
```

### Update Product Model
Add relation:
```prisma
sales InventorySale[] @relation("InventorySaleProduct")
```

### Update Order Model
Add relation (for future marketplace integration):
```prisma
inventory_sales InventorySale[] @relation("InventorySaleOrder")
```

### Update Account Model
Add relation:
```prisma
inventory_sales_buyer InventorySale[] @relation("InventorySaleBuyer")
```

### Update User Model
Add relation:
```prisma
inventory_sales_created InventorySale[] @relation("InventorySaleCreatedBy")
```

## Future Marketplace Integration

### Design for Online Orders
1. **Order Flow**:
   - Customer places order online → Creates `Order` + `OrderItem[]` (status: pending)
   - When order is fulfilled → Creates `InventorySale` with `order_id` linked to the Order
   - Both manual sales and online orders use the same `InventorySale` model

2. **Unified Stock Management**:
   - Manual sales: Reduce stock immediately when `InventorySale` is created
   - Online orders: Reduce stock when order is fulfilled (when `InventorySale` is created)
   - Both paths use the same stock reduction logic

3. **Unified Finance Integration**:
   - Both manual sales and online orders create finance transactions when paid
   - Same revenue tracking for both sales types

4. **Reporting**:
   - Can query all sales (manual + online) via `InventorySale`
   - Can filter by `order_id IS NULL` for manual sales only
   - Can filter by `order_id IS NOT NULL` for online orders only
   - Unified sales analytics and reporting

5. **Payment Tracking**:
   - Online orders: Payment can be tracked at Order level (pre-payment) or InventorySale level (post-fulfillment)
   - Manual sales: Payment tracked at InventorySale level
   - Both support partial payments and credit

## Business Rules

1. **Sell Button Visibility**
   - Only show "Sell" button if `is_listed_in_marketplace == true`
   - Only show if `stock_quantity > 0`

2. **Buyer Types & Credit Rules**
   - **Supplier**: Can buy on credit (unpaid/partial payment allowed)
     - **IMPORTANT**: Debt is deducted from their payroll payments
     - Unpaid amounts reduce their expected payroll payments
     - Must be clear/visible in payroll calculations
   - **Customer**: Must pay upfront (payment_status must be 'paid')
   - **Other**: Must pay upfront (payment_status must be 'paid')
   
   **Note**: Only suppliers can take items on debt. This is because suppliers have payroll payments that can be offset against their debt.

3. **Payment Rules**
   - If `buyer_type == 'supplier'`: 
     - Can be unpaid, partial, or paid
     - **Debt Deduction**: Unpaid amount (`total_amount - amount_paid`) is deducted from supplier's payroll payments
     - Debt is tracked and visible in payroll calculations
   - If `buyer_type == 'customer'` or `'other'`: 
     - `amount_paid` must equal `total_amount` (full payment required upfront)
     - No credit allowed
   - If `amount_paid > 0`: Create finance transaction as revenue

4. **Stock Management**
   - Reduce `stock_quantity` by `quantity` when sale is created
   - Update product `status` to 'out_of_stock' if stock reaches 0

5. **New Client Creation**
   - If `buyer_type == 'other'` and `buyer_phone` provided:
     - Check if phone exists in customers/suppliers
     - If not, optionally create a new customer account (if name provided)
   - `buyer_name` and `buyer_phone` are optional but recommended

6. **Finance Integration**
   - If `amount_paid > 0`: Create accounting transaction
     - Type: 'revenue'
     - Amount: `amount_paid`
     - Description: "Sale of [product_name] - [quantity] units"
     - Transaction date: `sale_date`

7. **Payroll Integration (Suppliers Only) - CRITICAL**
   - **Only suppliers can take items on debt** (customers and others must pay upfront)
   - When supplier buys on debt (`buyer_type == 'supplier'` and `payment_status != 'paid'`):
     - Calculate debt amount: `total_amount - amount_paid`
     - Link debt to supplier's account via `buyer_account_id`
     - **Debt is automatically deducted from supplier's payroll payments**
   - **Payroll Calculation Logic**:
     - When generating payroll for a supplier:
       1. Calculate gross amount from milk sales (existing logic)
       2. **Get all unpaid inventory sales** for this supplier:
          ```sql
          SELECT SUM(total_amount - amount_paid) as total_debt
          FROM inventory_sales
          WHERE buyer_type = 'supplier'
            AND buyer_account_id = [supplier_account_id]
            AND payment_status != 'paid'
          ```
       3. **Deduct debt from gross amount**: `net_amount = gross_amount - total_deductions - inventory_debt`
       4. Create `PayrollDeduction` record for inventory debt (type: 'inventory_debt')
   - **Debt Visibility** (must be clear):
     - Payroll calculation screen: Show "Inventory Debt" as a deduction line item
     - Supplier payroll details: Show outstanding inventory debt
     - Inventory sale details: Show if sale is on debt and linked to supplier
     - Supplier details screen: Show total outstanding inventory debt
   - **Debt Payment**:
     - When payroll is paid: Mark inventory sales as paid (if debt <= payroll amount)
     - If debt > payroll amount: Partially pay debt, remaining debt stays
     - Clear debt when `amount_paid` is updated to match `total_amount`

## Backend Implementation

### DTO: `CreateInventorySaleDto`
```typescript
{
  buyer_type: 'customer' | 'supplier' | 'other';
  buyer_account_id?: string; // Required if buyer_type is 'customer' or 'supplier'
  buyer_name?: string; // Optional, for new clients
  buyer_phone?: string; // Optional, for new clients
  quantity: number;
  unit_price: number;
  amount_paid: number;
  sale_date: string; // ISO date string
  notes?: string;
}
```

### Service Method: `sellInventoryItem`
1. Validate product exists and is listed in marketplace
2. Validate stock availability
3. **Validate payment rules**:
   - If `buyer_type == 'supplier'`: Can be unpaid, partial, or paid (debt allowed)
   - If `buyer_type == 'customer'` or `'other'`: `amount_paid` must equal `total_amount` (full payment required)
4. **Validate buyer**:
   - If `buyer_type == 'supplier'`: `buyer_account_id` is required (must be existing supplier)
   - If `buyer_type == 'customer'`: `buyer_account_id` is optional (can be new customer)
   - If `buyer_type == 'other'`: `buyer_account_id` is null (new client)
5. Create InventorySale record (order_id = null for manual sales)
6. Reduce product stock_quantity
7. Update product status if needed
8. If amount_paid > 0, create finance transaction
9. If buyer_type == 'other' and buyer_phone provided, optionally create customer
10. **If supplier debt created**: Log debt amount for payroll deduction

### Payroll Service Update: `processPayroll`
**Update existing payroll calculation to include inventory debt deduction:**

1. For each supplier in payroll run:
   - Calculate gross amount from milk sales (existing logic)
   - **NEW**: Get total inventory debt:
     ```typescript
     const inventoryDebt = await this.prisma.inventorySale.aggregate({
       where: {
         buyer_type: 'supplier',
         buyer_account_id: supplierAccountId,
         payment_status: { not: 'paid' },
       },
       _sum: {
         total_amount: true,
         amount_paid: true,
       },
     });
     const totalDebt = Number(inventoryDebt._sum.total_amount || 0) - Number(inventoryDebt._sum.amount_paid || 0);
     ```
   - **Deduct inventory debt from gross amount**:
     ```typescript
     const totalDeductions = existingDeductions + totalDebt;
     const netAmount = grossAmount - totalDeductions;
     ```
   - **Create PayrollDeduction** for inventory debt:
     ```typescript
     if (totalDebt > 0) {
       await this.prisma.payrollDeduction.create({
         data: {
           payslip_id: payslip.id,
           deduction_type: 'inventory_debt',
           amount: totalDebt,
           description: `Inventory purchases on debt`,
         },
       });
     }
     ```
2. **When payroll is marked as paid**:
   - Update inventory sales payment status:
     ```typescript
     // Mark inventory sales as paid (up to payroll amount)
     await this.updateInventorySalesPayment(payslip.supplier_account_id, payslip.net_amount);
     ```

### Future: Service Method: `fulfillOrder` (for marketplace)
1. Validate order exists and is in 'pending' or 'processing' status
2. For each OrderItem:
   - Validate stock availability
   - Create InventorySale with order_id linked to Order
   - Reduce product stock_quantity
3. Update Order status to 'processing' or 'shipped'
4. If order was pre-paid, create finance transaction
5. Unified stock and finance tracking with manual sales
6. **Note**: Online orders typically require upfront payment, so debt tracking may not apply

## Mobile Implementation

### UI Flow
1. User taps "Sell" button on inventory item bottom sheet
2. Show sell dialog/screen with:
   - Product info (name, price, available stock)
   - Buyer type selector (Customer/Supplier/Other)
   - Buyer selection dropdown (if customer/supplier)
   - New client form (if other):
     - Phone number (optional)
     - Name (optional)
   - Quantity input
   - Payment section:
     - Amount paid input
     - Payment status indicator
   - Notes (optional)
   - Sale date picker
3. Validation:
   - Quantity <= available stock
   - If other buyer: amount_paid == total_amount
   - If customer/supplier: amount_paid <= total_amount
4. Submit sale
5. Refresh inventory list and stats

### AppTheme Consistency
- Use AppTheme colors, fonts, spacing
- Compact design matching inventory module
- Reuse existing components (ConfirmationDialog, DetailsActionSheet patterns)
- Consistent button styles and form inputs

## API Endpoints

### POST `/api/inventory/:id/sell`
- Body: `CreateInventorySaleDto`
- Returns: Created `InventorySale` object
- Creates finance transaction if paid

## Testing Checklist
- [ ] Sell item to existing customer (unpaid)
- [ ] Sell item to existing customer (partial payment)
- [ ] Sell item to existing customer (full payment)
- [ ] Sell item to existing supplier (unpaid)
- [ ] Sell item to new client (other) with full payment
- [ ] Sell item to new client with phone/name
- [ ] Verify stock reduction
- [ ] Verify finance transaction created when paid
- [ ] Verify product status updated when stock reaches 0
- [ ] Verify sell button only shows for listed items
- [ ] Verify validation prevents invalid sales
