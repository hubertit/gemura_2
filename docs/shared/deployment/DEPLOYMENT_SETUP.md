# Gemura Backend Deployment Setup

## Overview

This deployment follows the same proven pattern as ResolveIt v2 backend deployment. The Gemura backend is deployed to the same server (`159.198.65.38`) and uses the shared DevLabs PostgreSQL database container.

## Key Features

1. **Automatic Port Detection**: The deployment script automatically finds an available port in the range 3000-3020
2. **Shared Database**: Uses the same `devslab-postgres` container as ResolveIt
3. **Docker-based**: Fully containerized deployment using Docker Compose
4. **Dynamic Configuration**: Port and CORS settings are automatically configured based on available ports

## Architecture

```
┌─────────────────────────────────────────┐
│  Server: 159.198.65.38                  │
│                                         │
│  ┌──────────────────────────────────┐  │
│  │  DevLabs PostgreSQL Container     │  │
│  │  (devslab-postgres)               │  │
│  │  Port: 5433 (host)                │  │
│  │  Databases:                        │  │
│  │    - resolveit_db                  │  │
│  │    - gemura_db                     │  │
│  └──────────────────────────────────┘  │
│                                         │
│  ┌──────────────────────────────────┐  │
│  │  ResolveIt Backend                │  │
│  │  Port: 3000                       │  │
│  └──────────────────────────────────┘  │
│                                         │
│  ┌──────────────────────────────────┐  │
│  │  Gemura Backend                   │  │
│  │  Port: [Auto-detected 3000-3020]  │  │
│  └──────────────────────────────────┘  │
│                                         │
└─────────────────────────────────────────┘
```

## Deployment Process

### Step 1: Port Detection

The deployment script (`scripts/deployment/deploy-to-server.sh`) first runs `find-available-port.sh` to:
1. Test each port from 3000-3020 on the server
2. Check if the port is listening (using `netstat` or `ss`)
3. Verify the port doesn't respond to HTTP requests
4. Return the first available port

### Step 2: File Upload

The script uploads the project files to `/opt/gemura` on the server, excluding:
- `node_modules`
- `.next` (Next.js build)
- `dist` (compiled files)
- `.git`
- `*.log`
- `.env*` (environment files)
- `mobile` (mobile app directory)
- `build` (build artifacts)

### Step 3: Database Setup

The script ensures:
1. DevLabs PostgreSQL container is running (shared with ResolveIt)
2. `gemura_db` database exists
3. Proper permissions are set

### Step 4: Build and Deploy

The script:
1. Creates `.env.devlabs` with dynamic port configuration
2. Builds Docker images
3. Starts containers with the detected port
4. Runs Prisma migrations automatically

## Files Modified

### 1. `scripts/deployment/find-available-port.sh` (NEW)
- Tests ports 3000-3020 on the server
- Returns the first available port to stdout
- Outputs status messages to stderr

### 2. `scripts/deployment/deploy-to-server.sh` (UPDATED)
- Added port detection step
- Uses dynamic port throughout deployment
- Updates `.env.devlabs` with detected port
- Updates all service URLs with detected port

### 3. `docker-compose.gemura.yml` (UPDATED)
- Changed `PORT: 3004` to `PORT: ${BACKEND_PORT:-3004}`
- Changed port mapping to use dynamic port: `${BACKEND_PORT:-3004}:${BACKEND_PORT:-3004}`

### 4. `backend/Dockerfile` (UPDATED)
- Updated healthcheck to use `PORT` environment variable dynamically

## Usage

### Step 1: Check Available Ports (Recommended)

**Always check available ports first!**

```bash
cd /Users/macbookpro/projects/flutter/gemura2
./scripts/deployment/check-available-ports.sh
```

This will show you:
- All ports in range 3000-3020
- Which ports are available
- Which ports are in use
- Recommended port to use

**Example output:**
```
Port 3000: ✗ IN USE (listening)
Port 3001: ✗ IN USE (listening)
Port 3002: ✓ AVAILABLE
Port 3003: ✓ AVAILABLE
...

Available Ports: 3002 3003 3004 3005 ...
Recommended: Use port 3002
```

