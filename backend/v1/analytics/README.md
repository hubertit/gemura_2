# Analytics API Documentation

## Overview
The Analytics API provides access to business intelligence data for external consumers like Looker, Tableau, and other BI tools.

## Base URL
```
http://localhost/gemura2/api/v2/analytics/
```

## Authentication
All endpoints require a valid user token passed in the request body.

## Endpoints

### 1. Collections Data
**Endpoint:** `GET /collections.php`

**Description:** Retrieves detailed collection/sales transaction data.

**Query Parameters:**
- `token` (required): User authentication token
- `date_from` (optional): Start date in YYYY-MM-DD format
- `date_to` (optional): End date in YYYY-MM-DD format
- `account_code` (optional): Account code to filter data

**Example Request:**
```
GET /collections?token=user_token_here&date_from=2024-01-01&date_to=2024-12-31
```

**Response:**
```json
{
  "code": 200,
  "status": "success",
  "message": "Collections data retrieved successfully",
  "data": [
    {
      "id": 123,
      "supplier_account_id": 25,
      "customer_account_id": 91,
      "supplier_name": "NTWARI Alphonse",
      "supplier_code": "A_03DC87",
      "customer_name": "KOPERATIVE KOZAMGI",
      "customer_code": "A_16C846",
      "quantity": 50.5,
      "unit_price": 1200,
      "total_price": 60600,
      "sale_at": "2024-01-15T08:30:00Z",
      "status": "completed",
      "notes": "Quality: Aremewe",
      "recorded_by": 91,
      "created_at": "2024-01-15T08:30:00Z",
      "updated_at": "2024-01-15T08:30:00Z"
    }
  ]
}
```

### 2. Metrics Data
**Endpoint:** `GET /metrics.php`

**Description:** Retrieves aggregated metrics and trends.

**Query Parameters:**
- `token` (required): User authentication token
- `date_from` (optional): Start date in YYYY-MM-DD format
- `date_to` (optional): End date in YYYY-MM-DD format
- `account_code` (optional): Account code to filter data

**Example Request:**
```
GET /metrics?token=user_token_here&date_from=2024-01-01&date_to=2024-12-31
```

**Response:**
```json
{
  "code": 200,
  "status": "success",
  "message": "Metrics data retrieved successfully",
  "data": {
    "summary": {
      "total_transactions": 1250,
      "total_volume": 15000.5,
      "total_revenue": 18000000,
      "avg_unit_price": 1200,
      "unique_partners": 45,
      "first_transaction": "2024-01-01T08:00:00Z",
      "last_transaction": "2024-12-31T18:00:00Z"
    },
    "monthly_trends": [
      {
        "month": "2024-01",
        "transactions": 120,
        "volume": 1500.5,
        "revenue": 1800000,
        "avg_price": 1200
      }
    ],
    "account_type": "customer",
    "date_range": {
      "from": "2024-01-01",
      "to": "2024-12-31"
    }
  }
}
```

### 3. Customer Analytics
**Endpoint:** `GET /customers.php`

**Description:** Retrieves customer-specific analytics and performance data.

**Query Parameters:**
- `token` (required): User authentication token
- `date_from` (optional): Start date in YYYY-MM-DD format
- `date_to` (optional): End date in YYYY-MM-DD format
- `account_code` (optional): Account code to filter data

**Example Request:**
```
GET /customers?token=user_token_here&date_from=2024-01-01&date_to=2024-12-31
```

**Response:**
```json
{
  "code": 200,
  "status": "success",
  "message": "Customer analytics data retrieved successfully",
  "data": {
    "customers": [
      {
        "id": 456,
        "name": "John Doe",
        "phone": "+250123456789",
        "email": "john@example.com",
        "type": "customer",
        "status": "active",
        "created_at": "2024-01-01T00:00:00Z",
        "analytics": {
          "total_transactions": 25,
          "total_volume": 500.5,
          "total_revenue": 600000,
          "avg_unit_price": 1200,
          "first_transaction": "2024-01-15T08:30:00Z",
          "last_transaction": "2024-12-15T16:45:00Z",
          "days_active": 334
        }
      }
    ],
    "top_customers": [
      {
        "name": "John Doe",
        "total_revenue": 600000,
        "transaction_count": 25
      }
    ],
    "account_type": "supplier",
    "date_range": {
      "from": "2024-01-01",
      "to": "2024-12-31"
    }
  }
}
```

## Error Responses

All endpoints return consistent error responses:

```json
{
  "code": 400,
  "status": "error",
  "message": "Missing token."
}
```

**Common Error Codes:**
- `400`: Bad Request (missing parameters)
- `403`: Unauthorized (invalid token)
- `500`: Internal Server Error

## Data Types

- **Integers**: Transaction counts, IDs
- **Floats**: Quantities, prices, volumes
- **Strings**: Names, phone numbers, emails
- **Dates**: ISO 8601 format (YYYY-MM-DDTHH:MM:SSZ)

## Usage Examples

### For Looker Integration
```javascript
// Configure Looker to use these endpoints
const config = {
  baseUrl: "http://localhost/gemura2/api/v2/analytics/",
  endpoints: {
    collections: "collections.php",
    metrics: "metrics.php",
    customers: "customers.php"
  }
};
```

### For Tableau Integration
```javascript
// Tableau can consume JSON APIs directly
const url = "http://localhost/gemura2/api/v2/analytics/metrics.php";
const data = {
  token: "your_token_here",
  date_from: "2024-01-01",
  date_to: "2024-12-31"
};
```

## Notes

- All endpoints are user-based (data filtered by user's account)
- Date ranges are optional (defaults to all-time data)
- No pagination implemented (returns all data)
- Consistent JSON response format across all endpoints
- Account type (customer/supplier) determines data perspective
