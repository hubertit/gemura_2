# Architecture Documentation

System architecture and design documentation for Gemura 2.0.

## 🏗️ System Architecture

### High-Level Overview

```
┌─────────────┐
│   Mobile    │  Flutter App
│   (Flutter) │
└──────┬──────┘
       │ HTTP/REST
       │
┌──────▼──────────────────┐
│   Backend API           │  NestJS Application
│   (NestJS/TypeScript)   │
└──────┬──────────────────┘
       │ Prisma ORM
       │
┌──────▼──────────┐
│   PostgreSQL    │  Database
│   (via DevLabs) │
└─────────────────┘
```

### Component Architecture

#### Backend (NestJS)
- **Framework:** NestJS with TypeScript
- **ORM:** Prisma
- **Database:** PostgreSQL
- **API Style:** RESTful
- **Documentation:** Swagger/OpenAPI

#### Mobile (Flutter)
- **Framework:** Flutter
- **Language:** Dart
- **State Management:** Riverpod
- **HTTP Client:** Dio
- **Architecture:** Feature-based modules

#### Database
- **Type:** PostgreSQL 15+
- **ORM:** Prisma
- **Location:** Shared DevLabs container
- **Network:** Docker network (devslab-network)

## 🔌 Integration Points

### API Communication
- **Protocol:** HTTP/HTTPS
- **Format:** JSON
- **Authentication:** Bearer Token
- **Base URL:** `http://159.198.65.38:3004/api`

### Database Connection
- **Connection String:** `postgresql://devslab_admin:password@devslab-postgres:5432/gemura_db`
- **Network:** Docker internal network
- **Port:** 5432 (internal), 5433 (host)

## 📦 Deployment Architecture

### Docker Setup
```
devslab-postgres (shared)
    │
    ├── gemura-backend (port 3004)
    └── resolveit-backend (port 3000)
```

### Network Configuration
- **Network:** `devslab-network`
- **Backend Port:** `3004`
- **Database Port:** `5433` (host), `5432` (container)

## 🔐 Security Architecture

### Authentication
- Token-based authentication
- JWT tokens
- Secure token storage (mobile)

### Authorization
- Role-based access control
- Account-based permissions
- Multi-account support

## 📊 Data Flow

### Request Flow
1. Mobile app → API request
2. Backend → Authenticate & authorize
3. Backend → Query database
4. Database → Return data
5. Backend → Transform & format
6. Backend → Return JSON response
7. Mobile app → Update UI

## 🔗 Module integration

Modules that affect money or value (sales, inventory, loans, receivables-payables, assets) **post to the accounting ledger** via a single posting path. Each such transaction is linked to the source event (`source_type` + `source_id`). See [Module Integration & Roadmap](../backend/module-integration-and-roadmap.md) for principles, current gaps, and implementation order (accounting extensions → posting from MilkSale/Inventory/Loans → assets → reporting).

---

## 🔗 Related Documentation

- [Deployment Guide](../deployment/README.md) - Deployment architecture
- [API Documentation](../api/README.md) - API architecture
- [Project Organization](../project/project-organization.md) - Project structure
- [Module Integration & Roadmap](../backend/module-integration-and-roadmap.md) - Cross-module linking and roadmap

---

**Last Updated:** March 2026
