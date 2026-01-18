import { Controller, Get, UseGuards, Query } from '@nestjs/common';
import { ApiTags, ApiOperation, ApiResponse, ApiBearerAuth, ApiQuery } from '@nestjs/swagger';
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
  @ApiOperation({ summary: 'Get payroll report' })
  @ApiQuery({ name: 'period_id', required: false })
  @ApiResponse({ status: 200, description: 'Payroll report generated successfully' })
  async getPayrollReport(@CurrentUser() user: User, @Query('period_id') periodId?: string) {
    return this.payrollReportsService.getPayrollReport(user, periodId);
  }
}

