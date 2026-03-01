# Deploy Backend - Quick Guide

## The backend is currently DOWN

Based on curl tests, the backend at `http://159.198.65.38:3004` is not responding.

## Quick Deployment Steps

### Option 1: Deploy via SSH (Recommended)

1. **SSH into the server:**
   ```bash
   ssh root@159.198.65.38
   # Password: QF87VtuYReX5v9p6e3
   ```

2. **Navigate to project directory:**
   ```bash
   cd /opt/gemura
   ```

3. **Run deployment script:**
   ```bash
   ./scripts/deploy-backend.sh
   ```

   Or if script is not there, run manually:
   ```bash
   # Stop existing containers
   docker-compose -f docker-compose.gemura.yml down
   
   # Build and start
   docker-compose -f docker-compose.gemura.yml build --no-cache
   docker-compose -f docker-compose.gemura.yml up -d
   
   # Check status
   docker ps | grep gemura-backend
   docker-compose -f docker-compose.gemura.yml logs backend
   ```

### Option 2: Use Remote Deployment Script

From your local machine:
```bash
cd /Users/macbookpro/projects/flutter/gemura2
./scripts/deployment/deploy-to-server.sh
```

This script will:
- Upload files to server
- Setup PostgreSQL if needed
- Build and deploy backend
- Verify deployment

## Manual Deployment Commands

If you're already on the server:

```bash
# 1. Navigate to project
cd /opt/gemura

# 2. Check if DevLabs PostgreSQL is running
docker ps | grep devslab-postgres

# 3. Stop existing backend
docker-compose -f docker-compose.gemura.yml down

# 4. Build backend
docker-compose -f docker-compose.gemura.yml build --no-cache backend

# 5. Start backend
docker-compose -f docker-compose.gemura.yml up -d backend

# 6. Check logs
docker-compose -f docker-compose.gemura.yml logs -f backend

# 7. Test health endpoint
curl http://localhost:3004/api/health
```

## Verify Deployment

After deployment, test from your local machine:

```bash
# Test health endpoint
curl http://159.198.65.38:3004/api/health

# Test API docs
curl http://159.198.65.38:3004/api/docs

# Test login (should work now)
curl -X POST http://159.198.65.38:3004/api/auth/login \
  -H "Content-Type: application/json" \
  -d '{"identifier": "250788606765", "password": "Pass123"}'
```

## Troubleshooting

### Container won't start
```bash
# Check logs
docker-compose -f docker-compose.gemura.yml logs backend

# Check container status
docker ps -a | grep gemura-backend

# Restart container
docker-compose -f docker-compose.gemura.yml restart backend
```

### Database connection issues
```bash
# Check if PostgreSQL is running
docker ps | grep devslab-postgres

# Test database connection from backend container
docker exec -it gemura-backend ping devslab-postgres
```

### Port already in use
```bash
# Find what's using port 3004
lsof -i :3004
# or
netstat -tuln | grep 3004

# Kill the process or change port in docker-compose.gemura.yml
```

## Expected Result

After successful deployment:
- ✅ Container `gemura-backend` should be running
- ✅ Health endpoint should return HTTP 200
- ✅ API docs should be accessible
- ✅ Login endpoint should work

---

**Status**: Backend is DOWN - needs deployment
