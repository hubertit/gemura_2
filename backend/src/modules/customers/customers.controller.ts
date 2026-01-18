import { Controller, Post, Get, Put, Delete, Body, UseGuards, Param } from '@nestjs/common';
import { ApiTags, ApiOperation, ApiResponse, ApiBearerAuth, ApiBody, ApiBadRequestResponse, ApiUnauthorizedResponse, ApiNotFoundResponse, ApiParam } from '@nestjs/swagger';
import { CustomersService } from './customers.service';
import { TokenGuard } from '../../common/guards/token.guard';
import { CurrentUser } from '../../common/decorators/user.decorator';
import { User } from '@prisma/client';
import { CreateCustomerDto } from './dto/create-customer.dto';
import { UpdateCustomerDto } from './dto/update-customer.dto';

@ApiTags('Customers')
@Controller('customers')
@UseGuards(TokenGuard)
@ApiBearerAuth()
export class CustomersController {
  constructor(private readonly customersService: CustomersService) {}

  @Post()
  @ApiOperation({
    summary: 'Create or update customer',
    description: 'Create a new customer relationship or update an existing one. If customer exists (by phone/email/nid), updates the relationship. Otherwise, creates new user, account, and wallet.',
  })
  @ApiBody({
    type: CreateCustomerDto,
    description: 'Customer information',
    examples: {
      createCustomer: {
        summary: 'Create new customer',
        value: {
          name: 'John Doe',
          phone: '250788123456',
          price_per_liter: 400.0,
          email: 'customer@example.com',
          nid: '1199887766554433',
          address: 'Kigali, Rwanda',
        },
      },
      minimalCustomer: {
        summary: 'Create customer with minimal info',
        value: {
          name: 'Jane Smith',
          phone: '250788654321',
          price_per_liter: 390.0,
        },
      },
    },
  })
  @ApiResponse({
    status: 200,
    description: 'Customer created/updated successfully',
    example: {
      code: 200,
      status: 'success',
      message: 'Customer created/updated successfully.',
      data: {
        customer: {
          account_id: 'account-uuid',
          account_code: 'A_XYZ789',
          name: 'John Doe',
          phone: '250788123456',
          price_per_liter: 400.0,
        },
      },
    },
  })
  @ApiBadRequestResponse({
    description: 'Invalid request - missing required fields or no default account',
    example: {
      code: 400,
      status: 'error',
      message: 'No valid default account found. Please set a default account.',
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
  async createCustomer(@CurrentUser() user: User, @Body() createDto: CreateCustomerDto) {
    return this.customersService.createCustomer(user, createDto);
  }

  @Get(':code')
  @ApiOperation({
    summary: 'Get customer details',
    description: 'Retrieve details of a specific customer by account code. Returns customer information and relationship details.',
  })
  @ApiParam({
    name: 'code',
    description: 'Customer account code',
    example: 'A_XYZ789',
  })
  @ApiResponse({
    status: 200,
    description: 'Customer fetched successfully',
    example: {
      code: 200,
      status: 'success',
      message: 'Customer fetched successfully.',
      data: {
        customer: {
          account_id: 'account-uuid',
          account_code: 'A_XYZ789',
          name: 'John Doe',
          type: 'tenant',
          status: 'active',
          user: {
            id: 'user-uuid',
            name: 'John Doe',
            phone: '250788123456',
            email: 'customer@example.com',
            nid: '1199887766554433',
            address: 'Kigali, Rwanda',
            account_type: 'customer',
          },
          relationship: {
            price_per_liter: 400.0,
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
    description: 'Customer account not found',
    example: {
      code: 404,
      status: 'error',
      message: 'Customer account not found.',
    },
  })
  async getCustomer(@CurrentUser() user: User, @Param('code') code: string) {
    return this.customersService.getCustomer(user, code);
  }

  @Put('update')
  @ApiOperation({
    summary: 'Update customer',
    description: 'Update customer details including name, contact info, price per liter, and relationship status.',
  })
  @ApiBody({
    type: UpdateCustomerDto,
    description: 'Customer update data',
    examples: {
      updatePrice: {
        summary: 'Update price per liter',
        value: {
          customer_account_code: 'A_XYZ789',
          price_per_liter: 410.0,
        },
      },
      updateInfo: {
        summary: 'Update customer information',
        value: {
          customer_account_code: 'A_XYZ789',
          name: 'John Doe Updated',
          phone: '250788123456',
          email: 'newemail@example.com',
        },
      },
    },
  })
  @ApiResponse({
    status: 200,
    description: 'Customer updated successfully',
    example: {
      code: 200,
      status: 'success',
      message: 'Customer updated successfully.',
      data: {
        customer: {
          account_code: 'A_XYZ789',
          price_per_liter: 430.0,
          relationship_status: 'active',
        },
      },
    },
  })
  @ApiBadRequestResponse({
    description: 'Invalid request - no fields to update or customer not found',
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
    description: 'Customer relationship not found',
    example: {
      code: 404,
      status: 'error',
      message: 'Customer relationship not found.',
    },
  })
  async updateCustomer(@CurrentUser() user: User, @Body() updateDto: UpdateCustomerDto) {
    return this.customersService.updateCustomer(user, updateDto);
  }

  @Delete(':code')
  @ApiOperation({
    summary: 'Delete customer relationship',
    description: 'Delete (deactivate) a customer relationship. This sets the relationship status to inactive.',
  })
  @ApiParam({
    name: 'code',
    description: 'Customer account code',
    example: 'A_XYZ789',
  })
  @ApiResponse({
    status: 200,
    description: 'Customer relationship deleted successfully',
    example: {
      code: 200,
      status: 'success',
      message: 'Customer relationship deleted successfully.',
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
    description: 'Customer relationship not found',
    example: {
      code: 404,
      status: 'error',
      message: 'Customer relationship not found.',
    },
  })
  async deleteCustomer(@CurrentUser() user: User, @Param('code') code: string) {
    return this.customersService.deleteCustomer(user, code);
  }
}

