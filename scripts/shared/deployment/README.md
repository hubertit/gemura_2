# Deployment Scripts

## Overview

These scripts deploy Gemura and Orora applications to the Kwezi server (209.74.80.195).

## Server Configuration

- **Server IP**: `209.74.80.195` (Kwezi server)
- **Deployment Paths**: 
  - Gemura: `/opt/gemura`
  - Orora: `/opt/orora`
- **Database**: Kwezi PostgreSQL (`kwezi-postgres`)
- **Database Name**: `gemura_db` (shared by Gemura and Orora)

## Port Allocation

| Port | Service |
|------|---------|
| 3000 | Kwezi UI |
| 3001 | HcRF UI |
| 3002 | Orchestrate UI |
| 3003 | Orchestrate API |
| 3004 | HcRF API |
| 3005 | ResolveIt Frontend |
| 3006 | Gemura Web |
| 3007 | Gemura Backend API |
| 3008 | ResolveIt Backend |
| 3009 | iFinance API |
| 3011 | Orora Web |

## Recommended Deployment Scripts

### Gemura Deployment
```bash
# From project root
./scripts/gemura/deployment/deploy-gemura.sh
```

### Orora Web Deployment
```bash
# From project root
./scripts/orora/deployment/deploy-orora-web.sh
```

## Shared Scripts

### `check-available-ports.sh`
Check available ports on the server before deploying.

```bash
./scripts/shared/deployment/check-available-ports.sh
```

### `deploy-to-server.sh`
Main deployment script for Gemura (backend + web).

```bash
./scripts/shared/deployment/deploy-to-server.sh
```

### `deploy-gemura-only-safe.sh`
Safe deployment that only updates Gemura containers without touching the database.

```bash
./scripts/shared/deployment/deploy-gemura-only-safe.sh
```

## Credentials

Credentials are stored in `scripts/shared/deployment/server-credentials.sh`. Do not commit this file.

**Setup:**
```bash
cd scripts/shared/deployment
cp server-credentials.sh.example server-credentials.sh
# Edit server-credentials.sh and set credentials
chmod 600 server-credentials.sh
```

## Requirements

- `sshpass` - For password-based SSH authentication
- `curl` - For health checks
- `tar` - For creating deployment archives
- SSH access to server

## Troubleshooting

### Check Server Connectivity
```bash
ssh root@209.74.80.195
```

### View Container Logs
```bash
# Gemura
ssh root@209.74.80.195 'cd /opt/gemura && docker compose -f docker/docker-compose.kwezi.yml logs -f'

# Orora
ssh root@209.74.80.195 'cd /opt/orora && docker compose -f docker/docker-compose.orora-web.yml logs -f'
```

### Restart Services
```bash
# Gemura
ssh root@209.74.80.195 'cd /opt/gemura && docker compose -f docker/docker-compose.kwezi.yml restart'

# Orora
ssh root@209.74.80.195 'cd /opt/orora && docker compose -f docker/docker-compose.orora-web.yml restart'
```

### Health Checks
```bash
# Gemura Backend
curl http://209.74.80.195:3007/api/health

# Gemura Web
curl http://209.74.80.195:3006/auth/login

# Orora Web
curl http://209.74.80.195:3011/auth/login
```
