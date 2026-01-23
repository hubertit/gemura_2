import { Injectable, BadRequestException } from '@nestjs/common';
import { PrismaService } from '../../../prisma/prisma.service';
import { User } from '@prisma/client';

@Injectable()
export class ReceivablesPayablesService {
  constructor(private prisma: PrismaService) {}

  /**
   * Get all Accounts Receivable (unpaid sales where user is supplier)
   */
  async getReceivables(user: User, filters?: {
    customer_account_id?: string;
    date_from?: string;
    date_to?: string;
    payment_status?: string;
  }) {
    if (!user.default_account_id) {
      throw new BadRequestException({
        code: 400,
        status: 'error',
        message: 'No valid default account found. Please set a default account first.',
      });
    }

    const where: any = {
      supplier_account_id: user.default_account_id,
      payment_status: { not: 'paid' },
      status: { not: 'deleted' },
    };

    // Apply filters
    if (filters?.customer_account_id) {
      where.customer_account_id = filters.customer_account_id;
    }

    if (filters?.payment_status) {
      where.payment_status = filters.payment_status;
    }

    if (filters?.date_from || filters?.date_to) {
      where.sale_at = {};
      if (filters.date_from) {
        where.sale_at.gte = new Date(filters.date_from);
      }
      if (filters.date_to) {
        const dateTo = new Date(filters.date_to);
        dateTo.setHours(23, 59, 59, 999);
        where.sale_at.lte = dateTo;
      }
    }

    const sales = await this.prisma.milkSale.findMany({
      where,
      include: {
        customer_account: true,
      },
      orderBy: { sale_at: 'desc' },
    });

    // Calculate outstanding amounts and aging
    const receivables = sales.map((sale) => {
      const totalAmount = Number(sale.quantity) * Number(sale.unit_price);
      const amountPaid = Number(sale.amount_paid || 0);
      const outstanding = totalAmount - amountPaid;
      const daysOutstanding = Math.floor(
        (new Date().getTime() - sale.sale_at.getTime()) / (1000 * 60 * 60 * 24)
      );

      let agingBucket = 'current';
      if (daysOutstanding > 90) {
        agingBucket = '90+';
      } else if (daysOutstanding > 60) {
        agingBucket = '61-90';
      } else if (daysOutstanding > 30) {
        agingBucket = '31-60';
      }

      return {
        sale_id: sale.id,
        customer: {
          id: sale.customer_account.id,
          code: sale.customer_account.code,
          name: sale.customer_account.name,
        },
        sale_date: sale.sale_at,
        quantity: Number(sale.quantity),
        unit_price: Number(sale.unit_price),
        total_amount: totalAmount,
        amount_paid: amountPaid,
        outstanding: outstanding,
        payment_status: sale.payment_status || 'unpaid',
        days_outstanding: daysOutstanding,
        aging_bucket: agingBucket,
        notes: sale.notes,
      };
    });

    // Group by customer
    const byCustomer = receivables.reduce((acc, rec) => {
      const customerId = rec.customer.id;
      if (!acc[customerId]) {
        acc[customerId] = {
          customer: rec.customer,
          total_outstanding: 0,
          invoice_count: 0,
          invoices: [],
        };
      }
      acc[customerId].total_outstanding += rec.outstanding;
      acc[customerId].invoice_count += 1;
      acc[customerId].invoices.push(rec);
      return acc;
    }, {} as Record<string, any>);

    // Calculate aging summary
    const agingSummary = {
      current: receivables.filter((r) => r.days_outstanding <= 30).reduce((sum, r) => sum + r.outstanding, 0),
      days_31_60: receivables.filter((r) => r.days_outstanding > 30 && r.days_outstanding <= 60).reduce((sum, r) => sum + r.outstanding, 0),
      days_61_90: receivables.filter((r) => r.days_outstanding > 60 && r.days_outstanding <= 90).reduce((sum, r) => sum + r.outstanding, 0),
      days_90_plus: receivables.filter((r) => r.days_outstanding > 90).reduce((sum, r) => sum + r.outstanding, 0),
    };

    return {
      code: 200,
      status: 'success',
      message: 'Receivables fetched successfully',
      data: {
        total_receivables: receivables.reduce((sum, r) => sum + r.outstanding, 0),
        total_invoices: receivables.length,
        by_customer: Object.values(byCustomer),
        aging_summary: agingSummary,
        all_receivables: receivables,
      },
    };
  }

