# Gemura Backend Deployment Guide

## Quick Deployment Steps

### 1. Pre-Deployment Checks

Run on the server:

```bash
cd /path/to/gemura2/backend
./scripts/pre-deployment-check.sh
```

This will verify:
- Port availability (3004, 3005)
- Database connection
- Docker setup

### 2. Create Database

```bash
cd backend/scripts
export POSTGRES_PASSWORD=your_password_here
./create-database.sh
```

Or manually:
```bash
psql -h localhost -p 5433 -U devslab -d postgres -c "CREATE DATABASE gemura_db;"
psql -h localhost -p 5433 -U devslab -d gemura_db -c "GRANT ALL PRIVILEGES ON DATABASE gemura_db TO devslab;"
```

### 3. Configure Environment

```bash
cd /path/to/gemura2
cp .env.example .env
# Edit .env and set POSTGRES_PASSWORD
```

Required environment variables:
```env
POSTGRES_PASSWORD=your_actual_password
POSTGRES_USER=devslab
POSTGRES_PORT=5433
POSTGRES_DB=gemura_db
BACKEND_PORT=3004
FRONTEND_PORT=3005
```

### 4. Deploy with Docker

```bash
cd /path/to/gemura2
docker-compose up -d --build
```

### 5. Verify Deployment

```bash
# Check container status
docker-compose ps

# Check logs
docker-compose logs -f backend

# Test health endpoint
curl http://159.198.65.38:3004/health

# Test API docs
curl http://159.198.65.38:3004/api/docs
```

### 6. Run Migrations (if needed)

Migrations run automatically on startup. To run manually:

```bash
docker-compose exec backend npx prisma migrate deploy
```

## Troubleshooting

### Database Connection Issues

```bash
# Test connection
psql -h localhost -p 5433 -U devslab -d gemura_db

# Check if database exists
psql -h localhost -p 5433 -U devslab -d postgres -c "\l" | grep gemura
```

### Port Conflicts

```bash
# Check if ports are in use
./backend/scripts/test-ports-detailed.sh 159.198.65.38

# If port 3004 is in use, update .env:
BACKEND_PORT=3006  # or another available port
```

### View Logs

```bash
# Backend logs
docker-compose logs -f backend

# All services
docker-compose logs -f
```

### Restart Services

```bash
docker-compose restart backend
```

### Stop Services

```bash
docker-compose down
```

## API Endpoints

- **Backend API**: `http://159.198.65.38:3004`
- **API Docs**: `http://159.198.65.38:3004/api/docs`
- **Health Check**: `http://159.198.65.38:3004/health`

## Next Steps

After successful deployment:
1. Test login endpoint
2. Verify database migrations
3. Test all API endpoints
4. Deploy frontend web app (port 3005)

