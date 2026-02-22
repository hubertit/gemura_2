# Backend Documentation

Backend-specific documentation for the NestJS API.

## 📚 Documentation

### API Documentation
- **[SWAGGER_DOCUMENTATION_STANDARDS.md](./SWAGGER_DOCUMENTATION_STANDARDS.md)** - Complete Swagger/OpenAPI documentation standards
- **[API_DOCUMENTATION_STATUS.md](./API_DOCUMENTATION_STATUS.md)** - Current documentation status for all controllers
- **[DOCUMENTATION_ROADMAP.md](./DOCUMENTATION_ROADMAP.md)** - Phased plan for completing API documentation

### Analysis
- **[analysis/README_DEPLOYMENT.md](./analysis/README_DEPLOYMENT.md)** - Deployment analysis
- **[analysis/TODO_ANALYSIS.md](./analysis/TODO_ANALYSIS.md)** - TODO analysis

### Modules
- **[modules/ACCOUNTING_TRANSACTIONS.md](./modules/ACCOUNTING_TRANSACTIONS.md)** - Accounting transactions module documentation

### Features
- **[features/INVENTORY_SALES_FEATURE_PLAN.md](./features/INVENTORY_SALES_FEATURE_PLAN.md)** - Inventory sales feature implementation plan

## 🏗️ Backend Structure

```
backend/
├── src/
│   ├── modules/          # Feature modules
│   │   ├── auth/        # Authentication
│   │   ├── accounts/    # Account management
│   │   ├── accounting/  # Accounting module
│   │   │   ├── transactions/  # Revenue/expense transactions
│   │   │   ├── reports/       # Financial reports
│   │   │   └── receivables-payables/  # AR/AP
│   │   ├── feed/        # Feed module
│   │   └── ...
│   ├── common/          # Shared utilities
│   └── prisma/          # Database module
├── prisma/              # Database schema
├── scripts/             # Utility scripts
└── docs/                # Backend documentation (legacy - see /docs/backend)
```

## 📖 Module Documentation

Each module in `src/modules/` contains:
- Controller - API endpoints (should have Swagger docs)
- Service - Business logic
- DTOs - Data transfer objects (should have @ApiProperty examples)
- Module - NestJS module definition

## 🔗 Related Documentation

- [Project Documentation](../project/README.md)
- [API Documentation](../api/README.md)
- [Deployment Guide](../deployment/README.md)
- [Swagger UI](http://localhost:3004/api/docs) - When backend is running

## 📝 Documentation Standards

All API endpoints should follow the standards in [SWAGGER_DOCUMENTATION_STANDARDS.md](./SWAGGER_DOCUMENTATION_STANDARDS.md).

Key requirements:
- `@ApiTags` for grouping
- `@ApiOperation` with summary and description
- `@ApiResponse` with examples
- `@ApiBody`, `@ApiQuery`, `@ApiParam` with examples
- DTOs with `@ApiProperty` examples

---

**Last Updated:** January 28, 2026
