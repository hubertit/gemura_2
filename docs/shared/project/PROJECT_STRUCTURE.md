# Gemura 2.0 - Project Structure

Complete project structure and organization guide.

## 📁 Directory Structure

```
gemura2/
│
├── 📄 README.md                    # Main project README
├── 📄 PROJECT_STRUCTURE.md          # This file
├── 📄 env.example                   # Environment variables template
│
├── 🐳 docker-compose.yml            # Local development compose
├── 🐳 docker-compose.gemura.yml     # Production deployment compose
├── 🐳 docker-compose.devlabs-db.yml # Shared database compose
│
├── 📂 backend/                      # NestJS Backend
│   ├── 📄 README.md                 # Backend documentation
│   ├── 📄 Dockerfile                # Backend Docker image
│   ├── 📄 package.json               # Dependencies
│   │
│   ├── 📂 src/                      # Source code
│   │   ├── 📄 main.ts               # Application entry point
│   │   ├── 📂 modules/              # Feature modules
│   │   │   ├── auth/               # Authentication
│   │   │   ├── accounts/            # Account management
│   │   │   ├── feed/                # Feed module
│   │   │   ├── market/              # Market module
│   │   │   └── ...                  # Other modules
│   │   ├── 📂 common/               # Shared utilities
│   │   │   ├── guards/             # Auth guards
│   │   │   ├── decorators/         # Custom decorators
│   │   │   └── interceptors/      # Interceptors
│   │   └── 📂 prisma/              # Database module
│   │
│   ├── 📂 prisma/                   # Database
│   │   ├── 📄 schema.prisma         # Database schema
│   │   └── 📂 migrations/          # Database migrations
│   │
│   ├── 📂 scripts/                  # Backend scripts
│   │   └── ...                     # Utility scripts
│   │
│   └── 📂 docs/                     # Backend documentation
│       └── 📂 analysis/            # Analysis docs
│
├── 📂 mobile/                       # Flutter Mobile App
│   ├── 📄 pubspec.yaml              # Flutter dependencies
│   │
│   ├── 📂 lib/                      # Dart source code
│   │   ├── 📂 core/                 # Core services
│   │   │   ├── config/             # Configuration
│   │   │   ├── services/           # Services
│   │   │   └── theme/              # App theme
│   │   ├── 📂 features/             # Feature modules
│   │   │   ├── auth/               # Authentication
│   │   │   ├── feed/               # Feed feature
│   │   │   ├── market/             # Market feature
│   │   │   └── ...                 # Other features
│   │   └── 📂 shared/              # Shared components
│   │       └── widgets/            # Reusable widgets
│   │
│   ├── 📂 android/                  # Android configuration
│   ├── 📂 ios/                      # iOS configuration
│   └── 📂 assets/                   # App assets
│
├── 📂 docs/                          # Project Documentation
│   ├── 📄 README.md                 # Documentation index
│   │
│   ├── 📂 project/                  # Project docs
│   │   ├── 📄 IMPLEMENTATION_STATUS.md
│   │   └── 📄 PROJECT_ORGANIZATION.md
│   │
│   ├── 📂 architecture/             # Architecture docs
│   │   └── 📄 README.md
│   │
│   ├── 📂 deployment/                # Deployment guides
│   │   ├── 📄 README.md
│   │   ├── 📄 FINAL_DEPLOYMENT_INSTRUCTIONS.md
│   │   ├── 📄 DEPLOYMENT_GUIDE.md
│   │   ├── 📄 DEPLOYMENT_OPTIMIZATION.md
│   │   └── 📄 AUTOMATIC_DEPLOYMENT.md
│   │
│   ├── 📂 api/                       # API documentation
│   │   ├── 📄 README.md
│   │   ├── 📄 APP_FLOW_DOCUMENTATION.md
│   │   └── 📄 REMAINING_ENDPOINTS.md
│   │
│   ├── 📂 mobile/                    # Mobile app docs
│   │   ├── 📄 README.md
│   │   ├── 📄 MOBILE_APP_INTEGRATION.md
│   │   └── 📄 API_ENDPOINT_MIGRATION.md
│   │
│   ├── 📂 testing/                   # Test results
│   │   ├── 📄 README.md
│   │   └── ...                      # Test reports
│   │
│   ├── 📂 migration/                 # Migration guides
│   │   ├── 📄 README.md
│   │   └── ...                      # Migration docs
│   │
│   └── 📂 archive/                   # Archived docs
│       ├── 📂 deployment/
│       └── 📂 testing/
│
├── 📂 scripts/                       # Utility Scripts
│   ├── 📄 README.md                  # Scripts documentation
│   │
│   ├── 📂 deployment/                # Deployment scripts
│   │   ├── 📄 deploy-to-server.sh   # Main deployment ⭐
│   │   ├── 📄 check-available-ports.sh
│   │   └── 📄 README.md
│   │
│   ├── 📂 testing/                   # Testing scripts
│   │   ├── 📄 test-deployment.sh
│   │   └── 📄 test-backend-simple.sh
│   │
│   ├── 📂 migration/                 # Migration scripts
│   │   ├── 📄 migrate-data.sh
│   │   └── 📂 tables/                # Table migrations
│   │
│   └── 📂 utils/                     # Utility scripts
│       └── 📄 check-backend-status.sh
│
└── 📂 database/                       # Database files
    └── 📄 gemura.sql                 # Legacy database dump
```

