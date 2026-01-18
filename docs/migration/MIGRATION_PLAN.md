# Gemura API Migration Plan: PHP/MySQL → NestJS/PostgreSQL

## 📋 Executive Summary

This document outlines the comprehensive migration plan for converting the Gemura API from PHP/MySQL to NestJS/PostgreSQL, while maintaining all existing functionalities and adding new Accounting and Payroll modules. The migration will follow the architecture patterns established in the ResolveIt v2 reference project.

---

## 🎯 Migration Objectives

1. **Preserve Functionality**: All existing API endpoints and business logic must remain intact
2. **Modernize Stack**: Migrate from PHP/MySQL to NestJS/PostgreSQL
3. **Add New Modules**: Implement Accounting and Payroll modules
4. **Web App Support**: Architecture must support both mobile and web applications
5. **Maintain API Compatibility**: Ensure backward compatibility during transition period

---

## 📊 Current System Analysis

### PHP API Structure
```
/api/v2/
├── auth/ (login, register, reset_password, verify_token)
├── accounts/ (get, list, manage_permissions, register_user, switch)
├── analytics/ (collections, customers, metrics, datasets, dimensions, exports)
├── api_keys/ (get)
├── collections/ (create, get, update, cancel)
├── customers/ (create, get, update, delete)
├── employees/ (create, get, update-access, delete)
├── kyc/ (upload_photo)
├── market/
│   ├── categories/ (create, get, list, update, delete)
│   ├── orders/ (create, get, list, update_status, admin, customers, sellers)
│   └── products/ (create, get, list, update, delete, search, featured, recent)
├── notifications/ (create, get, update, delete)
├── profile/ (get, update)
├── reports/ (my_report)
├── sales/ (sales, sell, update, cancel)
├── stats/ (overview, stats)
├── suppliers/ (create, get, update, delete)
└── wallets/ (get)
```

### ⚠️ Compatibility-critical behaviors (must remain unchanged)

1. **Authentication is “token-based”, not JWT**  
   - Most endpoints expect a `token` **in the JSON body** (and some also accept `token` as a query param; see `configs/token.php`).  
   - Mobile also sometimes sends `Authorization: Bearer <token>` (Flutter `AuthenticatedDioService`) while still sending `token` in request bodies in some services.

2. **Response envelope is not uniform across the API**  
   - Many endpoints return: `{ code, status, message, data }` (e.g., `auth/login.php`).  
   - Market order endpoints return: `{ success: boolean, data|error }` (e.g., `market/orders/admin/admin-list.php`, `market/orders/customers/my-orders.php`).  
   **Migration must preserve these shapes per endpoint** (or provide a compatibility layer).

3. **Authorization rules vary by module**  
   - Some market order endpoints rely only on query params like `customer_id`/`seller_id` with no token check (current behavior).  
   - We should improve security later, but **Phase 1 must keep existing behavior** to avoid breaking clients.

### ⚠️ Data/Schema anomalies to account for in migration

- **`user_accounts` table engine/collation differs**: defined as `MyISAM` with `latin1` while storing JSON in `permissions` (migration should normalize to Postgres JSONB + proper indexes).  
- **`users.token` is the session/auth token** currently used by clients; it must be preserved during cutover.  
- `configs/token.php` appears to reference `user_id` (but the `users` table uses `id`). This suggests legacy drift; we should rely on actual field usage in active endpoints and add contract tests.

