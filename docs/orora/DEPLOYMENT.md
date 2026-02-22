# Orora Deployment Guide

## Overview

This guide covers deploying the Orora platform to production on the Kwezi server.

---

## Server Information

| Property | Value |
|----------|-------|
| Server IP | 209.74.80.195 |
| Server Name | Kwezi Server |
| OS | Ubuntu Linux |
| SSH User | root |

### Port Allocation

| Port | Service | Status |
|------|---------|--------|
| 3006 | Gemura Web | Active |
| 3007 | Gemura/Orora Backend API | Active |
| 3011 | Orora Web | Active |
| 5432 | PostgreSQL (kwezi-postgres) | Active |

---

## Prerequisites

### Local Machine

- Node.js 18+
- Docker (optional, for local testing)
- `sshpass` for deployment scripts
- Git access to repository

### Server

- Docker and Docker Compose
- PostgreSQL container (kwezi-postgres)
- Network access to ports 3006, 3007, 3011

---

## Quick Deploy

### Deploy Everything

```bash
# From project root
./scripts/gemura/deployment/deploy-gemura.sh    # Backend + Gemura Web
./scripts/orora/deployment/deploy-orora-web.sh  # Orora Web
```

### Deploy Individual Components

```bash
# Orora Web only
./scripts/orora/deployment/deploy-orora-web.sh

# Gemura (Backend + Web)
./scripts/gemura/deployment/deploy-gemura.sh

# Safe deploy (no DB changes)
./scripts/shared/deployment/deploy-gemura-only-safe.sh
```

---

## Deployment Scripts

### Orora Web Deployment

**Script:** `scripts/orora/deployment/deploy-orora-web.sh`

**What it does:**
1. Creates archive of Orora Web files
2. Uploads to server via SCP
3. Extracts on server
4. Builds Docker image
5. Starts container on port 3011
6. Verifies deployment

**Usage:**
```bash
cd /path/to/orora
./scripts/orora/deployment/deploy-orora-web.sh
```

### Gemura Deployment

**Script:** `scripts/gemura/deployment/deploy-gemura.sh`

**What it does:**
1. Creates archive of backend + Gemura Web
2. Uploads to server
3. Builds Docker images (backend + frontend)
4. Starts containers (API on 3007, Web on 3006)
5. Runs database migrations
6. Verifies deployment

**Usage:**
```bash
cd /path/to/orora
./scripts/gemura/deployment/deploy-gemura.sh
```

---

## Manual Deployment

### Step 1: Build Locally (Optional)

```bash
# Backend
cd backend
npm install
npm run build

# Orora Web
cd apps/orora-web
npm install
npm run build
```

### Step 2: Create Archive

```bash
cd /path/to/orora
tar -czf deploy.tar.gz \
  --exclude='node_modules' \
  --exclude='.next' \
  --exclude='dist' \
  backend/ apps/orora-web/ docker/
```

### Step 3: Upload to Server

```bash
scp deploy.tar.gz root@209.74.80.195:/opt/orora/
```

### Step 4: Extract on Server

```bash
ssh root@209.74.80.195
cd /opt/orora
tar -xzf deploy.tar.gz
rm deploy.tar.gz
```

### Step 5: Build and Start

```bash
# On server
cd /opt/orora

# Orora Web
docker compose -f docker/docker-compose.orora-web.yml build
docker compose -f docker/docker-compose.orora-web.yml up -d

# Backend + Gemura Web
docker compose -f docker/docker-compose.kwezi.yml build
docker compose -f docker/docker-compose.kwezi.yml up -d
```

---

## Docker Compose Files

### Orora Web

**File:** `docker/docker-compose.orora-web.yml`

```yaml
version: '3.8'
services:
  orora-ui:
    build:
      context: ../apps/orora-web
      dockerfile: Dockerfile
    container_name: orora-ui
    restart: unless-stopped
    ports:
      - "3011:3000"
    environment:
      - NODE_ENV=production
      - NEXT_PUBLIC_API_URL=http://209.74.80.195:3007/api
    networks:
      - orora-network

networks:
  orora-network:
    driver: bridge
```

### Gemura (Backend + Web)

**File:** `docker/docker-compose.kwezi.yml`

```yaml
version: '3.8'
services:
  backend:
    build:
      context: ../backend
      dockerfile: Dockerfile
    container_name: gemura-backend
    restart: unless-stopped
    ports:
      - "3007:3007"
    environment:
      - DATABASE_URL=${DATABASE_URL}
      - JWT_SECRET=${JWT_SECRET}
      - NODE_ENV=production
    networks:
      - kwezi-network
    depends_on:
      - kwezi-postgres

  gemura-ui:
    build:
      context: ../apps/gemura-web
      dockerfile: Dockerfile
    container_name: gemura-ui
    restart: unless-stopped
    ports:
      - "3006:3000"
    environment:
      - NEXT_PUBLIC_API_URL=http://209.74.80.195:3007/api
    networks:
      - kwezi-network

networks:
  kwezi-network:
    external: true
```

---

## Environment Variables

### Backend (.env)

