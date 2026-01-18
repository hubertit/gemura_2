# Gemura Backend API

NestJS backend API for Gemura Financial Services Platform.

## 📁 Structure

```
backend/
├── src/
│   ├── modules/          # Feature modules
│   │   ├── auth/         # Authentication
│   │   ├── accounts/     # Account management
│   │   ├── sales/        # Sales management
│   │   ├── collections/  # Collections management
│   │   ├── suppliers/    # Supplier management
│   │   ├── customers/    # Customer management
│   │   └── ...
│   ├── common/           # Shared utilities
│   │   ├── decorators/   # Custom decorators
│   │   ├── guards/       # Auth guards
│   │   ├── filters/      # Exception filters
│   │   └── interceptors/ # Interceptors
│   ├── prisma/           # Database module
│   └── main.ts           # Application entry point
├── prisma/
│   ├── schema.prisma     # Database schema
│   └── migrations/       # Database migrations
└── scripts/              # Utility scripts
```

## 🚀 Getting Started

### Installation

```bash
npm install
```

### Database Setup

```bash
# Generate Prisma client
npm run prisma:generate

# Run migrations
npm run prisma:migrate:dev

# Seed database (optional)
npm run prisma:seed
```

### Development

```bash
# Start development server
npm run start:dev

# Build for production
npm run build

# Start production server
npm run start:prod
```

## 📚 API Documentation

Swagger documentation is available at:
- **Local**: http://localhost:3004/api/docs
- **Production**: http://159.198.65.38:3004/api/docs

## 🔧 Configuration

Environment variables are configured in `.env` file. See `env.example` for reference.

Key variables:
- `DATABASE_URL` - PostgreSQL connection string
- `JWT_SECRET` - JWT secret key
- `PORT` - Server port (default: 3004)
- `CORS_ORIGIN` - Allowed CORS origins

## 📦 Modules

### Implemented Modules

- ✅ **Auth** - Authentication & authorization
- ✅ **Accounts** - Account management & switching
- ✅ **Sales** - Sales management
- ✅ **Collections** - Milk collections
- ✅ **Suppliers** - Supplier management
- ✅ **Customers** - Customer management
- ✅ **Wallets** - Wallet management
- ✅ **Profile** - User profile management

### Planned Modules

- ⏳ KYC - Know Your Customer
- ⏳ Notifications - Push notifications
- ⏳ Market - Product marketplace
- ⏳ Analytics - Analytics & reporting
- ⏳ Accounting - Accounting module
- ⏳ Payroll - Payroll management

## 🧪 Testing

```bash
# Run tests
npm run test

# Run tests with coverage
npm run test:cov

# E2E tests
npm run test:e2e
```

## 📝 Code Style

- TypeScript strict mode enabled
- ESLint for linting
- Prettier for formatting
- Follow NestJS best practices

## 🔐 Security

- JWT authentication
- Token-based authorization
- Input validation
- CORS protection
- Helmet security headers

## 🐳 Docker

```bash
# Build Docker image
docker build -t gemura-backend .

# Run with Docker Compose
docker-compose up -d
```

## 📊 Database

- **ORM**: Prisma
- **Database**: PostgreSQL 15
- **Migrations**: Prisma Migrate
- **Studio**: `npm run prisma:studio`

## 🔗 Related Documentation

- [Deployment Guide](../docs/deployment/)
- [API Documentation](../docs/api/)
- [Migration Plan](../docs/migration/)
