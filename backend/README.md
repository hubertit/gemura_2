# Gemura Backend API

NestJS backend API for Gemura Financial Services, migrated from PHP/MySQL to NestJS/PostgreSQL.

## Features

- ✅ Token-based authentication (compatible with existing PHP API)
- ✅ Accounts management
- ✅ Suppliers management
- ✅ Milk collections
- ✅ Sales management
- ✅ Wallets
- ✅ User profiles
- ✅ Swagger API documentation

## Tech Stack

- **Framework**: NestJS 11.x
- **Database**: PostgreSQL (shared with ResolveIt v2)
- **ORM**: Prisma
- **Language**: TypeScript
- **Authentication**: Token-based (legacy compatible)

## Quick Start

### Prerequisites

- Node.js 20+
- Docker & Docker Compose
- Access to shared `devslab` PostgreSQL instance

### Local Development

1. Install dependencies:
```bash
npm install
```

2. Set up environment:
```bash
cp .env.example .env
# Edit .env with your database credentials
```

3. Generate Prisma Client:
```bash
npx prisma generate
```

4. Run migrations (when database is available):
```bash
npx prisma migrate dev
```

5. Start development server:
```bash
npm run start:dev
```

### Docker Deployment

See [DEPLOYMENT.md](../DEPLOYMENT.md) for full deployment instructions.

```bash
docker-compose up -d --build
```

## API Endpoints

All endpoints are prefixed with `/api`:

### Authentication
- `POST /api/auth/login` - User login

### Accounts
- `GET /api/accounts` - Get user accounts
- `GET /api/accounts/list` - List user accounts (alias)
- `POST /api/accounts/switch` - Switch default account

### Suppliers
- `POST /api/suppliers/create` - Create/update supplier

### Collections
- `POST /api/collections/create` - Record milk collection

### Sales
- `POST /api/sales/sales` - Get sales list (with filters)
- `PUT /api/sales/update` - Update sale
- `POST /api/sales/cancel` - Cancel sale

### Wallets
- `GET /api/wallets/get` - Get wallets for default account

### Profile
- `GET /api/profile/get` - Get user profile
- `PUT /api/profile/update` - Update user profile

## API Documentation

Swagger documentation available at:
- Development: `http://localhost:3004/api/docs`
- Production: `http://159.198.65.38:3004/api/docs`

## Database Schema

The database schema is defined in `prisma/schema.prisma`. All tables use:
- UUID primary keys
- `legacy_id` fields for migration reference
- Proper relations and indexes

## Response Format

All endpoints return responses in the format:
```json
{
  "code": 200,
  "status": "success",
  "message": "Operation successful",
  "data": { ... }
}
```

This matches the existing PHP API format for backward compatibility.

## Testing

```bash
# Unit tests
npm run test

# E2E tests
npm run test:e2e
```

## Build

```bash
npm run build
```

## License

Proprietary - Gemura Financial Services

