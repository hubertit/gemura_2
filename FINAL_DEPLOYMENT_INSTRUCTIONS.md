# 🚀 Final Deployment Instructions

## Complete Automated Deployment

On the server (159.198.65.38), run:

```bash
cd /path/to/gemura2
./backend/scripts/setup-and-deploy.sh
```

This single command will:
1. ✅ Check all prerequisites
2. ✅ Create the database
3. ✅ Generate Prisma Client
4. ✅ Build Docker images
5. ✅ Deploy services
6. ✅ Verify deployment
7. ✅ Check migrations

## What Gets Deployed

### Backend API (Port 3004)
- ✅ Authentication (login)
- ✅ Accounts management
- ✅ Suppliers management
- ✅ Milk collections
- ✅ Sales management
- ✅ Wallets
- ✅ User profiles
- ✅ Swagger API documentation

### Database
- ✅ PostgreSQL (shared with ResolveIt)
- ✅ Database: `gemura_db`
- ✅ User: `devslab`
- ✅ Port: `5433`

## Environment Setup

Before running deployment, ensure `.env` file exists:

```bash
cd /path/to/gemura2
cp .env.example .env
nano .env
```

Required variables:
```env
POSTGRES_PASSWORD=your_actual_password
POSTGRES_USER=devslab
POSTGRES_PORT=5433
POSTGRES_DB=gemura_db
BACKEND_PORT=3004
FRONTEND_PORT=3005
CORS_ORIGIN=http://159.198.65.38:3005,http://localhost:3005
```

## Verification

After deployment, verify:

1. **Health Check:**
   ```bash
   curl http://159.198.65.38:3004/health
   ```

2. **Swagger Docs:**
   Open browser: http://159.198.65.38:3004/api/docs

3. **Container Status:**
   ```bash
   docker-compose ps
   ```

4. **Logs:**
   ```bash
   docker-compose logs -f backend
   ```

## Troubleshooting

### Database Connection Issues
```bash
# Test connection
psql -h localhost -p 5433 -U devslab -d gemura_db

# Check if database exists
psql -h localhost -p 5433 -U devslab -d postgres -c "\l" | grep gemura
```

### Container Issues
```bash
# View logs
docker-compose logs backend

# Restart
docker-compose restart backend

# Rebuild
docker-compose up -d --build
```

### Migration Issues
```bash
# Check status
docker-compose exec backend npx prisma migrate status

# Apply manually
docker-compose exec backend npx prisma migrate deploy
```

## Post-Deployment

1. ✅ Test login endpoint
2. ✅ Verify all endpoints in Swagger
3. ✅ Check database tables
4. ✅ Test API with mobile app
5. ✅ Deploy frontend (port 3005)

## Support

- Check logs: `docker-compose logs -f backend`
- API Docs: http://159.198.65.38:3004/api/docs
- Health: http://159.198.65.38:3004/health

