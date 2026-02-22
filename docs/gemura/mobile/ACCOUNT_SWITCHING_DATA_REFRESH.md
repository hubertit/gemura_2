# Account Switching - Data Refresh Implementation

## Overview
This document describes how account switching triggers data refresh for all features that depend on the default/current account.

## Problem
When a user switches their default account, all features that display account-specific data (revenue, expenses, transactions, wallets, etc.) need to update to reflect the new account's data.

## Solution
The `switchAccount` method in `user_accounts_provider.dart` now invalidates/refreshes all providers that depend on the default account.

## Providers Refreshed on Account Switch

### Already Implemented (Before This Update)
1. **Wallets** - `walletsProvider` and `walletsNotifierProvider`
2. **Overview/Stats** - `overviewProvider` and `overviewNotifierProvider`
3. **Collections** - `collectionsProvider` and `collectionsNotifierProvider`
4. **Suppliers** - `suppliersProvider` and `suppliersNotifierProvider`
5. **Customers** - `customersProvider` and `customersNotifierProvider`
6. **Loans** - `loansProvider` (invalidated)
7. **Savings** - `savingsProvider` (invalidated)
8. **Notifications** - `notificationsNotifierProvider` (refreshed)

### Added in This Update
9. **Income Statement** - `incomeStatementProvider` (family provider - invalidates all instances)
10. **Transactions** - `transactionsProvider` (family provider - invalidates all instances)
11. **Receivables** - `receivablesProvider` (family provider - invalidates all instances)
12. **Payables** - `payablesProvider` (family provider - invalidates all instances)
13. **Sales** - `salesProvider` and `filteredSalesProvider` (family provider - invalidates all instances)
14. **Inventory** - `inventoryProvider` (family), `inventoryStatsProvider`, `inventoryItemProvider` (family)
15. **Home Wallet Display Cache** - `homeWalletDisplayAmountProvider` (reset to null)

## Implementation Details

### Family Providers
`incomeStatementProvider`, `transactionsProvider`, `receivablesProvider`, and `payablesProvider` are `FutureProvider.family` providers, meaning they can have multiple instances based on different parameters (e.g., different date ranges).

When we call `ref.invalidate(incomeStatementProvider)`, it invalidates **all instances** of that provider, regardless of their parameters. This ensures that:
- Home screen's current month income statement refreshes
- Finance screen's income statement (with any date range) refreshes
- Any other screen using income statement with different parameters refreshes

### Cache Reset
`homeWalletDisplayAmountProvider` is a `StateProvider` that caches the last displayed net profit amount. When switching accounts, we reset it to `null` so:
- The new account's data loads fresh (no stale cache from previous account)
- The UI doesn't show incorrect cached values during the transition

## Code Location
- **File**: `mobile/lib/features/home/presentation/providers/user_accounts_provider.dart`
- **Method**: `switchAccount()` (lines ~75-256)
- **Section**: After savings invalidation, before notifications refresh (lines ~198-230)

## Testing Checklist
When testing account switching, verify that the following update correctly:

- [ ] Home screen wallet card (net profit)
- [ ] Finance screen - Income statement (revenue, expenses, net income)
- [ ] Finance screen - Transactions list
- [ ] Finance screen - Receivables
- [ ] Finance screen - Payables
- [ ] Sales screen - Sales list
- [ ] Inventory screen - Inventory items and stats
- [ ] Overview/Stats screen
- [ ] Wallets screen
- [ ] Collections screen
- [ ] Suppliers screen
- [ ] Customers screen
- [ ] Loans screen
- [ ] Savings screen

## Notes
- All invalidations are wrapped in try-catch blocks to prevent one failure from blocking others
- There's a small delay (300ms) before refreshing overview to ensure backend has updated `default_account_id`
- The cache reset happens before other refreshes to ensure clean state
