# Documentation Organization Guide

## Overview
This document describes the organization structure and naming conventions for all documentation files in the `/docs` directory.

## Directory Structure

```
docs/
├── README.md                          # Main documentation index
├── shared/
│   ├── documentation-organization.md # This file
│   ├── project/                      # Project documentation
│   │   ├── README.md
│   │   ├── project-structure.md
│   │   ├── project-organization.md
│   │   ├── implementation-status.md
│   │   ├── modules-and-features.md
│   │   ├── next-steps.md
│   │   └── status/
│   ├── backend/
│   ├── api/
│   ├── deployment/
│   ├── testing/
│   ├── migration/
│   ├── architecture/
│   └── archive/
├── gemura/
│   ├── mobile/
│   └── web/
└── orora/
```

## Naming Conventions

### File Naming Standards

All documentation files use **kebab-case** (lowercase with hyphens):

1. **kebab-case.md** - Standard format
   - Example: `project-structure.md`, `api-documentation-status.md`, `deployment-guide.md`

2. **README.md** - Directory index files
   - Always `README.md` (capitalized)
   - Present in every major directory

3. Use descriptive names; no required suffixes. Common patterns:
   - `*-guide.md` - How-to guides
   - `*-status.md` - Status reports
   - `*-plan.md` - Implementation plans
   - `*-results.md` - Test/execution results

### Examples

✅ **Good:**
- `swagger-documentation-standards.md`
- `deployment-guide.md`
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
