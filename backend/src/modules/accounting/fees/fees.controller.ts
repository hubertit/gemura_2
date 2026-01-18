import { Controller, Post, Get, Body, UseGuards, Query, Param } from '@nestjs/common';
import { ApiTags, ApiOperation, ApiResponse, ApiBearerAuth, ApiBody, ApiQuery, ApiParam } from '@nestjs/swagger';
import { FeesService } from './fees.service';
import { TokenGuard } from '../../../common/guards/token.guard';
import { CurrentUser } from '../../../common/decorators/user.decorator';
import { User } from '@prisma/client';
import { CreateFeeTypeDto } from './dto/create-fee-type.dto';
import { CreateFeeRuleDto } from './dto/create-fee-rule.dto';
import { CreateDeductionDto } from './dto/create-deduction.dto';

@ApiTags('Accounting - Fees & Deductions')
@Controller('accounting/fees')
@UseGuards(TokenGuard)
@ApiBearerAuth()
export class FeesController {
  constructor(private readonly feesService: FeesService) {}

  @Post('fee-types')
  @ApiOperation({ summary: 'Create fee type' })
  @ApiBody({ type: CreateFeeTypeDto })
  @ApiResponse({ status: 200, description: 'Fee type created successfully' })
  async createFeeType(@CurrentUser() user: User, @Body() createDto: CreateFeeTypeDto) {
    return this.feesService.createFeeType(user, createDto);
  }

  @Get('fee-types')
  @ApiOperation({ summary: 'Get fee types' })
  @ApiResponse({ status: 200, description: 'Fee types fetched successfully' })
  async getFeeTypes(@CurrentUser() user: User) {
    return this.feesService.getFeeTypes(user);
  }

  @Post('fee-rules')
  @ApiOperation({ summary: 'Create fee rule' })
  @ApiBody({ type: CreateFeeRuleDto })
  @ApiResponse({ status: 200, description: 'Fee rule created successfully' })
  async createFeeRule(@CurrentUser() user: User, @Body() createDto: CreateFeeRuleDto) {
    return this.feesService.createFeeRule(user, createDto);
  }

  @Get('fee-rules')
  @ApiOperation({ summary: 'Get fee rules' })
  @ApiQuery({ name: 'supplier_account_id', required: false })
  @ApiResponse({ status: 200, description: 'Fee rules fetched successfully' })
  async getFeeRules(@CurrentUser() user: User, @Query('supplier_account_id') supplierAccountId?: string) {
    return this.feesService.getFeeRules(user, supplierAccountId);
  }

  @Post('deductions')
  @ApiOperation({ summary: 'Create deduction' })
  @ApiBody({ type: CreateDeductionDto })
  @ApiResponse({ status: 200, description: 'Deduction created successfully' })
  async createDeduction(@CurrentUser() user: User, @Body() createDto: CreateDeductionDto) {
    return this.feesService.createDeduction(user, createDto);
  }

  @Get('deductions')
  @ApiOperation({ summary: 'Get deductions' })
  @ApiQuery({ name: 'supplier_account_id', required: false })
  @ApiResponse({ status: 200, description: 'Deductions fetched successfully' })
  async getDeductions(@CurrentUser() user: User, @Query('supplier_account_id') supplierAccountId?: string) {
    return this.feesService.getDeductions(user, supplierAccountId);
  }
}