### Database Schema (25 Tables)
1. `accounts` - Tenant/branch accounts
2. `users` - User accounts
3. `user_accounts` - User-account relationships with roles
4. `suppliers_customers` - Supplier-customer relationships
5. `milk_sales` - Milk collection/sales transactions
6. `products` - Market products
7. `product_categories` - Product categorization
8. `product_images` - Product images
9. `orders` - Market orders
10. `order_items` - Order line items
11. `feed_posts` - Social feed posts
12. `feed_stories` - Social feed stories
13. `feed_comments` - Post comments
14. `feed_interactions` - User interactions (likes, shares)
15. `user_bookmarks` - Bookmarked posts
16. `user_relationships` - User follow relationships
17. `wallets` - User wallets
18. `notifications` - User notifications
19. `categories` - Feed categories
20. `api_keys` - API key management
21. `password_resets` - Password reset tokens
22. `user_onboardings` - User onboarding tracking
23. `user_points` - User points/rewards system
24. `user_referrals` - Referral system
25. `user_rewards` - User rewards

---

## 🏗️ Target Architecture (NestJS/PostgreSQL)

### Project Structure
```
gemura-backend/
├── prisma/
│   ├── schema.prisma
│   └── migrations/
├── src/
│   ├── common/
│   │   ├── decorators/
│   │   ├── filters/
│   │   ├── guards/
│   │   ├── interceptors/
│   │   └── pipes/
│   ├── config/
│   │   ├── database.config.ts
│   │   └── app.config.ts
│   ├── modules/
│   │   ├── auth/
│   │   ├── accounts/
│   │   ├── analytics/
│   │   ├── collections/
│   │   ├── customers/
│   │   ├── employees/
│   │   ├── kyc/
│   │   ├── market/
│   │   │   ├── categories/
│   │   │   ├── products/
│   │   │   └── orders/
│   │   ├── notifications/
│   │   ├── profile/
│   │   ├── reports/
│   │   ├── sales/
│   │   ├── stats/
│   │   ├── suppliers/
│   │   ├── wallets/
│   │   ├── feed/
│   │   │   ├── posts/
│   │   │   ├── stories/
│   │   │   ├── comments/
│   │   │   └── interactions/
│   │   ├── accounting/ ⭐ NEW
│   │   └── payroll/ ⭐ NEW
│   ├── prisma/
│   │   └── prisma.service.ts
│   └── main.ts
├── package.json
├── tsconfig.json
└── nest-cli.json
```

---

## 📐 Database Migration Strategy

### Prisma Schema Design Principles

1. **Preserve existing IDs for compatibility**: keep numeric IDs (`bigint`/`int`) for all existing tables to avoid breaking mobile/web payloads.
2. **Keep legacy token behavior**: preserve `users.token` and token lookup patterns during migration/cutover.
3. **Timestamps**: Standard `created_at` and `updated_at` fields
4. **Soft Deletes**: Use `deleted_at` instead of hard deletes where appropriate
5. **Relationships**: Proper foreign keys with cascade rules
6. **Enums**: Use Prisma enums for status fields
7. **Indexes**: Optimize for common query patterns

### Key Schema Changes

#### MySQL → PostgreSQL Conversions
- `bigint(20) UNSIGNED` → `BigInt` (Prisma) / `BIGINT` (Postgres)
- `int(11)` → `Int` / `INTEGER`
- `enum()` → Prisma `enum` type
- `timestamp` → `DateTime`
- `varchar(n)` → `String`
- `text` → `String` (unlimited)
- `decimal(10,2)` → `Decimal`

#### New Tables for Accounting Module (per `ACCOUNTING_MODULE_DATABASE_TABLES.md`)

We will implement the accounting module around these core tables (IDs as `BIGINT` for consistency with current DB):

- `chart_of_accounts`
- `accounting_transactions`
- `accounting_transaction_entries`
- `supplier_ledger`
- `fee_types`
- `supplier_fee_rules`
- `supplier_deductions`
- `invoices`, `invoice_items`
- `receipts`
- `audit_logs`
- Optional add-ons: `supplier_loans`, `loan_payments`

#### New Tables for Payroll Module (planned)

Payroll will be designed to integrate with accounting (auto-post salary expense + payables). Proposed tables:

