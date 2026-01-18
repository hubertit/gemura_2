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

### `find-available-port.sh`

Internal script that finds the first available port (used by deploy script).
Returns only the port number to stdout.

**Usage:**
```bash
PORT=$(./scripts/deployment/find-available-port.sh)
```

## Server Configuration

- **Server IP**: `159.198.65.38`
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
