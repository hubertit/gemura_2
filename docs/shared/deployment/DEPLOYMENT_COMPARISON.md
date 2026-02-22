# 📊 Deployment Comparison: ResolveIt vs Gemura

This document shows how Gemura deployment matches the proven ResolveIt v2 pattern.

## 🎯 Key Principle

**Both applications use the same deployment architecture and infrastructure, ensuring consistency and reliability.**

## 📁 File Structure Comparison

### ResolveIt v2
```
/opt/resolveit/
├── docker-compose.devlabs-db.yml    # Shared PostgreSQL
├── docker-compose.resolveit.yml     # ResolveIt app
├── docker-compose.yml                # Local dev
├── .env.devlabs                      # Environment vars
└── scripts/deployment/
    └── deploy-to-server.sh           # Deployment script
```

### Gemura
```
/opt/gemura/
├── docker-compose.devlabs-db.yml     # Shared PostgreSQL (same as ResolveIt)
├── docker-compose.gemura.yml         # Gemura app
├── docker-compose.yml                 # Local dev
├── .env.devlabs                      # Environment vars
└── scripts/deployment/
    └── deploy-to-server.sh           # Deployment script
```

## 🗄️ Database Configuration

| Aspect | ResolveIt | Gemura | Shared? |
|--------|-----------|--------|---------|
| **Container** | devslab-postgres | devslab-postgres | ✅ Yes |
| **Network** | devslab-network | devslab-network | ✅ Yes |
| **Database Name** | resolveit_db | gemura_db | ❌ No |
| **User** | devslab_admin | devslab_admin | ✅ Yes |
| **Password** | devslab_secure_password_2024 | devslab_secure_password_2024 | ✅ Yes |
| **Host Port** | 5433 | 5433 | ✅ Yes |
| **Container Port** | 5432 | 5432 | ✅ Yes |

## 🌐 Network & Ports

| Service | ResolveIt | Gemura | Notes |
|---------|----------|--------|-------|
| **Backend Port** | 3000 | 3004 | Different to avoid conflicts |
| **Frontend Port** | 3001 | 3005 | Different to avoid conflicts |
| **PostgreSQL Port** | 5433 | 5433 | Shared |
| **Docker Network** | devslab-network | devslab-network | Shared |

## 📦 Docker Compose Files

### ResolveIt: `docker-compose.resolveit.yml`
```yaml
services:
  backend:
    container_name: resolveit-backend
    env_file: [.env.devlabs]
    environment:
      PORT: 3000
      DATABASE_URL: postgresql://devslab_admin:...@devslab-postgres:5432/resolveit_db
    networks:
      - devslab-network
    command: >
      sh -c "
        sleep 10 &&
        npx prisma migrate deploy &&
        node dist/src/main.js
      "
```

### Gemura: `docker-compose.gemura.yml`
```yaml
services:
  backend:
    container_name: gemura-backend
    env_file: [.env.devlabs]
    environment:
      PORT: 3004
      DATABASE_URL: postgresql://devslab_admin:...@devslab-postgres:5432/gemura_db
    networks:
      - devslab-network
    command: >
      sh -c "
        sleep 10 &&
        npx prisma migrate deploy &&
        node dist/src/main.js
      "
```

**Identical structure, only ports and database names differ.**

## 🐳 Dockerfile Comparison

Both use the same multi-stage build pattern:

```dockerfile
FROM node:20-alpine AS base
FROM base AS deps
# ... install dependencies
FROM base AS builder
# ... build application
FROM base AS runner
# ... production image
CMD ["node", "dist/src/main.js"]
```

**Key differences:**
- ResolveIt: Exposes port 3000, health check on port 3000
- Gemura: Exposes port 3004, health check on port 3004

## 🚀 Deployment Scripts

### ResolveIt: `deploy-to-server.sh`
1. Uploads files to `/opt/resolveit`
2. Ensures DevLabs PostgreSQL is running
3. Creates `resolveit_db` database
4. Builds and starts ResolveIt containers

### Gemura: `deploy-to-server.sh`
1. Uploads files to `/opt/gemura`
2. Ensures DevLabs PostgreSQL is running
3. Creates `gemura_db` database
4. Builds and starts Gemura containers

**Same logic, different paths and database names.**

## 🔧 Environment Variables

### ResolveIt `.env.devlabs`
```env
POSTGRES_USER=devslab_admin
POSTGRES_PASSWORD=devslab_secure_password_2024
BACKEND_PORT=3000
FRONTEND_PORT=3001
DATABASE_URL=postgresql://devslab_admin:...@devslab-postgres:5432/resolveit_db
```

### Gemura `.env.devlabs`
```env
POSTGRES_USER=devslab_admin
POSTGRES_PASSWORD=devslab_secure_password_2024
BACKEND_PORT=3004
FRONTEND_PORT=3005
DATABASE_URL=postgresql://devslab_admin:...@devslab-postgres:5432/gemura_db
```

**Same structure, different ports and database.**

## ✅ Health Check Endpoints

Both applications have identical health check implementations:

### ResolveIt
- Endpoint: `/api/health`
- Returns: `{ status: 'ok', message: 'ResolveIt API v2 is running', timestamp: ... }`

### Gemura
- Endpoint: `/api/health`
- Returns: `{ status: 'ok', service: 'Gemura API', version: '2.0.0', timestamp: ... }`

## 🔐 Security Configuration

Both use identical security settings:
- ✅ Helmet for security headers
- ✅ CORS with origin validation
- ✅ Trust proxy configuration
- ✅ Validation pipes
- ✅ Same network isolation

## 📊 Deployment Commands

### ResolveIt
```bash
# Build
docker compose -f docker-compose.resolveit.yml --env-file .env.devlabs build

# Start
docker compose -f docker-compose.resolveit.yml --env-file .env.devlabs up -d

# Logs
docker compose -f docker-compose.resolveit.yml logs -f
```

### Gemura
```bash
# Build
docker compose -f docker-compose.gemura.yml --env-file .env.devlabs build

# Start
docker compose -f docker-compose.gemura.yml --env-file .env.devlabs up -d

# Logs
docker compose -f docker-compose.gemura.yml logs -f
```

**Identical commands, different compose file names.**

## 🎯 Key Takeaways

1. ✅ **Same Infrastructure**: Both use shared `devslab-postgres` and `devslab-network`
2. ✅ **Same Pattern**: Identical docker-compose structure and deployment scripts
3. ✅ **Same Security**: Identical security configurations
4. ✅ **Same Process**: Same deployment workflow and commands
5. ✅ **Isolated Data**: Separate databases prevent conflicts
6. ✅ **Isolated Ports**: Different ports prevent conflicts

## 🚀 Why This Works

- **Proven Pattern**: ResolveIt deployment is working well in production
- **Consistency**: Same pattern = same reliability
- **Maintainability**: Easy to understand and maintain
- **Scalability**: Can add more applications using the same pattern
- **Resource Efficiency**: Shared PostgreSQL container saves resources

## 📝 Summary

Gemura deployment is a **direct copy** of ResolveIt's working deployment pattern, with only:
- Different application name
- Different ports (3004/3005 vs 3000/3001)
- Different database name (gemura_db vs resolveit_db)
- Different deployment path (/opt/gemura vs /opt/resolveit)

Everything else is **identical**, ensuring the same reliability and ease of deployment.

