# Gemura Backend Deployment Guide

## Prerequisites

- Docker and Docker Compose installed
- Access to the shared `devslab` PostgreSQL instance (running on port 5433)
- PostgreSQL password for `devslab` user

## Database Setup

The Gemura backend uses the **same PostgreSQL container** as ResolveIt v2, but with a **separate database** (`gemura_db`).

### Step 1: Create the Database

Run the database creation script on the server where the `devslab` Postgres is running:

```bash
cd backend/scripts
chmod +x create-database.sh
./create-database.sh
```

Or manually:

```bash
psql -h localhost -p 5433 -U devslab -d postgres -c "CREATE DATABASE gemura_db;"
psql -h localhost -p 5433 -U devslab -d gemura_db -c "GRANT ALL PRIVILEGES ON DATABASE gemura_db TO devslab;"
```

## Environment Configuration

1. Copy the example environment file:

```bash
cp .env.example .env
```

2. Edit `.env` and set:

```env
POSTGRES_PASSWORD=your_actual_password_here
```

## Docker Deployment

### Build and Start

```bash
docker-compose up -d --build
```

### View Logs

```bash
docker-compose logs -f backend
```

### Stop Services

```bash
docker-compose down
```

## Database Migrations

Migrations run automatically on container startup. To run manually:

```bash
docker-compose exec backend npx prisma migrate deploy
```

To generate a new migration:

```bash
docker-compose exec backend npx prisma migrate dev --name migration_name
```

## Port Configuration

- **Backend API**: `http://localhost:3002`
- **API Docs (Swagger)**: `http://localhost:3002/api/docs`
- **Frontend (future)**: `http://localhost:3003`
- **PostgreSQL**: `localhost:5433` (shared with ResolveIt)

**Port Allocation:**
- `3000`: ResolveIt Backend
- `3001`: ResolveIt Frontend
- `3002`: Gemura Backend API
- `3003`: Gemura Frontend (future)
- `3004-3010`: Reserved for Gemura services

## Health Check

```bash
curl http://localhost:3002/health
```

## API Endpoints

All API endpoints are prefixed with `/api`:

- `POST /api/auth/login` - User login
- `GET /api/accounts` - Get user accounts
- `POST /api/accounts/switch` - Switch default account
- `POST /api/suppliers/create` - Create/update supplier
- `POST /api/collections/create` - Record milk collection
- `POST /api/sales/sales` - Get sales list
- `PUT /api/sales/update` - Update sale
- `POST /api/sales/cancel` - Cancel sale
- `GET /api/wallets/get` - Get wallets
- `GET /api/profile/get` - Get profile
- `PUT /api/profile/update` - Update profile

## Troubleshooting

### Database Connection Issues

If the backend can't connect to Postgres:

1. Verify Postgres is running: `docker ps | grep postgres`
2. Check Postgres port: `netstat -an | grep 5433`
3. Test connection: `psql -h localhost -p 5433 -U devslab -d gemura_db`

### Port Conflicts

If port 3002 is already in use:

1. Change `BACKEND_PORT` in `.env` (use 3004-3010 range)
2. Update `docker-compose.yml` port mapping
3. Update `PORT` environment variable in docker-compose.yml
4. Restart: `docker-compose up -d`

### Migration Errors

If migrations fail:

1. Check database exists: `psql -h localhost -p 5433 -U devslab -l | grep gemura`
2. Check Prisma schema: `docker-compose exec backend npx prisma validate`
3. Reset database (WARNING: deletes all data):
   ```bash
   docker-compose exec backend npx prisma migrate reset
   ```

