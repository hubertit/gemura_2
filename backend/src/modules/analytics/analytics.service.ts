import { Injectable, BadRequestException } from '@nestjs/common';
import { PrismaService } from '../../prisma/prisma.service';
import { User } from '@prisma/client';

@Injectable()
export class AnalyticsService {
  constructor(private prisma: PrismaService) {}

  async getCollectionAnalytics(user: User) {
    if (!user.default_account_id) {
      throw new BadRequestException({
        code: 400,
        status: 'error',
        message: 'No valid default account found.',
      });
    }

    const collections = await this.prisma.milkSale.findMany({
      where: {
        customer_account_id: user.default_account_id,
      },
      select: {
        quantity: true,
        unit_price: true,
        status: true,
        sale_at: true,
      },
    });

    const totalQuantity = collections.reduce((sum, c) => sum + Number(c.quantity), 0);
    const totalAmount = collections.reduce((sum, c) => sum + Number(c.quantity) * Number(c.unit_price), 0);
    const byStatus = collections.reduce((acc, c) => {
      acc[c.status] = (acc[c.status] || 0) + 1;
      return acc;
    }, {} as Record<string, number>);

    return {
      code: 200,
      status: 'success',
      message: 'Collection analytics fetched successfully.',
      data: {
        total_collections: collections.length,
        total_quantity: totalQuantity,
        total_amount: totalAmount,
        average_quantity: collections.length > 0 ? totalQuantity / collections.length : 0,
        by_status: byStatus,
      },
    };
  }

  async getCustomerAnalytics(user: User) {
    if (!user.default_account_id) {
      throw new BadRequestException({
        code: 400,
        status: 'error',
        message: 'No valid default account found.',
      });
    }

    const customers = await this.prisma.supplierCustomer.findMany({
      where: {
        supplier_account_id: user.default_account_id,
        relationship_status: 'active',
      },
      include: {
        customer_account: true,
      },
    });

    const totalCustomers = customers.length;
    const totalVolume = customers.reduce((sum, c) => sum + Number(c.average_supply_quantity), 0);

    return {
      code: 200,
      status: 'success',
      message: 'Customer analytics fetched successfully.',
      data: {
        total_customers: totalCustomers,
        total_volume: totalVolume,
        average_volume: totalCustomers > 0 ? totalVolume / totalCustomers : 0,
        customers: customers.map((c) => ({
          account_code: c.customer_account.code,
          name: c.customer_account.name,
          average_quantity: Number(c.average_supply_quantity),
          price_per_liter: Number(c.price_per_liter),
        })),
      },
    };
  }

  async getMetrics(user: User) {
    if (!user.default_account_id) {
      throw new BadRequestException({
        code: 400,
        status: 'error',
        message: 'No valid default account found.',
      });
    }

    const [collections, customers, suppliers, sales] = await Promise.all([
      this.prisma.milkSale.count({
        where: { customer_account_id: user.default_account_id },
      }),
      this.prisma.supplierCustomer.count({
        where: { supplier_account_id: user.default_account_id, relationship_status: 'active' },
      }),
      this.prisma.supplierCustomer.count({
        where: { customer_account_id: user.default_account_id, relationship_status: 'active' },
      }),
      this.prisma.milkSale.count({
        where: { supplier_account_id: user.default_account_id },
      }),
    ]);

    return {
      code: 200,
      status: 'success',
      message: 'Metrics fetched successfully.',
      data: {
        collections,
        customers,
        suppliers,
        sales,
      },
    };
  }
}

