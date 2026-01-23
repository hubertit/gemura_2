import { Controller, Get, Post, Put, Body, UseGuards, Query, Param, HttpCode } from '@nestjs/common';
import { ApiTags, ApiOperation, ApiResponse, ApiBearerAuth, ApiBody, ApiBadRequestResponse, ApiUnauthorizedResponse, ApiNotFoundResponse } from '@nestjs/swagger';
import { SalesService } from './sales.service';
import { TokenGuard } from '../../common/guards/token.guard';
import { CurrentUser } from '../../common/decorators/user.decorator';
import { User } from '@prisma/client';
import { GetSalesDto } from './dto/get-sales.dto';
import { UpdateSaleDto } from './dto/update-sale.dto';
import { CancelSaleDto } from './dto/cancel-sale.dto';
import { CreateSaleDto } from './dto/create-sale.dto';
import { RecordPaymentDto } from '../accounting/receivables-payables/dto/record-payment.dto';

@ApiTags('Sales')
@Controller('sales')
@UseGuards(TokenGuard)
@ApiBearerAuth()
export class SalesController {
  constructor(private readonly salesService: SalesService) {}

  @Post('sales')
  @HttpCode(200)
  @ApiOperation({
    summary: 'Get sales list with filters',
    description: 'Retrieve sales/milk collections for the authenticated user\'s default account. Supports filtering by customer, status, date range, quantity, and price.',
  })
  @ApiBody({
    type: GetSalesDto,
    description: 'Optional filters for sales query',
    examples: {
      allSales: {
        summary: 'Get all sales',
        value: {
          filters: {},
        },
      },
      filteredSales: {
        summary: 'Get filtered sales',
        value: {
          filters: {
            status: 'completed',
            date_from: '2025-01-01',
            date_to: '2025-01-31',
            quantity_min: 50,
            price_min: 350,
          },
        },
      },
    },
  })
  @ApiResponse({
    status: 200,
    description: 'Sales fetched successfully',
    example: {
      code: 200,
      status: 'success',
      message: 'Sales fetched successfully.',
      data: [
        {
          id: 'sale-uuid',
          quantity: 120.5,
          unit_price: 390.0,
          total_amount: 46995.0,
          status: 'completed',
          sale_at: '2025-01-04T10:00:00Z',
          supplier_account: {
            id: 'supplier-account-uuid',
            code: 'A_ABC123',
            name: 'Supplier Name',
            type: 'tenant',
            status: 'active',
          },
          customer_account: {
            id: 'customer-account-uuid',
            code: 'A_XYZ789',
            name: 'Customer Name',
            type: 'tenant',
            status: 'active',
          },
        },
      ],
    },
  })
  @ApiUnauthorizedResponse({
    description: 'Invalid or missing authentication token',
  })
  @ApiBadRequestResponse({
    description: 'No default account found',
  })
  async getSales(@CurrentUser() user: User, @Body() getSalesDto: GetSalesDto) {
    return this.salesService.getSales(user, getSalesDto.filters);
  }

  @Put('update')
  @ApiOperation({
    summary: 'Update a sale',
    description: 'Update sale details including quantity, status, customer, notes, or date. Only sales belonging to the user\'s default account can be updated.',
  })
  @ApiBody({
    type: UpdateSaleDto,
    description: 'Sale update data',
    examples: {
      updateStatus: {
        summary: 'Update sale status',
        value: {
          sale_id: 'sale-uuid',
          status: 'accepted',
        },
      },
      updateWithUUID: {
        summary: 'Update sale with customer UUID',
        value: {
          sale_id: 'sale-uuid',
          customer_account_id: '123e4567-e89b-12d3-a456-426614174000',
          quantity: 150.0,
          notes: 'Updated quantity after verification',
        },
      },
      updateQuantity: {
        summary: 'Update quantity and notes',
        value: {
          sale_id: 'sale-uuid',
          quantity: 150.0,
          notes: 'Updated quantity after verification',
        },
      },
    },
  })
  @ApiResponse({
    status: 200,
    description: 'Sale updated successfully',
    example: {
      code: 200,
      status: 'success',
      message: 'Sale updated successfully.',
      data: {
        id: 'sale-uuid',
        quantity: 150.0,
        unit_price: 390.0,
        status: 'completed',
        sale_at: '2025-01-04T10:00:00Z',
        notes: 'Updated quantity',
      },
    },
  })
  @ApiBadRequestResponse({
    description: 'Invalid request - no fields to update or missing sale_id',
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
    description: 'Sale not found or not owned by user',
    example: {
      code: 404,
      status: 'error',
      message: 'Sale not found or not owned by this supplier.',
    },
  })
  async updateSale(@CurrentUser() user: User, @Body() updateDto: UpdateSaleDto) {
    return this.salesService.updateSale(user, updateDto.sale_id, updateDto);
  }

