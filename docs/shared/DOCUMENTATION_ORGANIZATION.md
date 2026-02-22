# Documentation Organization Guide

## Overview
This document describes the organization structure and naming conventions for all documentation files in the `/docs` directory.

## Directory Structure

```
docs/
├── README.md                          # Main documentation index
├── DOCUMENTATION_ORGANIZATION.md      # This file
│
├── project/                           # Project documentation
│   ├── README.md                      # Project docs index
│   ├── PROJECT_STRUCTURE.md           # Project structure guide
│   ├── PROJECT_ORGANIZATION.md       # Organization details
│   ├── IMPLEMENTATION_STATUS.md       # Current status
│   ├── MODULES_AND_FEATURES.md       # Features overview
│   ├── NEXT_STEPS.md                 # Roadmap
│   └── status/                        # Status reports
│       ├── ORGANIZATION_COMPLETE.md
│       └── PROJECT_DOCUMENTATION_COMPLETE.md
│
├── backend/                           # Backend documentation
│   ├── README.md                      # Backend docs index
│   ├── SWAGGER_DOCUMENTATION_STANDARDS.md
│   ├── API_DOCUMENTATION_STATUS.md
│   ├── DOCUMENTATION_ROADMAP.md
│   ├── analysis/                      # Analysis documents
│   │   ├── README_DEPLOYMENT.md
│   │   └── TODO_ANALYSIS.md
│   ├── modules/                       # Module-specific docs
│   │   └── ACCOUNTING_TRANSACTIONS.md
│   └── features/                      # Feature plans
│       └── INVENTORY_SALES_FEATURE_PLAN.md
│
├── api/                              # API documentation
│   ├── README.md
│   ├── API_ARCHITECTURE.md
│   ├── APP_FLOW_DOCUMENTATION.md
│   └── ...
│
├── mobile/                           # Mobile app documentation
│   ├── README.md
│   ├── MOBILE_APP_INTEGRATION.md
│   ├── ACCOUNT_SWITCHING_DATA_REFRESH.md
│   └── ...
│
├── deployment/                       # Deployment guides
│   ├── README.md
│   ├── DEPLOYMENT_GUIDE.md
│   └── ...
│
├── testing/                          # Test results
│   ├── README.md
│   └── ...
│
├── migration/                        # Migration guides
│   ├── README.md
│   └── ...
│
├── architecture/                     # Architecture docs
│   └── README.md
│
└── archive/                          # Archived docs
    ├── deployment/
    └── testing/
```

## Naming Conventions

### File Naming Standards

All documentation files follow these naming conventions:

1. **UPPERCASE_WITH_UNDERSCORES.md** - Standard format
   - Example: `PROJECT_STRUCTURE.md`, `API_DOCUMENTATION_STATUS.md`

2. **README.md** - Directory index files
   - Always lowercase
   - Present in every major directory

3. **Type Suffixes** (optional but recommended):
   - `*_GUIDE.md` - How-to guides
   - `*_STATUS.md` - Status reports
   - `*_PLAN.md` - Implementation plans
   - `*_RESULTS.md` - Test/execution results
   - `*_STRUCTURE.md` - Structure documentation
   - `*_COMPLETE.md` - Completion reports

### Examples

✅ **Good:**
- `SWAGGER_DOCUMENTATION_STANDARDS.md`
- `DEPLOYMENT_GUIDE.md`
- `ACCOUNT_SWITCHING_DATA_REFRESH.md`
- `INVENTORY_SALES_FEATURE_PLAN.md`

❌ **Bad:**
- `swagger-docs.md` (should be uppercase with underscores)
- `deployment-guide.md` (should be uppercase)
- `accountSwitching.md` (should use underscores)

## Directory Organization Rules

### 1. All Documentation in `/docs`
- ✅ All project documentation files belong in `/docs`
- ❌ No documentation files in root directory (except main README.md)
- ❌ No documentation files in `backend/docs` (moved to `docs/backend`)
- ❌ No documentation files in `backend/src/modules/*/` (moved to `docs/backend/modules/`)

### 2. Categorization
- **project/** - Project-wide documentation
- **backend/** - Backend-specific documentation
- **api/** - API endpoint documentation
- **mobile/** - Mobile app documentation
- **deployment/** - Deployment guides
- **testing/** - Test results
- **migration/** - Migration guides
- **architecture/** - System architecture
- **archive/** - Outdated/archived docs

### 3. Subdirectories
- Use subdirectories for logical grouping
- Each major directory should have a `README.md`
- Use `status/` subdirectory for status reports
- Use `analysis/` subdirectory for analysis documents
- Use `modules/` subdirectory for module-specific docs
- Use `features/` subdirectory for feature plans

## File Location Rules

### Where to Put Documentation

1. **Project-wide docs** → `docs/project/`
   - Structure, organization, status

2. **Backend docs** → `docs/backend/`
   - API documentation standards
   - Module documentation
   - Feature plans

3. **API docs** → `docs/api/`
   - API architecture
   - Endpoint documentation
   - Testing results

4. **Mobile docs** → `docs/mobile/`
   - Mobile app integration
   - UI/UX documentation
   - Testing results

5. **Deployment docs** → `docs/deployment/`
   - Deployment guides
   - Server configuration
   - Troubleshooting

6. **Test results** → `docs/testing/`
   - All test results and reports

7. **Migration docs** → `docs/migration/`
   - Data migration guides
   - Migration status

## Consistency Checklist

When adding or moving documentation:

- [ ] File is in `/docs` directory (not root or backend)
- [ ] File follows UPPERCASE_WITH_UNDERSCORES.md naming
- [ ] File is in the correct category directory
- [ ] Directory has a README.md if it's a major category
- [ ] File name is descriptive and consistent
- [ ] No duplicate files in different locations
- [ ] Old locations are cleaned up

## Migration Notes

### Files Moved (January 28, 2026)

- `PROJECT_STRUCTURE.md` → `docs/project/PROJECT_STRUCTURE.md`
- `backend/docs/README.md` → `docs/backend/README.md`
- `backend/docs/analysis/*` → `docs/backend/analysis/*`
- `backend/src/modules/accounting/transactions/README.md` → `docs/backend/modules/ACCOUNTING_TRANSACTIONS.md`
- `docs/inventory-sales-feature-plan.md` → `docs/backend/features/INVENTORY_SALES_FEATURE_PLAN.md`
- `docs/MODULES_AND_FEATURES.md` → `docs/project/MODULES_AND_FEATURES.md`
- `docs/NEXT_STEPS.md` → `docs/project/NEXT_STEPS.md`
- `docs/ORGANIZATION_COMPLETE.md` → `docs/project/status/ORGANIZATION_COMPLETE.md`
- `docs/PROJECT_DOCUMENTATION_COMPLETE.md` → `docs/project/status/PROJECT_DOCUMENTATION_COMPLETE.md`

## Maintenance

- Review documentation organization quarterly
- Move misplaced files to correct locations
- Update README.md files when structure changes
- Archive outdated docs to `archive/` directory
- Keep naming consistent across all files

---

**Last Updated:** January 28, 2026  
**Maintained By:** Development Team
