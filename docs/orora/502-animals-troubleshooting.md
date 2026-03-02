# 502 on Animals and Other Pages (app.orora.rw)

When the Animals page (or other pages like Dashboard, Farms, Collections, Sales, Stats) show **"Request failed with status code 502"**, the browser is getting a **502 Bad Gateway** from the server. That means Nginx (or another reverse proxy) could not get a valid response from the upstream backend. The same backend serves all these pages, so a systemic backend issue can cause 502s on multiple routes.

## Request flow

- **Page:** https://app.orora.rw/animals  
- **API call:** `GET https://app.orora.rw/api/animals?account_id=...` (with auth)  
- **Nginx:** Proxies `/api/` to `http://127.0.0.1:3007`  
- **Backend:** NestJS API on port **3007** (shared Gemura/Orora backend)

So a 502 here means either the backend on **3007** is not responding correctly or not running.

## Checklist (production server)

Run these on the **production host** (e.g. 209.74.80.195) or from a place that can reach it.

### 1. Backend process and port

```bash
# Is anything listening on 3007?
ss -tlnp | grep 3007
# or
curl -s -o /dev/null -w "%{http_code}" http://127.0.0.1:3007/api/health
```

- If nothing listens on 3007 or health returns 000/connection refused → **backend is down**. Start/restart the backend (e.g. via your deploy script or Docker).
- If health returns **200** → backend is up; 502 is likely from a specific request (e.g. `/api/animals`) failing or timing out.

### 2. Call the animals endpoint directly

```bash
# Replace TOKEN with a valid Bearer token for an Orora user
curl -s -w "\nHTTP_CODE:%{http_code}\n" \
  -H "Authorization: Bearer TOKEN" \
  "http://127.0.0.1:3007/api/animals?account_id=YOUR_ACCOUNT_UUID"
```

- **502/connection reset/no response:** Backend may be crashing or timing out on this route (e.g. DB error, serialization error).
- **401:** Auth problem (wrong/expired token or missing account).
- **200 + JSON:** Backend is fine; then 502 in the browser is likely proxy/timeout or one-off.

### 3. Backend logs

Check the process that runs the NestJS API (e.g. Docker container or systemd unit):

```bash
# If using Docker
docker logs <backend-container-name> --tail 200

# Look for:
# - Uncaught exceptions
# - Serialization/JSON errors in the response pipeline (e.g. SerializePrismaInterceptor)
# - Prisma/DB errors
# - Out of memory / crash
```

Crashes or unhandled errors during `/api/animals` can cause the connection to close and Nginx to return 502.

### 4. Nginx proxy timeouts

In `gemura-orora.conf`, `/api/` has:

- `proxy_read_timeout 60s`
- `proxy_connect_timeout 10s`
- `proxy_send_timeout 60s`

If the backend is slow (e.g. heavy DB query), Nginx may close the connection and return 502. Check backend duration for `GET /api/animals` and consider increasing timeouts or optimizing the query.

## Common causes and fixes

| Cause | What to do |
|-------|------------|
| Backend not running on 3007 | Start/restart backend (e.g. `deploy-gemura.sh` or backend-only script). Ensure `PORT=3007` (or your API port) in the backend env. |
| Backend crash on `/api/animals` | Check backend logs for exceptions. Ensure latest backend code is deployed (including `SerializePrismaInterceptor` and recent fixes). |
| Prisma Decimal/BigInt serialization | Backend uses `SerializePrismaInterceptor` to convert Decimal/BigInt to strings. In production builds, Prisma's Decimal constructor name can be minified (e.g. to `'i'`), so the interceptor now also detects via `[object Decimal]` and duck-typing (`toString` + `toFixed`). Ensure the latest backend (with this fix) is deployed. |
| DB connection / query failure | Verify DB is reachable from the backend, run migrations if needed, and check for slow or failing queries in logs. |
| Wrong port or config | Confirm Nginx `proxy_pass` points to the same port the backend listens on (e.g. 3007). |

## After code changes

If you changed backend code (e.g. interceptor or animals module):

1. Rebuild and redeploy the backend to the server.
2. Restart the backend process/container.
3. Retest `GET /api/animals` with curl and then the Animals page in the browser.

## Code fixes applied (deploy to clear 502s)

1. **SerializePrismaInterceptor** (`backend/src/common/interceptors/serialize-prisma.interceptor.ts`): Decimal detection no longer relies only on `constructor.name === 'Decimal'` (minified in production). It also checks `Object.prototype.toString.call(value) === '[object Decimal]'` and uses duck-typing (`toString` + `toFixed`). The interceptor wraps conversion in `try/catch` so serialization itself does not crash the request; any unhandled errors are surfaced via Nest's global exception filter.
2. **HttpExceptionFilter** (`backend/src/common/filters/http-exception.filter.ts`): Global exception filter so any unhandled exception returns a valid JSON response (e.g. 500 with body) instead of crashing and causing nginx to return 502. Applies to all routes (animals, farms, stats, collections, etc.).

## Quick reference

- **Backend health:** `http://<server>:3007/api/health`
- **Nginx config:** `docker/nginx/gemura-orora.conf` (deployed e.g. to `/etc/nginx/sites-available/gemura-orora.conf`)
- **Backend serialization:** `backend/src/common/interceptors/serialize-prisma.interceptor.ts`
- **Backend exception handling:** `backend/src/common/filters/http-exception.filter.ts`
