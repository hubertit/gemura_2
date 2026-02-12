import {
  Controller,
  Get,
  Post,
  Put,
  Body,
  Param,
  Query,
  UseGuards,
  Res,
  HttpCode,
} from '@nestjs/common';
import { ApiTags, ApiOperation, ApiBearerAuth, ApiResponse, ApiParam, ApiQuery } from '@nestjs/swagger';
import { Response } from 'express';
import { LoansService } from './loans.service';
import { TokenGuard } from '../../common/guards/token.guard';
import { CurrentUser } from '../../common/decorators/user.decorator';
import { User } from '@prisma/client';
import { CreateLoanDto } from './dto/create-loan.dto';
import { UpdateLoanDto } from './dto/update-loan.dto';
import { BulkCreateLoansDto } from './dto/bulk-create-loans.dto';
import { RecordRepaymentDto } from './dto/record-repayment.dto';

@ApiTags('Loans')
@Controller('loans')
@UseGuards(TokenGuard)
@ApiBearerAuth()
export class LoansController {
  constructor(private readonly loansService: LoansService) {}

  @Post('create')
  @ApiOperation({ summary: 'Create a loan' })
  @ApiResponse({ status: 200, description: 'Loan created successfully.' })
  async create(@CurrentUser() user: User, @Body() dto: CreateLoanDto) {
    return this.loansService.create(user, dto);
  }

  @Post('get')
  @HttpCode(200)
  @ApiOperation({ summary: 'Get all loans with optional filters' })
  @ApiQuery({ name: 'account_id', required: false })
  @ApiQuery({ name: 'borrower_type', required: false, enum: ['supplier', 'customer', 'other'] })
  @ApiQuery({ name: 'status', required: false, enum: ['active', 'closed'] })
  @ApiQuery({ name: 'search', required: false })
  @ApiQuery({ name: 'date_from', required: false })
  @ApiQuery({ name: 'date_to', required: false })
  @ApiResponse({ status: 200, description: 'Loans list.' })
  async getMany(
    @CurrentUser() user: User,
    @Query('account_id') accountId?: string,
    @Query('borrower_type') borrowerType?: string,
    @Query('status') status?: string,
    @Query('search') search?: string,
    @Query('date_from') dateFrom?: string,
    @Query('date_to') dateTo?: string,
  ) {
    return this.loansService.getMany(user, {
      account_id: accountId,
      borrower_type: borrowerType,
      status,
      search,
      date_from: dateFrom,
      date_to: dateTo,
    });
  }

  @Get('template')
  @ApiOperation({
    summary: 'Download loans CSV template',
    description: 'Returns a CSV file with header row and one example row for bulk import.',
  })
  @ApiResponse({
    status: 200,
    description: 'CSV template file',
    headers: {
      'Content-Disposition': {
        description: 'attachment; filename="loans-template.csv"',
        schema: { type: 'string' },
      },
      'Content-Type': { description: 'text/csv; charset=utf-8', schema: { type: 'string' } },
    },
  })
  getTemplate(@Res() res: Response) {
    const csv = this.loansService.getTemplateCsv();
    res.setHeader('Content-Type', 'text/csv; charset=utf-8');
    res.setHeader('Content-Disposition', 'attachment; filename="loans-template.csv"');
    res.send(csv);
  }

  @Post('bulk')
  @ApiOperation({ summary: 'Bulk create loans' })
  @ApiResponse({
    status: 200,
    description: 'Bulk import result',
    example: {
      code: 200,
      status: 'success',
      message: 'Bulk import completed.',
      data: { success: 2, failed: 0, errors: [] },
    },
  })
  async bulkCreate(@CurrentUser() user: User, @Body() body: BulkCreateLoansDto) {
    const result = await this.loansService.bulkCreate(user, body.rows);
    return {
      code: 200,
      status: 'success',
      message: 'Bulk import completed.',
      data: result,
    };
  }

  @Get('by-id/:id')
  @ApiOperation({ summary: 'Get loan by ID' })
  @ApiParam({ name: 'id', description: 'Loan UUID' })
  @ApiResponse({ status: 200, description: 'Loan details.' })
  async getById(@CurrentUser() user: User, @Param('id') id: string) {
    return this.loansService.getById(user, id);
  }

  @Put('update/:id')
  @ApiOperation({ summary: 'Update a loan' })
  @ApiParam({ name: 'id', description: 'Loan UUID' })
  @ApiResponse({ status: 200, description: 'Loan updated.' })
  async update(@CurrentUser() user: User, @Param('id') id: string, @Body() dto: UpdateLoanDto) {
    return this.loansService.update(user, id, dto);
  }

  @Post(':id/repayment')
  @ApiOperation({ summary: 'Record a repayment for a loan' })
  @ApiParam({ name: 'id', description: 'Loan UUID' })
  @ApiResponse({ status: 200, description: 'Repayment recorded.' })
  async recordRepayment(
    @CurrentUser() user: User,
    @Param('id') id: string,
    @Body() dto: RecordRepaymentDto,
  ) {
    return this.loansService.recordRepayment(user, id, dto);
  }
}
