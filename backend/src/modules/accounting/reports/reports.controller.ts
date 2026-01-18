import { Controller, Get, UseGuards, Query } from '@nestjs/common';
import { ApiTags, ApiOperation, ApiResponse, ApiBearerAuth, ApiQuery } from '@nestjs/swagger';
import { ReportsService } from './reports.service';
import { TokenGuard } from '../../../common/guards/token.guard';
import { CurrentUser } from '../../../common/decorators/user.decorator';
import { User } from '@prisma/client';

@ApiTags('Accounting - Reports')
@Controller('accounting/reports')
@UseGuards(TokenGuard)
@ApiBearerAuth()
export class ReportsController {
  constructor(private readonly reportsService: ReportsService) {}

  @Get('balance-sheet')
  @ApiOperation({ summary: 'Get balance sheet' })
  @ApiQuery({ name: 'as_of_date', required: false })
  @ApiResponse({ status: 200, description: 'Balance sheet generated successfully' })
  async getBalanceSheet(@CurrentUser() user: User, @Query('as_of_date') asOfDate?: string) {
    return this.reportsService.getBalanceSheet(user, asOfDate);
  }

  @Get('income-statement')
  @ApiOperation({ summary: 'Get income statement' })
  @ApiQuery({ name: 'from_date', required: true })
  @ApiQuery({ name: 'to_date', required: true })
  @ApiResponse({ status: 200, description: 'Income statement generated successfully' })
  async getIncomeStatement(@CurrentUser() user: User, @Query('from_date') fromDate: string, @Query('to_date') toDate: string) {
    return this.reportsService.getIncomeStatement(user, fromDate, toDate);
  }

  @Get('trial-balance')
  @ApiOperation({ summary: 'Get trial balance' })
  @ApiQuery({ name: 'as_of_date', required: false })
  @ApiResponse({ status: 200, description: 'Trial balance generated successfully' })
  async getTrialBalance(@CurrentUser() user: User, @Query('as_of_date') asOfDate?: string) {
    return this.reportsService.getTrialBalance(user, asOfDate);
  }
}

