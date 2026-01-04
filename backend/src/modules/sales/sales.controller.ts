import { Controller, Get, Post, Put, Body, UseGuards, Query, Param } from '@nestjs/common';
import { ApiTags, ApiOperation, ApiResponse, ApiBearerAuth } from '@nestjs/swagger';
import { SalesService } from './sales.service';
import { TokenGuard } from '../../common/guards/token.guard';
import { CurrentUser } from '../../common/decorators/user.decorator';
import { User } from '@prisma/client';
import { GetSalesDto } from './dto/get-sales.dto';
import { UpdateSaleDto } from './dto/update-sale.dto';
import { CancelSaleDto } from './dto/cancel-sale.dto';

@ApiTags('Sales')
@Controller('sales')
@UseGuards(TokenGuard)
@ApiBearerAuth()
export class SalesController {
  constructor(private readonly salesService: SalesService) {}

  @Post('sales')
  @ApiOperation({ summary: 'Get sales list with filters' })
  @ApiResponse({ status: 200, description: 'Sales fetched successfully' })
  async getSales(@CurrentUser() user: User, @Body() getSalesDto: GetSalesDto) {
    return this.salesService.getSales(user, getSalesDto.filters);
  }

  @Put('update')
  @ApiOperation({ summary: 'Update a sale' })
  @ApiResponse({ status: 200, description: 'Sale updated successfully' })
  @ApiResponse({ status: 404, description: 'Sale not found' })
  async updateSale(@CurrentUser() user: User, @Body() updateDto: UpdateSaleDto) {
    return this.salesService.updateSale(user, updateDto.sale_id, updateDto);
  }

  @Post('cancel')
  @ApiOperation({ summary: 'Cancel a sale' })
  @ApiResponse({ status: 200, description: 'Sale cancelled successfully' })
  @ApiResponse({ status: 404, description: 'Sale not found' })
  async cancelSale(@CurrentUser() user: User, @Body() cancelDto: CancelSaleDto) {
    return this.salesService.cancelSale(user, cancelDto);
  }
}

