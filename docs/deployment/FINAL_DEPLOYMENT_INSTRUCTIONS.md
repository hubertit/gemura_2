# 🚀 Final Deployment Instructions

## Complete Automated Deployment

**This deployment follows the same proven pattern as ResolveIt v2.**

### Option 1: Automated Deployment Script (Recommended)

From your local machine:

```bash
cd /path/to/gemura2
./scripts/deployment/deploy-to-server.sh
```

This single command will:
1. ✅ Upload project files to server
2. ✅ Ensure DevLabs PostgreSQL is running (shared with ResolveIt)
3. ✅ Create the `gemura_db` database
4. ✅ Build Docker images
5. ✅ Deploy services
6. ✅ Run Prisma migrations
7. ✅ Verify deployment

### Option 2: Manual Deployment on Server

On the server (159.198.65.38), run:

```bash
cd /opt/gemura

# Ensure DevLabs PostgreSQL is running (if not already)
docker compose -f docker-compose.devlabs-db.yml up -d

# Create Gemura database
docker exec -i devslab-postgres psql -U devslab_admin -d postgres << 'EOF'
SELECT 'CREATE DATABASE gemura_db'
WHERE NOT EXISTS (SELECT FROM pg_database WHERE datname = 'gemura_db')\gexec
GRANT ALL PRIVILEGES ON DATABASE gemura_db TO devslab_admin;
EOF

# Create .env.devlabs file
cat > .env.devlabs << 'EOF'
POSTGRES_USER=devslab_admin
POSTGRES_PASSWORD=devslab_secure_password_2024
POSTGRES_DB=postgres
POSTGRES_PORT=5433
BACKEND_PORT=3004
FRONTEND_PORT=3005
CORS_ORIGIN=http://localhost:3005,http://localhost:3004,http://159.198.65.38:3005,http://159.198.65.38:3004
NEXT_PUBLIC_API_BASE=http://159.198.65.38:3004/api
DATABASE_URL=postgresql://devslab_admin:devslab_secure_password_2024@devslab-postgres:5432/gemura_db
EOF

# Build and start
docker compose -f docker-compose.gemura.yml --env-file .env.devlabs build
docker compose -f docker-compose.gemura.yml --env-file .env.devlabs up -d
```

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
- ✅ Health check endpoint

### Database
- ✅ PostgreSQL (shared with ResolveIt via `devslab-postgres` container)
- ✅ Database: `gemura_db`
- ✅ User: `devslab_admin`
- ✅ Port: `5433` (host), `5432` (container)
- ✅ Network: `devslab-network` (shared with ResolveIt)

## Environment Setup

The deployment script automatically creates `.env.devlabs` on the server. If deploying manually, create it with:

```bash
cat > .env.devlabs << 'EOF'
# DevLabs PostgreSQL Configuration
POSTGRES_USER=devslab_admin
POSTGRES_PASSWORD=devslab_secure_password_2024
POSTGRES_DB=postgres
POSTGRES_PORT=5433

# Gemura Configuration
BACKEND_PORT=3004
FRONTEND_PORT=3005
CORS_ORIGIN=http://localhost:3005,http://localhost:3004,http://159.198.65.38:3005,http://159.198.65.38:3004
NEXT_PUBLIC_API_BASE=http://159.198.65.38:3004/api

# Database connection for Gemura backend
DATABASE_URL=postgresql://devslab_admin:devslab_secure_password_2024@devslab-postgres:5432/gemura_db
EOF
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
# Test connection (from server)
docker exec -it devslab-postgres psql -U devslab_admin -d gemura_db

# Check if database exists
docker exec -it devslab-postgres psql -U devslab_admin -d postgres -c "\l" | grep gemura

# External connection (if port 5433 is accessible)
psql -h 159.198.65.38 -p 5433 -U devslab_admin -d gemura_db
```

### Container Issues
```bash
# View logs
docker compose -f docker-compose.gemura.yml logs -f backend

# Restart
docker compose -f docker-compose.gemura.yml restart backend

# Rebuild
docker compose -f docker-compose.gemura.yml --env-file .env.devlabs up -d --build
```

### Migration Issues
```bash
# Check status
docker compose -f docker-compose.gemura.yml exec backend npx prisma migrate status

# Apply manually
docker compose -f docker-compose.gemura.yml exec backend npx prisma migrate deploy
```

## Post-Deployment

1. ✅ Test login endpoint
2. ✅ Verify all endpoints in Swagger
3. ✅ Check database tables
4. ✅ Test API with mobile app
5. ✅ Deploy frontend (port 3005)

## Support

- Check logs: `docker compose -f docker-compose.gemura.yml logs -f backend`
- API Docs: http://159.198.65.38:3004/api/docs
- Health: http://159.198.65.38:3004/api/health

## Deployment Pattern

This deployment follows the **exact same pattern as ResolveIt v2**:
- ✅ Uses shared `devslab-postgres` PostgreSQL container
- ✅ Uses shared `devslab-network` Docker network
- ✅ Separate docker-compose files for database and application
- ✅ Environment variables in `.env.devlabs` file
- ✅ Automated deployment script
- ✅ Same security and configuration patterns

**Key Differences from ResolveIt:**
- ResolveIt: Ports 3000 (backend), 3001 (frontend)
- Gemura: Ports 3004 (backend), 3005 (frontend)
- Both share the same PostgreSQL container but use separate databases

