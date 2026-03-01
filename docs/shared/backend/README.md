# Backend Documentation

Backend-specific documentation for the NestJS API.

## 📚 Documentation

### API Documentation
- **[swagger-documentation-standards.md](./swagger-documentation-standards.md)** - Complete Swagger/OpenAPI documentation standards
- **[api-documentation-status.md](./api-documentation-status.md)** - Current documentation status for all controllers
- **[documentation-roadmap.md](./documentation-roadmap.md)** - Phased plan for completing API documentation

### Analysis
- **[analysis/readme-deployment.md](./analysis/readme-deployment.md)** - Deployment analysis
- **[analysis/todo-analysis.md](./analysis/todo-analysis.md)** - TODO analysis

### Modules
- **[modules/accounting-transactions.md](./modules/accounting-transactions.md)** - Accounting transactions module documentation

### Features
- **[features/inventory-sales-feature-plan.md](./features/inventory-sales-feature-plan.md)** - Inventory sales feature implementation plan

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

All API endpoints should follow the standards in [swagger-documentation-standards.md](./swagger-documentation-standards.md).

Key requirements:
- `@ApiTags` for grouping
- `@ApiOperation` with summary and description
- `@ApiResponse` with examples
- `@ApiBody`, `@ApiQuery`, `@ApiParam` with examples
- DTOs with `@ApiProperty` examples

---

**Last Updated:** January 28, 2026
