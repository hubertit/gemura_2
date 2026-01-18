import { Injectable, BadRequestException } from '@nestjs/common';
import { PrismaService } from '../../prisma/prisma.service';
import { User } from '@prisma/client';

@Injectable()
export class ReportsService {
  constructor(private prisma: PrismaService) {}

  async getMyReport(user: User) {
    if (!user.default_account_id) {
      throw new BadRequestException({
        code: 400,
        status: 'error',
        message: 'No valid default account found.',
      });
    }

    const [collections, sales, customers, suppliers] = await Promise.all([
      this.prisma.milkSale.findMany({
        where: { customer_account_id: user.default_account_id },
        include: { supplier_account: true },
        orderBy: { sale_at: 'desc' },
        take: 10,
      }),
      this.prisma.milkSale.findMany({
        where: { supplier_account_id: user.default_account_id },
        include: { customer_account: true },
        orderBy: { sale_at: 'desc' },
        take: 10,
      }),
      this.prisma.supplierCustomer.findMany({
        where: { supplier_account_id: user.default_account_id, relationship_status: 'active' },
        include: { customer_account: true },
        take: 10,
      }),
      this.prisma.supplierCustomer.findMany({
        where: { customer_account_id: user.default_account_id, relationship_status: 'active' },
        include: { supplier_account: true },
        take: 10,
      }),
    ]);

    return {
      code: 200,
      status: 'success',
      message: 'Report generated successfully.',
      data: {
        recent_collections: collections.map((c) => ({
          id: c.id,
          quantity: Number(c.quantity),
          unit_price: Number(c.unit_price),
          total: Number(c.quantity) * Number(c.unit_price),
          status: c.status,
          supplier: c.supplier_account.name,
          date: c.sale_at,
        })),
        recent_sales: sales.map((s) => ({
          id: s.id,
          quantity: Number(s.quantity),
          unit_price: Number(s.unit_price),
          total: Number(s.quantity) * Number(s.unit_price),
          status: s.status,
          customer: s.customer_account.name,
          date: s.sale_at,
        })),
        customers: customers.map((c) => ({
          account_code: c.customer_account.code,
          name: c.customer_account.name,
          price_per_liter: Number(c.price_per_liter),
        })),
        suppliers: suppliers.map((s) => ({
          account_code: s.supplier_account.code,
          name: s.supplier_account.name,
          price_per_liter: Number(s.price_per_liter),
        })),
      },
    };
  }
}

