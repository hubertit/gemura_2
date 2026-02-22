# Finance Project Port Configuration

**Project Location:** `/Applications/AMPPS/www/finance`  
**Analysis Date:** January 17, 2026

## Port Configuration

### Backend Port: **8080**

**Configuration:**
- **Docker Compose:** `docker-compose.devlabs.yml`
- **Port Mapping:** `${BACKEND_PORT:-8080}:8080`
- **Internal Port:** `SERVER_PORT=8080`
- **Container Name:** `ihuzo-finance-backend-nestjs`
- **Image:** `backend-backend:latest`

**Environment Variables:**
```env
SERVER_PORT=8080
BACKEND_PORT=8080
```

## Current Status on Server

**Container Status:**
- **Container:** `ihuzo-finance-backend-nestjs`
- **Port:** `0.0.0.0:8080->8080/tcp`
- **Status:** Running (but health check not responding)

**Note:** Port 8080 is **outside** the 3000-3020 range we're testing for Gemura.

## API Endpoints

Based on configuration files:
- **API Base:** `http://159.198.65.38:8080/api/v1`
- **Health Check:** `http://159.198.65.38:8080/api/v1/health`
- **Swagger Docs:** `http://159.198.65.38:8080/api/v1/docs`

## Database Configuration

**Uses Shared DevLabs PostgreSQL:**
- **Host:** `devslab-postgres` (shared container)
- **Port:** `5432` (internal), `5433` (external)
- **Database:** `ihuzo_finance`
- **User:** `devslab_admin`

## Summary

| Item | Value |
|------|-------|
| **Backend Port** | **8080** |
| **Container** | `ihuzo-finance-backend-nestjs` |
| **Status** | Running (health check may be starting) |
| **Port Range** | Outside 3000-3020 (no conflict with Gemura) |

## Notes

- Port 8080 is **NOT** in the 3000-3020 range
- No conflict with Gemura deployment ports
- Finance project uses port 8080 (Spring Boot default)
- Uses same shared DevLabs PostgreSQL as other projects
