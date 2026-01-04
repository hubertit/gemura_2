# Deployment Scripts

## Pre-Deployment Checks

### Complete Pre-Deployment Check

Run all checks before deploying:

```bash
cd backend
./scripts/pre-deployment-check.sh
```

This will check:
- Port availability (3100, 3101, etc.)
- Database connection
- Docker setup
- Node.js/Prisma (optional)

### Check Port Availability

Check if required ports are available:

```bash
./scripts/check-ports.sh
```

Checks:
- Port 3100 (Gemura Backend)
- Port 3101 (Gemura Frontend)
- Port 3000, 3001, 5433 (ResolveIt - should be in use)
- Common ports (80, 443, 3306, 5432, 8080)

### Check Database Connection

Verify database connection and check if `gemura_db` exists:

```bash
# Set environment variables first
export POSTGRES_PASSWORD=your_password
./scripts/check-database.sh
```

Or load from .env:
```bash
export $(cat .env | grep -v '^#' | xargs)
./scripts/check-database.sh
```

## Database Setup

### Create Database

Creates the `gemura_db` database on the shared devslab Postgres instance.

```bash
./scripts/create-database.sh
```

Or with custom settings:
```bash
DB_HOST=localhost DB_PORT=5433 DB_USER=devslab DB_NAME=gemura_db ./scripts/create-database.sh
```

## Environment Variables

- `POSTGRES_HOST` - Postgres host (default: localhost)
- `POSTGRES_PORT` - Postgres port (default: 5433)
- `POSTGRES_USER` - Postgres user (default: devslab)
- `POSTGRES_PASSWORD` - Postgres password (required)
- `POSTGRES_DB` - Database name (default: gemura_db)

## Prerequisites

- PostgreSQL client tools installed (`psql`)
- Access to devslab Postgres instance
- User `devslab` has CREATE DATABASE privileges
- Port checking tools: `netstat`, `ss`, or `lsof` (at least one)