  @Post('cancel')
  @HttpCode(200)
  @ApiOperation({
    summary: 'Cancel a sale',
    description: 'Cancel a sale by setting its status to "cancelled". Only sales belonging to the user\'s default account can be cancelled.',
  })
  @ApiBody({
    type: CancelSaleDto,
    description: 'Sale ID to cancel',
    examples: {
      cancelSale: {
        summary: 'Cancel sale',
        value: {
          sale_id: 'sale-uuid',
        },
      },
    },
  })
  @ApiResponse({
    status: 200,
    description: 'Sale cancelled successfully',
    example: {
      code: 200,
      status: 'success',
      message: 'Sale cancelled successfully.',
    },
  })
  @ApiBadRequestResponse({
    description: 'Invalid request - missing sale_id',
    example: {
      code: 400,
      status: 'error',
      message: 'Missing token or sale_id.',
    },
  })
  @ApiUnauthorizedResponse({
    description: 'Invalid or missing authentication token',
  })
  @ApiNotFoundResponse({
    description: 'Sale not found or not authorized',
    example: {
      code: 404,
      status: 'error',
      message: 'Sale not found or not authorized.',
    },
  })
  async cancelSale(@CurrentUser() user: User, @Body() cancelDto: CancelSaleDto) {
    return this.salesService.cancelSale(user, cancelDto);
  }

  @Post()
  @ApiOperation({
    summary: 'Create a new sale',
    description: 'Create a new milk sale transaction. The sale is created from the supplier perspective (user\'s default account is the supplier).',
  })
  @ApiBody({
    type: CreateSaleDto,
    description: 'Sale details',
    examples: {
      createSaleWithUUID: {
        summary: 'Create new sale (using UUID)',
        value: {
          customer_account_id: '123e4567-e89b-12d3-a456-426614174000',
          quantity: 120.5,
          unit_price: 390.0,
          status: 'accepted',
          sale_at: '2025-01-04T10:00:00Z',
          notes: 'Morning delivery',
        },
      },
      createSaleWithCode: {
        summary: 'Create sale with account code (fallback)',
        value: {
          customer_account_code: 'A_XYZ789',
          quantity: 120.5,
          unit_price: 390.0,
          status: 'accepted',
          sale_at: '2025-01-04T10:00:00Z',
          notes: 'Morning delivery',
        },
      },
      minimalSale: {
        summary: 'Create sale with minimal info (defaults to accepted)',
        value: {
          customer_account_id: '123e4567-e89b-12d3-a456-426614174000',
          quantity: 85.0,
        },
      },
    },
  })
  @ApiResponse({
    status: 200,
    description: 'Sale created successfully',
    example: {
      code: 200,
      status: 'success',
      message: 'Sale created successfully.',
      data: {
        id: 'sale-uuid',
        quantity: 120.5,
        unit_price: 390.0,
        total_amount: 46995.0,
        status: 'accepted',
        sale_at: '2025-01-04T10:00:00Z',
        notes: 'Morning delivery',
        payment_status: 'unpaid',
        supplier_account: {
          id: 'supplier-account-uuid',
          code: 'A_ABC123',
          name: 'Supplier Name',
          type: 'tenant',
          status: 'active',
        },
        customer_account: {
          id: 'customer-account-uuid',
          code: 'A_XYZ789',
          name: 'Customer Name',
          type: 'tenant',
          status: 'active',
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
      message: 'Access denied. Token is required.',
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
  async createSale(@CurrentUser() user: User, @Body() createDto: CreateSaleDto) {
    return this.salesService.createSale(user, createDto);
  }

  @Post(':saleId/payment')
  @HttpCode(200)
  @ApiOperation({
    summary: 'Record payment for a sale',
    description: 'Records a payment against an unpaid/partial sale. Creates journal entry: DR Cash, CR Accounts Receivable. Supports partial payments.',
  })
  @ApiBody({
    type: RecordPaymentDto,
    description: 'Payment details',
    examples: {
      fullPayment: {
        summary: 'Full payment',
        value: {
          amount: 40000,
          payment_date: '2025-01-23',
          notes: 'Payment via mobile money',
        },
      },
      partialPayment: {
        summary: 'Partial payment',
        value: {
          amount: 20000,
          notes: 'First installment',
        },
      },
    },
  })
  @ApiResponse({
    status: 200,
    description: 'Payment recorded successfully',
    example: {
      code: 200,
      status: 'success',
      message: 'Payment recorded successfully',
      data: {
        sale_id: 'sale-uuid',
        amount_paid: 40000,
        outstanding: 0,
        payment_status: 'paid',
      },
    },
  })
  @ApiBadRequestResponse({
    description: 'Invalid payment amount or exceeds outstanding balance',
  })
  @ApiNotFoundResponse({
    description: 'Sale not found or user does not have permission',
  })
  async recordPayment(
    @CurrentUser() user: User,
    @Param('saleId') saleId: string,
    @Body() paymentDto: RecordPaymentDto,
  ) {
    return this.salesService.recordPayment(user, saleId, paymentDto);
  }
}
