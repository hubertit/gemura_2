# Mobile App Documentation

Documentation for the Flutter mobile application.

## 📚 Documentation Files

### Integration & Migration
- **[mobile-app-integration.md](./mobile-app-integration.md)** - Complete mobile app integration guide
- **[api-endpoint-migration.md](./api-endpoint-migration.md)** - API endpoint migration from PHP to NestJS
- **[migration-progress.md](./migration-progress.md)** - Migration progress tracking
- **[migration-summary.md](./migration-summary.md)** - Migration summary

### Testing & Verification
- **[testing-results.md](./testing-results.md)** - Mobile app test results
- **[comprehensive-test-report.md](./comprehensive-test-report.md)** - Comprehensive test report
- **[final-testing-report.md](./final-testing-report.md)** - Final testing report
- **[integration-complete.md](./integration-complete.md)** - Integration completion status

### Features & Fixes
- **[account-switching-fix.md](./account-switching-fix.md)** - Account switching feature fix
- **[home-screen-redesign-complete.md](./home-screen-redesign-complete.md)** - Home screen redesign
- **[ui-redesign-plan.md](./ui-redesign-plan.md)** - UI redesign planning

### Analysis
- **[flutter-analyze-results.md](./flutter-analyze-results.md)** - Flutter code analysis results
- **[login-troubleshooting.md](./login-troubleshooting.md)** - Login troubleshooting guide

## 📱 Mobile App Structure

```
mobile/
├── lib/
│   ├── core/              # Core services and utilities
│   ├── features/         # Feature modules
│   │   ├── auth/         # Authentication
│   │   ├── feed/         # Feed feature
│   │   ├── market/       # Market feature
│   │   └── ...
│   └── shared/           # Shared widgets and components
├── android/              # Android configuration
├── ios/                  # iOS configuration
└── assets/               # App assets
```

## 🔌 API Integration

### Base URL
The mobile app connects to:
```
http://159.198.65.38:3004/api
```

### Authentication
- Token-based authentication
- Automatic token refresh
- Secure token storage

### Key Features
- Account switching
- Feed browsing
- Market browsing
- Order management

## 🧪 Testing

### Test Results
- [testing-results.md](./testing-results.md) - Test results
- [comprehensive-test-report.md](./comprehensive-test-report.md) - Comprehensive testing

### Running Tests
```bash
cd mobile
flutter test
flutter analyze
```

## 🔗 Related Documentation

- [API Documentation](../../shared/api/README.md) - Backend API
- [Deployment Guide](../../shared/deployment/README.md) - Deployment procedures
- [Testing Results](../../shared/testing/README.md) - Test results

---

**Last Updated:** January 18, 2026
