import { Controller, Post, Get, Put, Delete, Body, UseGuards, Param, Query, HttpCode } from '@nestjs/common';
import { ApiTags, ApiOperation, ApiResponse, ApiBearerAuth, ApiBody, ApiBadRequestResponse, ApiUnauthorizedResponse, ApiNotFoundResponse, ApiParam, ApiQuery } from '@nestjs/swagger';
import { CollectionsService } from './collections.service';
import { TokenGuard } from '../../common/guards/token.guard';
import { CurrentUser } from '../../common/decorators/user.decorator';
import { User } from '@prisma/client';
import { CreateCollectionDto } from './dto/create-collection.dto';
import { UpdateCollectionDto } from './dto/update-collection.dto';
import { CancelCollectionDto } from './dto/cancel-collection.dto';
import { CreateRejectionReasonDto } from './dto/create-rejection-reason.dto';
import { UpdateRejectionReasonDto } from './dto/update-rejection-reason.dto';

@ApiTags('Collections')
@Controller('collections')
@UseGuards(TokenGuard)
@ApiBearerAuth()
export class CollectionsController {
  constructor(private readonly collectionsService: CollectionsService) {}

  @Get('rejection-reasons')
  @ApiOperation({
    summary: 'Get all milk rejection reasons',
    description: 'Returns a list of all active milk rejection reasons ordered by sort order. Use query parameter include_inactive=true to include inactive reasons.',
  })
  @ApiQuery({
    name: 'include_inactive',
    required: false,
    type: String,
    description: 'Set to "true" to include inactive rejection reasons',
    example: 'false',
  })
  @ApiResponse({
    status: 200,
    description: 'Rejection reasons retrieved successfully',
    schema: {
      type: 'object',
      properties: {
        code: { type: 'number', example: 200 },
        status: { type: 'string', example: 'success' },
        message: { type: 'string', example: 'Rejection reasons retrieved successfully' },
        data: {
          type: 'array',
          items: {
            type: 'object',
            properties: {
              id: { type: 'string', example: 'edd315d2-dc7f-4a21-b58c-810d2295b258' },
              name: { type: 'string', example: 'Added Water' },
              description: { type: 'string', example: 'Water was added to the milk' },
              is_active: { type: 'boolean', example: true },
              sort_order: { type: 'number', example: 1 },
              created_at: { type: 'string', example: '2025-01-19T20:11:54.000Z' },
              updated_at: { type: 'string', example: '2025-01-19T20:11:54.000Z' },
            },
          },
        },
      },
    },
  })
  @ApiBadRequestResponse({
    description: 'Invalid query parameters',
    example: {
      code: 400,
      status: 'error',
      message: 'Invalid query parameter format',
    },
  })
  async getRejectionReasons(@Query('include_inactive') includeInactive?: string) {
    const include = includeInactive === 'true';
    const reasons = await this.collectionsService.getRejectionReasons(include);
    return {
      code: 200,
      status: 'success',
      message: 'Rejection reasons retrieved successfully',
      data: reasons,
    };
  }

  @Get('rejection-reasons/:id')
  @ApiOperation({
    summary: 'Get rejection reason by ID',
    description: 'Returns a single milk rejection reason by its ID',
  })
  @ApiParam({
    name: 'id',
    description: 'Rejection reason ID (UUID)',
    example: 'edd315d2-dc7f-4a21-b58c-810d2295b258',
  })
  @ApiResponse({
    status: 200,
    description: 'Rejection reason retrieved successfully',
    schema: {
      type: 'object',
      properties: {
        code: { type: 'number', example: 200 },
        status: { type: 'string', example: 'success' },
        message: { type: 'string', example: 'Rejection reason retrieved successfully' },
        data: {
          type: 'object',
          properties: {
            id: { type: 'string', example: 'edd315d2-dc7f-4a21-b58c-810d2295b258' },
            name: { type: 'string', example: 'Added Water' },
            description: { type: 'string', example: 'Water was added to the milk' },
            is_active: { type: 'boolean', example: true },
            sort_order: { type: 'number', example: 1 },
            created_at: { type: 'string', example: '2025-01-19T20:11:54.000Z' },
            updated_at: { type: 'string', example: '2025-01-19T20:11:54.000Z' },
          },
        },
      },
    },
  })
  @ApiNotFoundResponse({
    description: 'Rejection reason not found',
    example: {
      code: 404,
      status: 'error',
      message: 'Rejection reason not found',
    },
  })
  async getRejectionReasonById(@Param('id') id: string) {
    const reason = await this.collectionsService.getRejectionReasonById(id);
    return {
      code: 200,
      status: 'success',
      message: 'Rejection reason retrieved successfully',
      data: reason,
    };
  }

