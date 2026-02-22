import { Controller, Get, Post, Put, Body, Delete, Param, UseGuards } from '@nestjs/common';
import { ApiTags, ApiOperation, ApiResponse, ApiBearerAuth, ApiBody, ApiParam, ApiBadRequestResponse, ApiUnauthorizedResponse, ApiNotFoundResponse, ApiForbiddenResponse } from '@nestjs/swagger';
import { ApiKeysService } from './api-keys.service';
import { CreateApiKeyDto, UpdateApiKeyDto } from './dto/create-api-key.dto';
import { TokenGuard } from '../../common/guards/token.guard';
import { CurrentUser } from '../../common/decorators/user.decorator';
import { User } from '@prisma/client';

@ApiTags('API Keys')
@ApiBearerAuth()
@Controller('api-keys')
@UseGuards(TokenGuard)
export class ApiKeysController {
  constructor(private readonly apiKeysService: ApiKeysService) {}

  @Post()
  @ApiOperation({
    summary: 'Create a new API key',
    description: `Generate a new API key for analytics access. The API key is returned only once on creation and should be saved securely.

**Scoping:**
- By default, the key is scoped to your default account
- Specify \`account_id\` to scope to a specific account
- Set \`platform_wide: true\` (admin only) for platform-wide access

**Available Scopes:**
- \`analytics:*\` - Full analytics access
- \`analytics:collections:read\` - Milk collections analytics
- \`analytics:sales:read\` - Milk sales analytics
- \`analytics:suppliers:read\` - Supplier analytics
- \`analytics:inventory:read\` - Inventory analytics
- \`analytics:financial:read\` - Financial analytics
- \`analytics:payroll:read\` - Payroll analytics
- \`analytics:loans:read\` - Loans analytics
- \`analytics:platform:read\` - Platform-wide analytics (admin only)
- \`export:read\` - CSV export capability`,
  })
  @ApiBody({
    type: CreateApiKeyDto,
    description: 'API key creation details',
    examples: {
      simpleKey: {
        summary: 'Simple analytics key',
        description: 'Create an API key for your default account with full analytics access',
        value: {
          name: 'Looker Studio Dashboard',
          description: 'API key for Looker Studio integration',
        },
      },
      scopedKey: {
        summary: 'Scoped key with specific permissions',
        description: 'Create an API key with specific scopes',
        value: {
          name: 'Collections Analytics Only',
          description: 'Read-only access to milk collections data',
          scopes: ['analytics:collections:read', 'analytics:sales:read', 'export:read'],
        },
      },
      accountSpecific: {
        summary: 'Account-specific key',
        description: 'Create an API key for a specific account',
        value: {
          name: 'Gahengeri MCC Analytics',
          description: 'Analytics for Gahengeri MCC only',
          account_id: '550e8400-e29b-41d4-a716-446655440000',
          scopes: ['analytics:*'],
        },
      },
      platformWide: {
        summary: 'Platform-wide key (Admin only)',
        description: 'Create an API key with access to all accounts',
        value: {
          name: 'Platform Analytics',
          description: 'Full platform analytics access',
          platform_wide: true,
          scopes: ['analytics:*', 'analytics:platform:read'],
        },
      },
    },
  })
  @ApiResponse({
    status: 201,
    description: 'API key created successfully',
    schema: {
      example: {
        code: 200,
        status: 'success',
        message: 'API key created successfully. Save this key securely - it will not be shown again.',
        data: {
          id: '550e8400-e29b-41d4-a716-446655440000',
          api_key: 'gemura_a1b2c3d4e5f6...',
          name: 'Looker Studio Dashboard',
          description: 'API key for Looker Studio integration',
          account: {
            id: '550e8400-e29b-41d4-a716-446655440001',
            code: 'GAH001',
            name: 'Gahengeri MCC',
          },
          scopes: ['analytics:*'],
          rate_limit: 1000,
          is_active: true,
          expires_at: '2027-02-22T00:00:00Z',
          created_at: '2026-02-22T00:00:00Z',
        },
      },
    },
  })
  @ApiBadRequestResponse({
    description: 'Invalid request',
    schema: {
      example: {
        code: 400,
        status: 'error',
        message: 'Invalid scopes: invalid_scope',
      },
    },
  })
  @ApiForbiddenResponse({
    description: 'Permission denied',
    schema: {
      example: {
        code: 403,
        status: 'error',
        message: 'Only administrators can create platform-wide API keys.',
      },
    },
  })
  @ApiUnauthorizedResponse({
    description: 'Invalid or missing authentication token',
    schema: {
      example: {
        code: 401,
        status: 'error',
        message: 'Access denied. Token is required.',
      },
    },
  })
  create(@CurrentUser() user: User, @Body() createApiKeyDto: CreateApiKeyDto) {
    return this.apiKeysService.create(user.id, createApiKeyDto);
  }

