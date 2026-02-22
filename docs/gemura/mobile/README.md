# Mobile App Documentation

Documentation for the Flutter mobile application.

## 📚 Documentation Files

### Integration & Migration
- **[MOBILE_APP_INTEGRATION.md](./MOBILE_APP_INTEGRATION.md)** - Complete mobile app integration guide
- **[API_ENDPOINT_MIGRATION.md](./API_ENDPOINT_MIGRATION.md)** - API endpoint migration from PHP to NestJS
- **[MIGRATION_PROGRESS.md](./MIGRATION_PROGRESS.md)** - Migration progress tracking
- **[MIGRATION_SUMMARY.md](./MIGRATION_SUMMARY.md)** - Migration summary

### Testing & Verification
- **[TESTING_RESULTS.md](./TESTING_RESULTS.md)** - Mobile app test results
- **[COMPREHENSIVE_TEST_REPORT.md](./COMPREHENSIVE_TEST_REPORT.md)** - Comprehensive test report
- **[FINAL_TESTING_REPORT.md](./FINAL_TESTING_REPORT.md)** - Final testing report
- **[INTEGRATION_COMPLETE.md](./INTEGRATION_COMPLETE.md)** - Integration completion status

### Features & Fixes
- **[ACCOUNT_SWITCHING_FIX.md](./ACCOUNT_SWITCHING_FIX.md)** - Account switching feature fix
- **[HOME_SCREEN_REDESIGN_COMPLETE.md](./HOME_SCREEN_REDESIGN_COMPLETE.md)** - Home screen redesign
- **[UI_REDESIGN_PLAN.md](./UI_REDESIGN_PLAN.md)** - UI redesign planning

### Analysis
- **[FLUTTER_ANALYZE_RESULTS.md](./FLUTTER_ANALYZE_RESULTS.md)** - Flutter code analysis results
- **[LOGIN_TROUBLESHOOTING.md](./LOGIN_TROUBLESHOOTING.md)** - Login troubleshooting guide

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
- [TESTING_RESULTS.md](./TESTING_RESULTS.md) - Test results
- [COMPREHENSIVE_TEST_REPORT.md](./COMPREHENSIVE_TEST_REPORT.md) - Comprehensive testing

### Running Tests
```bash
cd mobile
flutter test
flutter analyze
```

## 🔗 Related Documentation

- [API Documentation](../api/README.md) - Backend API
- [Deployment Guide](../deployment/README.md) - Deployment procedures
- [Testing Results](../testing/README.md) - Test results

---

**Last Updated:** January 18, 2026
