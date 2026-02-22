# Scripts Directory

Utility scripts for deployment, testing, migration, and maintenance.

## 📁 Directory Structure

```
scripts/
├── README.md                    # This file
├── deployment/                   # Deployment scripts
│   ├── deploy-to-server.sh      # Main deployment script ⭐
│   ├── check-available-ports.sh
│   ├── find-available-port.sh
│   └── README.md
├── testing/                     # Testing scripts
│   ├── test-deployment.sh
│   ├── test-account-switching.sh
│   └── test-backend-simple.sh
├── migration/                   # Data migration scripts
│   ├── migrate-data.sh
│   ├── run-migration-on-server.sh
│   └── tables/                  # Table-specific migrations
└── utils/                       # Utility scripts
    └── check-backend-status.sh
```

## 🚀 Quick Reference

### Deployment

**Main deployment script:**
```bash
./scripts/deployment/deploy-to-server.sh
```

**Check available ports:**
```bash
./scripts/deployment/check-available-ports.sh
```

### Testing

**Test deployment readiness:**
```bash
./scripts/testing/test-deployment.sh
```

**Test backend:**
```bash
./scripts/testing/test-backend-simple.sh
```

### Utilities

**Check backend status:**
```bash
./scripts/utils/check-backend-status.sh
```

## 📚 Script Categories

### Deployment Scripts (`/deployment`)

Scripts for deploying the application to production.

**Key Scripts:**
- `deploy-to-server.sh` - Main automated deployment script
- `check-available-ports.sh` - Check server port availability
- `find-available-port.sh` - Find first available port

See [deployment/README.md](./deployment/README.md) for details.

### Testing Scripts (`/testing`)

Scripts for testing and verification.

**Key Scripts:**
- `test-deployment.sh` - Test deployment readiness
- `test-backend-simple.sh` - Simple backend health check
- `test-account-switching.sh` - Test account switching feature

### Migration Scripts (`/migration`)

Scripts for data migration from legacy system.

**Key Scripts:**
- `migrate-data.sh` - Main migration script
- `run-migration-on-server.sh` - Run migration on server
- `tables/*.sh` - Table-specific migration scripts

### Utility Scripts (`/utils`)

General utility scripts.

**Key Scripts:**
- `check-backend-status.sh` - Check backend health and status

## 🔧 Script Usage

### Making Scripts Executable

All scripts should be executable:
```bash
chmod +x scripts/**/*.sh
```

### Running Scripts

Always run from project root:
```bash
cd /path/to/gemura2
./scripts/deployment/deploy-to-server.sh
```

### Script Requirements

Most scripts require:
- `sshpass` - For password-based SSH
- `curl` - For HTTP requests
- `docker` - For container management
- `bash` - Bash shell (version 4+)

## 📝 Script Standards

All scripts follow these standards:
- **Error handling** - Use `set -e` for error handling
- **Logging** - Clear output with emojis and status indicators
- **Documentation** - Comments explaining what each section does
- **Portability** - Work on macOS and Linux
- **Safety** - Confirm destructive operations

## 🔍 Finding Scripts

### Need to deploy?
→ `scripts/deployment/deploy-to-server.sh`

### Want to test something?
→ `scripts/testing/`

### Need to migrate data?
→ `scripts/migration/`

### Looking for utilities?
→ `scripts/utils/`

## 🆕 Adding New Scripts

When adding new scripts:

1. **Place in appropriate directory**
   - Deployment → `deployment/`
   - Testing → `testing/`
   - Migration → `migration/`
   - Utilities → `utils/`

2. **Make executable**
   ```bash
   chmod +x scripts/category/new-script.sh
   ```

3. **Add to README**
   - Update this file or category-specific README
   - Document usage and requirements

4. **Follow standards**
   - Include error handling
   - Add clear logging
   - Document in comments

## 🔗 Related Documentation

- [Deployment Guide](../docs/deployment/README.md)
- [Testing Documentation](../docs/testing/README.md)
- [Migration Guide](../docs/migration/README.md)

---

**Last Updated:** January 18, 2026
