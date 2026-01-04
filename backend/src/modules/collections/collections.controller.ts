import { Controller, Post, Body, UseGuards } from '@nestjs/common';
import { ApiTags, ApiOperation, ApiResponse, ApiBearerAuth, ApiBody, ApiBadRequestResponse, ApiUnauthorizedResponse, ApiNotFoundResponse } from '@nestjs/swagger';
import { CollectionsService } from './collections.service';
import { TokenGuard } from '../../common/guards/token.guard';
import { CurrentUser } from '../../common/decorators/user.decorator';
import { User } from '@prisma/client';
import { CreateCollectionDto } from './dto/create-collection.dto';

@ApiTags('Collections')
@Controller('collections')
@UseGuards(TokenGuard)
@ApiBearerAuth()
export class CollectionsController {
  constructor(private readonly collectionsService: CollectionsService) {}

  @Post('create')
  @ApiOperation({
    summary: 'Record milk collection',
    description: 'Record a milk collection transaction from a supplier. The collection is stored as a milk sale record with quantity, unit price, and status.',
  })
  @ApiBody({
    type: CreateCollectionDto,
    description: 'Milk collection details',
    examples: {
      pendingCollection: {
        summary: 'Record pending collection',
        value: {
          supplier_account_code: 'A_ABC123',
          quantity: 120.5,
          status: 'pending',
          collection_at: '2025-01-04 10:00:00',
          notes: 'Morning collection',
        },
      },
      completedCollection: {
        summary: 'Record completed collection',
        value: {
          supplier_account_code: 'A_XYZ789',
          quantity: 85.0,
          status: 'completed',
          collection_at: '2025-01-04 14:30:00',
        },
      },
    },
  })
  @ApiResponse({
    status: 200,
    description: 'Milk collection recorded successfully',
    example: {
      code: 200,
      status: 'success',
      message: 'Milk collection recorded successfully.',
      data: {
        collection_id: 'uuid-here',
        supplier_account_code: 'A_ABC123',
        customer_account_id: 'account-uuid',
        quantity: 120.5,
        unit_price: 390.0,
        total_amount: 46995.0,
        status: 'pending',
        collection_at: '2025-01-04 10:00:00',
      },
    },
  })
  @ApiBadRequestResponse({
    description: 'Invalid request - missing required fields or no default account',
    examples: {
      missingFields: {
        summary: 'Missing required fields',
        value: {
          code: 400,
          status: 'error',
          message: 'Missing required fields.',
        },
      },
      noDefaultAccount: {
        summary: 'No default account',
        value: {
          code: 400,
          status: 'error',
          message: 'No valid default account found. Please set a default account.',
        },
      },
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
  @ApiNotFoundResponse({
    description: 'Supplier account not found',
    example: {
      code: 404,
      status: 'error',
      message: 'Supplier account not found.',
    },
  })
  async createCollection(@CurrentUser() user: User, @Body() createDto: CreateCollectionDto) {
    return this.collectionsService.createCollection(user, createDto);
  }
}
