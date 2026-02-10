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

Main deployment script that:
1. Uses specified port OR finds an available port (3000-3020)
2. Uploads project files to server
3. Sets up database (if needed)
4. Builds and deploys Docker containers

**Usage:**
```bash
# Auto-detect available port
./scripts/deployment/deploy-to-server.sh

# Use specific port (recommended - check ports first!)
./scripts/deployment/deploy-to-server.sh 3002
```

**Options:**
- No argument: Auto-detects first available port
- With port number: Uses the specified port (verifies it's available first)

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

## Credentials (same server as ResolveIT v2)

Gemura uses the **same server** as ResolveIT v2. Credentials are read from ResolveIT v2 when present so you maintain them in one place.

1. **Preferred:** In ResolveIT v2 create the credentials file (one-time):
   ```bash
   cd /Applications/AMPPS/www/resolveit/v2/scripts/deployment
   cp server-credentials.sh.example server-credentials.sh
   # Edit server-credentials.sh and set SERVER_PASS
   chmod 600 server-credentials.sh
   ```
   Then `deploy-to-server.sh` and `ensure-backend-up.sh` will source it automatically (default path: `/Applications/AMPPS/www/resolveit/v2/scripts/deployment/server-credentials.sh`).

2. **Override path:** `export RESOLVEIT_V2_CREDS=/path/to/server-credentials.sh` before running Gemura deploy scripts.

3. **Or set inline:** `export SERVER_PASS=your_password` (and optionally `SERVER_IP`, `SERVER_USER`).

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
