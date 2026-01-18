import { Controller, Post, Get, Put, Delete, Body, UseGuards, Param, Query, HttpCode } from '@nestjs/common';
import { ApiTags, ApiOperation, ApiResponse, ApiBearerAuth, ApiBody, ApiBadRequestResponse, ApiUnauthorizedResponse, ApiNotFoundResponse, ApiParam, ApiQuery } from '@nestjs/swagger';
import { SuppliersService } from './suppliers.service';
import { TokenGuard } from '../../common/guards/token.guard';
import { CurrentUser } from '../../common/decorators/user.decorator';
import { User } from '@prisma/client';
import { CreateSupplierDto } from './dto/create-supplier.dto';
import { UpdateSupplierDto } from './dto/update-supplier.dto';

@ApiTags('Suppliers')
@Controller('suppliers')
@UseGuards(TokenGuard)
@ApiBearerAuth()
export class SuppliersController {
  constructor(private readonly suppliersService: SuppliersService) {}

  @Post('create')
  @ApiOperation({
    summary: 'Create or update supplier',
    description: 'Create a new supplier relationship or update an existing one. If supplier exists (by phone/email/nid), updates the relationship. Otherwise, creates new user, account, and wallet.',
  })
  @ApiBody({
    type: CreateSupplierDto,
    description: 'Supplier information',
    examples: {
      createSupplier: {
        summary: 'Create new supplier',
        value: {
          name: 'John Doe',
          phone: '250788123456',
          price_per_liter: 390.0,
          email: 'supplier@example.com',
          nid: '1199887766554433',
          address: 'Kigali, Rwanda',
        },
      },
      minimalSupplier: {
        summary: 'Create supplier with minimal info',
        value: {
          name: 'Jane Smith',
          phone: '250788654321',
          price_per_liter: 400.0,
        },
      },
    },
  })
  @ApiResponse({
    status: 200,
    description: 'Supplier created/updated successfully',
    example: {
      code: 200,
      status: 'success',
      message: 'Supplier created/updated successfully.',
      data: {
        supplier: {
          account_id: 'account-uuid',
          account_code: 'A_ABC123',
          name: 'John Doe',
          phone: '250788123456',
          price_per_liter: 390.0,
        },
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
      message: 'Unauthorized. Invalid token.',
    },
  })
  async createSupplier(@CurrentUser() user: User, @Body() createDto: CreateSupplierDto) {
    return this.suppliersService.createOrUpdateSupplier(user, createDto);
  }

  @Post('get')
  @HttpCode(200)
  @ApiOperation({
    summary: 'Get all suppliers',
    description: 'Retrieve all active supplier relationships for the authenticated user.',
  })
  @ApiResponse({
    status: 200,
    description: 'Suppliers fetched successfully',
    example: {
      code: 200,
      status: 'success',
      message: 'Suppliers fetched successfully.',
      data: [
        {
          relationship_id: 'relationship-uuid',
          code: 'U_ABC123',
          name: 'John Doe',
          phone: '250788123456',
          email: 'supplier@example.com',
          nid: '1199887766554433',
          address: 'Kigali, Rwanda',
          account: {
            code: 'A_ABC123',
            name: 'John Doe',
          },
          price_per_liter: 390.0,
          average_supply_quantity: 120.5,
          relationship_status: 'active',
          created_at: '2025-01-04T10:00:00Z',
          updated_at: '2025-01-04T10:00:00Z',
        },
      ],
    },
  })
  @ApiUnauthorizedResponse({
    description: 'Invalid or missing authentication token',
    example: {
      code: 401,
      status: 'error',
      message: 'Unauthorized. Invalid token.',
    },
  })
  async getAllSuppliers(@CurrentUser() user: User) {
    return this.suppliersService.getAllSuppliers(user);
  }

  @Get(':code')
  @ApiOperation({
    summary: 'Get supplier details',
    description: 'Retrieve details of a specific supplier by account code. Returns supplier information and relationship details.',
  })
  @ApiParam({
    name: 'code',
    description: 'Supplier account code',
    example: 'A_ABC123',
  })
  @ApiResponse({
    status: 200,
    description: 'Supplier fetched successfully',
    example: {
      code: 200,
      status: 'success',
      message: 'Supplier fetched successfully.',
      data: {
        supplier: {
          account_id: 'account-uuid',
          account_code: 'A_ABC123',
          name: 'John Doe',
          type: 'tenant',
          status: 'active',
          user: {
            id: 'user-uuid',
            name: 'John Doe',
            phone: '250788123456',
            email: 'supplier@example.com',
            nid: '1199887766554433',
            address: 'Kigali, Rwanda',
            account_type: 'supplier',
          },
          relationship: {
            price_per_liter: 390.0,
            average_supply_quantity: 120.5,
            relationship_status: 'active',
            created_at: '2025-01-04T10:00:00Z',
            updated_at: '2025-01-04T10:00:00Z',
          },
        },
      },
    },
  })
  @ApiUnauthorizedResponse({
    description: 'Invalid or missing authentication token',
    example: {
      code: 401,
      status: 'error',
      message: 'Unauthorized. Invalid token.',
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
  async getSupplier(@CurrentUser() user: User, @Param('code') code: string) {
    return this.suppliersService.getSupplier(user, code);
  }

  @Put('update')
  @ApiOperation({
    summary: 'Update supplier relationship',
    description: 'Update supplier relationship details including price per liter and relationship status.',
  })
  @ApiBody({
    type: UpdateSupplierDto,
    description: 'Supplier update data',
    examples: {
      updatePrice: {
        summary: 'Update price per liter',
        value: {
          supplier_account_code: 'A_ABC123',
          price_per_liter: 400.0,
        },
      },
      updateStatus: {
        summary: 'Update relationship status',
        value: {
          supplier_account_code: 'A_ABC123',
          relationship_status: 'inactive',
        },
      },
    },
  })
  @ApiResponse({
    status: 200,
    description: 'Supplier updated successfully',
    example: {
      code: 200,
      status: 'success',
      message: 'Supplier updated successfully.',
      data: {
        supplier: {
          account_code: 'A_ABC123',
          price_per_liter: 410.0,
          relationship_status: 'active',
        },
      },
    },
  })
  @ApiBadRequestResponse({
    description: 'Invalid request - no fields to update or supplier not found',
    example: {
      code: 400,
      status: 'error',
      message: 'No fields to update.',
    },
  })
  @ApiUnauthorizedResponse({
    description: 'Invalid or missing authentication token',
    example: {
      code: 401,
      status: 'error',
      message: 'Unauthorized. Invalid token.',
    },
  })
  @ApiNotFoundResponse({
    description: 'Supplier relationship not found',
    example: {
      code: 404,
      status: 'error',
      message: 'Supplier relationship not found.',
    },
  })
  async updateSupplier(@CurrentUser() user: User, @Body() updateDto: UpdateSupplierDto) {
    return this.suppliersService.updateSupplier(user, updateDto);
  }

  @Delete(':code')
  @ApiOperation({
    summary: 'Delete supplier relationship',
    description: 'Delete (deactivate) a supplier relationship. This sets the relationship status to inactive.',
  })
  @ApiParam({
    name: 'code',
    description: 'Supplier account code',
    example: 'A_ABC123',
  })
  @ApiResponse({
    status: 200,
    description: 'Supplier relationship deleted successfully',
    example: {
      code: 200,
      status: 'success',
      message: 'Supplier relationship deleted successfully.',
    },
  })
  @ApiUnauthorizedResponse({
    description: 'Invalid or missing authentication token',
    example: {
      code: 401,
      status: 'error',
      message: 'Unauthorized. Invalid token.',
    },
  })
  @ApiNotFoundResponse({
    description: 'Supplier relationship not found',
    example: {
      code: 404,
      status: 'error',
      message: 'Supplier relationship not found.',
    },
  })
  async deleteSupplier(@CurrentUser() user: User, @Param('code') code: string) {
    return this.suppliersService.deleteSupplier(user, code);
  }
}
