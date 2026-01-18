import { Controller, Post, Get, Body, UseGuards, Param } from '@nestjs/common';
import { ApiTags, ApiOperation, ApiResponse, ApiBearerAuth, ApiBody, ApiParam } from '@nestjs/swagger';
import { ReceiptsService } from './receipts.service';
import { TokenGuard } from '../../../common/guards/token.guard';
import { CurrentUser } from '../../../common/decorators/user.decorator';
import { User } from '@prisma/client';
import { CreateReceiptDto } from './dto/create-receipt.dto';

@ApiTags('Accounting - Receipts')
@Controller('accounting/receipts')
@UseGuards(TokenGuard)
@ApiBearerAuth()
export class ReceiptsController {
  constructor(private readonly receiptsService: ReceiptsService) {}

  @Post()
  @ApiOperation({ summary: 'Create receipt' })
  @ApiBody({ type: CreateReceiptDto })
  @ApiResponse({ status: 200, description: 'Receipt created successfully' })
  async createReceipt(@CurrentUser() user: User, @Body() createDto: CreateReceiptDto) {
    return this.receiptsService.createReceipt(user, createDto);
  }

  @Get()
  @ApiOperation({ summary: 'List receipts' })
  @ApiResponse({ status: 200, description: 'Receipts fetched successfully' })
  async getReceipts(@CurrentUser() user: User) {
    return this.receiptsService.getReceipts(user);
  }

  @Get(':id')
  @ApiOperation({ summary: 'Get receipt' })
  @ApiParam({ name: 'id' })
  @ApiResponse({ status: 200, description: 'Receipt fetched successfully' })
  async getReceipt(@CurrentUser() user: User, @Param('id') id: string) {
    return this.receiptsService.getReceipt(user, id);
  }
}

