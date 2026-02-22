# Orora Platform

Orora is a comprehensive business management platform. Gemura is a subset of Orora focused on dairy/agricultural operations.

## Project Structure

```
orora/
├── apps/                       # Frontend Applications
│   ├── gemura-mobile/         # Gemura Mobile App (Flutter)
│   ├── gemura-web/            # Gemura Web App (Next.js)
│   ├── orora-mobile/          # Orora Mobile App (Flutter) - future
│   └── orora-web/             # Orora Web App (Next.js) - future
│
├── backend/                    # Shared NestJS API
│   ├── src/modules/           # Feature modules
│   └── prisma/                # Database schema
│
├── packages/                   # Shared Libraries
│   ├── shared-ui/             # Shared UI components
│   ├── api-client/            # Generated API client
│   └── shared-types/          # Shared TypeScript/Dart types
│
├── docs/                       # Documentation
│   ├── shared/                # Shared docs (API, architecture, deployment)
│   ├── gemura/                # Gemura-specific docs
│   └── orora/                 # Orora-specific docs
│
├── scripts/                    # Scripts
│   ├── shared/                # Shared scripts (deployment, migration)
│   ├── gemura/                # Gemura-specific scripts
│   └── orora/                 # Orora-specific scripts
│
├── docker/                     # Docker configurations
├── database/                   # Database files
└── .env                        # Environment variables
```

## Apps Overview

| App | Description | Modules |
|-----|-------------|---------|
| **Gemura** | Dairy/Agricultural management | Collections, Sales, Suppliers, Inventory, Payroll, Loans |
| **Orora** | Full business management | All Gemura modules + HR, Procurement, Assets, Projects, etc. |

## Getting Started

### Backend
```bash
cd backend
npm install
npm run start:dev
```

### Gemura Mobile
```bash
cd apps/gemura-mobile
flutter pub get
flutter run
```

### Gemura Web
```bash
cd apps/gemura-web
npm install
npm run dev
```

## Shared Database

All apps share the same PostgreSQL database and backend API. The API controls feature access based on the app context.

## Deployment

See `docs/shared/deployment/` for deployment guides.
