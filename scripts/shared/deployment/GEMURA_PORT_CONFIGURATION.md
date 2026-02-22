# Gemura Port Configuration

**Final Configuration:** Ports 3004 and 3005 are reserved for Gemura

## Port Allocation

| Port | Service | Status |
|------|---------|--------|
| **3004** | Gemura Backend | ✅ Configured |
| **3005** | Gemura Frontend | ✅ Reserved (when ready) |

## Configuration

### Backend (Port 3004)
- **Container:** `gemura-backend`
- **Port Mapping:** `3004:3004`
- **Environment:** `PORT=3004`
- **API Base:** `http://159.198.65.38:3004/api`
- **Health Check:** `http://159.198.65.38:3004/api/health`
- **Swagger Docs:** `http://159.198.65.38:3004/api/docs`

### Frontend (Port 3005)
- **Container:** `gemura-frontend` (when deployed)
- **Port Mapping:** `3005:3005`
- **Environment:** `PORT=3005`
- **URL:** `http://159.198.65.38:3005`
- **API Base:** `http://159.198.65.38:3004/api`

## Deployment

The deployment script is now configured to use fixed ports:

```bash
./scripts/deployment/deploy-to-server.sh
```

This will:
- Deploy/update backend on port 3004
- Reserve port 3005 for frontend (when ready)
- Configure CORS for both ports
- Set up environment variables correctly

## Current Status

- ✅ Port 3004: Gemura Backend is already running
- ✅ Port 3005: Available and reserved for frontend

## Files Updated

1. `scripts/deployment/deploy-to-server.sh` - Fixed to use ports 3004/3005
2. `docker-compose.gemura.yml` - Port mapping set to 3004:3004
3. `.env.devlabs` - Will be created with BACKEND_PORT=3004, FRONTEND_PORT=3005

## Notes

- Ports are now fixed (no dynamic detection)
- Backend is already deployed on 3004
- Frontend port 3005 is reserved for future deployment
- CORS is configured for both ports
