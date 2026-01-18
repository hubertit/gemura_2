import { Controller, Post, Get, Put, Body, UseGuards, Param, Query } from '@nestjs/common';
import { ApiTags, ApiOperation, ApiResponse, ApiBearerAuth, ApiBody, ApiParam, ApiQuery } from '@nestjs/swagger';
import { InvoicesService } from './invoices.service';
import { TokenGuard } from '../../../common/guards/token.guard';
import { CurrentUser } from '../../../common/decorators/user.decorator';
import { User } from '@prisma/client';
import { CreateInvoiceDto } from './dto/create-invoice.dto';
import { UpdateInvoiceDto } from './dto/update-invoice.dto';

@ApiTags('Accounting - Invoices')
@Controller('accounting/invoices')
@UseGuards(TokenGuard)
@ApiBearerAuth()
export class InvoicesController {
  constructor(private readonly invoicesService: InvoicesService) {}

  @Post()
  @ApiOperation({ summary: 'Create invoice' })
  @ApiBody({ type: CreateInvoiceDto })
  @ApiResponse({ status: 200, description: 'Invoice created successfully' })
  async createInvoice(@CurrentUser() user: User, @Body() createDto: CreateInvoiceDto) {
    return this.invoicesService.createInvoice(user, createDto);
  }

  @Get()
  @ApiOperation({ summary: 'List invoices' })
  @ApiQuery({ name: 'status', required: false })
  @ApiResponse({ status: 200, description: 'Invoices fetched successfully' })
  async getInvoices(@CurrentUser() user: User, @Query('status') status?: string) {
    return this.invoicesService.getInvoices(user, { status });
  }

  @Get(':id')
  @ApiOperation({ summary: 'Get invoice' })
  @ApiParam({ name: 'id' })
  @ApiResponse({ status: 200, description: 'Invoice fetched successfully' })
  async getInvoice(@CurrentUser() user: User, @Param('id') id: string) {
    return this.invoicesService.getInvoice(user, id);
  }

  @Put(':id')
  @ApiOperation({ summary: 'Update invoice' })
  @ApiParam({ name: 'id' })
  @ApiBody({ type: UpdateInvoiceDto })
  @ApiResponse({ status: 200, description: 'Invoice updated successfully' })
  async updateInvoice(@CurrentUser() user: User, @Param('id') id: string, @Body() updateDto: UpdateInvoiceDto) {
    return this.invoicesService.updateInvoice(user, id, updateDto);
  }
}

