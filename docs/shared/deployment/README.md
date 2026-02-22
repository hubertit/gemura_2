# Deployment Documentation

Complete guides for deploying Gemura 2.0 to production.

## 📋 Quick Start

**For fastest deployment:**
```bash
./scripts/deployment/deploy-to-server.sh
```

See [FINAL_DEPLOYMENT_INSTRUCTIONS.md](./FINAL_DEPLOYMENT_INSTRUCTIONS.md) for detailed steps.

## 📚 Documentation Files

### Essential Guides

1. **[FINAL_DEPLOYMENT_INSTRUCTIONS.md](./FINAL_DEPLOYMENT_INSTRUCTIONS.md)** ⭐ **START HERE**
   - Complete step-by-step deployment guide
   - Automated deployment script usage
   - Manual deployment procedures

2. **[DEPLOYMENT_GUIDE.md](./DEPLOYMENT_GUIDE.md)**
   - Comprehensive deployment documentation
   - Architecture overview
   - Server configuration

3. **[DEPLOYMENT_OPTIMIZATION.md](./DEPLOYMENT_OPTIMIZATION.md)**
   - Performance optimization guide
   - Docker layer caching
   - Build time improvements

4. **[AUTOMATIC_DEPLOYMENT.md](./AUTOMATIC_DEPLOYMENT.md)**
   - Automatic container recreation
   - Deployment automation
   - Health verification

### Reference Documents

- **[DEPLOYMENT_COMPARISON.md](./DEPLOYMENT_COMPARISON.md)** - Comparison with ResolveIt deployment
- **[DEPLOYMENT_SETUP.md](./DEPLOYMENT_SETUP.md)** - Initial server setup
- **[DEPLOYMENT_CHECKLIST.md](./DEPLOYMENT_CHECKLIST.md)** - Pre-deployment checklist

## 🚀 Deployment Process

### Automated Deployment (Recommended)

```bash
cd /path/to/gemura2
./scripts/deployment/deploy-to-server.sh
```

This single command:
1. ✅ Uploads project files (optimized, ~37MB)
2. ✅ Sets up DevLabs PostgreSQL
3. ✅ Creates `gemura_db` database
4. ✅ Builds Docker images (with caching)
5. ✅ Deploys services
6. ✅ Verifies health

**Time:** 2-5 minutes (much faster with optimizations!)

### Manual Deployment

See [FINAL_DEPLOYMENT_INSTRUCTIONS.md](./FINAL_DEPLOYMENT_INSTRUCTIONS.md) for manual steps.

## 🏗️ Architecture

### Server Configuration
- **Server IP:** `159.198.65.38`
- **Backend Port:** `3004`
- **Frontend Port:** `3005` (when ready)
- **Database:** Shared DevLabs PostgreSQL (port `5433`)

### Docker Setup
- **Network:** `devslab-network` (shared with ResolveIt)
- **Database Container:** `devslab-postgres`
- **Backend Container:** `gemura-backend`

## 📊 Deployment Performance

| Stage | Time | Notes |
|-------|------|-------|
| File Upload | 30-60 sec | Optimized (37MB vs 208MB) |
| Docker Build | 1-3 min | Uses layer caching |
| Container Start | 10-20 sec | Health check included |
| **Total** | **2-5 min** | Much faster than before! |

## ✅ Verification

After deployment, verify:

```bash
# Health check
curl http://159.198.65.38:3004/api/health

# API docs
curl http://159.198.65.38:3004/api/docs

# Container status
ssh root@159.198.65.38 'cd /opt/gemura && docker compose -f docker-compose.gemura.yml ps'
```

## 🔧 Troubleshooting

### Container won't start
- Check logs: `docker compose -f docker-compose.gemura.yml logs backend`
- Verify database is running: `docker ps | grep devslab-postgres`

### Build takes too long
- Ensure Docker layer caching is enabled (don't use `--no-cache`)
- Check network speed for file upload

### Port conflicts
- Check what's using port 3004: `lsof -i :3004`
- Verify no other Gemura instances running

## 📝 Best Practices

1. ✅ **Always use automated script** - Faster and more reliable
2. ✅ **Let Docker cache layers** - Don't use `--no-cache` unless necessary
3. ✅ **Verify health after deployment** - Check health endpoint
4. ✅ **Monitor logs** - Watch for errors during startup
5. ✅ **Keep documentation updated** - Update docs when procedures change

## 🔗 Related Documentation

- [API Documentation](../api/README.md) - API endpoints
- [Project Organization](../project/PROJECT_ORGANIZATION.md) - Project structure
- [Testing Results](../testing/README.md) - Test verification

---

**Last Updated:** January 18, 2026
