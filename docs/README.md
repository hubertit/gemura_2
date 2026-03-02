# Orora Documentation

Welcome to the Orora project documentation.

## Project Overview

Orora is a comprehensive Cattle Farming Platform built for livestock farmers in Rwanda. It includes web and mobile applications sharing a common backend API.

## Documentation Structure

```
docs/
├── README.md              # This file
├── orora/                 # Orora Platform Documentation
├── gemura/                # Gemura-specific (mobile, web)
└── shared/                # Shared (API, deployment, migration, testing, project)
```

## Numbered index (where to start)

1. **Overview** – [Orora README](./orora/README.md) or [Shared README](./shared/README.md)
2. **Deployment** – [Shared deployment](./shared/deployment/README.md) → [final-deployment-instructions.md](./shared/deployment/final-deployment-instructions.md)
3. **API** – [Shared API](./shared/api/README.md)
4. **Project structure** – [structure.md](./shared/structure.md), [project-organization](./shared/project/project-organization.md)
5. **Migration** – [Shared migration](./shared/migration/README.md)
6. **Testing** – [Shared testing](./shared/testing/README.md)
7. **Module integration & roadmap** – [Shared backend: module-integration-and-roadmap](./shared/backend/module-integration-and-roadmap.md) (best practices, accounting spine, assets/liabilities/production/inventory plan)

## Quick Links

### Orora Platform

| Document | Description |
|----------|-------------|
| [Overview](./orora/README.md) | Project overview and quick start |
| [Architecture](./orora/architecture.md) | System design and technology stack |
| [Roadmap](./orora/roadmap.md) | Development timeline and milestones |
| [Features](./orora/features.md) | Detailed feature specifications |
| [API](./orora/api.md) | REST API documentation |
| [Database](./orora/database.md) | Database schema and models |
| [Deployment](./orora/deployment.md) | Deployment and operations guide |
| [Mobile](./orora/mobile.md) | Mobile app development guide |
| [Feedback Strategy](./orora/feedback-strategy.md) | User feedback and communication plan |

## Project Timeline

| Milestone | Date | Status |
|-----------|------|--------|
| **Soft Launch** | March 15, 2026 | In Progress |
| **Beta** | April 15, 2026 | Planned |
| **v1.0 Release** | June 15, 2026 | Planned |

## Key Features

- **Animal Management** - Register and track individual cattle
- **Milk Collection** - Record daily milk production
- **Health Tracking** - Vaccinations, treatments, vet visits
- **Breeding Management** - Reproduction and calving records
- **Financial Operations** - Payments, loans, payroll
- **Inventory** - Feed, medicine, equipment tracking
- **Analytics** - Reports and data insights

## Platform Components

| Component | Technology | Port |
|-----------|------------|------|
| Orora Web | Next.js | 3011 |
| Orora Mobile | Flutter | - |
| Gemura Web | Next.js | 3006 |
| Backend API | NestJS | 3007 |
| Database | PostgreSQL | 5432 |

## Server

**Production:** 209.74.80.195 (Kwezi Server)

## Repository

https://github.com/hubertit/gemura_2