  /**
   * Get all Accounts Payable (unpaid collections where user is customer)
   */
  async getPayables(user: User, filters?: {
    supplier_account_id?: string;
    date_from?: string;
    date_to?: string;
    payment_status?: string;
  }) {
    if (!user.default_account_id) {
      throw new BadRequestException({
        code: 400,
        status: 'error',
        message: 'No valid default account found. Please set a default account first.',
      });
    }

    const where: any = {
      customer_account_id: user.default_account_id,
      payment_status: { not: 'paid' },
      status: { not: 'deleted' },
    };

    // Apply filters
    if (filters?.supplier_account_id) {
      where.supplier_account_id = filters.supplier_account_id;
    }

    if (filters?.payment_status) {
      where.payment_status = filters.payment_status;
    }

    if (filters?.date_from || filters?.date_to) {
      where.sale_at = {};
      if (filters.date_from) {
        where.sale_at.gte = new Date(filters.date_from);
      }
      if (filters.date_to) {
        const dateTo = new Date(filters.date_to);
        dateTo.setHours(23, 59, 59, 999);
        where.sale_at.lte = dateTo;
      }
    }

    const collections = await this.prisma.milkSale.findMany({
      where,
      include: {
        supplier_account: true,
      },
      orderBy: { sale_at: 'desc' },
    });

    // Calculate outstanding amounts and aging
    const payables = collections.map((collection) => {
      const totalAmount = Number(collection.quantity) * Number(collection.unit_price);
      const amountPaid = Number(collection.amount_paid || 0);
      const outstanding = totalAmount - amountPaid;
      const daysOutstanding = Math.floor(
        (new Date().getTime() - collection.sale_at.getTime()) / (1000 * 60 * 60 * 24)
      );

      let agingBucket = 'current';
      if (daysOutstanding > 90) {
        agingBucket = '90+';
      } else if (daysOutstanding > 60) {
        agingBucket = '61-90';
      } else if (daysOutstanding > 30) {
        agingBucket = '31-60';
      }

      return {
        collection_id: collection.id,
        supplier: {
          id: collection.supplier_account.id,
          code: collection.supplier_account.code,
          name: collection.supplier_account.name,
        },
        collection_date: collection.sale_at,
        quantity: Number(collection.quantity),
        unit_price: Number(collection.unit_price),
        total_amount: totalAmount,
        amount_paid: amountPaid,
        outstanding: outstanding,
        payment_status: collection.payment_status || 'unpaid',
        days_outstanding: daysOutstanding,
        aging_bucket: agingBucket,
        notes: collection.notes,
      };
    });

    // Group by supplier
    const bySupplier = payables.reduce((acc, pay) => {
      const supplierId = pay.supplier.id;
      if (!acc[supplierId]) {
        acc[supplierId] = {
          supplier: pay.supplier,
          total_outstanding: 0,
          invoice_count: 0,
          invoices: [],
        };
      }
      acc[supplierId].total_outstanding += pay.outstanding;
      acc[supplierId].invoice_count += 1;
      acc[supplierId].invoices.push(pay);
      return acc;
    }, {} as Record<string, any>);

    // Calculate aging summary
    const agingSummary = {
      current: payables.filter((p) => p.days_outstanding <= 30).reduce((sum, p) => sum + p.outstanding, 0),
      days_31_60: payables.filter((p) => p.days_outstanding > 30 && p.days_outstanding <= 60).reduce((sum, p) => sum + p.outstanding, 0),
      days_61_90: payables.filter((p) => p.days_outstanding > 60 && p.days_outstanding <= 90).reduce((sum, p) => sum + p.outstanding, 0),
      days_90_plus: payables.filter((p) => p.days_outstanding > 90).reduce((sum, p) => sum + p.outstanding, 0),
    };

    return {
      code: 200,
      status: 'success',
      message: 'Payables fetched successfully',
      data: {
        total_payables: payables.reduce((sum, p) => sum + p.outstanding, 0),
        total_invoices: payables.length,
        by_supplier: Object.values(bySupplier),
        aging_summary: agingSummary,
        all_payables: payables,
      },
    };
  }
}
