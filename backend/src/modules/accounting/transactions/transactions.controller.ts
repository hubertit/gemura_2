import { Controller, Post, Get, Put, Delete, Body, UseGuards, Query, Param } from '@nestjs/common';
import { ApiTags, ApiOperation, ApiResponse, ApiBearerAuth, ApiBody, ApiQuery, ApiParam } from '@nestjs/swagger';
import { TransactionsService } from './transactions.service';
import { TokenGuard } from '../../../common/guards/token.guard';
import { CurrentUser } from '../../../common/decorators/user.decorator';
import { User } from '@prisma/client';
import { CreateTransactionDto, TransactionType } from './dto/create-transaction.dto';
import { UpdateTransactionDto } from './dto/update-transaction.dto';

@ApiTags('Accounting - Transactions')
@Controller('accounting/transactions')
@UseGuards(TokenGuard)
@ApiBearerAuth()
export class TransactionsController {
  constructor(private readonly transactionsService: TransactionsService) {}

  @Post()
  @ApiOperation({ summary: 'Record revenue or expense transaction' })
  @ApiBody({ type: CreateTransactionDto })
  @ApiResponse({ status: 200, description: 'Transaction recorded successfully' })
  async createTransaction(@CurrentUser() user: User, @Body() createDto: CreateTransactionDto) {
    return this.transactionsService.createTransaction(user, createDto);
  }

  @Get()
  @ApiOperation({ summary: 'Get revenue and expense transactions' })
  @ApiQuery({ name: 'type', enum: TransactionType, required: false, description: 'Filter by transaction type' })
  @ApiQuery({ name: 'date_from', required: false, description: 'Start date (YYYY-MM-DD)' })
  @ApiQuery({ name: 'date_to', required: false, description: 'End date (YYYY-MM-DD)' })
  @ApiQuery({ name: 'limit', required: false, description: 'Limit number of results' })
  @ApiResponse({ status: 200, description: 'Transactions fetched successfully' })
  async getTransactions(
    @CurrentUser() user: User,
    @Query('type') type?: TransactionType,
    @Query('date_from') dateFrom?: string,
    @Query('date_to') dateTo?: string,
    @Query('limit') limit?: string,
  ) {
    return this.transactionsService.getTransactions(user, {
      type,
      date_from: dateFrom,
      date_to: dateTo,
      limit: limit ? parseInt(limit, 10) : undefined,
    });
  }

  @Get(':id')
  @ApiOperation({ summary: 'Get transaction by ID' })
  @ApiParam({ name: 'id', description: 'Transaction ID' })
  @ApiResponse({ status: 200, description: 'Transaction fetched successfully' })
  async getTransaction(@CurrentUser() user: User, @Param('id') id: string) {
    return this.transactionsService.getTransaction(user, id);
  }
}
