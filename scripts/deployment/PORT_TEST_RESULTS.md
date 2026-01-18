# Port Test Results - 159.198.65.38

**Test Date:** January 17, 2026  
**Test Range:** 3000-3020  
**Test Method:** CURL requests with response analysis

## Port Status Summary

### ✅ Ports Responding (IN USE)

| Port | Status | Service | Details |
|------|--------|---------|---------|
| **3000** | HTTP 500 | ResolveIt Backend | Internal server error - service running but has issues |
| **3001** | HTTP 200 | ResolveIt Frontend | HTML response - Next.js frontend |
| **3002** | HTTP 404 | Unknown Backend | Service running, returns 404 for root path |
| **3004** | HTTP 200 | **Gemura Backend** | ✅ **Already deployed!** Health check works, Swagger docs available |
| **3010** | HTTP 200 | Unknown Frontend | HTML response - Next.js frontend |

### ✅ Ports Available (NO RESPONSE)

**Recommended ports for new services:**
- **3003** ⭐ (First available)
- 3005
- 3006
- 3007
- 3008
- 3009
- 3011
- 3012
- 3013
- 3014
- 3015
- 3016
- 3017
- 3018
- 3019
- 3020

## Detailed Findings

### Port 3000 - ResolveIt Backend
- **Status:** HTTP 500 Internal Server Error
- **Response:** `{"statusCode":500,"message":"Internal server error"}`
- **Headers:** Shows NestJS/Helmet security headers
- **Service:** ResolveIt Backend API (has an error)

### Port 3001 - ResolveIt Frontend
- **Status:** HTTP 200 OK
- **Response:** HTML (Next.js application)
- **Service:** ResolveIt Frontend UI

### Port 3002 - Unknown Backend
- **Status:** HTTP 404 Not Found
- **Response:** `{"message":"Cannot GET /","error":"Not Found","statusCode":404}`
- **Headers:** Shows NestJS/Helmet security headers with CORS
- **Service:** Some backend service running, but root endpoint not found
- **Note:** Could be a backend service that requires specific endpoints

### Port 3004 - Gemura Backend ✅
- **Status:** HTTP 200 OK
- **Health Check:** ✅ Working
  ```json
  {
    "status": "ok",
    "service": "Gemura API",
    "version": "2.0.0",
    "timestamp": "2026-01-17T11:03:38.646Z"
  }
  ```
- **Swagger Docs:** ✅ Available at `/api/docs`
- **Service:** **Gemura Backend is already deployed and running!**

### Port 3010 - Unknown Frontend
- **Status:** HTTP 200 OK
- **Response:** HTML (Next.js application)
- **Service:** Unknown frontend service

## Recommendations

### For Gemura Deployment

**Option 1: Use existing deployment (Port 3004)**
- Gemura is already deployed on port 3004
- Health check is working
- Swagger docs are available
- **Action:** Update/redeploy if needed, or leave as is

**Option 2: Deploy to new port**
- **Recommended:** Port **3003** (first available)
- Port 3005-3009, 3011-3020 are also available

### Port Allocation Strategy

```
3000 - ResolveIt Backend (in use, has error)
3001 - ResolveIt Frontend (in use)
3002 - Unknown Backend (in use)
3003 - ⭐ AVAILABLE - Recommended for Gemura
3004 - Gemura Backend (already deployed)
3005 - AVAILABLE
3006-3009 - AVAILABLE
3010 - Unknown Frontend (in use)
3011-3020 - AVAILABLE
```

## Testing Commands

### Test all ports:
```bash
./scripts/deployment/test-ports-with-curl.sh
```

### Test specific port:
```bash
curl -v http://159.198.65.38:3004/api/health
```

### Check Gemura status:
```bash
curl http://159.198.65.38:3004/api/health | jq .
```

## Next Steps

1. **If Gemura is already on 3004:**
   - Verify it's the correct version
   - Update/redeploy if needed
   - Or deploy to a new port (3003 recommended)

2. **If deploying to new port:**
   - Use port 3003 (first available)
   - Run: `./scripts/deployment/deploy-to-server.sh 3003`

3. **Investigate port 3002:**
   - Determine what service is running
   - May need to be reconfigured or stopped
