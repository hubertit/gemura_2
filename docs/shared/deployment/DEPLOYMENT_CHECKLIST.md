# Gemura Backend Deployment Checklist

## Pre-Deployment ✅

- [x] Port configuration (3004 backend, 3005 frontend)
- [x] Docker setup (docker-compose.yml, Dockerfile)
- [x] Prisma schema with all tables
- [x] All API modules implemented
- [x] Swagger documentation complete
- [x] Build successful
- [x] Deployment scripts created

## Server-Side Deployment Steps

### Step 1: Pre-Deployment Checks
```bash
# SSH to server
ssh user@159.198.65.38

# Navigate to project
cd /path/to/gemura2

# Run pre-deployment check
cd backend
./scripts/pre-deployment-check.sh
```

**Expected Results:**
- ✅ Ports 3004, 3005 available
- ✅ Database connection works
- ✅ Docker installed and running

### Step 2: Create Database
```bash
cd backend/scripts
export POSTGRES_PASSWORD=your_password
./create-database.sh
```

**Verify:**
```bash
psql -h localhost -p 5433 -U devslab -d gemura_db -c "SELECT 1;"
```

### Step 3: Configure Environment
```bash
cd /path/to/gemura2
cp .env.example .env
nano .env  # Edit with actual password
```

**Required in .env:**
```env
POSTGRES_PASSWORD=your_actual_password
POSTGRES_USER=devslab
POSTGRES_PORT=5433
POSTGRES_DB=gemura_db
BACKEND_PORT=3004
FRONTEND_PORT=3005
CORS_ORIGIN=http://159.198.65.38:3005,http://localhost:3005
```

### Step 4: Deploy
```bash
cd /path/to/gemura2
docker-compose up -d --build
```

**Watch logs:**
```bash
docker-compose logs -f backend
```

**Expected output:**
- ✅ Waiting for database...
- ✅ Prisma migrations running
- ✅ Starting Gemura API...
- ✅ 🚀 Gemura API running on http://localhost:3004

### Step 5: Verify Deployment

**Health Check:**
```bash
curl http://159.198.65.38:3004/health
```

**Expected Response:**
```json
{
  "status": "ok",
  "service": "Gemura API",
  "version": "2.0.0",
  "timestamp": "2025-01-04T..."
}
```

**API Docs:**
```bash
curl http://159.198.65.38:3004/api/docs
```

**Test Login (if you have test credentials):**
```bash
curl -X POST http://159.198.65.38:3004/api/auth/login \
  -H "Content-Type: application/json" \
  -d '{
    "identifier": "test@example.com",
    "password": "password123"
  }'
```

### Step 6: Check Database Migrations

```bash
docker-compose exec backend npx prisma migrate status
```

**Expected:** All migrations applied

## Post-Deployment Testing

### Test Endpoints

1. **Health Check**
   ```bash
   curl http://159.198.65.38:3004/health
   ```

2. **Swagger Docs**
   - Open: http://159.198.65.38:3004/api/docs
   - Verify all endpoints are documented

3. **Login Endpoint** (requires test user)
   ```bash
   curl -X POST http://159.198.65.38:3004/api/auth/login \
     -H "Content-Type: application/json" \
     -d '{"identifier": "email@example.com", "password": "password"}'
   ```

## Troubleshooting

### Container won't start
```bash
# Check logs
docker-compose logs backend

# Check container status
docker-compose ps

# Restart
docker-compose restart backend
```

### Database connection fails
```bash
# Test connection manually
psql -h localhost -p 5433 -U devslab -d gemura_db

# Check DATABASE_URL in .env
# Verify password is correct
```

### Migrations fail
```bash
# Check Prisma status
docker-compose exec backend npx prisma migrate status

# Reset if needed (WARNING: deletes data)
docker-compose exec backend npx prisma migrate reset
```

### Port conflicts
```bash
# Check what's using the port
./backend/scripts/test-ports-detailed.sh 159.198.65.38

# Update .env with different port
BACKEND_PORT=3006
```

## Success Criteria

- [ ] Health endpoint returns 200
- [ ] Swagger docs accessible
- [ ] Database migrations applied
- [ ] Container running without errors
- [ ] All endpoints documented in Swagger
- [ ] Can connect to database from container

## Next Steps After Deployment

1. Test all API endpoints via Swagger
2. Verify database schema matches Prisma schema
3. Test authentication flow
4. Deploy frontend web app (port 3005)
5. Set up monitoring and logging

