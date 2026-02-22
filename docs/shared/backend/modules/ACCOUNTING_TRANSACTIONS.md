# Transactions API

This module provides simplified endpoints for recording revenue and expense transactions tied to a user's default account.

## Endpoints

### POST `/api/accounting/transactions`
Record a revenue or expense transaction.

**Request Body:**
```json
{
  "type": "revenue",  // or "expense"
  "amount": 50000,
  "description": "Milk sales revenue",
  "transaction_date": "2025-01-18",
  "account_id": "optional-uuid"  // Optional: specific chart of account ID
}
```

**Response:**
```json
{
  "code": 200,
  "status": "success",
  "message": "Revenue recorded successfully.",
  "data": {
    "id": "transaction-uuid",
    "type": "revenue",
    "amount": 50000,
    "description": "Milk sales revenue",
    "transaction_date": "2025-01-18T00:00:00.000Z",
    "account": "Account Name",
    "category_account": "General Revenue - Account Name",
    "cash_account": "Cash - Account Name"
  }
}
```

### GET `/api/accounting/transactions`
Get transactions with optional filters.

**Query Parameters:**
- `type` (optional): Filter by "revenue" or "expense"
- `date_from` (optional): Start date (YYYY-MM-DD)
- `date_to` (optional): End date (YYYY-MM-DD)
- `limit` (optional): Limit number of results (default: 50)

**Response:**
```json
{
  "code": 200,
  "status": "success",
  "message": "Transactions fetched successfully.",
  "data": [
    {
      "id": "transaction-uuid",
      "type": "revenue",
      "amount": 50000,
      "description": "Milk sales revenue",
      "transaction_date": "2025-01-18T00:00:00.000Z",
      "category_account": "General Revenue - Account Name"
    }
  ]
}
```

## How It Works

1. **Automatic Account Creation:**
   - Creates/finds a Cash (Asset) account for the user's default account
   - Creates/finds a default Revenue or Expense account if not specified
   - Account codes follow pattern: `CASH-{ACCOUNT_CODE}`, `REV-{ACCOUNT_CODE}`, `EXP-{ACCOUNT_CODE}`

2. **Journal Entry Creation:**
   - **Revenue**: Credits Revenue account, Debits Cash account
   - **Expense**: Debits Expense account, Credits Cash account
   - All entries are automatically balanced (debits = credits)

3. **Account Linking:**
   - All transactions are tied to the user's `default_account_id`
   - Transactions are filtered by the user who created them

## Validation

- `type`: Must be "revenue" or "expense"
- `amount`: Must be a positive number >= 0.01
- `description`: Required, non-empty string
- `transaction_date`: Must be a valid date string (YYYY-MM-DD)
- `account_id`: Optional, must be a valid UUID if provided

## Error Responses

- **400 Bad Request**: Missing default account, invalid data, account type mismatch
- **401 Unauthorized**: Missing or invalid authentication token
- **500 Internal Server Error**: Server error

## Testing

Use the `test-transactions.http` file with REST Client extension or similar tool to test the endpoints.
