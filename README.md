# Gemura 2.0

Modern financial services platform for milk collection and distribution management.

## 🚀 Project Overview

Gemura is a comprehensive platform that helps manage milk collection, sales, and financial operations. This v2.0 rewrite migrates from PHP/MySQL to NestJS/PostgreSQL for better performance, scalability, and maintainability.

## 📁 Project Structure

```
gemura2/
├── README.md                    # This file
├── docker-compose.yml           # Local development
├── docker-compose.gemura.yml    # Production deployment
├── docker-compose.devlabs-db.yml # Shared database
├── env.example                  # Environment variables template
│
├── backend/                     # NestJS Backend API
│   ├── src/                     # Source code
│   │   ├── modules/            # Feature modules
│   │   ├── common/             # Shared utilities
│   │   └── prisma/             # Database module
│   ├── prisma/                 # Database schema & migrations
│   ├── scripts/                # Backend utility scripts
│   └── docs/                   # Backend documentation
│
├── mobile/                      # Flutter Mobile App
│   ├── lib/                    # Dart source code
│   ├── android/                # Android configuration
│   ├── ios/                    # iOS configuration
│   └── assets/                 # App assets
│
├── docs/                        # Project Documentation
│   ├── project/                # Project overview & status
│   ├── deployment/             # Deployment guides
│   ├── api/                    # API documentation
│   ├── mobile/                 # Mobile app docs
│   ├── testing/                # Test results
│   ├── migration/              # Migration guides
│   └── archive/                # Archived docs
│
├── scripts/                     # Utility Scripts
│   ├── deployment/             # Deployment scripts
│   ├── testing/                # Testing scripts
│   ├── migration/              # Migration scripts
│   └── utils/                  # Utility scripts
│
└── database/                     # Database files
    └── gemura.sql              # Legacy database dump
```

## 🏗️ Technology Stack

- **Backend:** NestJS (TypeScript) with Prisma ORM
- **Database:** PostgreSQL 15+
- **Mobile:** Flutter (Dart)
- **Deployment:** Docker & Docker Compose
- **API Docs:** Swagger/OpenAPI

## 📚 Documentation

All documentation is organized in the [`docs/`](./docs/) directory:

- **[Project Overview](./docs/project/)** - Project status and organization
- **[Deployment Guide](./docs/deployment/)** - Complete deployment instructions
- **[API Documentation](./docs/api/)** - API endpoints and usage
- **[Mobile App](./docs/mobile/)** - Mobile app integration guides
- **[Testing](./docs/testing/)** - Test results and verification
- **[Migration](./docs/migration/)** - Data migration guides

See [docs/README.md](./docs/README.md) for complete documentation index.

## 🚀 Quick Start

### Prerequisites

- Node.js 20+
- Docker & Docker Compose
- PostgreSQL 15+ (or use DevLabs shared database)
- Flutter SDK (for mobile development)

### Backend Setup

```bash
cd backend
npm install
npx prisma generate
npm run start:dev
```

### Mobile Setup

```bash
cd mobile
flutter pub get
flutter run
```

### Deployment

**Quick deployment:**
```bash
./scripts/deployment/deploy-to-server.sh
```

See [Deployment Guide](./docs/deployment/FINAL_DEPLOYMENT_INSTRUCTIONS.md) for detailed instructions.

## 🌐 Production URLs

- **API Base:** http://159.198.65.38:3004/api
- **Swagger Docs:** http://159.198.65.38:3004/api/docs
- **Health Check:** http://159.198.65.38:3004/api/health

## ✅ Current Status

### Implemented Features

- ✅ Authentication & Authorization (6 endpoints)
- ✅ Multi-Account Management (3 endpoints)
- ✅ Sales Module (4 endpoints) - **Recently Completed**
- ✅ Collections Module (11 endpoints) - **Recently Completed**
- ✅ Suppliers Module (6 endpoints) - **Recently Completed**
- ✅ Customers Module (6 endpoints) - **Recently Completed**
- ✅ Inventory Module (5 endpoints)
- ✅ Feed Module (Posts, Comments, Interactions)
- ✅ Market Module (Products, Orders, Categories)
- ✅ Accounting Module
- ✅ Payroll Module
- ✅ Analytics & Reporting
- ✅ Mobile App Integration

### Recent Updates (January 20, 2026)

- ✅ **UUID Consistency**: All endpoints now prioritize UUIDs over account codes
- ✅ **Soft Delete**: All delete operations preserve data (status-based)
- ✅ **Default Status**: Sales and collections default to 'accepted' status
- ✅ **Account IDs**: All responses include account UUIDs
- ✅ **Swagger Documentation**: All endpoints fully documented

### Development Status

See [Implementation Status](./docs/project/IMPLEMENTATION_STATUS.md) for detailed progress.

## 📖 Key Documentation

### Getting Started
- [Project Organization](./docs/project/PROJECT_ORGANIZATION.md) - Project structure
- [Deployment Guide](./docs/deployment/DEPLOYMENT_GUIDE.md) - How to deploy

### Development
- [API Documentation](./docs/api/README.md) - API endpoints
- [Mobile Integration](./docs/mobile/MOBILE_APP_INTEGRATION.md) - Mobile app guide

### Operations
- [Deployment Optimization](./docs/deployment/DEPLOYMENT_OPTIMIZATION.md) - Performance tips
- [Testing Results](./docs/testing/README.md) - Test verification

## 🔧 Scripts

All utility scripts are in [`scripts/`](./scripts/):

- **Deployment:** `scripts/deployment/deploy-to-server.sh`
- **Testing:** `scripts/testing/test-backend-simple.sh`
- **Migration:** `scripts/migration/migrate-data.sh`

See [scripts/README.md](./scripts/README.md) for complete script documentation.

## 📝 Development Workflow

1. **Make changes** to code
2. **Test locally** using development environment
3. **Deploy** using automated deployment script
4. **Verify** using health checks and tests

## 🤝 Contributing

When contributing:
1. Follow the existing code structure
2. Update relevant documentation
3. Add tests for new features
4. Follow the deployment process

## 📧 Support

For issues or questions:
- Check [Documentation](./docs/README.md)
- Review [Deployment Guide](./docs/deployment/README.md)
- Check [API Documentation](./docs/api/README.md)

---

**Version:** 2.0.0  
**Last Updated:** January 20, 2026  
**Status:** ✅ Production Ready | Core Modules Complete