### Step 2: Deploy to Server

**Option A: Use specific port (Recommended)**
```bash
# Use the port you saw from Step 1
./scripts/deployment/deploy-to-server.sh 3002
```

**Option B: Auto-detect port**
```bash
# Script will automatically find first available port
./scripts/deployment/deploy-to-server.sh
```

The script will:
1. Use your specified port OR find an available port
2. Verify the port is actually available
3. Upload files to server
4. Setup database (if needed)
5. Build and deploy with the selected port

### Manual Port Testing

```bash
./scripts/deployment/find-available-port.sh
```

This will test ports and output the first available one.

## Environment Variables

The deployment creates `.env.devlabs` on the server with:

```env
# DevLabs PostgreSQL Configuration
POSTGRES_USER=devslab_admin
POSTGRES_PASSWORD=devslab_secure_password_2024
POSTGRES_DB=postgres
POSTGRES_PORT=5433

# Gemura Configuration (Dynamic)
BACKEND_PORT=<detected_port>
FRONTEND_PORT=<detected_port + 1>
CORS_ORIGIN=http://localhost:<frontend_port>,http://localhost:<backend_port>,http://159.198.65.38:<frontend_port>,http://159.198.65.38:<backend_port>
NEXT_PUBLIC_API_BASE=http://159.198.65.38:<backend_port>/api

# Database connection
DATABASE_URL=postgresql://devslab_admin:devslab_secure_password_2024@devslab-postgres:5432/gemura_db
```

## Accessing the Application

After deployment, the application will be available at:

- **Backend API**: `http://159.198.65.38:<detected_port>/api`
- **API Docs**: `http://159.198.65.38:<detected_port>/api/docs`
- **Health Check**: `http://159.198.65.38:<detected_port>/api/health`

The deployment script will output the exact URLs after successful deployment.

## Comparison with ResolveIt v2

| Feature | ResolveIt v2 | Gemura |
|---------|-------------|--------|
| Database | Shared DevLabs PostgreSQL | Shared DevLabs PostgreSQL |
| Backend Port | 3000 (fixed) | Auto-detected (3000-3020) |
| Frontend Port | 3001 (fixed) | Auto-detected + 1 |
| Deployment Path | `/opt/resolveit` | `/opt/gemura` |
| Database Name | `resolveit_db` | `gemura_db` |
| Network | `devslab-network` | `devslab-network` |

## Troubleshooting

### Port Already in Use

If the deployment fails because a port is in use:
1. The script will automatically try the next available port
2. If all ports 3000-3020 are taken, the deployment will fail with an error
3. Check what's using the ports: `ssh root@159.198.65.38 'netstat -tuln | grep -E ":(300[0-9]|30[12][0-9])"'`

### Database Connection Issues

```bash
# Test database connection
ssh root@159.198.65.38 'docker exec -it devslab-postgres psql -U devslab_admin -d gemura_db'

# Check if database exists
ssh root@159.198.65.38 'docker exec -it devslab-postgres psql -U devslab_admin -d postgres -c "\l"'
```

### View Logs

```bash
# Backend logs
ssh root@159.198.65.38 'cd /opt/gemura && docker compose -f docker-compose.gemura.yml logs -f backend'

# All services
ssh root@159.198.65.38 'cd /opt/gemura && docker compose -f docker-compose.gemura.yml logs -f'
```

### Restart Services

```bash
ssh root@159.198.65.38 'cd /opt/gemura && docker compose -f docker-compose.gemura.yml restart'
```

### Stop Services

```bash
ssh root@159.198.65.38 'cd /opt/gemura && docker compose -f docker-compose.gemura.yml down'
```

## Notes

- The database is already deployed and shared with ResolveIt
- Port detection happens automatically - no manual configuration needed
- The deployment follows the exact same pattern as ResolveIt v2 for consistency
- All ports in the range 3000-3020 are tested to find the first available one
