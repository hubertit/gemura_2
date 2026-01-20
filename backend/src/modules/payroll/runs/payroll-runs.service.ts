import { Injectable, BadRequestException, NotFoundException } from '@nestjs/common';
import { PrismaService } from '../../../prisma/prisma.service';
import { User } from '@prisma/client';
import { CreatePayrollRunDto } from './dto/create-payroll-run.dto';
import { UpdatePayrollRunDto } from './dto/update-payroll-run.dto';
import { GeneratePayrollDto } from './dto/generate-payroll.dto';
import { MarkPayrollPaidDto } from './dto/mark-payroll-paid.dto';
import { TransactionsService } from '../../accounting/transactions/transactions.service';
import { TransactionType } from '../../accounting/transactions/dto/create-transaction.dto';
import { Response } from 'express';
import * as ExcelJS from 'exceljs';
const PDFDocument = require('pdfkit');

@Injectable()
export class PayrollRunsService {
  constructor(
    private prisma: PrismaService,
    private transactionsService: TransactionsService,
  ) {}

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
        payslips: r.payslips.map((p) => ({
          id: p.id,
          supplier: p.supplier_account.name,
          supplier_code: p.supplier_account.code,
          gross_amount: Number(p.gross_amount),
          net_amount: Number(p.net_amount),
          milk_sales_count: p.milk_sales_count,
          period_start: p.period_start,
          period_end: p.period_end,
        })),
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

