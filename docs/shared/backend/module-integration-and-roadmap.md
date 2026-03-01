# Module Integration & Roadmap

**Purpose:** Best practices for modules talking to each other, and the plan for Assets, Liabilities, Accounting extensions, Production, and Inventory before implementation.

**Last updated:** March 2026

---

## 1. Principles (best practices)

### Single source of truth per domain
- **Accounting** = ledger (ChartOfAccount, AccountingTransaction). All money/value flows that affect the books should post here.
- **Operational modules** (MilkSale, InventorySale, Loan, etc.) = source events. They create or update their own data; when a financial effect occurs, they **post** to accounting instead of duplicating logic.

### Cross-module linking
- **Reference, don’t duplicate:** When a journal entry is created from e.g. a milk sale or inventory sale, store `source_type` + `source_id` (or equivalent) on the accounting transaction so reports and audits can trace back.
- **Ids, not copies:** Link via foreign keys or typed references (e.g. `milk_sale_id`, `inventory_sale_id`). Avoid storing duplicated amounts or dates that can go out of sync.
- **Scoping:** All modules that write to the ledger must use the same tenant/account scope (e.g. user’s default account or explicit account_id). Chart of accounts may use account-scoped codes (e.g. `CASH-{accountCode}`) or an explicit `account_id` on ChartOfAccount.

### Event-style posting
- When something with a financial impact happens (sale, purchase, payment, loan disbursement), the owning module creates the journal entry (or calls a shared accounting service). One event → one (or one set of) transaction(s). No double-posting for the same event.

### Consistency
- Use the same date, amount, and currency in the operational record and in the accounting entry. Use transactions (DB transaction) where both operational and accounting writes must succeed or fail together.

---

## 2. Current state (what exists)

| Area | What exists | Gap |
|------|-------------|-----|
| **Accounting** | ChartOfAccount (Asset, Liability, Equity, Revenue, Expense), AccountingTransaction, entries. Transactions (revenue/expense), receivables-payables, reports. Scoped by account via code prefix. | No `source_type`/`source_id` on transactions; no Chart CRUD; no posting from other modules. |
| **Inventory** | Product (stock_quantity, account_id), InventorySale, InventoryMovement (sale_out, purchase_in, adjustment, transfer). | Not posted to accounting. No automatic journal on sale or purchase. |
| **Production** | MilkSale (supplier→customer, quantity, price, animal_id), Collections. | No formal “production run” or batch; not posted to accounting. |
| **Assets** | Only in chart (account_type = Asset). | No asset register (equipment, vehicles, etc.). |
| **Liabilities** | Loans (lender/borrower), receivables-payables. Chart has Liability. | No posting of loan disbursement/repayment or AP to ledger; no formal liability register if needed. |

---

## 3. Plan before implementation

### Phase A – Accounting foundation (do first)
1. **Chart of accounts**
   - Add CRUD or at least list/filter by `account_type` (Asset, Liability, Equity, Revenue, Expense).
   - Optionally add `account_id` to ChartOfAccount for strict per-tenant charts; otherwise keep current code-prefix scoping.
2. **Source tracking**
   - Add optional `source_type` (e.g. `milk_sale`, `inventory_sale`, `loan`, `asset`, `manual`) and `source_id` (UUID) on AccountingTransaction so every entry can be traced to an event.
3. **Shared posting helper**
   - One place (e.g. AccountingService or a dedicated PostingService) that creates AccountingTransaction + entries from (account_id, date, lines[], source_type, source_id). All modules that post to the ledger call this.

### Phase B – Operational modules post to accounting
1. **Milk sales / production**
   - When a milk sale is confirmed (or paid): post DR Cash/Receivable, CR Revenue (and optional cost side). Set `source_type = 'milk_sale'`, `source_id = milk_sale.id`.
2. **Inventory**
   - **InventorySale:** On create (or on payment): post DR Receivable/Cash, CR Revenue; optionally DR COGS, CR Inventory asset. `source_type = 'inventory_sale'`, `source_id = inventory_sale.id`.
   - **InventoryMovement** (purchase_in, adjustment_in): post DR Inventory (asset account), CR Cash/Payable or adjustment account. Link via `source_type`/`source_id` to movement.
3. **Loans**
   - On disbursement: DR Loan receivable (or expense), CR Cash. On repayment: DR Cash, CR Loan receivable. Use `source_type = 'loan'`, `source_id = loan.id` (and optionally repayment id if needed).
4. **Receivables/Payables**
   - When recording a payment: post DR Cash, CR Receivable (or DR Payable, CR Cash). Already have receivables-payables module; ensure it creates AccountingTransaction entries and uses source_type/source_id.

### Phase C – New modules
1. **Assets**
   - New entity: e.g. Asset (name, type, purchase_date, cost, account_id, optional farm_id/location_id). On create/update/disposal, post to ChartOfAccount (Asset account and optionally Cash/Payable). Link via source_type/source_id.
2. **Liabilities (optional)**
   - If you need a formal liability register (e.g. contracts), add a small module that stores the contract and posts to Liability accounts. Loans + AP already cover most liability flows; this is for extra structure.
3. **Production (optional)**
   - Optional ProductionRun (date, farm_id, optional product_type) to group milk collections/sales. Link MilkSale/collections to it. Posting to accounting still from MilkSale; run is for reporting only.

### Phase D – Reporting and integrity
- Reports (income statement, balance sheet) already use ChartOfAccount; ensure they respect account scope and, if needed, filter by source_type.
- Add simple checks: e.g. “every MilkSale with status X has exactly one AccountingTransaction with source_type = milk_sale and source_id = id.”

---

## 4. Data model changes (summary)

| Change | Purpose |
|--------|---------|
| AccountingTransaction: optional `source_type`, `source_id` | Trace entries to operational events. |
| ChartOfAccount: optional `account_id` | Per-tenant chart if desired. |
| New: Asset (or FixedAsset) | Register fixed assets; post to Asset accounts. |
| Optional: ProductionRun | Group production (milk) for reporting. |

No change to core Inventory or MilkSale schema for linking; they get linked via AccountingTransaction.source_*.

---

## 5. Implementation order

1. **Accounting:** Source fields + shared posting helper; Chart list/CRUD (or list by type).
2. **Posting from existing modules:** MilkSale → revenue; InventorySale + InventoryMovement → revenue/inventory/COGS; Loans → disbursement/repayment; receivables-payables payments.
3. **Assets:** Asset register + post to ledger.
4. **Production run (optional):** If needed for reporting.
5. **Reporting and checks:** Use source_* in reports; add integrity checks.

---

## 6. References

- Backend accounting: `backend/src/modules/accounting/` (transactions, receivables-payables, reports).
- Schema: `ChartOfAccount`, `AccountingTransaction`, `AccountingTransactionEntry` in `backend/prisma/schema.prisma`.
- Orora architecture: `docs/orora/architecture.md`.
- Project next steps: `docs/shared/project/next-steps.md`.