- `payroll_employees` (link to `users` and/or `accounts`)
- `payroll_periods`
- `payroll_runs` (processing batches per period)
- `payroll_payslips` (per employee per run)
- `payroll_deductions` (tax/benefits/loan/fees; supports fixed + percentage)
- `payroll_payments` (cash/bank/mobile money; supports partial payments)

> We will finalize payroll schema after confirming how the current (legacy) web UI expects payroll fields, and after aligning with the Accounting module’s “fee/deductions” approach.

---

## 🔄 API Endpoint Migration Mapping

### Authentication Module
| PHP Endpoint | NestJS Route | Method | Status |
|-------------|--------------|--------|--------|
| `/auth/login.php` | `/auth/login` | POST | ✅ Migrate |
| `/auth/register.php` | `/auth/register` | POST | ✅ Migrate |
| `/auth/verify_token.php` | `/auth/verify` | POST | ✅ Migrate |
| `/auth/request_reset.php` | `/auth/forgot-password` | POST | ✅ Migrate |
| `/auth/reset_password.php` | `/auth/reset-password` | POST | ✅ Migrate |

### Configs / Utility Module (required for backward compatibility)
| PHP Endpoint | NestJS Route | Method | Status |
|-------------|--------------|--------|--------|
| `/configs/index.php` | `/configs` | GET | ✅ Migrate |
| `/configs/token.php` | `/auth/token` | GET/POST | ✅ Migrate |
| `/configs/validate.data.php` | (internal helper) | - | ✅ Re-implement |

### API Keys Module
| PHP Endpoint | NestJS Route | Method | Status |
|-------------|--------------|--------|--------|
| `/api_keys/get.php` | `/api-keys` | POST | ✅ Migrate |

### Accounts Module
| PHP Endpoint | NestJS Route | Method | Status |
|-------------|--------------|--------|--------|
| `/accounts/get.php` | `/accounts/:id` | GET | ✅ Migrate |
| `/accounts/list.php` | `/accounts` | GET | ✅ Migrate |
| `/accounts/register_user.php` | `/accounts/register-user` | POST | ✅ Migrate |
| `/accounts/switch.php` | `/accounts/switch` | POST | ✅ Migrate |
| `/accounts/manage_permissions.php` | `/accounts/:id/permissions` | PUT | ✅ Migrate |

### Employees Module
| PHP Endpoint | NestJS Route | Method | Status |
|-------------|--------------|--------|--------|
| `/employees/create.php` | `/employees` | POST | ✅ Migrate |
| `/employees/get.php` | `/employees` | GET | ✅ Migrate |
| `/employees/update-access.php` | `/employees/:id/access` | PUT | ✅ Migrate |
| `/employees/delete.php` | `/employees/:id` | DELETE | ✅ Migrate |

### Profile + KYC Module
| PHP Endpoint | NestJS Route | Method | Status |
|-------------|--------------|--------|--------|
| `/profile/get.php` | `/profile` | POST | ✅ Migrate |
| `/profile/update.php` | `/profile` | PUT | ✅ Migrate |
| `/kyc/upload_photo.php` | `/kyc/upload-photo` | POST | ✅ Migrate |

### Collections Module
| PHP Endpoint | NestJS Route | Method | Status |
|-------------|--------------|--------|--------|
| `/collections/create.php` | `/collections` | POST | ✅ Migrate |
| `/collections/get.php` | `/collections/:id` | GET | ✅ Migrate |
| `/collections/update.php` | `/collections/:id` | PUT | ✅ Migrate |
| `/collections/cancel.php` | `/collections/:id/cancel` | POST | ✅ Migrate |

### Customers Module
| PHP Endpoint | NestJS Route | Method | Status |
|-------------|--------------|--------|--------|
| `/customers/create.php` | `/customers` | POST | ✅ Migrate |
| `/customers/get.php` | `/customers/:id` | GET | ✅ Migrate |
| `/customers/update.php` | `/customers/:id` | PUT | ✅ Migrate |
| `/customers/delete.php` | `/customers/:id` | DELETE | ✅ Migrate |

