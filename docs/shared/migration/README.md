# Migration Documentation

Data migration guides and procedures for migrating from legacy PHP/MySQL system to NestJS/PostgreSQL.

## 📚 Migration Guides

### Main Guides
- **[DATA_MIGRATION_GUIDE.md](./DATA_MIGRATION_GUIDE.md)** - Complete migration guide
- **[MIGRATION_PLAN.md](./MIGRATION_PLAN.md)** - Detailed migration plan
- **[DATA_MIGRATION_EXECUTION.md](./DATA_MIGRATION_EXECUTION.md)** - Migration execution steps

### Status Reports
- **[MIGRATION_PROGRESS.md](./MIGRATION_PROGRESS.md)** - Current migration progress
- **[MIGRATION_READY.md](./MIGRATION_READY.md)** - Migration readiness status
- **[DATA_MIGRATION_READY.md](./DATA_MIGRATION_READY.md)** - Data migration readiness

### Priority Documents
- **[MILK_SALES_PRIORITY.md](./MILK_SALES_PRIORITY.md)** - Milk sales migration priority

## 🚀 Migration Process

### Step 1: Preparation
1. Review [MIGRATION_PLAN.md](./MIGRATION_PLAN.md)
2. Check [MIGRATION_READY.md](./MIGRATION_READY.md)
3. Verify database backups

### Step 2: Execution
1. Follow [DATA_MIGRATION_GUIDE.md](./DATA_MIGRATION_GUIDE.md)
2. Run migration scripts
3. Verify data integrity

### Step 3: Verification
1. Check migration status
2. Verify data completeness
3. Test application functionality

## 📋 Migration Scripts

Migration scripts are located in `scripts/migration/`:

```bash
# Main migration script
./scripts/migration/migrate-data.sh

# Run on server
./scripts/migration/run-migration-on-server.sh

# Table-specific migrations
./scripts/migration/tables/migrate-users.sh
./scripts/migration/tables/migrate-accounts.sh
# ... etc
```

## ✅ Migration Status

See [MIGRATION_PROGRESS.md](./MIGRATION_PROGRESS.md) for current status.

## 🔗 Related Documentation

- [Testing Results](../testing/README.md) - Migration test results
- [API Documentation](../api/README.md) - API endpoints
- [Deployment Guide](../deployment/README.md) - Deployment procedures

---

**Last Updated:** January 18, 2026
