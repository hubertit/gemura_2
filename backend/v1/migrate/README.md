# Milk Collection Migration API

This API migrates milk collection data from the old V1 system to the new V2 system using phone numbers as references.

## API Endpoint

```
POST /api/v2/migrate/collections.php
```

## Features

- **Phone Number Mapping**: Uses phone numbers to match users between V1 and V2 systems
- **Automatic Relationship Creation**: Creates supplier-customer relationships if they don't exist
- **Status Mapping**: Maps V1 statuses to V2 statuses (Approved → Accepted, etc.)
- **Dry Run Mode**: Test migration without actually inserting data
- **Batch Processing**: Process data in batches with configurable limits
- **Detailed Reporting**: Provides detailed success/failure reports

## Request Parameters

| Parameter | Type | Required | Default | Description |
|-----------|------|----------|---------|-------------|
| `token` | string | No | - | User authentication token |
| `migration_user_id` | integer | No | 1 | User ID to record as migration creator |
| `limit` | integer | No | 100 | Maximum number of records to process |
| `dry_run` | boolean | No | false | If true, only analyze data without inserting |

## Request Examples

### 1. Dry Run (Test Mode)
```bash
curl -X POST http://localhost/gemura2/api/v2/migrate/collections.php \
  -H 'Content-Type: application/json' \
  -d '{
    "dry_run": true,
    "limit": 10
  }'
```

### 2. Small Migration
```bash
curl -X POST http://localhost/gemura2/api/v2/migrate/collections.php \
  -H 'Content-Type: application/json' \
  -d '{
    "dry_run": false,
    "limit": 50
  }'
```

### 3. Full Migration with Authentication
```bash
curl -X POST http://localhost/gemura2/api/v2/migrate/collections.php \
  -H 'Content-Type: application/json' \
  -d '{
    "token": "your_user_token_here",
    "dry_run": false,
    "limit": 1000
  }'
```

## Response Format

### Success Response
```json
{
  "code": 200,
  "status": "success",
  "message": "Migration completed successfully.",
  "data": {
    "total_processed": 100,
    "successful": 85,
    "failed": 15,
    "details": [
      {
        "success": true,
        "new_id": 12345,
        "collection_id": "1",
        "supplier": "250722509687",
        "customer": "250788636104",
        "quantity": 120.00,
        "amount": 40800.00
      },
      {
        "success": false,
        "reason": "Supplier not found: 250999999999",
        "collection_id": "2"
      }
    ]
  }
}
```

### Error Response
```json
{
  "code": 500,
  "status": "error",
  "message": "Migration failed: Failed to fetch data from old API"
}
```

## Data Mapping

### V1 to V2 Field Mapping

| V1 Field | V2 Field | Notes |
|----------|----------|-------|
| `supplier` | `supplier_account_id` | Mapped via phone number |
| `customer` | `customer_account_id` | Mapped via phone number |
| `quantity` | `quantity` | Direct mapping |
| `collection_date` | `sale_at` | Direct mapping |
| `status` | `status` | Mapped: Approved→Accepted, Rejected→Rejected |
| `quality_check` | `notes` | Added to notes field |

### Status Mapping

| V1 Status | V2 Status |
|-----------|-----------|
| `Approved` | `accepted` |
| `Rejected` | `rejected` |
| `Pending` | `pending` |

## Migration Process

1. **Fetch Data**: Retrieves milk collection data from old API
2. **Phone Mapping**: Maps supplier/customer phone numbers to V2 user accounts
3. **Relationship Check**: Ensures supplier-customer relationships exist
4. **Price Lookup**: Gets unit price from supplier-customer relationship
5. **Data Insertion**: Inserts records into `milk_sales` table
6. **Reporting**: Returns detailed success/failure report

## Testing

Use the test script to run different migration scenarios:

```bash
php /Applications/AMPPS/www/gemura2/api/v2/migrate/test_migration.php
```

## Important Notes

- **Phone Number Matching**: Users must exist in V2 system with matching phone numbers
- **Default Price**: Uses 340 RWF/liter as default price if no relationship exists
- **Zero Quantities**: Skips records with zero or negative quantities
- **Original ID Tracking**: Original collection ID is stored in notes field
- **Batch Processing**: Process large datasets in smaller batches to avoid timeouts

## Troubleshooting

### Common Issues

1. **"Supplier not found"**: Phone number doesn't match any V2 user
2. **"Customer not found"**: Phone number doesn't match any V2 user
3. **"Zero quantity"**: Record has 0 or negative quantity
4. **"Database error"**: Check database connection and table structure

### Debug Mode

The API includes error reporting for debugging. Check your server logs for detailed error messages.

## Security

- Always use authentication tokens for production migrations
- Test with dry_run mode first
- Process data in small batches
- Backup your database before running migrations
