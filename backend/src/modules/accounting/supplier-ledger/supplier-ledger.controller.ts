import { Controller, Get, UseGuards, Param } from '@nestjs/common';
import { ApiTags, ApiOperation, ApiResponse, ApiBearerAuth, ApiParam } from '@nestjs/swagger';
import { SupplierLedgerService } from './supplier-ledger.service';
import { TokenGuard } from '../../../common/guards/token.guard';
import { CurrentUser } from '../../../common/decorators/user.decorator';
import { User } from '@prisma/client';

@ApiTags('Accounting - Supplier Ledger')
@Controller('accounting/supplier-ledger')
@UseGuards(TokenGuard)
@ApiBearerAuth()
export class SupplierLedgerController {
  constructor(private readonly supplierLedgerService: SupplierLedgerService) {}

  @Get(':supplier_account_id')
  @ApiOperation({ summary: 'Get supplier ledger' })
  @ApiParam({ name: 'supplier_account_id' })
  @ApiResponse({ status: 200, description: 'Supplier ledger fetched successfully' })
  async getSupplierLedger(@CurrentUser() user: User, @Param('supplier_account_id') supplierAccountId: string) {
    return this.supplierLedgerService.getSupplierLedger(user, supplierAccountId);
  }
}

