# Remote Database Connection Setup

**Last Updated**: January 20, 2026  
**Status**: ✅ Connected to Remote Database

---

## ✅ **CURRENT CONFIGURATION**

The backend is now connected to the **REMOTE** database:

- **Host**: `159.198.65.38:5433`
- **Database**: `gemura_db`
- **User**: `devslab_admin`
- **Connection**: Remote PostgreSQL (production)

---

## 📋 **CONNECTION DETAILS**

### DATABASE_URL
```
postgresql://devslab_admin:devslab_secure_password_2024@159.198.65.38:5433/gemura_db?schema=public
```

### Port Information
- **5433**: Published port on remote server (accessible externally)
- **5432**: Internal Docker port (used within Docker network)

---

## 🔄 **HOW IT WAS CONFIGURED**

The `backend/.env` file was updated with the remote database connection string.

### Before (Local):
```
DATABASE_URL="postgresql://postgres:@localhost:5432/gemura_db?schema=public"
```

### After (Remote):
```
DATABASE_URL="postgresql://devslab_admin:devslab_secure_password_2024@159.198.65.38:5433/gemura_db?schema=public"
```

---

## ✅ **VERIFICATION**

### 1. Check Prisma Connection
```bash
cd backend
npx prisma migrate status
```

Should show: `PostgreSQL database "gemura_db" at "159.198.65.38:5433"`

### 2. Test Database Query
```bash
cd backend
npx prisma db execute --stdin <<< "SELECT current_database(), version();"
```

### 3. Check Backend Health
```bash
curl http://localhost:3004/api/health
```

Should return: `{"status":"ok","service":"Gemura API",...}`

---

## 🔄 **RESTART BACKEND**

After updating the connection, restart the backend:

```bash
# Stop current backend (Ctrl+C in terminal)
# Then restart:
cd backend
npm run start:dev
```

---

## 🚨 **TROUBLESHOOTING**

### Connection Refused

**Error**: `ECONNREFUSED` or `Connection refused`

**Solution**:
- Verify server is accessible: `ping 159.198.65.38`
- Check port is open: `nc -zv 159.198.65.38 5433`
- Ensure PostgreSQL is running on remote server

### Authentication Failed

**Error**: `password authentication failed`

**Solution**:
- Verify credentials are correct
- Check if user `devslab_admin` has access to `gemura_db`

### Database Does Not Exist

**Error**: `database "gemura_db" does not exist`

**Solution**:
- Create database on remote server
- Or sync migrations (see [Remote DB Sync](../migration/SYNC_REMOTE_DB_INSTRUCTIONS.md))

---

## 📝 **IMPORTANT NOTES**

1. **Backup Created**: Original `.env` backed up as `.env.backup`
2. **Restart Required**: Backend must be restarted to use new connection
3. **Migrations**: Run `npx prisma migrate deploy` to sync schema
4. **Security**: Never commit `.env` files with credentials

---

## 🔗 **RELATED DOCUMENTATION**

- [Remote DB Sync](../migration/SYNC_REMOTE_DB_INSTRUCTIONS.md) - Sync schema changes
- [Deployment Guide](./DEPLOYMENT_GUIDE.md) - Production deployment
- [Connect to Remote DB](./CONNECT_TO_REMOTE_DB.md) - Connection instructions

---

**Last Updated**: January 20, 2026
