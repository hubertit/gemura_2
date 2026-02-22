# Orora System Architecture

## Overview

Orora follows a modern microservices-ready monolith architecture, designed for scalability while maintaining development simplicity.

```
┌─────────────────────────────────────────────────────────────────────────┐
│                              CLIENTS                                     │
├─────────────────┬─────────────────┬─────────────────────────────────────┤
│   Orora Mobile  │   Orora Web     │   Third-Party Integrations          │
│   (Flutter)     │   (Next.js)     │   (API Keys)                        │
└────────┬────────┴────────┬────────┴──────────────┬──────────────────────┘
         │                 │                        │
         │              HTTPS                       │
         │                 │                        │
┌────────▼─────────────────▼────────────────────────▼──────────────────────┐
│                         API GATEWAY / LOAD BALANCER                       │
│                         (Nginx / Cloud Load Balancer)                     │
└────────────────────────────────┬─────────────────────────────────────────┘
                                 │
┌────────────────────────────────▼─────────────────────────────────────────┐
│                         BACKEND API (NestJS)                              │
│  ┌─────────────┬─────────────┬─────────────┬─────────────┬─────────────┐ │
│  │   Auth      │   Animals   │   Milk      │   Inventory │   Payroll   │ │
│  │   Module    │   Module    │   Module    │   Module    │   Module    │ │
│  └─────────────┴─────────────┴─────────────┴─────────────┴─────────────┘ │
│  ┌─────────────┬─────────────┬─────────────┬─────────────┬─────────────┐ │
│  │   Loans     │   Charges   │   Analytics │   Users     │   Accounts  │ │
│  │   Module    │   Module    │   Module    │   Module    │   Module    │ │
│  └─────────────┴─────────────┴─────────────┴─────────────┴─────────────┘ │
└────────────────────────────────┬─────────────────────────────────────────┘
                                 │
┌────────────────────────────────▼─────────────────────────────────────────┐
│                         DATA LAYER                                        │
│  ┌─────────────────────────────────────────────────────────────────────┐ │
│  │                    PostgreSQL (Prisma ORM)                          │ │
│  │   gemura_db: accounts, users, animals, milk_sales, inventory, etc.  │ │
│  └─────────────────────────────────────────────────────────────────────┘ │
└──────────────────────────────────────────────────────────────────────────┘
```

## Technology Stack

### Backend

| Component | Technology | Purpose |
|-----------|------------|---------|
| Runtime | Node.js 18+ | JavaScript runtime |
| Framework | NestJS 10.x | Enterprise Node.js framework |
| ORM | Prisma 5.x | Type-safe database access |
| Database | PostgreSQL 15 | Primary data store |
| Auth | JWT + bcrypt | Authentication & authorization |
| Validation | class-validator | Request validation |
| Documentation | Swagger/OpenAPI | API documentation |

### Web Application (Orora Web)

| Component | Technology | Purpose |
|-----------|------------|---------|
| Framework | Next.js 14 | React framework with SSR |
| Styling | Tailwind CSS | Utility-first CSS |
| State | Zustand | Client-side state management |
| Forms | React Hook Form | Form handling |
| HTTP | Fetch API | API communication |

### Mobile Application (Orora Mobile)

| Component | Technology | Purpose |
|-----------|------------|---------|
| Framework | Flutter 3.x | Cross-platform mobile |
| State | Riverpod / Provider | State management |
| Storage | SharedPreferences + SQLite | Local data persistence |
| HTTP | Dio | API communication |
| Offline | Hive / Drift | Offline-first data sync |

## Module Architecture

### Core Modules

```
backend/src/modules/
├── auth/                 # Authentication & authorization
├── users/                # User management
├── accounts/             # Account/organization management
├── animals/              # 🆕 Livestock registration & tracking
├── milk-sales/           # Milk collection & sales
├── inventory/            # Product & stock management
├── suppliers/            # Supplier/farmer management
├── customers/            # Customer/MCC management
├── payroll/              # Payment processing
├── loans/                # Loan management
├── charges/              # Fee management
└── analytics/            # Reporting & insights
```

### Module Structure (Standard Pattern)

```
modules/animals/
├── animals.module.ts         # Module definition
├── animals.controller.ts     # REST endpoints
├── animals.service.ts        # Business logic
├── dto/
│   ├── create-animal.dto.ts  # Input validation
│   └── update-animal.dto.ts
├── entities/
│   └── animal.entity.ts      # Type definitions
└── tests/
    └── animals.service.spec.ts
```

## Data Architecture

### Multi-Tenancy Model

Orora uses an **account-based multi-tenancy** model:

