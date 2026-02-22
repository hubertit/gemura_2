# Scripts

Automation scripts for development, deployment, and maintenance.

## Structure

```
scripts/
├── shared/            # Shared scripts (used by all apps)
│   ├── deployment/   # Deployment scripts
│   ├── migration/    # Database migration scripts
│   ├── testing/      # Testing scripts
│   └── utils/        # Utility scripts
│
├── gemura/           # Gemura-specific scripts
│
└── orora/            # Orora-specific scripts
```

## Common Commands

### Deployment
```bash
./scripts/shared/deployment/deploy-backend.sh
./scripts/shared/deployment/deploy-gemura-web.sh
```

### Database
```bash
./scripts/shared/migration/backup-database.sh
./scripts/shared/migration/restore-database.sh
```

### Testing
```bash
./scripts/shared/testing/run-api-tests.sh
```
