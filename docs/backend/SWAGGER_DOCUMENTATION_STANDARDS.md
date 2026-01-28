# Swagger/OpenAPI Documentation Standards

## Overview
This document defines the standards for documenting all API endpoints in the Gemura backend using Swagger/OpenAPI decorators.

## General Principles

1. **Consistency**: All endpoints should follow the same documentation pattern
2. **Completeness**: Every endpoint should have complete documentation
3. **Examples**: All DTOs and responses should include realistic examples
4. **Clarity**: Descriptions should be clear and helpful for API consumers

## Required Decorators

### Controller Level
```typescript
@ApiTags('Module Name')  // Required: Groups endpoints in Swagger UI
@Controller('endpoint-path')
@UseGuards(TokenGuard)  // If authentication required
@ApiBearerAuth()         // If authentication required
```

### Endpoint Level

#### 1. @ApiOperation (Required)
```typescript
@ApiOperation({
  summary: 'Brief one-line description',
  description: 'Detailed description explaining what the endpoint does, when to use it, and any important notes.',
})
```

#### 2. @ApiResponse (Required for all status codes)
```typescript
@ApiResponse({
  status: 200,
  description: 'Success description',
  example: {
    code: 200,
    status: 'success',
    message: 'Operation completed successfully.',
    data: {
      // Example response data
    },
  },
})
```

#### 3. @ApiBody (Required for POST/PUT/PATCH)
```typescript
@ApiBody({
  type: YourDto,
  description: 'Description of request body',
  examples: {
    example1: {
      summary: 'Example title',
      value: {
        field1: 'example value',
        field2: 123,
      },
    },
  },
})
```

#### 4. @ApiQuery (Required for query parameters)
```typescript
@ApiQuery({
  name: 'param_name',
  required: true,  // or false
  description: 'Parameter description',
  example: 'example-value',
  type: String,  // or Number, Boolean, etc.
})
```

#### 5. @ApiParam (Required for path parameters)
```typescript
@ApiParam({
  name: 'id',
  description: 'Resource identifier',
  example: '550e8400-e29b-41d4-a716-446655440000',
  type: String,
})
```

#### 6. Error Responses (Required)
```typescript
@ApiBadRequestResponse({
  description: 'Invalid request data',
  example: {
    code: 400,
    status: 'error',
    message: 'Error message',
  },
})

@ApiUnauthorizedResponse({
  description: 'Missing or invalid authentication',
  example: {
    code: 401,
    status: 'error',
    message: 'Access denied. Token is required.',
  },
})

@ApiForbiddenResponse({
  description: 'Insufficient permissions',
  example: {
    code: 403,
    status: 'error',
    message: 'Access denied. Insufficient permissions.',
  },
})

@ApiNotFoundResponse({
  description: 'Resource not found',
  example: {
    code: 404,
    status: 'error',
    message: 'Resource not found.',
  },
})
```

## DTO Standards

### Required Decorators
```typescript
import { ApiProperty } from '@nestjs/swagger';

export class YourDto {
  @ApiProperty({
    description: 'Field description',
    example: 'example-value',  // Required: realistic example
    type: String,  // Optional but recommended
    required: true,  // or false
    format: 'uuid',  // If applicable (uuid, email, date-time, etc.)
    enum: ['value1', 'value2'],  // If enum
  })
  @IsNotEmpty()
  @IsString()
  fieldName: string;
}
```

### Example Values Guidelines

- **UUIDs**: Use `'550e8400-e29b-41d4-a716-446655440000'`
- **Dates**: Use `'2025-01-28'` for dates, `'2025-01-28T10:30:00Z'` for datetime
- **Emails**: Use `'user@example.com'`
- **Phone**: Use `'250788123456'` (Rwandan format)
- **Amounts**: Use realistic values like `150000` (RWF)
- **Names**: Use realistic names like `'John Doe'`, `'KOPERATIVE KOZAMGI'`

## Response Format Standards

All API responses follow this structure:

```typescript
{
  code: number,        // HTTP status code
  status: string,      // 'success' or 'error'
  message: string,     // Human-readable message
  data?: any,          // Response data (if success)
}
```

## Common Patterns

### Pagination
```typescript
@ApiQuery({ name: 'page', required: false, example: 1, type: Number })
@ApiQuery({ name: 'limit', required: false, example: 20, type: Number })
```

### Date Ranges
```typescript
@ApiQuery({ 
  name: 'from_date', 
  required: true, 
  example: '2025-01-01',
  description: 'Start date (YYYY-MM-DD)',
  type: String,
})
@ApiQuery({ 
  name: 'to_date', 
  required: true, 
  example: '2025-01-31',
  description: 'End date (YYYY-MM-DD)',
  type: String,
})
```

### Filters
```typescript
@ApiQuery({ 
  name: 'status', 
  required: false, 
  example: 'active',
  enum: ['active', 'inactive', 'pending'],
  description: 'Filter by status',
})
```

## Checklist for Each Endpoint

- [ ] @ApiTags on controller
- [ ] @ApiOperation with summary and description
- [ ] @ApiResponse for 200 (success)
- [ ] @ApiResponse for 400 (bad request)
- [ ] @ApiResponse for 401 (unauthorized) if auth required
- [ ] @ApiResponse for 403 (forbidden) if applicable
- [ ] @ApiResponse for 404 (not found) if applicable
- [ ] @ApiBody for POST/PUT/PATCH with examples
- [ ] @ApiQuery for all query parameters with examples
- [ ] @ApiParam for all path parameters with examples
- [ ] All DTOs have @ApiProperty with examples
- [ ] Examples use realistic values
- [ ] Descriptions are clear and helpful

## File Organization

- Controllers: `backend/src/modules/{module}/{module}.controller.ts`
- DTOs: `backend/src/modules/{module}/dto/{dto-name}.dto.ts`
- Services: `backend/src/modules/{module}/{module}.service.ts`

## Examples

See `backend/src/modules/accounts/accounts.controller.ts` for a complete example of well-documented endpoints.
