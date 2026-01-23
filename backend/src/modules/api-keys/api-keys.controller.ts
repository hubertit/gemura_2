import { Controller, Get, Post, Body, Delete, Param, UseGuards } from '@nestjs/common';
import { ApiTags, ApiOperation, ApiResponse, ApiBearerAuth, ApiBody, ApiParam, ApiBadRequestResponse, ApiUnauthorizedResponse, ApiNotFoundResponse } from '@nestjs/swagger';
import { ApiKeysService } from './api-keys.service';
import { CreateApiKeyDto } from './dto/create-api-key.dto';
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
    description: 'Generate a new API key for the authenticated user. The API key is returned only once on creation and should be saved securely. Default expiration is 1 year from creation date.',
  })
  @ApiBody({
    type: CreateApiKeyDto,
    description: 'API key creation details',
    examples: {
      defaultExpiration: {
        summary: 'Create with default expiration (1 year)',
        value: {
          name: 'Production API Key',
        },
      },
      customExpiration: {
        summary: 'Create with custom expiration',
        value: {
          name: 'Temporary API Key',
          expires_at: '2025-12-31T23:59:59Z',
        },
      },
    },
  })
  @ApiResponse({
    status: 201,
    description: 'API key created successfully',
    example: {
      id: 'api-key-uuid',
      name: 'Production API Key',
      api_key: 'gemura_abc123def456...',
      expires_at: '2026-01-23T00:00:00Z',
      is_active: true,
      created_at: '2025-01-23T00:00:00Z',
      updated_at: '2025-01-23T00:00:00Z',
    },
  })
  @ApiBadRequestResponse({
    description: 'Invalid request',
    example: {
      code: 400,
      status: 'error',
      message: 'API key name is required.',
    },
  })
  @ApiUnauthorizedResponse({
    description: 'Invalid or missing authentication token',
    example: {
      code: 401,
      status: 'error',
      message: 'Access denied. Token is required.',
    },
  })
  create(@CurrentUser() user: User, @Body() createApiKeyDto: CreateApiKeyDto) {
    return this.apiKeysService.create(user.id, createApiKeyDto);
  }

  @Get()
  @ApiOperation({
    summary: 'Get all API keys for current user',
    description: 'Retrieve a list of all API keys belonging to the authenticated user. The actual API key values are not returned for security reasons.',
  })
  @ApiResponse({
    status: 200,
    description: 'List of API keys retrieved successfully',
    example: [
      {
        id: 'api-key-uuid',
        name: 'Production API Key',
        expires_at: '2026-01-23T00:00:00Z',
        is_active: true,
        created_at: '2025-01-23T00:00:00Z',
        updated_at: '2025-01-23T00:00:00Z',
      },
    ],
  })
  @ApiUnauthorizedResponse({
    description: 'Invalid or missing authentication token',
    example: {
      code: 401,
      status: 'error',
      message: 'Access denied. Token is required.',
    },
  })
  findAll(@CurrentUser() user: User) {
    return this.apiKeysService.findAll(user.id);
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
    example: {
      id: 'api-key-uuid',
      name: 'Production API Key',
      expires_at: '2026-01-23T00:00:00Z',
      is_active: true,
      created_at: '2025-01-23T00:00:00Z',
      updated_at: '2025-01-23T00:00:00Z',
    },
  })
  @ApiNotFoundResponse({
    description: 'API key not found',
    example: {
      code: 404,
      status: 'error',
      message: 'API key not found',
    },
  })
  @ApiUnauthorizedResponse({
    description: 'Invalid or missing authentication token',
    example: {
      code: 401,
      status: 'error',
      message: 'Access denied. Token is required.',
    },
  })
  remove(@Param('id') id: string, @CurrentUser() user: User) {
    return this.apiKeysService.remove(id, user.id);
  }
}

