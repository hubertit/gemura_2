# Scripts

Automation scripts for development, deployment, and maintenance.

## Structure

```
scripts/
├── shared/            # Shared scripts (used by all apps)
│   ├── deployment/   # Legacy deployment scripts
│   ├── migration/    # Database migration scripts
│   ├── testing/      # Testing scripts
│   └── utils/        # Utility scripts
│
├── gemura/           # Gemura-specific scripts
│   └── deployment/   # Gemura deployment to Kwezi server
│
└── orora/            # Orora-specific scripts
    └── deployment/   # Orora deployment to Kwezi server
```

## Deployment Scripts

### Kwezi Server (209.74.80.195)

| App | Port | Command |
|-----|------|---------|
| Gemura Backend | 3007 | `./scripts/gemura/deployment/deploy-gemura.sh` |
| Gemura Web | 3006 | `./scripts/gemura/deployment/deploy-gemura.sh` |
| Orora Web | 3011 | `./scripts/orora/deployment/deploy-orora-web.sh` |

### Deploy Gemura (Backend + Web)
```bash
./scripts/gemura/deployment/deploy-gemura.sh
```

### Deploy Orora Web
```bash
./scripts/orora/deployment/deploy-orora-web.sh
```

## Server Port Allocation (Kwezi - 209.74.80.195)

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
| 3010 | (Reserved) |
| 3011 | Orora Web |

## Shared Scripts

The `scripts/shared/` directory contains common scripts used by all applications. All scripts now use the Kwezi server (209.74.80.195).

## Database Scripts

```bash
# Backup database
./scripts/shared/deployment/backup-production-to-local.sh

# Run migrations
./backend/scripts/run-migration.sh
```