  async generatePayroll(user: User, generateDto: GeneratePayrollDto) {
    let run: any = null;
    try {
      if (!user.default_account_id) {
        throw new BadRequestException({
          code: 400,
          status: 'error',
          message: 'No valid default account found.',
        });
      }

      // Create payroll run
      run = await this.prisma.payrollRun.create({
      data: {
        period_id: null,
        run_date: new Date(),
        period_start: new Date(generateDto.period_start),
        period_end: new Date(generateDto.period_end),
        payment_terms_days: generateDto.payment_terms_days || 15,
        total_amount: 0,
        status: 'draft',
        created_by: user.id,
      },
    });

      // Get supplier account IDs if specific suppliers are selected
      let supplierAccountIds: string[] | undefined;
      if (generateDto.supplier_account_codes && generateDto.supplier_account_codes.length > 0) {
        console.log('Looking for supplier accounts with codes:', generateDto.supplier_account_codes);
        const accounts = await this.prisma.account.findMany({
          where: {
            code: { in: generateDto.supplier_account_codes },
          },
          select: { id: true, code: true },
        });
        console.log('Found accounts:', accounts.length, accounts.map(a => a.code));
        supplierAccountIds = accounts.map((a) => a.id);

        if (supplierAccountIds.length === 0) {
          // Delete the run if no valid accounts found
          await this.prisma.payrollRun.delete({ where: { id: run.id } });
          throw new BadRequestException({
            code: 400,
            status: 'error',
            message: 'No valid supplier accounts found for the provided account codes.',
          });
        }

        // Automatically create PayrollSupplier records for suppliers that don't exist
        const paymentTermsDays = generateDto.payment_terms_days || 15;
        for (const accountId of supplierAccountIds) {
          await this.prisma.payrollSupplier.upsert({
            where: { supplier_account_id: accountId },
            update: {
              is_active: true,
              payment_terms_days: paymentTermsDays,
            },
            create: {
              supplier_account_id: accountId,
              payment_terms_days: paymentTermsDays,
              is_active: true,
            },
          });
        }
      }

    // Get payroll suppliers - filter by selected suppliers if provided
    const payrollSuppliersWhere: any = {
      is_active: true,
    };

    if (supplierAccountIds && supplierAccountIds.length > 0) {
      payrollSuppliersWhere.supplier_account_id = { in: supplierAccountIds };
    }

    console.log('Finding payroll suppliers with where clause:', JSON.stringify(payrollSuppliersWhere));
    const payrollSuppliers = await this.prisma.payrollSupplier.findMany({
      where: payrollSuppliersWhere,
      include: {
        supplier_account: {
          select: {
            id: true,
            code: true,
            name: true,
            status: true,
          },
        },
      },
    });
    console.log('Found payroll suppliers:', payrollSuppliers.length);

    if (payrollSuppliers.length === 0) {
      // Delete the run if no suppliers found
      await this.prisma.payrollRun.delete({ where: { id: run.id } });
      throw new BadRequestException({
        code: 400,
        status: 'error',
        message: 'No active suppliers found for the selected criteria.',
      });
    }

    const startDate = new Date(generateDto.period_start);
    startDate.setHours(0, 0, 0, 0);
    
    const endDate = new Date(generateDto.period_end);
    endDate.setHours(23, 59, 59, 999); // Include the entire end date
    
    const paymentTermsDays = generateDto.payment_terms_days || 15;

    let totalAmount = 0;
    const payslipsCreated = [];

    // Process each supplier
    for (const payrollSupplier of payrollSuppliers) {
      // Skip if supplier account is missing or inactive
      if (!payrollSupplier.supplier_account || payrollSupplier.supplier_account.status !== 'active') {
        console.warn(`Skipping supplier ${payrollSupplier.id}: account missing or inactive`);
        continue;
      }

      console.log(`Processing supplier: ${payrollSupplier.supplier_account.name} (${payrollSupplier.supplier_account.code})`);
      const supplierPaymentTerms = payrollSupplier.payment_terms_days || paymentTermsDays;

      // Get milk sales for this supplier
      console.log(`Querying milk sales for supplier ${payrollSupplier.supplier_account_id}, customer ${user.default_account_id}, dates ${startDate.toISOString()} to ${endDate.toISOString()}`);
      const milkSales = await this.prisma.milkSale.findMany({
        where: {
          supplier_account_id: payrollSupplier.supplier_account_id,
          customer_account_id: user.default_account_id,
          sale_at: {
            gte: startDate,
            lte: endDate,
          },
        },
        orderBy: {
          sale_at: 'asc',
        },
      });

      console.log(`Found ${milkSales.length} milk sales for supplier ${payrollSupplier.supplier_account.name}`);

      if (milkSales.length === 0) {
        // Still create a payslip with 0 amount to show the supplier was processed
        const payslip = await this.prisma.payrollPayslip.create({
          data: {
            run_id: run.id,
            supplier_account_id: payrollSupplier.supplier_account_id,
            payroll_supplier_id: payrollSupplier.id,
            gross_amount: 0,
            total_deductions: 0,
            net_amount: 0,
            milk_sales_count: 0,
            period_start: startDate,
            period_end: endDate,
            status: 'generated',
          },
        });

        payslipsCreated.push({
          supplier: payrollSupplier.supplier_account?.name || 'Unknown',
          supplier_code: payrollSupplier.supplier_account?.code || 'Unknown',
          net_amount: 0,
          gross_amount: 0,
          milk_sales_count: 0,
        });
        continue; // Skip to next supplier
      }

      // Calculate gross amount (total from milk sales)
      const grossAmount = milkSales.reduce((sum, sale) => {
        return sum + Number(sale.quantity) * Number(sale.unit_price);
      }, 0);

      const totalDeductions = 0;
      const netAmount = grossAmount - totalDeductions;

      if (netAmount <= 0) {
        continue; // Skip if net amount is zero or negative
      }

      // Create payslip
      const payslip = await this.prisma.payrollPayslip.create({
        data: {
          run_id: run.id,
          supplier_account_id: payrollSupplier.supplier_account_id,
          payroll_supplier_id: payrollSupplier.id,
          gross_amount: grossAmount,
          total_deductions: totalDeductions,
          net_amount: netAmount,
          milk_sales_count: milkSales.length,
          period_start: startDate,
          period_end: endDate,
          status: 'generated',
        },
      });

      totalAmount += netAmount;
      payslipsCreated.push({
        supplier: payrollSupplier.supplier_account?.name || 'Unknown',
        supplier_code: payrollSupplier.supplier_account?.code || 'Unknown',
        net_amount: netAmount,
        gross_amount: grossAmount,
        milk_sales_count: milkSales.length,
      });
    }

    // Update run with total amount
    await this.prisma.payrollRun.update({
      where: { id: run.id },
      data: {
        total_amount: totalAmount,
        status: 'completed',
      },
    });

    return {
      code: 200,
      status: 'success',
      message: payslipsCreated.length > 0
        ? `Payroll generated successfully for ${payslipsCreated.length} supplier(s).`
        : `Payroll generated but no milk sales found for selected suppliers in the date range.`,
      data: {
        run_id: run.id,
        period_start: generateDto.period_start,
        period_end: generateDto.period_end,
        suppliers_processed: payslipsCreated.length,
        total_amount: totalAmount,
        payslips: payslipsCreated,
      },
    };
    } catch (error) {
      console.error('Error in generatePayroll:', error);
      console.error('Error stack:', error?.stack);
      console.error('Error message:', error?.message);
      // If a run was created, try to delete it
      if (run?.id) {
        try {
          await this.prisma.payrollRun.delete({ where: { id: run.id } }).catch(() => {});
        } catch (e) {
          // Ignore deletion errors
        }
      }
      throw error;
    }
  }

