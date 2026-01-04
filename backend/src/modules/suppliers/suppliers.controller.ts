import { Controller, Post, Body, UseGuards } from '@nestjs/common';
import { ApiTags, ApiOperation, ApiResponse, ApiBearerAuth, ApiBody, ApiBadRequestResponse, ApiUnauthorizedResponse } from '@nestjs/swagger';
import { SuppliersService } from './suppliers.service';
import { TokenGuard } from '../../common/guards/token.guard';
import { CurrentUser } from '../../common/decorators/user.decorator';
import { User } from '@prisma/client';
import { CreateSupplierDto } from './dto/create-supplier.dto';

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
}
