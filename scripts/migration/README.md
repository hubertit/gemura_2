# Data Migration Scripts

This directory contains scripts to migrate data from Gemura v1 (PHP/MySQL) to v2 (NestJS/PostgreSQL).

## Prerequisites

1. **MySQL Access**: Access to the original MySQL database
2. **PostgreSQL Access**: Access to the new PostgreSQL database
3. **Tools Required**:
   - `mysql` client
   - `psql` client
   - `uuidgen` (usually pre-installed)

## Configuration

Set environment variables or edit the script:

```bash
# MySQL Connection
export MYSQL_HOST="localhost"
export MYSQL_PORT="3306"
export MYSQL_DB="gemura"
export MYSQL_USER="root"
export MYSQL_PASS="your_password"

# PostgreSQL Connection
export PG_HOST="devslab-postgres"  # or localhost if local
export PG_PORT="5432"
export PG_DB="gemura_db"
export PG_USER="devslab_admin"
export PG_PASS="devslab_secure_password_2024"
```

## Usage

### Full Migration

```bash
./scripts/migration/migrate-data.sh
```

This will:
1. Check MySQL and PostgreSQL connections
2. Migrate all tables in dependency order
3. Validate row counts
4. Generate summary report

### Individual Table Migration

```bash
./scripts/migration/tables/migrate-accounts.sh \
  mysql_host mysql_port mysql_db mysql_user mysql_pass \
  pg_host pg_port pg_db pg_user pg_pass
```

## Migration Order

Tables are migrated in this order to respect foreign key dependencies:

1. `accounts` - Base accounts
2. `users` - User accounts (references accounts)
3. `user_accounts` - User-account relationships
4. `suppliers_customers` - Supplier-customer relationships
5. `milk_sales` - Collections/sales (references accounts, users)
6. `products` - Market products
7. `product_categories` - Product categorization
8. `product_images` - Product images
9. `categories` - Feed categories
10. `orders` - Market orders
11. `order_items` - Order line items
12. `wallets` - User wallets
13. `notifications` - Notifications
14. `feed_posts` - Social feed posts
15. `feed_stories` - Feed stories
16. `feed_comments` - Post comments
17. `feed_interactions` - User interactions
18. `user_bookmarks` - Bookmarked posts
19. `user_relationships` - User follow relationships
20. `api_keys` - API keys
21. `password_resets` - Password reset tokens
22. `user_onboardings` - Onboarding tracking
23. `user_points` - Points system
24. `user_referrals` - Referral system
25. `user_rewards` - User rewards

## Key Features

### ID Mapping
- Old MySQL numeric IDs preserved in `legacy_id` field
- New UUIDs generated for all records
- Foreign keys automatically mapped to new UUIDs

### Data Preservation
- All original data preserved
- Tokens preserved for authentication continuity
- Timestamps preserved
- Relationships maintained

### Safety
- Uses `ON CONFLICT DO NOTHING` to prevent duplicates
- Can be run multiple times safely
- Validates row counts after migration

## Validation

After migration, verify:

1. **Row Counts**: Compare MySQL vs PostgreSQL
2. **Relationships**: Check foreign keys are correct
3. **Data Integrity**: Spot check sample records
4. **API Testing**: Test endpoints with migrated data

## Troubleshooting

### Connection Issues
- Verify MySQL credentials
- Verify PostgreSQL is accessible
- Check network/firewall settings

### Foreign Key Errors
- Ensure parent tables migrated first
- Check ID mapping is correct
- Verify legacy_id values match

### Data Type Issues
- Check date formats
- Verify decimal precision
- Check JSON/JSONB conversion

## Next Steps

After successful migration:

1. ✅ Verify data integrity
2. ✅ Test API endpoints
3. ✅ Update mobile app configuration
4. ✅ Monitor for issues
5. ✅ Archive old MySQL database

---

**Important**: Always backup both databases before running migration!

