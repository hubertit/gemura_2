# Server Analysis – 30 Jan 2026

**Server:** 159.198.65.38  
**Purpose:** Understand why Gemura backend was down and what was fixed.

---

## 1. What We Found (After Reboot)

### 1.1 Containers

| Container                  | Status        | Notes                                      |
|---------------------------|---------------|--------------------------------------------|
| **devslab-postgres**      | **Dead**      | Shared PostgreSQL for Gemura and others    |
| **gemura-backend**        | **Not present** | No Gemura container on the server       |
| resolveit-frontend-1      | Up (healthy)  | Port 3001                                 |
| resolveit-backend-1      | Up (health: starting) | Port 3000                         |
| ihuzo-finance-backend-nestjs | Restarting | Likely depends on devslab-postgres    |
| orchestrate-*             | Up            | Ports 3006, 3007                           |

### 1.2 Root Cause: devslab-postgres

- **State:** `dead`
- **Error from Docker:**
  ```text
  driver "overlay2" failed to remove root filesystem: unlinkat
  /var/lib/docker/overlay2/.../merged: device or resource busy
  ```
- **Effect:** The container could not be removed or started. Other services (ResolveIt, ihuzo-finance, Gemura) that use this PostgreSQL were affected. Gemura was never started because deploy failed at the PostgreSQL step.

### 1.3 Ports

- **3004:** Not listening (no Gemura backend).
- **5433:** Not listening (devslab-postgres dead).

### 1.4 Disk and Docker

- **Disk:** `/` 82% used (92G / 118G), 21G free – OK.
- **Docker:** Active. Build cache ~10.85GB reclaimable.

### 1.5 Firewall

- **Type:** iptables (not ufw). Policy DROP on INPUT; traffic is allowed via specific rules (e.g. dpt:20, 21, 22, …).
- **Port 3004:** No rule allowing TCP 3004 in the checked chains (INPUT, LOCALINPUT). So **incoming access to 3004 from the internet is blocked**.

### 1.6 Gemura Deploy Path

- `/opt/gemura` exists with compose files and `.env.devlabs`.
- No Gemura container was present because deploy had failed earlier at the PostgreSQL step.

---

## 2. What We Did

1. **Force-removed the dead Postgres container**
   - `docker rm -f devslab-postgres` (succeeded after reboot).
2. **Started DevLabs PostgreSQL**
   - `cd /opt/gemura && docker compose -f docker-compose.devlabs-db.yml up -d`
   - devslab-postgres: **Up**, port 5433.
3. **Built and started Gemura backend**
   - `docker compose -f docker-compose.gemura.yml --env-file .env.devlabs build backend`
   - `docker compose -f docker-compose.gemura.yml --env-file .env.devlabs up -d --force-recreate --no-deps backend`
   - gemura-backend: **Up**, port 3004.

---

## 3. Current State (After Fixes)

| Service            | Status   | Port  |
|--------------------|----------|-------|
| devslab-postgres   | Up (healthy) | 5433 |
| gemura-backend     | Up (health: starting) | 3004 |

- Backend is running on the server and listening on 3004 inside the host.
- **Health from outside** (`http://159.198.65.38:3004/api/health`) still fails because **port 3004 is not allowed by the firewall**.

---

## 4. Why External Health Check Fails

- **Cause:** Firewall (iptables) is blocking incoming TCP to port 3004.
- **Fix:** Allow TCP 3004 in the server firewall.

**If the server uses ufw:**

```bash
ssh root@159.198.65.38
ufw allow 3004/tcp
ufw reload
```

**If the server uses iptables / custom chains (e.g. cPanel/WHM):**

- Add an ACCEPT rule for TCP destination port 3004 in the appropriate chain (e.g. INPUT or the chain that handles new incoming traffic).
- Or use the control panel’s “Firewall” / “Security” section to open port 3004.

After opening 3004, verify:

```bash
curl -s http://159.198.65.38:3004/api/health
```

---

## 5. Summary

| Item | Finding |
|------|--------|
| **Why backend was down** | devslab-postgres was **dead** (overlay2 “device or resource busy” after reboot). Deploy failed at Postgres step, so Gemura backend was never started. |
| **Why no Gemura container** | Deploy script never reached “build & start Gemura” because it failed earlier on Postgres. |
| **What we fixed** | Force-removed dead devslab-postgres, started Postgres, then built and started gemura-backend. |
| **Why health still fails from outside** | Firewall blocks port 3004. Open 3004 (ufw or iptables/panel) and re-test. |

---

## 6. Useful Commands (On Server)

```bash
# SSH
ssh root@159.198.65.38

# Container status
docker ps -a --format 'table {{.Names}}\t{{.Status}}\t{{.Ports}}'

# Gemura logs
cd /opt/gemura && docker compose -f docker-compose.gemura.yml logs -f backend

# Health from server (localhost)
curl -s http://localhost:3004/api/health

# Restart Gemura backend
cd /opt/gemura && docker compose -f docker-compose.gemura.yml --env-file .env.devlabs restart backend
```