### Suppliers Module
| PHP Endpoint | NestJS Route | Method | Status |
|-------------|--------------|--------|--------|
| `/suppliers/create.php` | `/suppliers` | POST | ✅ Migrate |
| `/suppliers/get.php` | `/suppliers/:id` | GET | ✅ Migrate |
| `/suppliers/update.php` | `/suppliers/:id` | PUT | ✅ Migrate |
| `/suppliers/delete.php` | `/suppliers/:id` | DELETE | ✅ Migrate |

### Sales Module
| PHP Endpoint | NestJS Route | Method | Status |
|-------------|--------------|--------|--------|
| `/sales/sell.php` | `/sales` | POST | ✅ Migrate |
| `/sales/sales.php` | `/sales` | GET | ✅ Migrate |
| `/sales/update.php` | `/sales/:id` | PUT | ✅ Migrate |
| `/sales/cancel.php` | `/sales/:id/cancel` | POST | ✅ Migrate |

### Wallets Module
| PHP Endpoint | NestJS Route | Method | Status |
|-------------|--------------|--------|--------|
| `/wallets/get.php` | `/wallets` | POST | ✅ Migrate |

### Market Module
| PHP Endpoint | NestJS Route | Method | Status |
|-------------|--------------|--------|--------|
| `/market/products/create.php` | `/market/products` | POST | ✅ Migrate |
| `/market/products/list.php` | `/market/products` | GET | ✅ Migrate |
| `/market/products/get.php` | `/market/products/:id` | GET | ✅ Migrate |
| `/market/products/update.php` | `/market/products/:id` | PUT | ✅ Migrate |
| `/market/products/delete.php` | `/market/products/:id` | DELETE | ✅ Migrate |
| `/market/products/search.php` | `/market/products/search` | GET | ✅ Migrate |
| `/market/products/featured.php` | `/market/products/featured` | GET | ✅ Migrate |
| `/market/products/recent.php` | `/market/products/recent` | GET | ✅ Migrate |
| `/market/categories/create.php` | `/market/categories` | POST | ✅ Migrate |
| `/market/categories/list.php` | `/market/categories` | GET | ✅ Migrate |
| `/market/categories/get.php` | `/market/categories/:id` | GET | ✅ Migrate |
| `/market/categories/update.php` | `/market/categories/:id` | PUT | ✅ Migrate |
| `/market/categories/delete.php` | `/market/categories/:id` | DELETE | ✅ Migrate |
| `/market/orders/create.php` | `/market/orders` | POST | ✅ Migrate |
| `/market/orders/list.php` | `/market/orders` | GET | ✅ Migrate |
| `/market/orders/get.php` | `/market/orders/:id` | GET | ✅ Migrate |
| `/market/orders/update_status.php` | `/market/orders/:id/status` | PUT | ✅ Migrate |
| `/market/orders/admin/admin-list.php` | `/market/orders/admin/list` | GET | ✅ Migrate |
| `/market/orders/admin/admin-details.php` | `/market/orders/admin/:id` | GET | ✅ Migrate |
| `/market/orders/customers/my-orders.php` | `/market/orders/customers/my-orders` | GET | ✅ Migrate |
| `/market/orders/customers/my-order-details.php` | `/market/orders/customers/my-order-details` | GET | ✅ Migrate |
| `/market/orders/customers/place-order.php` | `/market/orders/customers/place-order` | POST | ✅ Migrate |
| `/market/orders/customers/cancel-order.php` | `/market/orders/customers/cancel-order` | POST | ✅ Migrate |
| `/market/orders/sellers/seller-orders.php` | `/market/orders/sellers/orders` | GET | ✅ Migrate |
| `/market/orders/sellers/seller-order-details.php` | `/market/orders/sellers/order-details` | GET | ✅ Migrate |
| `/market/orders/sellers/update-status.php` | `/market/orders/sellers/update-status` | POST | ✅ Migrate |

