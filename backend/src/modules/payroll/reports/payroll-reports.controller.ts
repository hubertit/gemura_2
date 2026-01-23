import { Controller, Get, UseGuards, Query } from '@nestjs/common';
import { ApiTags, ApiOperation, ApiResponse, ApiBearerAuth, ApiQuery, ApiBadRequestResponse, ApiUnauthorizedResponse } from '@nestjs/swagger';
import { PayrollReportsService } from './payroll-reports.service';
import { TokenGuard } from '../../../common/guards/token.guard';
import { CurrentUser } from '../../../common/decorators/user.decorator';
import { User } from '@prisma/client';

@ApiTags('Payroll - Reports')
@Controller('payroll/reports')
@UseGuards(TokenGuard)
@ApiBearerAuth()
export class PayrollReportsController {
  constructor(private readonly payrollReportsService: PayrollReportsService) {}

  @Get()
  @ApiOperation({
    summary: 'Get payroll report',
    description: 'Generate a comprehensive payroll report for the authenticated user\'s default account. Optionally filter by payroll period ID. Includes total payroll amounts, supplier counts, and detailed run information.',
  })
  @ApiQuery({
    name: 'period_id',
    required: false,
    description: 'Optional payroll period ID to filter by specific period',
    example: '550e8400-e29b-41d4-a716-446655440000',
  })
  @ApiResponse({
    status: 200,
    description: 'Payroll report generated successfully',
    example: {
      code: 200,
      status: 'success',
      message: 'Payroll report generated successfully.',
      data: {
        total_runs: 5,
        total_payroll: 2500000.0,
        total_suppliers: 30,
        runs: [
          {
            id: 'run-uuid',
            run_date: '2025-01-20T00:00:00Z',
            period_start: '2025-01-01T00:00:00Z',
            period_end: '2025-01-15T00:00:00Z',
            total_amount: 500000.0,
            payslip_count: 30,
            payslips: [
              {
                id: 'payslip-uuid',
                supplier_account: {
                  id: 'supplier-uuid',
                  code: 'S_ABC123',
                  name: 'Supplier Name',
                },
                gross_amount: 20000.0,
                deductions: 2000.0,
                net_amount: 18000.0,
                status: 'paid',
              },
            ],
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
  async getPayrollReport(@CurrentUser() user: User, @Query('period_id') periodId?: string) {
    return this.payrollReportsService.getPayrollReport(user, periodId);
  }
}