```
Account (Tenant)
├── Users (with roles)
├── Animals (livestock)
├── MilkSales (collections)
├── Products (inventory)
├── Suppliers (farmers)
├── Customers (buyers)
└── PayrollRuns (payments)
```

### Key Relationships

```
Account (MCC/Farm)
    │
    ├── owns → Animals
    │              └── produces → MilkSales
    │
    ├── has → Suppliers (farmers)
    │              └── deliver → MilkSales
    │
    ├── has → Customers (buyers)
    │              └── receive → MilkSales
    │
    └── manages → Products (inventory)
                     └── sold via → InventorySales
```

## Authentication & Authorization

### Authentication Flow

```
┌──────────┐      ┌──────────┐      ┌──────────┐
│  Client  │──1──▶│   Auth   │──2──▶│   User   │
│          │      │  Module  │      │   DB     │
└──────────┘      └──────────┘      └──────────┘
     │                 │
     │◀───3. JWT───────┤
     │                 │
     ├───4. Request────▶ (with JWT in header)
     │                 │
     │◀───5. Response──┤
```

1. Client sends credentials (phone + password)
2. Auth module validates against database
3. Returns JWT token (7-day expiry)
4. Client includes token in Authorization header
5. Protected endpoints validate token

### Role-Based Access Control (RBAC)

| Role | Permissions |
|------|-------------|
| `owner` | Full access to account |
| `admin` | Manage users, settings |
| `manager` | Manage operations, view reports |
| `collector` | Record milk collections |
| `supplier` | View own data, submit milk |
| `viewer` | Read-only access |

## API Design

### RESTful Conventions

```
GET    /api/animals          # List all animals
POST   /api/animals          # Create animal
GET    /api/animals/:id      # Get single animal
PATCH  /api/animals/:id      # Update animal
DELETE /api/animals/:id      # Delete animal
```

### Response Format

```json
{
  "success": true,
  "data": { ... },
  "meta": {
    "page": 1,
    "limit": 20,
    "total": 100
  }
}
```

### Error Format

```json
{
  "success": false,
  "error": {
    "code": "VALIDATION_ERROR",
    "message": "Invalid input",
    "details": [...]
  }
}
```

## Deployment Architecture

### Production (Kwezi Server)

```
┌─────────────────────────────────────────────────────────────┐
│                    Kwezi Server (209.74.80.195)             │
├─────────────────────────────────────────────────────────────┤
│                                                             │
│  ┌─────────────────┐  ┌─────────────────┐                  │
│  │  Orora Web      │  │  Gemura Web     │                  │
│  │  :3011          │  │  :3006          │                  │
│  └────────┬────────┘  └────────┬────────┘                  │
│           │                    │                            │
│  ┌────────▼────────────────────▼────────┐                  │
│  │         Gemura Backend API           │                  │
│  │         :3007                        │                  │
│  └────────────────────┬─────────────────┘                  │
│                       │                                     │
│  ┌────────────────────▼─────────────────┐                  │
│  │         kwezi-postgres               │                  │
│  │         :5432                        │                  │
│  │   ├── gemura_db                      │                  │
│  │   └── (other databases)              │                  │
│  └──────────────────────────────────────┘                  │
│                                                             │
└─────────────────────────────────────────────────────────────┘
```

### Port Allocation

| Port | Service |
|------|---------|
| 3006 | Gemura Web |
| 3007 | Gemura/Orora Backend API |
| 3011 | Orora Web |
| 5432 | PostgreSQL |

## Security Considerations

### Authentication Security

- Passwords hashed with bcrypt (cost factor 10)
- JWT tokens with 7-day expiration
- Refresh token rotation (planned)
- Rate limiting on auth endpoints

### Data Security

- All API endpoints require authentication (except public)
- Account-level data isolation
- SQL injection prevention via Prisma ORM
- Input validation on all endpoints

### Infrastructure Security

- HTTPS in production
- Firewall rules limiting port access
- Docker container isolation
- Regular security updates

## Scalability Considerations

### Current Architecture (MVP)

- Single server deployment
- Shared PostgreSQL database
- Stateless API design
- Horizontal scaling ready

### Future Scaling (Post-MVP)

1. **Database**: Read replicas, connection pooling
2. **Caching**: Redis for session and query caching
3. **CDN**: Static assets via CDN
4. **Load Balancing**: Multiple API instances
5. **Microservices**: Split modules if needed

## Monitoring & Observability

### Logging

- Structured JSON logs
- Request/response logging
- Error tracking with stack traces

### Health Checks

- `GET /api/health` - API health
- Database connectivity check
- Memory/CPU monitoring

### Metrics (Planned)

- Request latency
- Error rates
- Database query performance
- Active users
