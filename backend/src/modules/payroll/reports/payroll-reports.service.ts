import { Injectable, BadRequestException } from '@nestjs/common';
import { PrismaService } from '../../../prisma/prisma.service';
import { User } from '@prisma/client';

@Injectable()
export class PayrollReportsService {
  constructor(private prisma: PrismaService) {}

  async getPayrollReport(user: User, periodId?: string) {
    if (!user.default_account_id) {
      throw new BadRequestException({
        code: 400,
        status: 'error',
        message: 'No valid default account found.',
      });
    }

    const runs = await this.prisma.payrollRun.findMany({
      where: periodId ? { period_id: periodId } : {},
      include: {
        period: true,
        payslips: {
          include: {
            supplier_account: {
              select: {
                id: true,
                code: true,
                name: true,
              },
            },
            deductions: true,
          },
        },
      },
      orderBy: { run_date: 'desc' },
    });

    const totalPayroll = runs.reduce((sum, r) => sum + Number(r.total_amount), 0);
    const totalSuppliers = new Set(runs.flatMap((r) => r.payslips.map((p) => p.supplier_account_id))).size;

    return {
      code: 200,
      status: 'success',
      message: 'Payroll report generated successfully.',
      data: {
        total_runs: runs.length,
        total_payroll: totalPayroll,
        total_suppliers: totalSuppliers,
        runs: runs.map((r) => ({
          id: r.id,
          period_name: r.period?.period_name || 'Flexible Run',
          run_date: r.run_date,
          period_start: r.period_start,
          period_end: r.period_end,
          payment_terms_days: r.payment_terms_days,
          total_amount: Number(r.total_amount),
          payslips_count: r.payslips.length,
          suppliers: r.payslips.map((p) => ({
            supplier: p.supplier_account.name,
            gross_amount: Number(p.gross_amount),
            net_amount: Number(p.net_amount),
            milk_sales_count: p.milk_sales_count,
            period_start: p.period_start,
            period_end: p.period_end,
          })),
        })),
      },
    };
  }
}