  async markAsPaid(user: User, runId: string, markPaidDto: MarkPayrollPaidDto) {
    if (!user.default_account_id) {
      throw new BadRequestException({
        code: 400,
        status: 'error',
        message: 'No valid default account found.',
      });
    }

    // Find the payroll run
    const run = await this.prisma.payrollRun.findUnique({
      where: { id: runId },
      include: {
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
    });

    if (!run) {
      throw new NotFoundException({
        code: 404,
        status: 'error',
        message: 'Payroll run not found.',
      });
    }

    const paymentDate = markPaidDto.payment_date 
      ? new Date(markPaidDto.payment_date) 
      : new Date();

    // If payslip_id is provided, mark only that payslip as paid
    if (markPaidDto.payslip_id) {
      const payslip = run.payslips.find((p) => p.id === markPaidDto.payslip_id);
      
      if (!payslip) {
        throw new NotFoundException({
          code: 404,
          status: 'error',
          message: 'Payslip not found in this payroll run.',
        });
      }

      if (payslip.status === 'paid') {
        throw new BadRequestException({
          code: 400,
          status: 'error',
          message: 'Payslip is already marked as paid.',
        });
      }

      // Update payslip status
      await this.prisma.payrollPayslip.update({
        where: { id: payslip.id },
        data: {
          status: 'paid',
          payment_date: paymentDate,
          paid_by: user.id,
        },
      });

      // Create expense transaction in finance
      const netAmount = Number(payslip.net_amount);
      if (netAmount > 0) {
        try {
          await this.transactionsService.createTransaction(user, {
            type: TransactionType.EXPENSE,
            amount: netAmount,
            description: `Payroll payment to ${payslip.supplier_account?.name || 'Supplier'} - Period: ${payslip.period_start.toISOString().split('T')[0]} to ${payslip.period_end.toISOString().split('T')[0]}`,
            transaction_date: paymentDate.toISOString().split('T')[0],
          });
        } catch (error) {
          console.error('Failed to create finance transaction for payroll payment:', error);
          // Don't fail the payment marking if finance transaction fails
        }
      }

      return {
        code: 200,
        status: 'success',
        message: 'Payslip marked as paid successfully.',
        data: {
          payslip_id: payslip.id,
          supplier: payslip.supplier_account?.name,
          net_amount: netAmount,
          payment_date: paymentDate,
        },
      };
    }

    // Otherwise, mark all unpaid payslips in the run as paid
    const unpaidPayslips = run.payslips.filter((p) => p.status !== 'paid');
    
    if (unpaidPayslips.length === 0) {
      throw new BadRequestException({
        code: 400,
        status: 'error',
        message: 'All payslips in this run are already marked as paid.',
      });
    }

    let totalPaid = 0;
    const updatedPayslips = [];

    // Update all unpaid payslips
    for (const payslip of unpaidPayslips) {
      const netAmount = Number(payslip.net_amount);
      
      await this.prisma.payrollPayslip.update({
        where: { id: payslip.id },
        data: {
          status: 'paid',
          payment_date: paymentDate,
          paid_by: user.id,
        },
      });

      // Create expense transaction for each payslip
      if (netAmount > 0) {
        try {
          await this.transactionsService.createTransaction(user, {
            type: TransactionType.EXPENSE,
            amount: netAmount,
            description: `Payroll payment to ${payslip.supplier_account?.name || 'Supplier'} - Period: ${payslip.period_start.toISOString().split('T')[0]} to ${payslip.period_end.toISOString().split('T')[0]}`,
            transaction_date: paymentDate.toISOString().split('T')[0],
          });
        } catch (error) {
          console.error(`Failed to create finance transaction for payslip ${payslip.id}:`, error);
          // Don't fail the payment marking if finance transaction fails
        }
      }

      totalPaid += netAmount;
      updatedPayslips.push({
        payslip_id: payslip.id,
        supplier: payslip.supplier_account?.name,
        net_amount: netAmount,
      });
    }

    return {
      code: 200,
      status: 'success',
      message: `${updatedPayslips.length} payslip(s) marked as paid successfully.`,
      data: {
        run_id: run.id,
        payslips_paid: updatedPayslips.length,
        total_amount: totalPaid,
        payment_date: paymentDate,
        payslips: updatedPayslips,
      },
    };
  }

  async exportPayroll(user: User, runId: string, format: string, res: Response) {
    // Find the payroll run
    const run = await this.prisma.payrollRun.findUnique({
      where: { id: runId },
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
          orderBy: {
            supplier_account: {
              name: 'asc',
            },
          },
        },
      },
    });

