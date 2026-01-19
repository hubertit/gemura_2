import { Injectable, BadRequestException, NotFoundException } from '@nestjs/common';
import { PrismaService } from '../../../prisma/prisma.service';
import { User } from '@prisma/client';
import { CreatePayrollRunDto } from './dto/create-payroll-run.dto';
import { UpdatePayrollRunDto } from './dto/update-payroll-run.dto';

@Injectable()
export class PayrollRunsService {
  constructor(private prisma: PrismaService) {}

  async createRun(user: User, createDto: CreatePayrollRunDto) {
    if (!user.default_account_id) {
      throw new BadRequestException({
        code: 400,
        status: 'error',
        message: 'No valid default account found.',
      });
    }

    // If period_id is provided, verify it exists
    if (createDto.period_id) {
      const period = await this.prisma.payrollPeriod.findUnique({
        where: { id: createDto.period_id },
      });

      if (!period) {
        throw new NotFoundException({
          code: 404,
          status: 'error',
          message: 'Payroll period not found.',
        });
      }
    }

    const run = await this.prisma.payrollRun.create({
      data: {
        period_id: createDto.period_id || null,
        run_date: new Date(createDto.run_date || new Date()),
        period_start: createDto.period_start ? new Date(createDto.period_start) : null,
        period_end: createDto.period_end ? new Date(createDto.period_end) : null,
        payment_terms_days: createDto.payment_terms_days || null,
        total_amount: 0,
        status: 'draft',
        created_by: user.id,
      },
    });

    return {
      code: 200,
      status: 'success',
      message: 'Payroll run created successfully.',
      data: {
        id: run.id,
        period_id: run.period_id,
        run_date: run.run_date,
        period_start: run.period_start,
        period_end: run.period_end,
        payment_terms_days: run.payment_terms_days,
        status: run.status,
      },
    };
  }

  async getRuns(user: User, periodId?: string) {
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
          },
        },
      },
      orderBy: { run_date: 'desc' },
    });

    return {
      code: 200,
      status: 'success',
      message: 'Payroll runs fetched successfully.',
      data: runs.map((r) => ({
        id: r.id,
        period_name: r.period?.period_name || 'Flexible Run',
        run_date: r.run_date,
        period_start: r.period_start,
        period_end: r.period_end,
        payment_terms_days: r.payment_terms_days,
        total_amount: Number(r.total_amount),
        status: r.status,
        payslips_count: r.payslips.length,
      })),
    };
  }

  async updateRun(user: User, runId: string, updateDto: UpdatePayrollRunDto) {
    const run = await this.prisma.payrollRun.findUnique({ where: { id: runId } });
    if (!run) {
      throw new NotFoundException({
        code: 404,
        status: 'error',
        message: 'Payroll run not found.',
      });
    }

    const updated = await this.prisma.payrollRun.update({
      where: { id: runId },
      data: {
        status: updateDto.status || run.status,
        total_amount: updateDto.total_amount !== undefined ? updateDto.total_amount : run.total_amount,
      },
    });

    return {
      code: 200,
      status: 'success',
      message: 'Payroll run updated successfully.',
      data: updated,
    };
  }

  async processPayroll(user: User, runId: string) {
    if (!user.default_account_id) {
      throw new BadRequestException({
        code: 400,
        status: 'error',
        message: 'No valid default account found.',
      });
    }

    const run = await this.prisma.payrollRun.findUnique({
      where: { id: runId },
      include: {
        period: true,
      },
    });

    if (!run) {
      throw new NotFoundException({
        code: 404,
        status: 'error',
        message: 'Payroll run not found.',
      });
    }

    // Determine date range for milk sales
    const endDate = run.period_end || new Date();
    const paymentTermsDays = run.payment_terms_days || 15;
    const startDate = run.period_start || new Date(endDate.getTime() - paymentTermsDays * 24 * 60 * 60 * 1000);

    // Get all active payroll suppliers
    const payrollSuppliers = await this.prisma.payrollSupplier.findMany({
      where: {
        is_active: true,
      },
      include: {
        supplier_account: true,
      },
    });

    let totalAmount = 0;
    const payslipsCreated = [];

    // Process each supplier
    for (const payrollSupplier of payrollSuppliers) {
      const supplierPaymentTerms = payrollSupplier.payment_terms_days || paymentTermsDays;
      const supplierEndDate = run.period_end || new Date();
      const supplierStartDate = run.period_start || new Date(supplierEndDate.getTime() - supplierPaymentTerms * 24 * 60 * 60 * 1000);

      // Get unpaid milk sales for this supplier within the date range
      // Milk sales that haven't been paid (not in any paid payslip)
      const paidMilkSaleIds = await this.prisma.payrollPayslip.findMany({
        where: {
          supplier_account_id: payrollSupplier.supplier_account_id,
          status: 'paid',
        },
        select: {
          id: true,
        },
      });

      // Get milk sales for this supplier
      const milkSales = await this.prisma.milkSale.findMany({
        where: {
          supplier_account_id: payrollSupplier.supplier_account_id,
          customer_account_id: user.default_account_id,
          sale_at: {
            gte: supplierStartDate,
            lte: supplierEndDate,
          },
          status: 'accepted',
        },
        orderBy: {
          sale_at: 'asc',
        },
      });

      if (milkSales.length === 0) {
        continue; // Skip suppliers with no milk sales in this period
      }

      // Calculate gross amount (total from milk sales)
      const grossAmount = milkSales.reduce((sum, sale) => {
        return sum + Number(sale.quantity) * Number(sale.unit_price);
      }, 0);

      // Get deductions for this supplier (fees, etc.)
      // Note: SupplierDeduction table has been removed as it was not used by the mobile app
      // Deductions are now calculated as 0 (no deductions feature in current implementation)
      const deductions: any[] = [];
      const totalDeductions = 0;
      const netAmount = grossAmount - totalDeductions;

      if (netAmount <= 0) {
        continue; // Skip if net amount is zero or negative
      }

      // Create payslip
      const payslip = await this.prisma.payrollPayslip.create({
        data: {
          run_id: runId,
          supplier_account_id: payrollSupplier.supplier_account_id,
          gross_amount: grossAmount,
          total_deductions: totalDeductions,
          net_amount: netAmount,
          milk_sales_count: milkSales.length,
          period_start: supplierStartDate,
          period_end: supplierEndDate,
          status: 'generated',
        },
      });

      totalAmount += netAmount;
      payslipsCreated.push({
        supplier: payrollSupplier.supplier_account.name,
        net_amount: netAmount,
        milk_sales_count: milkSales.length,
      });
    }

    // Update run with total amount
    await this.prisma.payrollRun.update({
      where: { id: runId },
      data: {
        total_amount: totalAmount,
        status: 'completed',
      },
    });

    return {
      code: 200,
      status: 'success',
      message: 'Payroll processed successfully.',
      data: {
        run_id: runId,
        suppliers_processed: payslipsCreated.length,
        total_amount: totalAmount,
        payslips: payslipsCreated,
      },
    };
  }
}