  @Post('rejection-reasons')
  @ApiOperation({
    summary: 'Create a new milk rejection reason',
    description: 'Creates a new milk rejection reason. The name must be unique.',
  })
  @ApiBody({
    type: CreateRejectionReasonDto,
    description: 'Rejection reason details',
    examples: {
      addedWater: {
        summary: 'Added Water',
        value: {
          name: 'Added Water',
          description: 'Water was added to the milk',
          sort_order: 1,
        },
      },
      antibiotics: {
        summary: 'Antibiotics',
        value: {
          name: 'Antibiotics',
          description: 'Antibiotic residues detected in milk',
          sort_order: 2,
        },
      },
    },
  })
  @ApiResponse({
    status: 201,
    description: 'Rejection reason created successfully',
    schema: {
      type: 'object',
      properties: {
        code: { type: 'number', example: 201 },
        status: { type: 'string', example: 'success' },
        message: { type: 'string', example: 'Rejection reason created successfully' },
        data: {
          type: 'object',
          properties: {
            id: { type: 'string', example: 'edd315d2-dc7f-4a21-b58c-810d2295b258' },
            name: { type: 'string', example: 'Added Water' },
            description: { type: 'string', example: 'Water was added to the milk' },
            is_active: { type: 'boolean', example: true },
            sort_order: { type: 'number', example: 1 },
            created_at: { type: 'string', example: '2025-01-19T20:11:54.000Z' },
            updated_at: { type: 'string', example: '2025-01-19T20:11:54.000Z' },
          },
        },
      },
    },
  })
  @ApiBadRequestResponse({
    description: 'Invalid input or name already exists',
    examples: {
      invalidInput: {
        summary: 'Invalid input',
        value: {
          code: 400,
          status: 'error',
          message: 'Name is required',
        },
      },
      duplicateName: {
        summary: 'Duplicate name',
        value: {
          code: 400,
          status: 'error',
          message: 'A rejection reason with this name already exists',
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
  async createRejectionReason(@Body() createDto: CreateRejectionReasonDto) {
    const reason = await this.collectionsService.createRejectionReason(createDto);
    return {
      code: 201,
      status: 'success',
      message: 'Rejection reason created successfully',
      data: reason,
    };
  }

  @Put('rejection-reasons/:id')
  @ApiOperation({
    summary: 'Update a milk rejection reason',
    description: 'Updates an existing milk rejection reason. All fields are optional.',
  })
  @ApiParam({
    name: 'id',
    description: 'Rejection reason ID (UUID)',
    example: 'edd315d2-dc7f-4a21-b58c-810d2295b258',
  })
  @ApiBody({
    type: UpdateRejectionReasonDto,
    description: 'Rejection reason update details',
    examples: {
      updateName: {
        summary: 'Update name',
        value: {
          name: 'Water Added',
        },
      },
      deactivate: {
        summary: 'Deactivate reason',
        value: {
          is_active: false,
        },
      },
      updateAll: {
        summary: 'Update all fields',
        value: {
          name: 'Added Water',
          description: 'Water was added to the milk',
          is_active: true,
          sort_order: 1,
        },
      },
    },
  })
  @ApiResponse({
    status: 200,
    description: 'Rejection reason updated successfully',
    schema: {
      type: 'object',
      properties: {
        code: { type: 'number', example: 200 },
        status: { type: 'string', example: 'success' },
        message: { type: 'string', example: 'Rejection reason updated successfully' },
        data: {
          type: 'object',
          properties: {
            id: { type: 'string', example: 'edd315d2-dc7f-4a21-b58c-810d2295b258' },
            name: { type: 'string', example: 'Added Water' },
            description: { type: 'string', example: 'Water was added to the milk' },
            is_active: { type: 'boolean', example: true },
            sort_order: { type: 'number', example: 1 },
            created_at: { type: 'string', example: '2025-01-19T20:11:54.000Z' },
            updated_at: { type: 'string', example: '2025-01-19T20:11:54.000Z' },
          },
        },
      },
    },
  })
  @ApiNotFoundResponse({
    description: 'Rejection reason not found',
    example: {
      code: 404,
      status: 'error',
      message: 'Rejection reason not found',
    },
  })
  @ApiBadRequestResponse({
    description: 'Invalid input or name already exists',
    examples: {
      invalidInput: {
        summary: 'Invalid input',
        value: {
          code: 400,
          status: 'error',
          message: 'Invalid input data',
        },
      },
      duplicateName: {
        summary: 'Duplicate name',
        value: {
          code: 400,
          status: 'error',
          message: 'A rejection reason with this name already exists',
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
  async updateRejectionReason(@Param('id') id: string, @Body() updateDto: UpdateRejectionReasonDto) {
    const reason = await this.collectionsService.updateRejectionReason(id, updateDto);
    return {
      code: 200,
      status: 'success',
      message: 'Rejection reason updated successfully',
      data: reason,
    };
  }

  @Delete('rejection-reasons/:id')
  @HttpCode(200)
  @ApiOperation({
    summary: 'Delete a milk rejection reason',
    description: 'Soft deletes a milk rejection reason by setting is_active to false. The reason will no longer appear in active lists but can be reactivated.',
  })
  @ApiParam({
    name: 'id',
    description: 'Rejection reason ID (UUID)',
    example: 'edd315d2-dc7f-4a21-b58c-810d2295b258',
  })
  @ApiResponse({
    status: 200,
    description: 'Rejection reason deleted successfully',
    schema: {
      type: 'object',
      properties: {
        code: { type: 'number', example: 200 },
        status: { type: 'string', example: 'success' },
        message: { type: 'string', example: 'Rejection reason deleted successfully' },
        data: {
          type: 'object',
          properties: {
            id: { type: 'string', example: 'uuid' },
            name: { type: 'string', example: 'Added Water' },
            description: { type: 'string', example: 'Water was added to the milk' },
            is_active: { type: 'boolean', example: false },
            sort_order: { type: 'number', example: 1 },
            created_at: { type: 'string', example: '2025-01-19T20:11:54.000Z' },
            updated_at: { type: 'string', example: '2025-01-19T20:11:54.000Z' },
          },
        },
      },
    },
  })
  @ApiNotFoundResponse({
    description: 'Rejection reason not found',
    example: {
      code: 404,
      status: 'error',
      message: 'Rejection reason not found',
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
  async deleteRejectionReason(@Param('id') id: string) {
    const reason = await this.collectionsService.deleteRejectionReason(id);
    return {
      code: 200,
      status: 'success',
      message: 'Rejection reason deleted successfully',
      data: reason,
    };
  }

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

  @Get(':id')
  @ApiOperation({
    summary: 'Get collection details',
    description: 'Retrieve details of a specific milk collection by ID. Only collections belonging to the user\'s default account can be accessed.',
  })
  @ApiParam({
    name: 'id',
    description: 'Collection ID',
    example: 'collection-uuid',
  })
  @ApiResponse({
    status: 200,
    description: 'Collection fetched successfully',
    example: {
      code: 200,
      status: 'success',
      message: 'Collection fetched successfully.',
      data: {
        id: 'collection-uuid',
        quantity: 120.5,
        unit_price: 390.0,
        total_amount: 46995.0,
        status: 'pending',
        collection_at: '2025-01-04T10:00:00Z',
        notes: 'Morning collection',
        supplier_account: {
          code: 'A_ABC123',
          name: 'Supplier Name',
          type: 'tenant',
          status: 'active',
        },
        customer_account: {
          code: 'A_XYZ789',
          name: 'Customer Name',
          type: 'tenant',
          status: 'active',
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
    description: 'Collection not found or not authorized',
    example: {
      code: 404,
      status: 'error',
      message: 'Collection not found or not authorized.',
    },
  })
  async getCollection(@CurrentUser() user: User, @Param('id') id: string) {
    return this.collectionsService.getCollection(user, id);
  }

  @Put('update')
  @ApiOperation({
    summary: 'Update collection',
    description: 'Update collection details including quantity, status, date, or notes. Only collections belonging to the user\'s default account can be updated.',
  })
  @ApiBody({
    type: UpdateCollectionDto,
    description: 'Collection update data',
    examples: {
      updateStatus: {
        summary: 'Update collection status',
        value: {
          collection_id: 'collection-uuid',
          status: 'accepted',
        },
      },
      updateQuantity: {
        summary: 'Update quantity and notes',
        value: {
          collection_id: 'collection-uuid',
          quantity: 150.0,
          notes: 'Updated after verification',
        },
      },
    },
  })
  @ApiResponse({
    status: 200,
    description: 'Collection updated successfully',
    example: {
      code: 200,
      status: 'success',
      message: 'Collection updated successfully.',
      data: {
        id: 'collection-uuid',
        quantity: 150.0,
        unit_price: 410.0,
        total_amount: 61500.0,
        status: 'accepted',
        collection_at: '2025-01-04T10:00:00Z',
        notes: 'Updated after verification',
      },
    },
  })
  @ApiBadRequestResponse({
    description: 'Invalid request - no fields to update',
    example: {
      code: 400,
      status: 'error',
      message: 'No fields to update.',
    },
  })
  @ApiUnauthorizedResponse({
    description: 'Invalid or missing authentication token',
  })
  @ApiNotFoundResponse({
    description: 'Collection not found or not authorized',
  })
  async updateCollection(@CurrentUser() user: User, @Body() updateDto: UpdateCollectionDto) {
    return this.collectionsService.updateCollection(user, updateDto);
  }

  @Post('cancel')
  @HttpCode(200)
  @ApiOperation({
    summary: 'Cancel collection',
    description: 'Cancel a collection by setting its status to "cancelled". Only collections belonging to the user\'s default account can be cancelled.',
  })
  @ApiBody({
    type: CancelCollectionDto,
    description: 'Collection ID to cancel',
    examples: {
      cancelCollection: {
        summary: 'Cancel collection',
        value: {
          collection_id: 'collection-uuid',
        },
      },
    },
  })
  @ApiResponse({
    status: 200,
    description: 'Collection cancelled successfully',
    example: {
      code: 200,
      status: 'success',
      message: 'Collection cancelled successfully.',
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
    description: 'Collection not found or not authorized',
    example: {
      code: 404,
      status: 'error',
      message: 'Collection not found or not authorized.',
    },
  })
  async cancelCollection(@CurrentUser() user: User, @Body() cancelDto: CancelCollectionDto) {
    return this.collectionsService.cancelCollection(user, cancelDto);
  }
}