  @Get()
  @ApiOperation({
    summary: 'Get all API keys',
    description: 'Retrieve a list of all API keys you have access to. The actual API key values are not returned for security reasons.',
  })
  @ApiResponse({
    status: 200,
    description: 'List of API keys retrieved successfully',
    schema: {
      example: {
        code: 200,
        status: 'success',
        message: 'API keys retrieved successfully.',
        data: [
          {
            id: '550e8400-e29b-41d4-a716-446655440000',
            name: 'Looker Studio Dashboard',
            description: 'API key for Looker Studio integration',
            scopes: ['analytics:*'],
            rate_limit: 1000,
            request_count: 1523,
            last_used_at: '2026-02-22T10:30:00Z',
            expires_at: '2027-02-22T00:00:00Z',
            is_active: true,
            created_at: '2026-02-22T00:00:00Z',
            updated_at: '2026-02-22T00:00:00Z',
            account: {
              id: '550e8400-e29b-41d4-a716-446655440001',
              code: 'GAH001',
              name: 'Gahengeri MCC',
            },
            created_by: {
              id: '550e8400-e29b-41d4-a716-446655440002',
              name: 'John Doe',
            },
          },
        ],
      },
    },
  })
  @ApiUnauthorizedResponse({
    description: 'Invalid or missing authentication token',
  })
  findAll(@CurrentUser() user: User) {
    return this.apiKeysService.findAll(user.id);
  }

  @Get('scopes')
  @ApiOperation({
    summary: 'Get available scopes',
    description: 'Retrieve a list of all available permission scopes for API keys.',
  })
  @ApiResponse({
    status: 200,
    description: 'Available scopes retrieved successfully',
    schema: {
      example: {
        code: 200,
        status: 'success',
        message: 'Available scopes retrieved successfully.',
        data: {
          scopes: [
            'analytics:*',
            'analytics:collections:read',
            'analytics:sales:read',
          ],
          descriptions: {
            'analytics:*': 'Full access to all analytics endpoints',
            'analytics:collections:read': 'Read milk collections analytics',
            'analytics:sales:read': 'Read milk sales analytics',
          },
        },
      },
    },
  })
  getAvailableScopes() {
    return this.apiKeysService.getAvailableScopes();
  }

  @Get(':id')
  @ApiOperation({
    summary: 'Get API key details',
    description: 'Retrieve details of a specific API key. The actual key value is not returned.',
  })
  @ApiParam({
    name: 'id',
    description: 'API key ID',
    example: '550e8400-e29b-41d4-a716-446655440000',
  })
  @ApiResponse({
    status: 200,
    description: 'API key details retrieved successfully',
  })
  @ApiNotFoundResponse({
    description: 'API key not found',
  })
  findOne(@Param('id') id: string, @CurrentUser() user: User) {
    return this.apiKeysService.findOne(id, user.id);
  }

  @Put(':id')
  @ApiOperation({
    summary: 'Update an API key',
    description: 'Update API key name, description, scopes, or active status.',
  })
  @ApiParam({
    name: 'id',
    description: 'API key ID',
    example: '550e8400-e29b-41d4-a716-446655440000',
  })
  @ApiBody({ type: UpdateApiKeyDto })
  @ApiResponse({
    status: 200,
    description: 'API key updated successfully',
  })
  @ApiNotFoundResponse({
    description: 'API key not found',
  })
  @ApiForbiddenResponse({
    description: 'Permission denied',
  })
  update(@Param('id') id: string, @CurrentUser() user: User, @Body() updateDto: UpdateApiKeyDto) {
    return this.apiKeysService.update(id, user.id, updateDto);
  }

  @Delete(':id')
  @ApiOperation({
    summary: 'Delete an API key',
    description: 'Permanently delete an API key. This action cannot be undone. The API key will immediately stop working.',
  })
  @ApiParam({
    name: 'id',
    description: 'API key ID',
    example: '550e8400-e29b-41d4-a716-446655440000',
  })
  @ApiResponse({
    status: 200,
    description: 'API key deleted successfully',
    schema: {
      example: {
        code: 200,
        status: 'success',
        message: 'API key deleted successfully.',
      },
    },
  })
  @ApiNotFoundResponse({
    description: 'API key not found',
  })
  @ApiForbiddenResponse({
    description: 'Permission denied',
  })
  @ApiUnauthorizedResponse({
    description: 'Invalid or missing authentication token',
  })
  remove(@Param('id') id: string, @CurrentUser() user: User) {
    return this.apiKeysService.remove(id, user.id);
  }
}

