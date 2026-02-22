# Deployment Scripts

## Overview

These scripts deploy the Gemura backend to the production server following the same pattern as ResolveIt v2.

## Scripts

### `check-available-ports.sh` ⭐ **START HERE**

**Check available ports first before deploying!**

Shows all ports in range 3000-3020 and indicates which are available.

**Usage:**
```bash
./scripts/deployment/check-available-ports.sh
```

**Output:**
- Lists all ports with status (Available/In Use)
- Shows recommended port to use
- Returns first available port to stdout

**Example:**
```bash
# Check available ports
./scripts/deployment/check-available-ports.sh

# Or capture the recommended port
PORT=$(./scripts/deployment/check-available-ports.sh)
echo "Will use port: $PORT"
```

### `deploy-to-server.sh`

Main deployment script. **Run from project root.**

**What it does:**
1. Backs up the production database
2. **Builds the frontend locally** (prod API URL) so the server never runs the heavy Next.js build (avoids OOM)
3. Uploads backend + web (with pre-built `.next`) + `docker-compose.gemura.prebuilt.yml` + deployment scripts
4. On server: ensures Docker + DevLabs PostgreSQL, then builds backend image and frontend image (frontend just copies `.next`), starts both containers

**Usage:**
```bash
cd /path/to/gemura2
./scripts/deployment/deploy-to-server.sh
```

**Behaviour:**
- Upload is retried once on connection failure (e.g. brief "No route to host").
- After `docker compose down`, the script waits a few seconds before rebuild/up to reduce "overlay2 device or resource busy" issues.

**If you see "overlay2 failed to remove root filesystem" / "device or resource busy":**
1. Restart Docker on the server: `ssh root@159.198.65.38 'systemctl restart docker'`, wait 15s, then re-run the script.
2. If it persists, reboot the server: `ssh root@159.198.65.38 'reboot'`, wait ~2 min, then re-run.

### `auto-deploy-backend.sh` ⭐ **AUTO-DEPLOY**

**Automatically deploys backend changes to production!**

This script:
1. Checks if backend files changed in the last commit
2. Automatically deploys to production if changes detected
3. Can be run manually or via git hook

**Usage:**
```bash
# Check last commit and deploy if backend changed
./scripts/deployment/auto-deploy-backend.sh

# Force deploy regardless of changes
./scripts/deployment/auto-deploy-backend.sh --force
```

**Auto-deployment via Git Hook:**
The project includes a `post-commit` git hook that automatically deploys backend changes after each commit. The hook:
- Detects if backend files changed
- Runs deployment in background (non-blocking)
- Logs to `/tmp/gemura-auto-deploy.log`

**Setup Git Hook:**
```bash
# Install the git hook (one-time setup)
./scripts/deployment/setup-auto-deploy.sh
```

**How it works:**
1. After each commit, the hook checks if backend files changed
2. If backend files changed, it automatically runs `auto-deploy-backend.sh`
3. Deployment runs in background (doesn't block your terminal)
4. Check deployment logs: `tail -f /tmp/gemura-auto-deploy.log`

**To disable auto-deployment:**
```bash
rm .git/hooks/post-commit
```

**To re-enable:**
```bash
./scripts/deployment/setup-auto-deploy.sh
```

### `find-available-port.sh`

Internal script that finds the first available port (used by deploy script).
Returns only the port number to stdout.

**Usage:**
```bash
PORT=$(./scripts/deployment/find-available-port.sh)
```

## Credentials (project-local)

Credentials are stored **only in this project**. Do not commit the credentials file.

1. **One-time setup:**
   ```bash
   cd scripts/deployment
   cp server-credentials.sh.example server-credentials.sh
   # Edit server-credentials.sh and set SERVER_PASS (and SERVER_IP, SERVER_USER if needed)
   chmod 600 server-credentials.sh
   ```
   `deploy-to-server.sh` and `ensure-backend-up.sh` source `scripts/deployment/server-credentials.sh` automatically.

2. **Override path (optional):** `export GEMURA_SERVER_CREDS=/path/to/server-credentials.sh` before running deploy scripts.

3. **Or set inline:** `export SERVER_PASS=your_password` (and optionally `SERVER_IP`, `SERVER_USER`).

## Network / firewall

The deploy script connects to **159.198.65.38** over SSH. If your current network blocks that (e.g. corporate firewall, restricted Wi‑Fi):

- The script runs a **quick connectivity check** first and exits with a clear message if the server is unreachable.
- **Workarounds:** use a different network (e.g. mobile hotspot), a VPN, or run the deploy from a machine that can reach the server (e.g. from the server itself after cloning the repo there).

## Server Configuration

- **Server IP**: `159.198.65.38` (same as ResolveIT v2)
- **Deployment Path**: `/opt/gemura`
- **Database**: Shared DevLabs PostgreSQL (`devslab-postgres`)
- **Database Name**: `gemura_db`
- **Network**: `devslab-network` (shared with ResolveIt)

## Port Detection

The deployment automatically detects available ports by:
1. Checking if port is listening (using `netstat` or `ss`)
2. Testing HTTP connectivity
3. Selecting the first available port in range 3000-3020

## Requirements

- `sshpass` - For password-based SSH authentication
- `curl` - For port testing
- `tar` - For creating deployment archives
- SSH access to server with password authentication

## Troubleshooting

### Port Detection Fails

If port detection fails, check:
```bash
# Test ports manually
ssh root@159.198.65.38 'netstat -tuln | grep -E ":(300[0-9]|30[12][0-9])"'
```

### SSH Connection Issues

Verify SSH access:
```bash
ssh root@159.198.65.38
```

### Deployment Fails

Check logs:
```bash
ssh root@159.198.65.38 'cd /opt/gemura && docker compose -f docker-compose.gemura.yml logs'
```

### Health endpoint not reachable (`http://159.198.65.38:3004/api/health`)

1. **Run the diagnostic on the server** (after SSH):
   ```bash
   ssh root@159.198.65.38
   cd /opt/gemura && bash scripts/deployment/check-backend-on-server.sh
   ```
   This shows container status, port 3004, backend logs, and whether the health check works from localhost.

2. **Open firewall** if the diagnostic shows the backend is up on the server but you still can’t reach it from outside:
   ```bash
   ssh root@159.198.65.38 'ufw allow 3004/tcp && ufw reload'
   ```

3. **Redeploy** so the backend binds to `0.0.0.0` (required in Docker): run `./scripts/deployment/deploy-to-server.sh` again after the code change in `backend/src/main.ts`.
