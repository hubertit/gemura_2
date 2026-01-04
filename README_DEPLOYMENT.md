# 🚀 Gemura Backend - Quick Deployment

## One-Command Deployment

On the server, run:

```bash
cd /path/to/gemura2
./deploy.sh
```

This script will:
1. ✅ Check pre-deployment requirements
2. ✅ Create database (if needed)
3. ✅ Build and deploy with Docker
4. ✅ Verify deployment

## Manual Deployment

If you prefer step-by-step:

### 1. Pre-Checks
```bash
cd backend
./scripts/pre-deployment-check.sh
```

### 2. Create Database
```bash
cd backend/scripts
export POSTGRES_PASSWORD=your_password
./create-database.sh
```

### 3. Configure Environment
```bash
cd /path/to/gemura2
cp .env.example .env
# Edit .env with your password
```

### 4. Deploy
```bash
docker-compose up -d --build
```

### 5. Verify
```bash
curl http://159.198.65.38:3004/health
```

## Access Points

- **API**: http://159.198.65.38:3004
- **Swagger Docs**: http://159.198.65.38:3004/api/docs
- **Health Check**: http://159.198.65.38:3004/health

## Troubleshooting

```bash
# View logs
docker-compose logs -f backend

# Restart
docker-compose restart backend

# Stop
docker-compose down
```

## What's Deployed

✅ **7 API Modules:**
- Authentication (login)
- Accounts (get, switch)
- Suppliers (create/update)
- Collections (record milk)
- Sales (list, update, cancel)
- Wallets (get)
- Profile (get, update)

✅ **Features:**
- Token-based authentication
- Swagger API documentation
- PostgreSQL database
- Docker deployment
- Health monitoring

## Next Steps

1. Test API endpoints via Swagger UI
2. Verify database migrations
3. Deploy frontend web app (port 3005)

