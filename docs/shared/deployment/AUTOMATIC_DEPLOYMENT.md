# Automatic Container Recreation on Deployment

## Overview

The deployment script is configured to **automatically recreate containers with the new image** after each deployment. This ensures that:

1. ✅ Latest code is always running
2. ✅ No manual intervention needed
3. ✅ Old containers are properly cleaned up
4. ✅ Health checks verify successful deployment

## How It Works

### Deployment Process

When you run `./scripts/deployment/deploy-to-server.sh`, it automatically:

1. **Uploads latest code** to the server
2. **Stops and removes** existing containers
3. **Cleans up** any stuck containers
4. **Builds new Docker image** with `--no-cache` (ensures fresh build)
5. **Recreates containers** with `--force-recreate` flag (ensures new image is used)
6. **Waits and verifies** backend health (up to 60 seconds)
7. **Shows deployment status** and verification

### Key Flags Used

```bash
# Force recreate containers (even if config hasn't changed)
--force-recreate

# Don't recreate dependencies (only backend)
--no-deps

# Build without cache (ensures latest code)
--no-cache

# Remove orphaned containers
--remove-orphans
```

## Deployment Command

Simply run:

```bash
cd /Users/macbookpro/projects/flutter/gemura2
./scripts/deployment/deploy-to-server.sh
```

The script handles everything automatically - no manual steps needed!

## Verification

After deployment, the script automatically:

- ✅ Checks container status
- ✅ Verifies backend health endpoint
- ✅ Shows which image is running
- ✅ Displays service URLs

## Manual Override (if needed)

If you ever need to manually recreate containers:

```bash
ssh root@159.198.65.38
cd /opt/gemura
docker compose -f docker-compose.gemura.yml --env-file .env.devlabs up -d --force-recreate backend
```

## Troubleshooting

If containers don't update:

1. **Check if build completed**: Look for "Building Gemura containers..." in deployment log
2. **Verify image was created**: `docker images | grep gemura-backend`
3. **Force remove and restart**:
   ```bash
   docker compose -f docker-compose.gemura.yml --env-file .env.devlabs down
   docker compose -f docker-compose.gemura.yml --env-file .env.devlabs up -d --force-recreate backend
   ```

## Benefits

- 🚀 **Zero-downtime deployments** (containers are recreated, not restarted)
- 🔄 **Always uses latest code** (no stale containers)
- 🧹 **Automatic cleanup** (removes old/stuck containers)
- ✅ **Health verification** (confirms deployment success)
- 📊 **Status reporting** (shows what's running)
