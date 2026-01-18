# Backend Documentation

Backend-specific documentation for the NestJS API.

## 📚 Documentation

### Analysis
- **[analysis/README_DEPLOYMENT.md](./analysis/README_DEPLOYMENT.md)** - Deployment analysis
- **[analysis/TODO_ANALYSIS.md](./analysis/TODO_ANALYSIS.md)** - TODO analysis

## 🏗️ Backend Structure

```
backend/
├── src/
│   ├── modules/          # Feature modules
│   │   ├── auth/        # Authentication
│   │   ├── accounts/    # Account management
│   │   ├── feed/        # Feed module
│   │   └── ...
│   ├── common/          # Shared utilities
│   └── prisma/          # Database module
├── prisma/              # Database schema
├── scripts/             # Utility scripts
└── docs/                # Backend documentation
```

## 📖 Module Documentation

Each module in `src/modules/` contains:
- Controller - API endpoints
- Service - Business logic
- DTOs - Data transfer objects
- Module - NestJS module definition

## 🔗 Related Documentation

- [Project Documentation](../../docs/project/README.md)
- [API Documentation](../../docs/api/README.md)
- [Deployment Guide](../../docs/deployment/README.md)

---

**Last Updated:** January 18, 2026
