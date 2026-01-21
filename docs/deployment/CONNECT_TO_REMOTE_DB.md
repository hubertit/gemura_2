# Connect Backend to Remote Database

**Last Updated**: January 20, 2026

---

## 🔍 **CURRENT STATUS**

The backend is currently connected to a **LOCAL** PostgreSQL database:
- **Host**: `localhost:5432`
- **Database**: `gemura_db`
- **NOT** connected to remote server (159.198.65.38)

---

## 🔄 **HOW TO CONNECT TO REMOTE DATABASE**

### Option 1: Update .env File (Recommended for Development)

Edit `backend/.env`:

```bash
# Change from:
DATABASE_URL="postgresql://postgres:@localhost:5432/gemura_db?schema=public"

# To:
DATABASE_URL="postgresql://devslab_admin:devslab_secure_password_2024@159.198.65.38:5433/gemura_db?schema=public"
```

**Note**: Port `5433` is the published port on the remote server (5432 is internal Docker port).

### Option 2: Use Environment Variable

Set `DATABASE_URL` before starting the backend:

```bash
export DATABASE_URL="postgresql://devslab_admin:devslab_secure_password_2024@159.198.65.38:5433/gemura_db?schema=public"
npm run start:dev
```

### Option 3: Use Docker Compose (Production)

The `docker-compose.gemura.yml` already configures remote database connection:

```yaml
DATABASE_URL: postgresql://devslab_admin:devslab_secure_password_2024@devslab-postgres:5432/gemura_db
```

This uses Docker networking (container name `devslab-postgres`).

---

## ✅ **VERIFY CONNECTION**

After updating, verify the connection:

### 1. Check Prisma Connection

```bash
cd backend
npx prisma migrate status
```

Should show: `PostgreSQL database "gemura_db" at "159.198.65.38:5433"`

### 2. Test Backend Health

```bash
curl http://localhost:3004/api/health
```

Should return: `{"status":"ok","service":"Gemura API",...}`

### 3. Check Database Connection

```bash
cd backend
npx prisma db execute --stdin <<< "SELECT current_database(), version();"
```

---

## 🚨 **TROUBLESHOOTING**

### Connection Refused

**Error**: `Connection refused` or `ECONNREFUSED`

**Solution**: 
- Verify remote server is accessible: `ping 159.198.65.38`
- Check if port 5433 is open: `nc -zv 159.198.65.38 5433`
- Ensure PostgreSQL is running on remote server

### Authentication Failed

**Error**: `password authentication failed`

**Solution**:
- Verify credentials: `devslab_admin` / `devslab_secure_password_2024`
- Check if user has access to `gemura_db` database

### Database Does Not Exist

**Error**: `database "gemura_db" does not exist`

**Solution**:
- Create database on remote server (see [Remote DB Sync](../migration/SYNC_REMOTE_DB_INSTRUCTIONS.md))
- Or connect to existing database

---

## 📝 **IMPORTANT NOTES**

1. **Local Development**: Use local database for faster development
2. **Testing**: Use remote database to test against production data
3. **Production**: Backend on server automatically uses remote database via Docker
4. **Security**: Never commit `.env` files with real credentials

---

## 🔗 **RELATED DOCUMENTATION**

- [Remote DB Sync](../migration/SYNC_REMOTE_DB_INSTRUCTIONS.md) - Sync schema changes
- [Deployment Guide](./DEPLOYMENT_GUIDE.md) - Production deployment
- [Database Configuration](./DEPLOYMENT_SETUP.md) - Database setup

---

**Last Updated**: January 20, 2026