```bash
# Database
DATABASE_URL=postgresql://kwezi:password@kwezi-postgres:5432/gemura_db?schema=public

# Auth
JWT_SECRET=your-secret-key
JWT_EXPIRES_IN=7d

# Server
API_PORT=3007
CORS_ORIGIN=http://209.74.80.195:3006,http://209.74.80.195:3011

# Node
NODE_ENV=production
```

### Orora Web (.env.production)

```bash
NEXT_PUBLIC_API_URL=http://209.74.80.195:3007/api
```

### Gemura Web (.env.production)

```bash
NEXT_PUBLIC_API_URL=http://209.74.80.195:3007/api
```

---

## Database Operations

### Run Migrations

```bash
# SSH to server
ssh root@209.74.80.195

# Enter backend container
docker exec -it gemura-backend sh

# Run migrations
npx prisma migrate deploy

# Or from local (with DB access)
cd backend
DATABASE_URL="postgresql://..." npx prisma migrate deploy
```

### Backup Database

```bash
# On server
docker exec kwezi-postgres pg_dump -U kwezi gemura_db > /opt/backups/gemura_$(date +%Y%m%d).sql

# Download to local
scp root@209.74.80.195:/opt/backups/gemura_*.sql ./backups/
```

### Restore Database

```bash
# Upload backup
scp backup.sql root@209.74.80.195:/tmp/

# Restore
docker exec -i kwezi-postgres psql -U kwezi gemura_db < /tmp/backup.sql
```

---

## Monitoring

### Check Container Status

```bash
ssh root@209.74.80.195 "docker ps --format 'table {{.Names}}\t{{.Status}}\t{{.Ports}}'"
```

### View Logs

```bash
# Orora Web
ssh root@209.74.80.195 "docker logs orora-ui --tail 100 -f"

# Backend
ssh root@209.74.80.195 "docker logs gemura-backend --tail 100 -f"

# Gemura Web
ssh root@209.74.80.195 "docker logs gemura-ui --tail 100 -f"
```

### Health Checks

```bash
# Backend API
curl http://209.74.80.195:3007/api/health

# Orora Web
curl -I http://209.74.80.195:3011/auth/login

# Gemura Web
curl -I http://209.74.80.195:3006/auth/login
```

---

## Troubleshooting

### Container Won't Start

```bash
# Check logs
docker logs orora-ui

# Check if port is in use
netstat -tlnp | grep 3011

# Rebuild container
docker compose -f docker/docker-compose.orora-web.yml build --no-cache
docker compose -f docker/docker-compose.orora-web.yml up -d
```

### Database Connection Failed

```bash
# Check PostgreSQL is running
docker ps | grep postgres

# Test connection
docker exec kwezi-postgres psql -U kwezi -d gemura_db -c "SELECT 1"

# Check DATABASE_URL in .env
```

### API Not Responding

```bash
# Check backend container
docker ps | grep gemura-backend

# Check logs
docker logs gemura-backend --tail 50

# Restart backend
docker restart gemura-backend
```

### Deployment Script Fails

```bash
# Check SSH connectivity
ssh root@209.74.80.195 "echo OK"

# Check credentials file
cat scripts/shared/deployment/server-credentials.sh

# Run with debug
bash -x ./scripts/orora/deployment/deploy-orora-web.sh
```

---

## Rollback

### Quick Rollback

```bash
# SSH to server
ssh root@209.74.80.195

# Stop current container
docker stop orora-ui

# Start previous image (if available)
docker run -d --name orora-ui-old -p 3011:3000 orora-ui:previous
```

### Restore from Backup

1. Stop containers
2. Restore database from backup
3. Deploy previous code version
4. Start containers

---

## Security

### Firewall Rules

```bash
# Allow only necessary ports
ufw allow 22/tcp    # SSH
ufw allow 3006/tcp  # Gemura Web
ufw allow 3007/tcp  # Backend API
ufw allow 3011/tcp  # Orora Web
```

### SSL/HTTPS (Future)

For production with custom domain:
1. Set up Nginx as reverse proxy
2. Install Let's Encrypt SSL certificates
3. Configure HTTPS redirects

---

## CI/CD (Future)

### GitHub Actions Workflow

```yaml
name: Deploy Orora

on:
  push:
    branches: [main]
    paths:
      - 'apps/orora-web/**'

jobs:
  deploy:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      
      - name: Deploy to server
        env:
          SERVER_PASS: ${{ secrets.SERVER_PASS }}
        run: |
          ./scripts/orora/deployment/deploy-orora-web.sh
```

---

## Useful Commands

### Restart All Services

```bash
ssh root@209.74.80.195 << 'EOF'
docker restart gemura-backend gemura-ui orora-ui
EOF
```

### Clean Up Docker

```bash
ssh root@209.74.80.195 << 'EOF'
docker system prune -f
docker image prune -f
EOF
```

### Check Disk Space

```bash
ssh root@209.74.80.195 "df -h"
```

### Check Memory Usage

```bash
ssh root@209.74.80.195 "free -h && docker stats --no-stream"
```
