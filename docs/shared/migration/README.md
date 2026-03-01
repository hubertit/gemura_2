# Migration Documentation

Data migration guides and procedures for migrating from legacy PHP/MySQL system to NestJS/PostgreSQL.

## 📚 Migration Guides

### Main Guides
- **[data-migration-guide.md](./data-migration-guide.md)** - Complete migration guide
- **[migration-plan.md](./migration-plan.md)** - Detailed migration plan
- **[data-migration-execution.md](./data-migration-execution.md)** - Migration execution steps

### Status Reports
- **[migration-progress.md](./migration-progress.md)** - Current migration progress
- **[migration-ready.md](./migration-ready.md)** - Migration readiness status
- **[data-migration-ready.md](./data-migration-ready.md)** - Data migration readiness

### Priority Documents
- **[milk-sales-priority.md](./milk-sales-priority.md)** - Milk sales migration priority

## 🚀 Migration Process

### Step 1: Preparation
1. Review [migration-plan.md](./migration-plan.md)
2. Check [migration-ready.md](./migration-ready.md)
3. Verify database backups

### Step 2: Execution
1. Follow [data-migration-guide.md](./data-migration-guide.md)
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

See [migration-progress.md](./migration-progress.md) for current status.

## 🔗 Related Documentation

- [Testing Results](../testing/README.md) - Migration test results
- [API Documentation](../api/README.md) - API endpoints
- [Deployment Guide](../deployment/README.md) - Deployment procedures

---

**Last Updated:** January 18, 2026