    if (!run) {
      throw new NotFoundException({
        code: 404,
        status: 'error',
        message: 'Payroll run not found.',
      });
    }

    const exportFormat = (format || 'excel').toLowerCase();
    const periodName = run.period?.period_name || 'Flexible Run';
    const periodStart = run.period_start 
      ? new Date(run.period_start).toLocaleDateString() 
      : 'N/A';
    const periodEnd = run.period_end 
      ? new Date(run.period_end).toLocaleDateString() 
      : 'N/A';
    const runDate = new Date(run.run_date).toLocaleDateString();

    if (exportFormat === 'pdf') {
      // Generate PDF
      const doc = new PDFDocument({ margin: 50 });
      const filename = `payroll_${run.id.substring(0, 8)}_${Date.now()}.pdf`;

      res.setHeader('Content-Type', 'application/pdf');
      res.setHeader('Content-Disposition', `attachment; filename="${filename}"`);

      doc.pipe(res);

      // Header
      doc.fontSize(20).text('Payroll Report', { align: 'center' });
      doc.moveDown();
      doc.fontSize(12);
      doc.text(`Period: ${periodName}`, { align: 'center' });
      doc.text(`Date Range: ${periodStart} - ${periodEnd}`, { align: 'center' });
      doc.text(`Run Date: ${runDate}`, { align: 'center' });
      doc.text(`Status: ${run.status}`, { align: 'center' });
      doc.text(`Total Amount: ${Number(run.total_amount).toLocaleString()} Frw`, { align: 'center' });
      doc.moveDown(2);

      // Payslips table
      let yPos = doc.y;
      doc.fontSize(10);
      
      // Table header
      doc.text('Supplier', 50, yPos);
      doc.text('Code', 200, yPos);
      doc.text('Gross', 280, yPos, { width: 80, align: 'right' });
      doc.text('Deductions', 370, yPos, { width: 80, align: 'right' });
      doc.text('Net Amount', 460, yPos, { width: 80, align: 'right' });
      doc.text('Status', 550, yPos);
      
      yPos += 20;
      doc.moveTo(50, yPos).lineTo(630, yPos).stroke();
      yPos += 10;

      // Table rows
      for (const payslip of run.payslips) {
        if (yPos > 700) {
          doc.addPage();
          yPos = 50;
        }

        const supplierName = payslip.supplier_account?.name || 'Unknown';
        const supplierCode = payslip.supplier_account?.code || 'N/A';
        const grossAmount = Number(payslip.gross_amount).toLocaleString();
        const deductions = Number(payslip.total_deductions).toLocaleString();
        const netAmount = Number(payslip.net_amount).toLocaleString();

        doc.text(supplierName.substring(0, 20), 50, yPos, { width: 140 });
        doc.text(supplierCode, 200, yPos, { width: 70 });
        doc.text(grossAmount, 280, yPos, { width: 80, align: 'right' });
        doc.text(deductions, 370, yPos, { width: 80, align: 'right' });
        doc.text(netAmount, 460, yPos, { width: 80, align: 'right' });
        doc.text(payslip.status, 550, yPos, { width: 70 });

        yPos += 20;
      }

      // Footer
      yPos += 10;
      doc.moveTo(50, yPos).lineTo(630, yPos).stroke();
      yPos += 15;
      doc.fontSize(12);
      doc.text(`Total: ${Number(run.total_amount).toLocaleString()} Frw`, 460, yPos, { width: 80, align: 'right' });

      doc.end();
    } else {
      // Generate Excel
      const workbook = new ExcelJS.Workbook();
      const worksheet = workbook.addWorksheet('Payroll Report');

      // Header row
      worksheet.mergeCells('A1:F1');
      worksheet.getCell('A1').value = 'Payroll Report';
      worksheet.getCell('A1').font = { size: 16, bold: true };
      worksheet.getCell('A1').alignment = { horizontal: 'center', vertical: 'middle' };

      // Period info
      worksheet.getCell('A2').value = 'Period:';
      worksheet.getCell('B2').value = periodName;
      worksheet.getCell('A3').value = 'Date Range:';
      worksheet.getCell('B3').value = `${periodStart} - ${periodEnd}`;
      worksheet.getCell('A4').value = 'Run Date:';
      worksheet.getCell('B4').value = runDate;
      worksheet.getCell('A5').value = 'Status:';
      worksheet.getCell('B5').value = run.status;
      worksheet.getCell('A6').value = 'Total Amount:';
      worksheet.getCell('B6').value = Number(run.total_amount);
      worksheet.getCell('B6').numFmt = '#,##0.00';

      // Table header
      const headerRow = worksheet.getRow(8);
      headerRow.values = ['Supplier', 'Code', 'Gross Amount', 'Deductions', 'Net Amount', 'Milk Sales', 'Status', 'Payment Date'];
      headerRow.font = { bold: true };
      headerRow.fill = {
        type: 'pattern',
        pattern: 'solid',
        fgColor: { argb: 'FFE0E0E0' },
      };

      // Column widths
      worksheet.getColumn(1).width = 30;
      worksheet.getColumn(2).width = 15;
      worksheet.getColumn(3).width = 15;
      worksheet.getColumn(4).width = 15;
      worksheet.getColumn(5).width = 15;
      worksheet.getColumn(6).width = 12;
      worksheet.getColumn(7).width = 12;
      worksheet.getColumn(8).width = 15;

      // Data rows
      let rowIndex = 9;
      for (const payslip of run.payslips) {
        const row = worksheet.getRow(rowIndex);
        row.values = [
          payslip.supplier_account?.name || 'Unknown',
          payslip.supplier_account?.code || 'N/A',
          Number(payslip.gross_amount),
          Number(payslip.total_deductions),
          Number(payslip.net_amount),
          payslip.milk_sales_count,
          payslip.status,
          payslip.payment_date ? new Date(payslip.payment_date).toLocaleDateString() : '',
        ];

        // Format amount columns
        row.getCell(3).numFmt = '#,##0.00';
        row.getCell(4).numFmt = '#,##0.00';
        row.getCell(5).numFmt = '#,##0.00';

        rowIndex++;
      }

      // Total row
      const totalRow = worksheet.getRow(rowIndex + 1);
      totalRow.getCell(1).value = 'TOTAL';
      totalRow.getCell(1).font = { bold: true };
      totalRow.getCell(5).value = Number(run.total_amount);
      totalRow.getCell(5).numFmt = '#,##0.00';
      totalRow.getCell(5).font = { bold: true };

      const filename = `payroll_${run.id.substring(0, 8)}_${Date.now()}.xlsx`;
      res.setHeader('Content-Type', 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet');
      res.setHeader('Content-Disposition', `attachment; filename="${filename}"`);

      await workbook.xlsx.write(res);
      res.end();
    }
  }
}
