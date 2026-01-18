import { Module } from '@nestjs/common';
import { PayrollSuppliersController } from './suppliers/payroll-suppliers.controller';
import { PayrollSuppliersService } from './suppliers/payroll-suppliers.service';
import { PayrollPeriodsController } from './periods/payroll-periods.controller';
import { PayrollPeriodsService } from './periods/payroll-periods.service';
import { PayrollRunsController } from './runs/payroll-runs.controller';
import { PayrollRunsService } from './runs/payroll-runs.service';
import { PayrollReportsController } from './reports/payroll-reports.controller';
import { PayrollReportsService } from './reports/payroll-reports.service';
import { PrismaModule } from '../../prisma/prisma.module';

@Module({
  imports: [PrismaModule],
  controllers: [
    PayrollSuppliersController,
    PayrollPeriodsController,
    PayrollRunsController,
    PayrollReportsController,
  ],
  providers: [
    PayrollSuppliersService,
    PayrollPeriodsService,
    PayrollRunsService,
    PayrollReportsService,
  ],
  exports: [
    PayrollSuppliersService,
    PayrollPeriodsService,
    PayrollRunsService,
    PayrollReportsService,
  ],
})
export class PayrollModule {}

