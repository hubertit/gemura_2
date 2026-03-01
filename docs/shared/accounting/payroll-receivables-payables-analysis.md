# Payroll, Receivables & Payables - Logic Analysis

**Date:** 2026-02-02  
**Scope:** Payroll runs, inventory debt deduction, Receivables, Payables

---

## 1. Data Flow Summary

| Entity | Receivables (We're owed) | Payables (We owe) |
|--------|--------------------------|-------------------|
| **MilkSale** | supplier=us, customer=them (they owe us for milk) | customer=us, supplier=them (we owe them for milk) |
| **InventorySale** | buyer=supplier (they owe us for inventory) | N/A |
| **Payroll** | Deducts supplier inventory debt → settles InventorySale | Pays for milk → settles MilkSale (payables) |

---

## 2. Critical Gaps Found

### 2.1 Double Payment Risk (CRITICAL)
**Issue:** `processPayroll` and `generatePayroll` do NOT exclude milk sales already paid in previous payroll runs.

- `processPayroll` fetches `paidMilkSaleIds` but **never uses it** to filter milk sales
- Neither flow filters by `payment_status: { not: 'paid' }` on MilkSale
- **Impact:** Same milk could be paid twice if included in overlapping runs

### 2.2 processPayroll - Missing Filters
- No `status: { not: 'deleted' }` on milk sales → deleted collections could be paid
- No exclusion of milk sales already in paid payslips

### 2.3 markAsPaid - No Transaction Atomicity
- Multiple DB updates (payslip, InventorySales, MilkSales, expense) without `$transaction`
- **Impact:** Partial failure could leave inconsistent state (e.g. payslip marked paid but MilkSales not updated)

### 2.4 getRuns - No Multi-Tenant Scoping
- Returns ALL payroll runs in the system
- No filter by `created_by` or account
- **Impact:** In multi-tenant setup, users could see other accounts' payroll data

### 2.5 Receivables - Empty customer.id Grouping
- InventorySales with `buyer_account_id=null` get `customer: { id: '', ... }`
- Grouping by `customerId` could merge unrelated items under key `''`

---

## 3. Best Practices Already in Place

| Practice | Status |
|----------|--------|
| Net amount never negative (capped at 0) | ✓ |
| Deductions capped at gross (can't deduct more than we owe them) | ✓ |
| Inventory debt allocated oldest-first for partial settlement | ✓ |
| PayrollDeduction links to InventorySale for audit trail | ✓ |
| markAsPaid updates both InventorySales and MilkSales | ✓ |
| recordPaymentForReceivable for direct debt payment | ✓ |
| remaining_debt in payroll response when debt > gross | ✓ |
| Payment validation (amount > 0, not exceeding outstanding) | ✓ |

---

## 4. Recommendations

1. **Exclude paid milk sales** in both processPayroll and generatePayroll
2. **Wrap markAsPaid** in `prisma.$transaction` for atomicity
3. **Scope getRuns** by `created_by: user.id` (or account if schema supports)
4. **Add status filter** to processPayroll milk sales: `status: { not: 'deleted' }`
5. **Remove dead code** - paidMilkSaleIds in processPayroll (or use it correctly)
