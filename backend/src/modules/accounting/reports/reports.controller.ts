import { Controller, Get, UseGuards, Query } from '@nestjs/common';
import { 
  ApiTags, 
  ApiOperation, 
  ApiResponse, 
  ApiBearerAuth, 
  ApiQuery,
  ApiUnauthorizedResponse,
  ApiBadRequestResponse,
} from '@nestjs/swagger';
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
  @ApiOperation({
    summary: 'Get balance sheet',
    description: 'Retrieve a balance sheet report showing assets, liabilities, and equity as of a specific date. The report is scoped to the user\'s default account. If no date is provided, uses the current date.',
  })
  @ApiQuery({
    name: 'as_of_date',
    required: false,
    description: 'Date to generate the balance sheet as of (YYYY-MM-DD). Defaults to current date if not provided.',
    example: '2025-01-28',
    type: String,
  })
  @ApiResponse({
    status: 200,
    description: 'Balance sheet generated successfully',
    example: {
      code: 200,
      status: 'success',
      message: 'Balance sheet generated successfully.',
      data: {
        as_of_date: '2025-01-28T00:00:00.000Z',
        assets: [
          {
            code: 'CASH-ACC001',
            name: 'Cash Account',
            balance: 1500000,
          },
        ],
        liabilities: [
          {
            code: 'PAY-ACC001',
            name: 'Payables',
            balance: 500000,
          },
        ],
        equity: [
          {
            code: 'EQUITY-ACC001',
            name: 'Owner Equity',
            balance: 1000000,
          },
        ],
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
  async getBalanceSheet(@CurrentUser() user: User, @Query('as_of_date') asOfDate?: string) {
    return this.reportsService.getBalanceSheet(user, asOfDate);
  }

  @Get('income-statement')
  @ApiOperation({
    summary: 'Get income statement',
    description: 'Retrieve an income statement (profit & loss) report showing revenue, expenses, and net income for a date range. The report is scoped to the user\'s default account and includes only transactions related to that account\'s chart of accounts (CASH-*, REV-*, EXP-*).',
  })
  @ApiQuery({
    name: 'from_date',
    required: true,
    description: 'Start date of the reporting period (YYYY-MM-DD)',
    example: '2025-01-01',
    type: String,
  })
  @ApiQuery({
    name: 'to_date',
    required: true,
    description: 'End date of the reporting period (YYYY-MM-DD)',
    example: '2025-01-31',
    type: String,
  })
  @ApiResponse({
    status: 200,
    description: 'Income statement generated successfully',
    example: {
      code: 200,
      status: 'success',
      message: 'Income statement generated successfully.',
      data: {
        from_date: '2025-01-01T00:00:00.000Z',
        to_date: '2025-01-31T23:59:59.999Z',
        revenue: 2500000,
        expenses: 1200000,
        net_income: 1300000,
      },
    },
  })
  @ApiBadRequestResponse({
    description: 'Invalid date format or missing required parameters',
    example: {
      code: 400,
      status: 'error',
      message: 'from_date and to_date are required.',
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
  async getIncomeStatement(@CurrentUser() user: User, @Query('from_date') fromDate: string, @Query('to_date') toDate: string) {
    return this.reportsService.getIncomeStatement(user, fromDate, toDate);
  }

  @Get('trial-balance')
  @ApiOperation({
    summary: 'Get trial balance',
    description: 'Retrieve a trial balance report showing all account balances as of a specific date. The report is scoped to the user\'s default account. If no date is provided, uses the current date.',
  })
  @ApiQuery({
    name: 'as_of_date',
    required: false,
    description: 'Date to generate the trial balance as of (YYYY-MM-DD). Defaults to current date if not provided.',
    example: '2025-01-28',
    type: String,
  })
  @ApiResponse({
    status: 200,
    description: 'Trial balance generated successfully',
    example: {
      code: 200,
      status: 'success',
      message: 'Trial balance generated successfully.',
      data: {
        as_of_date: '2025-01-28T00:00:00.000Z',
        accounts: [
          {
            code: 'CASH-ACC001',
            name: 'Cash Account',
            account_type: 'Asset',
            debit_balance: 1500000,
            credit_balance: 0,
            net_balance: 1500000,
          },
        ],
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
  async getTrialBalance(@CurrentUser() user: User, @Query('as_of_date') asOfDate?: string) {
    return this.reportsService.getTrialBalance(user, asOfDate);
  }

  @Get('revenue-expenses-over-time')
  @ApiOperation({
    summary: 'Get revenue and expenses by day',
    description: 'Returns a time series of daily revenue and expenses for the given date range. Used by the dashboard "Revenue & expenses over time" chart. Revenue includes direct Revenue account credits and AR payments; expenses include Expense account debits and AP payments. Scoped to the user\'s default account (CASH-*, REV-*, EXP-* chart of accounts).',
  })
  @ApiQuery({
    name: 'from_date',
    required: true,
    description: 'Start date of the reporting period (YYYY-MM-DD).',
    example: '2025-01-01',
  })
  @ApiQuery({
    name: 'to_date',
    required: true,
    description: 'End date of the reporting period (YYYY-MM-DD).',
    example: '2025-01-31',
  })
  @ApiResponse({
    status: 200,
    description: 'Daily series of revenue and expenses',
    schema: {
      example: {
        code: 200,
        status: 'success',
        message: 'Revenue and expenses over time.',
        data: {
          series: [
            { date: '2025-01-01', revenue: 150000, expenses: 50000 },
            { date: '2025-01-02', revenue: 200000, expenses: 30000 },
            { date: '2025-01-03', revenue: 0, expenses: 75000 },
          ],
        },
      },
    },
  })
  @ApiBadRequestResponse({
    description: 'Missing or invalid date parameters',
    schema: { example: { code: 400, status: 'error', message: 'from_date and to_date are required.' } },
  })
  @ApiUnauthorizedResponse({
    description: 'Invalid or missing authentication token',
    schema: { example: { code: 401, status: 'error', message: 'Access denied. Token is required.' } },
  })
  async getRevenueExpensesOverTime(
    @CurrentUser() user: User,
    @Query('from_date') fromDate: string,
    @Query('to_date') toDate: string,
  ) {
    return this.reportsService.getRevenueExpensesOverTime(user, fromDate, toDate);
  }

  @Get('expense-by-category')
  @ApiOperation({
    summary: 'Get expense grouped by category',
    description: 'Returns expense totals grouped by chart of account name (category) for the date range. Used by the dashboard "Expense by category" donut chart. Only Expense-type accounts (EXP-* prefix for the user\'s default account) are included. Scoped to the user\'s default account.',
  })
  @ApiQuery({
    name: 'from_date',
    required: true,
    description: 'Start date of the reporting period (YYYY-MM-DD).',
    example: '2025-01-01',
  })
  @ApiQuery({
    name: 'to_date',
    required: true,
    description: 'End date of the reporting period (YYYY-MM-DD).',
    example: '2025-01-31',
  })
  @ApiResponse({
    status: 200,
    description: 'Expense totals per category (chart of account name)',
    schema: {
      example: {
        code: 200,
        status: 'success',
        message: 'Expense by category.',
        data: {
          series: [
            { category_name: 'Transport', amount: 250000 },
            { category_name: 'Supplies', amount: 180000 },
            { category_name: 'Utilities', amount: 120000 },
          ],
        },
      },
    },
  })
  @ApiBadRequestResponse({
    description: 'Missing or invalid date parameters',
    schema: { example: { code: 400, status: 'error', message: 'from_date and to_date are required.' } },
  })
  @ApiUnauthorizedResponse({
    description: 'Invalid or missing authentication token',
    schema: { example: { code: 401, status: 'error', message: 'Access denied. Token is required.' } },
  })
  async getExpenseByCategory(
    @CurrentUser() user: User,
    @Query('from_date') fromDate: string,
    @Query('to_date') toDate: string,
  ) {
    return this.reportsService.getExpenseByCategory(user, fromDate, toDate);
  }
}

