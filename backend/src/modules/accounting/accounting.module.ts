import { Module } from '@nestjs/common';
import { ReportsController } from './reports/reports.controller';
import { ReportsService } from './reports/reports.service';
import { TransactionsController } from './transactions/transactions.controller';
import { TransactionsService } from './transactions/transactions.service';
import { ReceivablesPayablesController } from './receivables-payables/receivables-payables.controller';
import { ReceivablesPayablesService } from './receivables-payables/receivables-payables.service';
import { PrismaModule } from '../../prisma/prisma.module';

@Module({
  imports: [PrismaModule],
  controllers: [
    ReportsController,
    TransactionsController,
    ReceivablesPayablesController,
  ],
  providers: [
    ReportsService,
    TransactionsService,
    ReceivablesPayablesService,
  ],
  exports: [
    ReportsService,
    TransactionsService,
    ReceivablesPayablesService,
  ],
})
export class AccountingModule {}

