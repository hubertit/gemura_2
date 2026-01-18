# 🚀 Gemura Deployment Guide

This guide follows the same deployment pattern as ResolveIt v2, which is proven to work well.

## 📋 Prerequisites

- Server access: `159.198.65.38`
- Docker and Docker Compose installed on server
- SSH access with password authentication

## 🏗️ Architecture

Gemura uses the **same shared DevLabs PostgreSQL** container as ResolveIt:
- **Database Container**: `devslab-postgres` (port 5433)
- **Database Name**: `gemura_db`
- **Network**: `devslab-network` (shared with ResolveIt)
- **Backend Port**: `3004`
- **Frontend Port**: `3005` (when ready)

## 📁 Deployment Files

### 1. `docker-compose.devlabs-db.yml`
Shared PostgreSQL container (same as ResolveIt). Only needs to be started once if not already running.

### 2. `docker-compose.gemura.yml`
Gemura application services (backend + frontend when ready). This is the main deployment file.

### 3. `.env.devlabs`
Environment variables file (created automatically by deployment script).

## 🚀 Quick Deployment

### Option 1: Automated Deployment Script (Recommended)

```bash
cd /path/to/gemura2
./scripts/deployment/deploy-to-server.sh
```

This script will:
1. ✅ Upload project files to server
2. ✅ Ensure DevLabs PostgreSQL is running
3. ✅ Create `gemura_db` database
4. ✅ Build and start Gemura containers
5. ✅ Run Prisma migrations

### Option 2: Manual Deployment

#### Step 1: Upload Files to Server

```bash
# On your local machine
cd /path/to/gemura2
tar --exclude='node_modules' --exclude='.next' --exclude='dist' \
    --exclude='.git' --exclude='*.log' --exclude='.env*' \
    --exclude='mobile' --exclude='build' \
    -czf /tmp/gemura-deploy.tar.gz .
scp /tmp/gemura-deploy.tar.gz root@159.198.65.38:/tmp/
ssh root@159.198.65.38 "cd /opt/gemura && tar -xzf /tmp/gemura-deploy.tar.gz && rm /tmp/gemura-deploy.tar.gz"
```

#### Step 2: Setup Database (if not already running)

```bash
ssh root@159.198.65.38
cd /opt/gemura

# Start DevLabs PostgreSQL (if not running)
docker compose -f docker-compose.devlabs-db.yml up -d

# Create Gemura database
docker exec -i devslab-postgres psql -U devslab_admin -d postgres << 'EOF'
SELECT 'CREATE DATABASE gemura_db'
WHERE NOT EXISTS (SELECT FROM pg_database WHERE datname = 'gemura_db')\gexec
GRANT ALL PRIVILEGES ON DATABASE gemura_db TO devslab_admin;
EOF
```

#### Step 3: Create Environment File

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

#### Step 4: Build and Start

```bash
# Build containers
docker compose -f docker-compose.gemura.yml --env-file .env.devlabs build

# Start containers
docker compose -f docker-compose.gemura.yml --env-file .env.devlabs up -d

# Check status
docker compose -f docker-compose.gemura.yml ps
```

## ✅ Verification

After deployment, verify everything is working:

```bash
# Health check
curl http://159.198.65.38:3004/api/health

# API docs
curl http://159.198.65.38:3004/api/docs

# Check logs
docker compose -f docker-compose.gemura.yml logs -f backend
```

## 🔧 Management Commands

### View Logs
```bash
ssh root@159.198.65.38 'cd /opt/gemura && docker compose -f docker-compose.gemura.yml logs -f'
```

### Restart Services
```bash
ssh root@159.198.65.38 'cd /opt/gemura && docker compose -f docker-compose.gemura.yml restart'
```

### Stop Services
```bash
ssh root@159.198.65.38 'cd /opt/gemura && docker compose -f docker-compose.gemura.yml down'
```

### Update and Redeploy
```bash
# Run deployment script again (it will rebuild and restart)
./scripts/deployment/deploy-to-server.sh
```

## 📊 Service URLs

- **Backend API**: http://159.198.65.38:3004/api
- **API Docs**: http://159.198.65.38:3004/api/docs
- **Health Check**: http://159.198.65.38:3004/api/health

## 🔐 Database Credentials

- **Host**: localhost:5433 (from server) or 159.198.65.38:5433 (external)
- **User**: devslab_admin
- **Password**: devslab_secure_password_2024
- **Database**: gemura_db

## 🆚 Comparison with ResolveIt

| Aspect | ResolveIt | Gemura |
|--------|-----------|--------|
| Backend Port | 3000 | 3004 |
| Frontend Port | 3001 | 3005 |
| Database | resolveit_db | gemura_db |
| Network | devslab-network | devslab-network |
| PostgreSQL | devslab-postgres:5432 | devslab-postgres:5432 |
| Deployment Path | /opt/resolveit | /opt/gemura |

Both applications share the same PostgreSQL container and Docker network.

## 🐛 Troubleshooting

### Database Connection Issues
```bash
# Test connection
docker exec -it devslab-postgres psql -U devslab_admin -d gemura_db

# Check if database exists
docker exec -it devslab-postgres psql -U devslab_admin -d postgres -c "\l"
```

### Container Issues
```bash
# View logs
docker compose -f docker-compose.gemura.yml logs backend

# Restart
docker compose -f docker-compose.gemura.yml restart backend

# Rebuild
docker compose -f docker-compose.gemura.yml --env-file .env.devlabs up -d --build
```

### Migration Issues
```bash
# Check migration status
docker compose -f docker-compose.gemura.yml exec backend npx prisma migrate status

# Apply migrations manually
docker compose -f docker-compose.gemura.yml exec backend npx prisma migrate deploy
```

## 📝 Notes

- The deployment follows the exact same pattern as ResolveIt v2
- Both applications can run simultaneously on the same server
- They share the PostgreSQL container but use separate databases
- Ports are configured to avoid conflicts (ResolveIt: 3000/3001, Gemura: 3004/3005)

