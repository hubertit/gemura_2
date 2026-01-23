import { Controller, Get, Query, UseGuards } from '@nestjs/common';
import { ApiTags, ApiOperation, ApiResponse, ApiBearerAuth, ApiQuery } from '@nestjs/swagger';
import { ReceivablesPayablesService } from './receivables-payables.service';
import { TokenGuard } from '../../../common/guards/token.guard';
import { CurrentUser } from '../../../common/decorators/user.decorator';
import { User } from '@prisma/client';

@Controller('accounting')
@ApiTags('Accounting - Receivables & Payables')
@UseGuards(TokenGuard)
@ApiBearerAuth()
export class ReceivablesPayablesController {
  constructor(private receivablesPayablesService: ReceivablesPayablesService) {}

  @Get('receivables')
  @ApiOperation({
    summary: 'Get Accounts Receivable',
    description: 'Returns all unpaid/partial milk sales where the authenticated user is the supplier. Includes aging analysis and grouping by customer.',
  })
  @ApiQuery({ name: 'customer_account_id', required: false, description: 'Filter by customer account ID' })
  @ApiQuery({ name: 'date_from', required: false, description: 'Start date (YYYY-MM-DD)' })
  @ApiQuery({ name: 'date_to', required: false, description: 'End date (YYYY-MM-DD)' })
  @ApiQuery({ name: 'payment_status', required: false, description: 'Filter by payment status (unpaid, partial)' })
  @ApiResponse({
    status: 200,
    description: 'Receivables fetched successfully',
    schema: {
      example: {
        code: 200,
        status: 'success',
        message: 'Receivables fetched successfully',
        data: {
          total_receivables: 150000,
          total_invoices: 5,
          by_customer: [
            {
              customer: { id: '...', code: 'A_XYZ', name: 'Customer Name' },
              total_outstanding: 100000,
              invoice_count: 3,
              invoices: [
                {
                  sale_id: '...',
                  sale_date: '2025-01-20T10:00:00Z',
                  quantity: 100,
                  unit_price: 400,
                  total_amount: 40000,
                  amount_paid: 0,
                  outstanding: 40000,
                  payment_status: 'unpaid',
                  days_outstanding: 3,
                  aging_bucket: 'current',
                },
              ],
            },
          ],
          aging_summary: {
            current: 100000,
            days_31_60: 30000,
            days_61_90: 20000,
            days_90_plus: 0,
          },
          all_receivables: [],
        },
      },
    },
  })
  async getReceivables(
    @CurrentUser() user: User,
    @Query('customer_account_id') customerAccountId?: string,
    @Query('date_from') dateFrom?: string,
    @Query('date_to') dateTo?: string,
    @Query('payment_status') paymentStatus?: string,
  ) {
    return this.receivablesPayablesService.getReceivables(user, {
      customer_account_id: customerAccountId,
      date_from: dateFrom,
      date_to: dateTo,
      payment_status: paymentStatus,
    });
  }

  @Get('payables')
  @ApiOperation({
    summary: 'Get Accounts Payable',
    description: 'Returns all unpaid/partial milk collections where the authenticated user is the customer/collector. Includes aging analysis and grouping by supplier.',
  })
  @ApiQuery({ name: 'supplier_account_id', required: false, description: 'Filter by supplier account ID' })
  @ApiQuery({ name: 'date_from', required: false, description: 'Start date (YYYY-MM-DD)' })
  @ApiQuery({ name: 'date_to', required: false, description: 'End date (YYYY-MM-DD)' })
  @ApiQuery({ name: 'payment_status', required: false, description: 'Filter by payment status (unpaid, partial)' })
  @ApiResponse({
    status: 200,
    description: 'Payables fetched successfully',
    schema: {
      example: {
        code: 200,
        status: 'success',
        message: 'Payables fetched successfully',
        data: {
          total_payables: 200000,
          total_invoices: 8,
          by_supplier: [
            {
              supplier: { id: '...', code: 'S_ABC', name: 'Supplier Name' },
              total_outstanding: 120000,
              invoice_count: 4,
              invoices: [
                {
                  collection_id: '...',
                  collection_date: '2025-01-20T10:00:00Z',
                  quantity: 200,
                  unit_price: 350,
                  total_amount: 70000,
                  amount_paid: 0,
                  outstanding: 70000,
                  payment_status: 'unpaid',
                  days_outstanding: 3,
                  aging_bucket: 'current',
                },
              ],
            },
          ],
          aging_summary: {
            current: 150000,
            days_31_60: 30000,
            days_61_90: 20000,
            days_90_plus: 0,
          },
          all_payables: [],
        },
      },
    },
  })
  async getPayables(
    @CurrentUser() user: User,
    @Query('supplier_account_id') supplierAccountId?: string,
    @Query('date_from') dateFrom?: string,
    @Query('date_to') dateTo?: string,
    @Query('payment_status') paymentStatus?: string,
  ) {
    return this.receivablesPayablesService.getPayables(user, {
      supplier_account_id: supplierAccountId,
      date_from: dateFrom,
      date_to: dateTo,
      payment_status: paymentStatus,
    });
  }
}
