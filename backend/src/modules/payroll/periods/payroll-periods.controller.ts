import { Controller, Post, Get, Body, UseGuards } from '@nestjs/common';
import { ApiTags, ApiOperation, ApiResponse, ApiBearerAuth, ApiBody } from '@nestjs/swagger';
import { PayrollPeriodsService } from './payroll-periods.service';
import { TokenGuard } from '../../../common/guards/token.guard';
import { CurrentUser } from '../../../common/decorators/user.decorator';
import { User } from '@prisma/client';
import { CreatePayrollPeriodDto } from './dto/create-payroll-period.dto';

@ApiTags('Payroll - Periods')
@Controller('payroll/periods')
@UseGuards(TokenGuard)
@ApiBearerAuth()
export class PayrollPeriodsController {
  constructor(private readonly payrollPeriodsService: PayrollPeriodsService) {}

  @Post()
  @ApiOperation({ summary: 'Create payroll period' })
  @ApiBody({ type: CreatePayrollPeriodDto })
  @ApiResponse({ status: 200, description: 'Period created successfully' })
  async createPeriod(@CurrentUser() user: User, @Body() createDto: CreatePayrollPeriodDto) {
    return this.payrollPeriodsService.createPeriod(user, createDto);
  }

  @Get()
  @ApiOperation({ summary: 'Get payroll periods' })
  @ApiResponse({ status: 200, description: 'Periods fetched successfully' })
  async getPeriods(@CurrentUser() user: User) {
    return this.payrollPeriodsService.getPeriods(user);
  }
}