> Note: market orders currently use `{success,data}` responses and query-parameter filtering; keep identical behavior during Phase 1.

### Feed Module
| PHP Endpoint | NestJS Route | Method | Status |
|-------------|--------------|--------|--------|
| Feed endpoints are consumed by the mobile app but are not present in `/api/v2` tree snapshot | (inventory from mobile + server) | Various | ✅ Migrate |

**Action:** Before implementation, create an explicit “Feed API contract” list by grepping the mobile services (e.g., `FeedService`) for the exact PHP paths used in production, then locate those PHP files in the server codebase (they may be outside `/api/v2`).

### Analytics Module
| PHP Endpoint | NestJS Route | Method | Status |
|-------------|--------------|--------|--------|
| `/analytics/collections.php` | `/analytics/collections` | GET | ✅ Migrate |
| `/analytics/customers.php` | `/analytics/customers` | GET | ✅ Migrate |
| `/analytics/metrics.php` | `/analytics/metrics` | GET | ✅ Migrate |

### Stats + Reports + Notifications Modules
| PHP Endpoint | NestJS Route | Method | Status |
|-------------|--------------|--------|--------|
| `/stats/overview.php` | `/stats/overview` | POST | ✅ Migrate |
| `/stats/stats.php` | `/stats` | POST | ✅ Migrate |
| `/reports/my_report.php` | `/reports/my-report` | POST | ✅ Migrate |
| `/notifications/create.php` | `/notifications` | POST | ✅ Migrate |
| `/notifications/get.php` | `/notifications` | POST | ✅ Migrate |
| `/notifications/update.php` | `/notifications/:id` | PUT | ✅ Migrate |
| `/notifications/delete.php` | `/notifications/:id` | DELETE | ✅ Migrate |

### Migration scripts (internal tooling; do not expose publicly)
| PHP Endpoint | NestJS Route | Method | Status |
|-------------|--------------|--------|--------|
| `/migrate/simple_migrate.php` | (admin-only scripts) | - | ✅ Replace |
| `/migrate/collections.php` | (admin-only scripts) | - | ✅ Replace |
| `/migrate/test_migration.php` | (removed) | - | ✅ Replace |
| `/migrate/test_simple.php` | (removed) | - | ✅ Replace |

### ⭐ NEW: Accounting Module
| Endpoint | Route | Method | Status |
|----------|-------|--------|--------|
| - | `/accounting/chart-of-accounts` | GET, POST, PUT, DELETE | 🆕 New |
| - | `/accounting/journal-entries` | GET, POST, PUT | 🆕 New |
| - | `/accounting/reports` | GET | 🆕 New |
| - | `/accounting/balance-sheet` | GET | 🆕 New |
| - | `/accounting/income-statement` | GET | 🆕 New |
| - | `/accounting/trial-balance` | GET | 🆕 New |

### ⭐ NEW: Payroll Module
| Endpoint | Route | Method | Status |
|----------|-------|--------|--------|
| - | `/payroll/employees` | GET, POST, PUT, DELETE | 🆕 New |
| - | `/payroll/periods` | GET, POST | 🆕 New |
| - | `/payroll/entries` | GET, POST, PUT | 🆕 New |
| - | `/payroll/process` | POST | 🆕 New |
| - | `/payroll/reports` | GET | 🆕 New |

---

## 🛠️ Implementation Phases

### Phase 1: Foundation Setup (Week 1-2)
- [ ] Initialize NestJS project structure
- [ ] Set up Prisma with PostgreSQL
- [ ] Create base Prisma schema from MySQL schema
- [ ] Implement **legacy token auth compatibility** first (token in body/query, optional Bearer token)
- [ ] Add JWT as **optional** (new clients) once legacy compatibility is green
- [ ] Configure environment variables
- [ ] Set up Docker for local development
- [ ] Create base modules structure
- [ ] Set up Swagger/OpenAPI documentation
 - [ ] Add contract tests (“golden” request/response snapshots) for every migrated PHP endpoint

