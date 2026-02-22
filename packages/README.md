# Packages

Shared libraries and code used across apps.

## Structure

```
packages/
├── shared-ui/         # Shared UI components
├── api-client/        # Generated API client
└── shared-types/      # Shared TypeScript/Dart types
```

## shared-ui

Reusable UI components shared between web apps (React) and potentially mobile apps.

## api-client

Auto-generated API client from OpenAPI/Swagger specification.

```bash
# Generate client from backend API
npm run generate:api-client
```

## shared-types

TypeScript and Dart type definitions shared across frontend apps.
