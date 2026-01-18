import { Controller, Post, Get, Put, Body, UseGuards, Param, Query, HttpCode } from '@nestjs/common';
import { ApiTags, ApiOperation, ApiResponse, ApiBearerAuth, ApiBody, ApiParam, ApiQuery } from '@nestjs/swagger';
import { PayrollRunsService } from './payroll-runs.service';
import { TokenGuard } from '../../../common/guards/token.guard';
import { CurrentUser } from '../../../common/decorators/user.decorator';
import { User } from '@prisma/client';
import { CreatePayrollRunDto } from './dto/create-payroll-run.dto';
import { UpdatePayrollRunDto } from './dto/update-payroll-run.dto';

@ApiTags('Payroll - Runs')
@Controller('payroll/runs')
@UseGuards(TokenGuard)
@ApiBearerAuth()
export class PayrollRunsController {
  constructor(private readonly payrollRunsService: PayrollRunsService) {}

  @Post()
  @ApiOperation({ summary: 'Create payroll run' })
  @ApiBody({ type: CreatePayrollRunDto })
  @ApiResponse({ status: 200, description: 'Run created successfully' })
  async createRun(@CurrentUser() user: User, @Body() createDto: CreatePayrollRunDto) {
    return this.payrollRunsService.createRun(user, createDto);
  }

  @Get()
  @ApiOperation({ summary: 'Get payroll runs' })
  @ApiQuery({ name: 'period_id', required: false })
  @ApiResponse({ status: 200, description: 'Runs fetched successfully' })
  async getRuns(@CurrentUser() user: User, @Query('period_id') periodId?: string) {
    return this.payrollRunsService.getRuns(user, periodId);
  }

  @Put(':id')
  @ApiOperation({ summary: 'Update payroll run' })
  @ApiParam({ name: 'id' })
  @ApiBody({ type: UpdatePayrollRunDto })
  @ApiResponse({ status: 200, description: 'Run updated successfully' })
  async updateRun(@CurrentUser() user: User, @Param('id') id: string, @Body() updateDto: UpdatePayrollRunDto) {
    return this.payrollRunsService.updateRun(user, id, updateDto);
  }

  @Post(':id/process')
  @HttpCode(200)
  @ApiOperation({ summary: 'Process payroll' })
  @ApiParam({ name: 'id' })
  @ApiResponse({ status: 200, description: 'Payroll processed successfully' })
  async processPayroll(@CurrentUser() user: User, @Param('id') id: string) {
    return this.payrollRunsService.processPayroll(user, id);
  }
}