### Phase 2: Core Modules Migration (Week 3-6)
- [ ] **Auth Module**: Login, register, password reset
- [ ] **Accounts Module**: Account management, switching, permissions
- [ ] **Users Module**: User CRUD operations
- [ ] **Profile Module**: Profile management, KYC
- [ ] **Suppliers Module**: Supplier CRUD
- [ ] **Customers Module**: Customer CRUD
- [ ] **Collections Module**: Milk collection management
- [ ] **Sales Module**: Sales transactions
- [ ] **Wallets Module**: Wallet management

### Phase 3: Market & Feed Modules (Week 7-9)
- [ ] **Market Categories**: Category management
- [ ] **Products Module**: Product CRUD, search, featured
- [ ] **Orders Module**: Order management, status updates
- [ ] **Feed Posts**: Post creation, listing, interactions
- [ ] **Feed Stories**: Story management
- [ ] **Feed Comments**: Comment system
- [ ] **Feed Interactions**: Likes, shares, bookmarks

### Phase 4: Analytics & Reports (Week 10-11)
- [ ] **Analytics Module**: Collections, customers, metrics
- [ ] **Stats Module**: Overview, statistics
- [ ] **Reports Module**: Report generation
- [ ] **Notifications Module**: Notification system

### Phase 5: New Modules - Accounting (Week 12-14)
- [ ] **Chart of Accounts**: Account structure management
- [ ] **Journal Entries**: Double-entry bookkeeping
- [ ] **Financial Reports**: Balance sheet, income statement, trial balance
- [ ] **Account Reconciliation**: Reconciliation features
- [ ] **Accounting Integration**: Link with sales, collections, payroll

### Phase 6: New Modules - Payroll (Week 15-17)
- [ ] **Employee Management**: Employee CRUD, positions, departments
- [ ] **Payroll Periods**: Period management
- [ ] **Payroll Processing**: Salary calculation, deductions
- [ ] **Payroll Reports**: Payslips, payroll summaries
- [ ] **Deductions Management**: Tax, benefits, loans
- [ ] **Payroll Integration**: Link with accounting

### Phase 7: Testing & Optimization (Week 18-19)
- [ ] Unit tests for all modules
- [ ] Integration tests
- [ ] API endpoint testing
- [ ] Performance optimization
- [ ] Security audit
- [ ] Documentation completion

### Phase 8: Deployment & Migration (Week 20-21)
- [ ] Database migration scripts
- [ ] Data migration from MySQL to PostgreSQL
- [ ] API deployment
- [ ] Mobile app API endpoint updates
- [ ] Web app API integration
- [ ] Monitoring and logging setup

---

## 🔐 Security Considerations

### Authentication & Authorization
- **Phase 1**: legacy `users.token` compatibility (do not break mobile)
- **Phase 2**: JWT for new clients + gradual migration plan
- Role-based access control (RBAC)
- Account-level permissions
- API key management for third-party integrations

### Data Protection
- Password hashing (bcrypt)
- Sensitive data encryption
- SQL injection prevention (Prisma ORM)
- XSS protection
- CORS configuration
- Rate limiting

### Audit Trail
- All mutations logged with user ID and timestamp
- Change tracking for critical data
- Login attempt logging
- API access logging

---

## 📱 Web App Architecture

### Next.js Structure (Following ResolveIt v2 pattern)

**Current state / reference:**
- The reference architecture is `resolveit/v2` (NestJS + Next.js).
- There is an existing legacy Angular frontend under `/Applications/AMPPS/www/gemura2` (includes payroll-related screens). We can use it to confirm required fields/flows, but the migration target is **a new Next.js web app** aligned with ResolveIt v2 patterns.
- In this repo, `ui/` is currently empty; it will become the new Next.js web app workspace.

