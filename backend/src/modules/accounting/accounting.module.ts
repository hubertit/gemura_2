import { Module } from '@nestjs/common';
import { ReportsController } from './reports/reports.controller';
import { ReportsService } from './reports/reports.service';
import { TransactionsController } from './transactions/transactions.controller';
import { TransactionsService } from './transactions/transactions.service';
import { PrismaModule } from '../../prisma/prisma.module';

@Module({
  imports: [PrismaModule],
  controllers: [
    ReportsController,
    TransactionsController,
  ],
  providers: [
    ReportsService,
    TransactionsService,
  ],
  exports: [
    ReportsService,
    TransactionsService,
  ],
})
export class AccountingModule {}

