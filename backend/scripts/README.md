# Database Setup Scripts

## Create Database

Creates the `gemura_db` database on the shared devslab Postgres instance.

```bash
./scripts/create-database.sh
```

Or with custom settings:
```bash
DB_HOST=localhost DB_PORT=5433 DB_USER=devslab DB_NAME=gemura_db ./scripts/create-database.sh
```

## Environment Variables

- `DB_HOST` - Postgres host (default: localhost)
- `DB_PORT` - Postgres port (default: 5433)
- `DB_USER` - Postgres user (default: devslab)
- `DB_NAME` - Database name (default: gemura_db)

## Prerequisites

- PostgreSQL client tools installed
- Access to devslab Postgres instance
- User `devslab` has CREATE DATABASE privileges