```
gemura-web/
├── src/
│   ├── app/ (App Router)
│   │   ├── (auth)/
│   │   │   ├── login/
│   │   │   └── register/
│   │   ├── (dashboard)/
│   │   │   ├── dashboard/
│   │   │   ├── collections/
│   │   │   ├── sales/
│   │   │   ├── customers/
│   │   │   ├── suppliers/
│   │   │   ├── market/
│   │   │   ├── accounting/ ⭐ NEW
│   │   │   ├── payroll/ ⭐ NEW
│   │   │   └── reports/
│   │   └── api/ (API routes if needed)
│   ├── components/
│   │   ├── ui/ (shadcn/ui components)
│   │   ├── forms/
│   │   ├── tables/
│   │   └── charts/
│   ├── lib/
│   │   ├── api/ (API client)
│   │   ├── utils/
│   │   └── hooks/
│   └── store/ (State management - Zustand/Redux)
├── public/
└── package.json
```

### Key Features for Web App
1. **Admin Dashboard**: Full system management
2. **User Dashboard**: Account-specific views
3. **Accounting Dashboard**: Financial overview, reports
4. **Payroll Dashboard**: Employee management, payroll processing
5. **Analytics Dashboard**: Charts, graphs, insights
6. **Market Management**: Product and order management
7. **Feed Management**: Content moderation

---

## 🧪 Testing Strategy

### Unit Tests
- Service layer logic
- Business rules validation
- Utility functions

### Integration Tests
- API endpoint testing
- Database operations
- Authentication flows

### E2E Tests
- Critical user journeys
- Payment flows
- Reporting workflows

### Test Coverage Target
- Minimum 80% code coverage
- 100% coverage for critical paths

---

## 📚 Documentation Requirements

### API Documentation
- OpenAPI/Swagger specification
- Endpoint descriptions
- Request/response examples
- Error codes and messages

### Developer Documentation
- Setup instructions
- Architecture overview
- Module documentation
- Database schema documentation

### User Documentation
- API usage guides
- Web app user manual
- Accounting module guide
- Payroll module guide

---

## 🚀 Deployment Strategy

### Infrastructure
- **Backend**: NestJS on Node.js (Docker container)
- **Database**: PostgreSQL (managed service or Docker)
- **Web App**: Next.js (Vercel or self-hosted)
- **File Storage**: AWS S3 or similar for images/documents

### Docker deployment on the same server (port-safe)

We will deploy using the **same pattern as ResolveIt v2**:
- `docker-compose.yml` with env-substituted ports
- Non-standard Postgres host port to avoid collisions
- Separate backend/frontend host ports

#### Database will be on the same Docker/Postgres instance as ResolveIt (shared container)

Per requirement: Gemura will use the **same PostgreSQL container/instance** already running for ResolveIt (the “devslab” Postgres).  
We will create **a new database** inside that same Postgres server (e.g., `gemura_db`) and use the **same DB user** (`devslab`).

This means:
- **No new Postgres container**
- **No new Postgres host port**
- Only a new DB + migrations for Gemura

#### Default port proposal (chosen to avoid ResolveIt’s defaults)

ResolveIt uses `BACKEND_PORT=3000`, `FRONTEND_PORT=3001`, `POSTGRES_PORT=5433`.  
For Gemura on the same server, we will default to:

- **Gemura Backend (NestJS)**: `3100` (container `3000`)
- **Gemura Web UI (Next.js)**: `3101` (container `3001`)

All of these must remain **configurable** in `.env`:

```bash
GEMURA_BACKEND_PORT=3100
GEMURA_FRONTEND_PORT=3101
```

#### Create the new database on the shared Postgres (one-time)

Create the DB using the existing Postgres port/user (example uses ResolveIt’s published port `5433` and the shared user `devslab`):

