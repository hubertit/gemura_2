# Orora API Documentation

## Overview

The Orora API is a RESTful API built with NestJS that serves both the web and mobile applications.

**Base URL:** `http://209.74.80.195:3007/api`

**Documentation:** `http://209.74.80.195:3007/api/docs` (Swagger UI)

---

## Authentication

### Login

```http
POST /api/auth/login
Content-Type: application/json

{
  "phone": "250788606765",
  "password": "Pass123"
}
```

**Response:**

```json
{
  "access_token": "eyJhbGciOiJIUzI1NiIs...",
  "user": {
    "id": "uuid",
    "name": "John Doe",
    "phone": "250788606765",
    "email": "john@example.com",
    "account_type": "farmer",
    "default_account_id": "uuid"
  }
}
```

### Using the Token

Include the token in the Authorization header for all protected endpoints:

```http
GET /api/animals
Authorization: Bearer eyJhbGciOiJIUzI1NiIs...
```

---

## API Endpoints

### Animals

#### List Animals

```http
GET /api/animals
Authorization: Bearer {token}
```

**Query Parameters:**

| Parameter | Type | Description |
|-----------|------|-------------|
| page | number | Page number (default: 1) |
| limit | number | Items per page (default: 20) |
| search | string | Search by tag or name |
| status | string | Filter by status |
| gender | string | Filter by gender |
| breed | string | Filter by breed |

**Response:**

```json
{
  "success": true,
  "data": [
    {
      "id": "uuid",
      "tag_number": "A001",
      "name": "Bella",
      "breed": "Friesian",
      "gender": "female",
      "date_of_birth": "2022-05-15",
      "status": "lactating",
      "account_id": "uuid",
      "created_at": "2024-01-01T00:00:00Z"
    }
  ],
  "meta": {
    "page": 1,
    "limit": 20,
    "total": 45,
    "totalPages": 3
  }
}
```

#### Create Animal

```http
POST /api/animals
Authorization: Bearer {token}
Content-Type: application/json

{
  "tag_number": "A002",
  "name": "Daisy",
  "breed": "Friesian",
  "gender": "female",
  "date_of_birth": "2023-03-10",
  "source": "born_on_farm",
  "status": "active",
  "mother_id": "uuid-of-mother",
  "notes": "Healthy calf"
}
```

#### Get Animal

```http
GET /api/animals/{id}
Authorization: Bearer {token}
```

#### Update Animal

```http
PATCH /api/animals/{id}
Authorization: Bearer {token}
Content-Type: application/json

{
  "status": "lactating",
  "notes": "Started milking"
}
```

#### Delete Animal

```http
DELETE /api/animals/{id}
Authorization: Bearer {token}
```

---

### Animal Weights

#### Record Weight

```http
POST /api/animals/{id}/weights
Authorization: Bearer {token}
Content-Type: application/json

{
  "weight_kg": 450.5,
  "recorded_at": "2024-02-22T08:00:00Z",
  "notes": "Monthly weigh-in"
}
```

#### Get Weight History

```http
GET /api/animals/{id}/weights
Authorization: Bearer {token}
```

---

### Animal Health

#### Record Health Event

```http
POST /api/animals/{id}/health
Authorization: Bearer {token}
Content-Type: application/json

{
  "event_type": "vaccination",
  "event_date": "2024-02-22",
  "description": "FMD vaccination",
  "medicine_name": "FMD Vaccine",
  "dosage": "5ml",
  "administered_by": "Dr. Smith",
  "next_due_date": "2024-08-22",
  "cost": 5000
}
```

#### Get Health History

```http
GET /api/animals/{id}/health
Authorization: Bearer {token}
```

---

### Milk Collections

#### Record Collection

```http
POST /api/collections
Authorization: Bearer {token}
Content-Type: application/json

{
  "supplier_account_id": "uuid",
  "quantity": 25.5,
  "unit_price": 300,
  "sale_at": "2024-02-22T06:00:00Z",
  "animal_id": "uuid",  // Optional - link to specific cow
  "notes": "Morning collection"
}
```

#### List Collections

```http
GET /api/collections
Authorization: Bearer {token}
```

**Query Parameters:**

| Parameter | Type | Description |
|-----------|------|-------------|
| startDate | date | Filter from date |
| endDate | date | Filter to date |
| supplierId | uuid | Filter by supplier |
| status | string | Filter by status |

---

### Suppliers

#### List Suppliers

```http
GET /api/suppliers
Authorization: Bearer {token}
```

#### Create Supplier

```http
POST /api/suppliers
Authorization: Bearer {token}
Content-Type: application/json

{
  "name": "John Farmer",
  "phone": "250788000000",
  "address": "Kigali, Rwanda",
  "price_per_liter": 300
}
```

---

### Inventory

#### List Products

```http
GET /api/inventory/products
Authorization: Bearer {token}
```