## 🎯 Key Directories

### `/backend`
NestJS backend API with TypeScript.

**Key Files:**
- `src/main.ts` - Application entry point
- `src/modules/` - Feature modules
- `prisma/schema.prisma` - Database schema

### `/mobile`
Flutter mobile application.

**Key Files:**
- `lib/main.dart` - App entry point
- `lib/features/` - Feature modules
- `lib/core/` - Core services

### `/docs`
All project documentation organized by category.

**Key Categories:**
- `deployment/` - Deployment guides
- `api/` - API documentation
- `mobile/` - Mobile app docs
- `testing/` - Test results

### `/scripts`
Utility scripts for deployment, testing, and migration.

**Key Scripts:**
- `deployment/deploy-to-server.sh` - Main deployment
- `testing/test-backend-simple.sh` - Backend testing

## 📋 File Naming Conventions

### Documentation
- `README.md` - Directory index/overview
- `*_GUIDE.md` - How-to guides
- `*_STATUS.md` - Status reports
- `*_RESULTS.md` - Test/execution results

### Scripts
- `*.sh` - Shell scripts
- `deploy-*.sh` - Deployment scripts
- `test-*.sh` - Testing scripts
- `migrate-*.sh` - Migration scripts

### Code
- `*.ts` - TypeScript files
- `*.dart` - Dart files
- `*.prisma` - Prisma schema files

## 🔍 Finding Files

### Need to deploy?
→ `scripts/deployment/deploy-to-server.sh`

### Looking for API docs?
→ `docs/api/README.md`

### Want deployment guide?
→ `docs/deployment/FINAL_DEPLOYMENT_INSTRUCTIONS.md`

### Need project status?
→ `docs/project/IMPLEMENTATION_STATUS.md`

### Looking for backend code?
→ `backend/src/modules/`

### Need mobile app code?
→ `mobile/lib/features/`

## 📚 Documentation Hierarchy

1. **Main README** (`README.md`) - Project overview
2. **Category READMEs** (`docs/*/README.md`) - Category overviews
3. **Specific Docs** - Detailed documentation files

## ✅ Organization Principles

1. **Clear Separation** - Backend, mobile, docs, scripts
2. **Logical Grouping** - Related files together
3. **Easy Navigation** - README files in each directory
4. **Consistent Naming** - Standard naming conventions
5. **Archive Old** - Outdated docs in archive/

---

**Last Updated:** January 18, 2026  
**Status:** ✅ Well Organized
