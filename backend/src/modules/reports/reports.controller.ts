import { Controller, Post, UseGuards, HttpCode } from '@nestjs/common';
import { ApiTags, ApiOperation, ApiResponse, ApiBearerAuth, ApiUnauthorizedResponse, ApiBadRequestResponse } from '@nestjs/swagger';
import { ReportsService } from './reports.service';
import { TokenGuard } from '../../common/guards/token.guard';
import { CurrentUser } from '../../common/decorators/user.decorator';
import { User } from '@prisma/client';

@ApiTags('Reports')
@Controller('reports')
@UseGuards(TokenGuard)
@ApiBearerAuth()
export class ReportsController {
  constructor(private readonly reportsService: ReportsService) {}

  @Post('my-report')
  @HttpCode(200)
  @ApiOperation({
    summary: 'Get user report',
    description: 'Generate a comprehensive report for the authenticated user\'s default account, including recent collections, sales, customers, and suppliers.',
  })
  @ApiResponse({
    status: 200,
    description: 'Report generated successfully',
    example: {
      code: 200,
      status: 'success',
      message: 'Report generated successfully.',
      data: {
        recent_collections: [
          {
            id: 'collection-uuid',
            quantity: 200.0,
            unit_price: 350.0,
            total: 70000.0,
            status: 'accepted',
            supplier: 'Supplier Name',
            date: '2025-01-23T10:00:00Z',
          },
        ],
        recent_sales: [
          {
            id: 'sale-uuid',
            quantity: 150.0,
            unit_price: 390.0,
            total: 58500.0,
            status: 'accepted',
            customer: 'Customer Name',
            date: '2025-01-23T14:30:00Z',
          },
        ],
        customers: [
          {
            account_code: 'A_XYZ789',
            name: 'Customer Name',
            price_per_liter: 400.0,
          },
        ],
        suppliers: [
          {
            account_code: 'S_ABC123',
            name: 'Supplier Name',
            price_per_liter: 350.0,
          },
        ],
      },
    },
  })
  @ApiBadRequestResponse({
    description: 'No default account found',
    example: {
      code: 400,
      status: 'error',
      message: 'No valid default account found.',
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
  async getMyReport(@CurrentUser() user: User) {
    return this.reportsService.getMyReport(user);
  }
}

