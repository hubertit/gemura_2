import { Module } from '@nestjs/common';
import { ChartOfAccountsController } from './chart-of-accounts/chart-of-accounts.controller';
import { ChartOfAccountsService } from './chart-of-accounts/chart-of-accounts.service';
import { JournalEntriesController } from './journal-entries/journal-entries.controller';
import { JournalEntriesService } from './journal-entries/journal-entries.service';
import { SupplierLedgerController } from './supplier-ledger/supplier-ledger.controller';
import { SupplierLedgerService } from './supplier-ledger/supplier-ledger.service';
import { FeesController } from './fees/fees.controller';
import { FeesService } from './fees/fees.service';
import { InvoicesController } from './invoices/invoices.controller';
import { InvoicesService } from './invoices/invoices.service';
import { ReceiptsController } from './receipts/receipts.controller';
import { ReceiptsService } from './receipts/receipts.service';
import { ReportsController } from './reports/reports.controller';
import { ReportsService } from './reports/reports.service';
import { TransactionsController } from './transactions/transactions.controller';
import { TransactionsService } from './transactions/transactions.service';
import { PrismaModule } from '../../prisma/prisma.module';

@Module({
  imports: [PrismaModule],
  controllers: [
    ChartOfAccountsController,
    JournalEntriesController,
    SupplierLedgerController,
    FeesController,
    InvoicesController,
    ReceiptsController,
    ReportsController,
    TransactionsController,
  ],
  providers: [
    ChartOfAccountsService,
    JournalEntriesService,
    SupplierLedgerService,
    FeesService,
    InvoicesService,
    ReceiptsService,
    ReportsService,
    TransactionsService,
  ],
  exports: [
    ChartOfAccountsService,
    JournalEntriesService,
    SupplierLedgerService,
    FeesService,
    InvoicesService,
    ReceiptsService,
    ReportsService,
    TransactionsService,
  ],
})
export class AccountingModule {}