#### Create Product

```http
POST /api/inventory/products
Authorization: Bearer {token}
Content-Type: application/json

{
  "name": "Dairy Meal 50kg",
  "description": "High protein dairy feed",
  "price": 35000,
  "stock_quantity": 100,
  "min_stock_level": 20
}
```

#### Record Sale

```http
POST /api/inventory/sales
Authorization: Bearer {token}
Content-Type: application/json

{
  "product_id": "uuid",
  "buyer_type": "supplier",
  "buyer_account_id": "uuid",
  "quantity": 2,
  "unit_price": 35000,
  "payment_status": "unpaid",
  "sale_date": "2024-02-22"
}
```

---

### Loans

#### Create Loan

```http
POST /api/loans
Authorization: Bearer {token}
Content-Type: application/json

{
  "borrower_type": "supplier",
  "borrower_account_id": "uuid",
  "principal": 100000,
  "disbursement_date": "2024-02-22",
  "due_date": "2024-05-22",
  "notes": "Emergency loan"
}
```

#### List Loans

```http
GET /api/loans
Authorization: Bearer {token}
```

#### Record Repayment

```http
POST /api/loans/{id}/repayments
Authorization: Bearer {token}
Content-Type: application/json

{
  "amount": 25000,
  "repayment_date": "2024-03-01",
  "source": "direct"
}
```

---

### Analytics

#### Dashboard Summary

```http
GET /api/analytics/dashboard
Authorization: Bearer {token}
```

**Response:**

```json
{
  "success": true,
  "data": {
    "animals": {
      "total": 150,
      "by_status": {
        "active": 120,
        "lactating": 45,
        "dry": 30,
        "pregnant": 25,
        "sick": 5
      },
      "by_gender": {
        "male": 30,
        "female": 120
      }
    },
    "milk": {
      "today": 450.5,
      "this_week": 3150.0,
      "this_month": 13500.0
    },
    "financial": {
      "total_receivable": 2500000,
      "total_payable": 1800000,
      "outstanding_loans": 500000
    }
  }
}
```

#### Milk Production Report

```http
GET /api/analytics/milk
Authorization: Bearer {token}
```

**Query Parameters:**

| Parameter | Type | Description |
|-----------|------|-------------|
| startDate | date | Report start date |
| endDate | date | Report end date |
| groupBy | string | day, week, month |

---

## Error Handling

### Error Response Format

```json
{
  "success": false,
  "error": {
    "code": "VALIDATION_ERROR",
    "message": "Validation failed",
    "details": [
      {
        "field": "tag_number",
        "message": "Tag number is required"
      }
    ]
  }
}
```

### Error Codes

| Code | HTTP Status | Description |
|------|-------------|-------------|
| VALIDATION_ERROR | 400 | Invalid input data |
| UNAUTHORIZED | 401 | Missing or invalid token |
| FORBIDDEN | 403 | Insufficient permissions |
| NOT_FOUND | 404 | Resource not found |
| CONFLICT | 409 | Duplicate resource |
| INTERNAL_ERROR | 500 | Server error |

---

## Rate Limiting

- Default: 100 requests per minute per IP
- Authenticated: 1000 requests per hour per user
- API Keys: Custom limits based on plan

---

## Pagination

All list endpoints support pagination:

```http
GET /api/animals?page=2&limit=50
```

**Response includes:**

```json
{
  "meta": {
    "page": 2,
    "limit": 50,
    "total": 150,
    "totalPages": 3,
    "hasNextPage": true,
    "hasPrevPage": true
  }
}
```

---

## Filtering & Sorting

### Filtering

```http
GET /api/animals?status=active&gender=female&breed=Friesian
```

### Sorting

```http
GET /api/animals?sortBy=created_at&sortOrder=desc
```

### Search

```http
GET /api/animals?search=bella
```

---

## Webhooks (Planned)

Future webhook support for:
- New milk collection recorded
- Animal status change
- Payment processed
- Low stock alert

---

## SDK & Libraries

### JavaScript/TypeScript

```typescript
import { OroraClient } from '@orora/sdk';

const client = new OroraClient({
  baseUrl: 'http://209.74.80.195:3007/api',
  token: 'your-token'
});

const animals = await client.animals.list({ status: 'active' });
```

### Flutter/Dart

```dart
import 'package:orora_sdk/orora_sdk.dart';

final client = OroraClient(
  baseUrl: 'http://209.74.80.195:3007/api',
  token: 'your-token',
);

final animals = await client.animals.list(status: 'active');
```

---

## API Versioning

Current version: **v1** (default)

Version is included in the base URL path when needed:
- `/api/v1/animals` (explicit)
- `/api/animals` (defaults to v1)

---

## Support

- **API Issues:** Create issue on GitHub
- **Documentation:** See `/api/docs` for interactive docs
- **Status:** Check API health at `/api/health`