```bash
psql -h localhost -p 5433 -U devslab -d postgres -c "CREATE DATABASE gemura_db;"
psql -h localhost -p 5433 -U devslab -d postgres -c "GRANT ALL PRIVILEGES ON DATABASE gemura_db TO devslab;"
```

#### Gemura backend DATABASE_URL (shared Postgres)

Gemura backend should point to the shared Postgres service:

- **Preferred (same Docker network as Postgres)**:
  - `DATABASE_URL=postgresql://devslab:<password>@devslab-postgres:5432/gemura_db`
- **Alternative (via host published port)**:
  - `DATABASE_URL=postgresql://devslab:<password>@<server-ip>:5433/gemura_db`

> The exact Postgres hostname inside Docker depends on the existing container/service name used by ResolveIt (commonly something like `devslab-postgres` or `resolveit-postgres`). We’ll attach Gemura backend container to that same Docker network so we can use the service name reliably.

#### Recommendation: do not expose Postgres publicly

If only the Gemura backend needs database access, we should **not publish** Postgres to a host port at all (remove `ports:` for Postgres in compose).  
Backend will connect via Docker network: `postgres:5432` (service name), same as ResolveIt’s pattern.  

Only expose `GEMURA_POSTGRES_PORT` when you explicitly need external admin access (e.g., from a workstation), and then ensure firewall rules restrict access.

#### “Do not use taken ports” checklist (run on the server before `up -d`)

Verify the intended ports are free (example):

```bash
netstat -tulpn | grep -E "3100|3101"
```

If any port is already in use, change the `.env` values and re-check.

#### Optional improvement (recommended): reverse proxy instead of exposing high ports

If the server already uses Nginx/Apache, we can proxy:
- `https://api.your-domain.tld` → Gemura backend container port
- `https://app.your-domain.tld` → Gemura frontend container port

This avoids exposing additional ports publicly, but we can still keep direct port binding available for debugging.

### Environment Setup
- Development
- Staging
- Production

### CI/CD Pipeline
- Automated testing
- Code quality checks
- Automated deployments
- Database migrations

---

## 📊 Migration Checklist

### Pre-Migration
- [ ] Complete system analysis
- [ ] Database schema design
- [ ] API endpoint mapping
- [ ] Architecture design approval
- [ ] Development environment setup

### During Migration
- [ ] Phase-by-phase implementation
- [ ] Continuous testing
- [ ] Code reviews
- [ ] Documentation updates
- [ ] Stakeholder updates

### Post-Migration
- [ ] Data migration verification
- [ ] API compatibility testing
- [ ] Performance benchmarking
- [ ] Security audit
- [ ] User acceptance testing
- [ ] Production deployment
- [ ] Monitoring setup

---

## 🎯 Success Criteria

1. ✅ All existing PHP endpoints replicated in NestJS
2. ✅ 100% API response compatibility
3. ✅ All data successfully migrated to PostgreSQL
4. ✅ Accounting module fully functional
5. ✅ Payroll module fully functional
6. ✅ Web app operational
7. ✅ Mobile app compatibility maintained
8. ✅ Performance equal or better than PHP version
9. ✅ Security standards met
10. ✅ Documentation complete

---

## 📝 Notes

- **API Versioning**: Consider maintaining `/v2` prefix for backward compatibility
- **Token Migration**: Need to migrate existing user tokens or force re-authentication
- **Data Migration**: Scripts needed to convert MySQL data to PostgreSQL format
- **Testing**: Parallel run period recommended before full cutover
- **Rollback Plan**: Keep PHP API running during transition period

---

## 🔗 References

- ResolveIt v2 Architecture: `/Applications/AMPPS/www/resolveit/v2`
- NestJS Documentation: https://docs.nestjs.com
- Prisma Documentation: https://www.prisma.io/docs
- PostgreSQL Documentation: https://www.postgresql.org/docs

---

**Document Version**: 1.0  
**Last Updated**: 2026-01-04  
**Author**: Migration Planning Team

