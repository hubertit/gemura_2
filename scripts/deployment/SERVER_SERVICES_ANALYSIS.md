# Server Services Analysis - 159.198.65.38

**Analysis Date:** January 17, 2026  
**Method:** SSH + Docker inspection

## All Running Services

### Docker Containers

| Container Name | Image | Port | Status | Uptime | Service |
|---------------|-------|------|--------|--------|---------|
| **gemura-backend** | gemura-backend:latest | **3004** | Healthy | 7 days | ✅ **Gemura Backend** |
| resolveit-backend | 2266408b1d15 | 3000 | Healthy | 5 days | ResolveIt Backend |
| resolveit-frontend | resolveit-frontend | 3001 | Healthy | 5 days | ResolveIt Frontend |
| **zoea-backend** | zoeaevents-backend:latest | **3002** | Healthy | 7 days | Zoea Events Backend |
| **be7aa6eadb17_zoea-admin** | zoea-admin-admin | **3010** | Healthy | 6 days | Zoea Admin Frontend |
| ihuzo-finance-backend-nestjs | backend-backend:latest | 8080 | Starting | < 1 sec | Finance Backend |
| devslab-postgres | postgres:15-alpine | 5433 | Healthy | 7 days | Shared PostgreSQL |

## Port Allocation

### Ports 3000-3020

| Port | Service | Container | Status | Notes |
|------|---------|-----------|--------|-------|
| **3000** | ResolveIt Backend | resolveit-backend | ✅ Running | Has error (HTTP 500) |
| **3001** | ResolveIt Frontend | resolveit-frontend | ✅ Running | Working |
| **3002** | Zoea Events Backend | zoea-backend | ✅ Running | Working |
| **3003** | - | - | ✅ **AVAILABLE** | **Recommended for Gemura** |
| **3004** | **Gemura Backend** | **gemura-backend** | ✅ **Running** | **Already deployed!** |
| **3005** | - | - | ✅ **AVAILABLE** | Available |
| **3006-3009** | - | - | ✅ **AVAILABLE** | Available |
| **3010** | Zoea Admin Frontend | be7aa6eadb17_zoea-admin | ✅ Running | Working |
| **3011-3020** | - | - | ✅ **AVAILABLE** | Available |

## Service Details

### Gemura Backend (Port 3004) ✅

**Container:** `gemura-backend`  
**Image:** `gemura-backend:latest`  
**Status:** Healthy, running for 7 days  
**Location:** `/opt/gemura/`  
**Configuration:**
- Uses `docker-compose.gemura.yml`
- Environment: `NODE_ENV=production`, `PORT=3004`
- Database: `postgresql://devslab_admin:...@devslab-postgres:5432/gemura_db`
- Health check: ✅ Working (`/api/health` returns OK)
- Swagger docs: ✅ Available at `/api/docs`

**Conclusion:** Gemura is already deployed and running on port 3004!

### ResolveIt Services

**Backend (3000):**
- Container: `resolveit-backend`
- Status: Running but has HTTP 500 error
- Location: `/opt/resolveit/`

**Frontend (3001):**
- Container: `resolveit-frontend`
- Status: Healthy, working

### Zoea Events Services

**Backend (3002):**
- Container: `zoea-backend`
- Image: `zoeaevents-backend:latest`
- Status: Healthy, running for 7 days
- This explains the HTTP 404 on port 3002 - it's a backend that requires specific endpoints

**Admin Frontend (3010):**
- Container: `be7aa6eadb17_zoea-admin`
- Image: `zoea-admin-admin`
- Status: Healthy, running for 6 days
- This is the frontend we saw responding with HTML

### Finance Backend (Port 8080)

**Container:** `ihuzo-finance-backend-nestjs`  
**Image:** `backend-backend:latest`  
**Port:** 8080 (outside our test range)  
**Status:** Just started (health: starting)  
**Location:** `/opt/finance/`

## Directory Structure

```
/opt/
├── gemura/          # Gemura deployment (port 3004)
│   ├── .env.devlabs
│   └── docker-compose.gemura.yml
├── resolveit/       # ResolveIt deployment (ports 3000, 3001)
│   └── .env.devlabs
├── finance/         # Finance backend (port 8080)
│   └── backend/
└── zoeaEvents/      # Zoea Events (ports 3002, 3010)
    ├── .env.devlabs
    └── docker-compose.zoea.yml
```

## Recommendations

### For Gemura Deployment

**Option 1: Keep Current Deployment (Port 3004)**
- ✅ Gemura is already deployed and working
- Health check is passing
- Swagger docs are accessible
- **Action:** Update/redeploy if you need to push new code

**Option 2: Deploy to New Port (Port 3003)**
- Port 3003 is the first available port
- Would allow keeping old version on 3004 for testing
- **Action:** Run `./scripts/deployment/deploy-to-server.sh 3003`

### Available Ports Summary

**Recommended for new services:**
- **3003** ⭐ (First available, recommended)
- 3005-3009 (Available)
- 3011-3020 (Available)

## Database

**Shared PostgreSQL Container:**
- Container: `devslab-postgres`
- Port: 5433 (host) → 5432 (container)
- Status: Healthy, running for 7 days
- Used by: ResolveIt, Gemura, and potentially other services

## Next Steps

1. **If keeping port 3004:**
   - Verify it's the correct version
   - Update/redeploy if needed: `./scripts/deployment/deploy-to-server.sh 3004`

2. **If deploying to new port:**
   - Use port 3003: `./scripts/deployment/deploy-to-server.sh 3003`

3. **To check current Gemura version:**
   ```bash
   sshpass -p 'QF87VtuYReX5v9p6e3' ssh root@159.198.65.38 'docker logs gemura-backend --tail 50'
   ```
