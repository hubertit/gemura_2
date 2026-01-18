import { Controller, Get, Post, Body, Delete, Param, UseGuards } from '@nestjs/common';
import { ApiTags, ApiOperation, ApiResponse, ApiBearerAuth } from '@nestjs/swagger';
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
  @ApiOperation({ summary: 'Create a new API key' })
  @ApiResponse({ status: 201, description: 'API key created successfully' })
  create(@CurrentUser() user: User, @Body() createApiKeyDto: CreateApiKeyDto) {
    return this.apiKeysService.create(user.id, createApiKeyDto);
  }

  @Get()
  @ApiOperation({ summary: 'Get all API keys for current user' })
  @ApiResponse({ status: 200, description: 'List of API keys' })
  findAll(@CurrentUser() user: User) {
    return this.apiKeysService.findAll(user.id);
  }

  @Delete(':id')
  @ApiOperation({ summary: 'Delete an API key' })
  @ApiResponse({ status: 200, description: 'API key deleted successfully' })
  remove(@Param('id') id: string, @CurrentUser() user: User) {
    return this.apiKeysService.remove(id, user.id);
  }
}

