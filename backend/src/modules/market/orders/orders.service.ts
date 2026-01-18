import { Injectable, BadRequestException, NotFoundException } from '@nestjs/common';
import { PrismaService } from '../../../prisma/prisma.service';
import { User } from '@prisma/client';
import { CreateOrderDto } from './dto/create-order.dto';

@Injectable()
export class OrdersService {
  constructor(private prisma: PrismaService) {}

  async createOrder(user: User, createDto: CreateOrderDto) {
    if (!user.default_account_id) {
      throw new BadRequestException({
        code: 400,
        status: 'error',
        message: 'No valid default account found.',
      });
    }

    // Calculate total
    let totalAmount = 0;
    const orderItems = [];

    for (const item of createDto.items) {
      const product = await this.prisma.product.findUnique({
        where: { id: item.product_id },
      });

      if (!product) {
        throw new NotFoundException({
          code: 404,
          status: 'error',
          message: `Product ${item.product_id} not found.`,
        });
      }

      const price = item.price || Number(product.price);
      const itemTotal = price * item.quantity;
      totalAmount += itemTotal;

      orderItems.push({
        product_id: item.product_id,
        quantity: item.quantity,
        price: price,
      });
    }

    // Create order
    const order = await this.prisma.order.create({
      data: {
        customer_id: createDto.customer_id || null,
        seller_id: createDto.seller_id || null,
        account_id: user.default_account_id,
        total_amount: totalAmount,
        status: 'pending',
        shipping_address: createDto.shipping_address || null,
      },
    });

    // Create order items
    await Promise.all(
      orderItems.map((item) =>
        this.prisma.orderItem.create({
          data: {
            order_id: order.id,
            product_id: item.product_id,
            quantity: item.quantity,
            price: item.price,
          },
        }),
      ),
    );

    return {
      code: 200,
      status: 'success',
      message: 'Order created successfully.',
      data: {
        id: order.id,
        total_amount: Number(order.total_amount),
        status: order.status,
        items: orderItems,
      },
    };
  }

  async getOrders(user: User, filters?: any) {
    if (!user.default_account_id) {
      throw new BadRequestException({
        code: 400,
        status: 'error',
        message: 'No valid default account found.',
      });
    }

    const orders = await this.prisma.order.findMany({
      where: {
        account_id: user.default_account_id,
        ...(filters?.status && { status: filters.status as any }),
      },
      include: {
        items: {
          include: {
            product: true,
          },
        },
      },
      orderBy: { created_at: 'desc' },
      take: filters?.limit || 100,
    });

    return {
      code: 200,
      status: 'success',
      message: 'Orders fetched successfully.',
      data: orders.map((o) => ({
        id: o.id,
        total_amount: Number(o.total_amount),
        status: o.status,
        items: o.items.map((i) => ({
          product: i.product.name,
          quantity: i.quantity,
          price: Number(i.price),
        })),
        created_at: o.created_at,
      })),
    };
  }

  async getOrder(user: User, orderId: string) {
    const order = await this.prisma.order.findUnique({
      where: { id: orderId },
      include: {
        items: {
          include: {
            product: true,
          },
        },
      },
    });

    if (!order) {
      throw new NotFoundException({
        code: 404,
        status: 'error',
        message: 'Order not found.',
      });
    }

    return {
      code: 200,
      status: 'success',
      message: 'Order fetched successfully.',
      data: {
        id: order.id,
        total_amount: Number(order.total_amount),
        status: order.status,
        shipping_address: order.shipping_address,
        items: order.items.map((i) => ({
          product: {
            id: i.product.id,
            name: i.product.name,
            price: Number(i.product.price),
          },
          quantity: i.quantity,
          price: Number(i.price),
          total: Number(i.price) * i.quantity,
        })),
        created_at: order.created_at,
      },
    };
  }

  async updateOrderStatus(user: User, orderId: string, status: string) {
    const order = await this.prisma.order.findUnique({ where: { id: orderId } });
    if (!order) {
      throw new NotFoundException({
        code: 404,
        status: 'error',
        message: 'Order not found.',
      });
    }

    const updated = await this.prisma.order.update({
      where: { id: orderId },
      data: { status: status as any },
    });

    return {
      code: 200,
      status: 'success',
      message: 'Order status updated successfully.',
      data: {
        id: updated.id,
        status: updated.status,
      },
    };
  }

  async getAdminOrders(user: User) {
    return this.getOrders(user, { limit: 500 });
  }

  async getAdminOrder(user: User, orderId: string) {
    return this.getOrder(user, orderId);
  }

  async getCustomerOrders(user: User) {
    if (!user.default_account_id) {
      throw new BadRequestException({
        code: 400,
        status: 'error',
        message: 'No valid default account found.',
      });
    }

    const orders = await this.prisma.order.findMany({
      where: {
        customer_id: user.id,
        account_id: user.default_account_id,
      },
      include: {
        items: {
          include: {
            product: true,
          },
        },
      },
      orderBy: { created_at: 'desc' },
    });

    return {
      code: 200,
      status: 'success',
      message: 'Customer orders fetched successfully.',
      data: orders.map((o) => ({
        id: o.id,
        total_amount: Number(o.total_amount),
        status: o.status,
        items: o.items.map((i) => ({
          product: i.product.name,
          quantity: i.quantity,
          price: Number(i.price),
        })),
        created_at: o.created_at,
      })),
    };
  }

  async getCustomerOrderDetails(user: User, orderId: string) {
    return this.getOrder(user, orderId);
  }

  async placeOrder(user: User, createDto: CreateOrderDto) {
    return this.createOrder(user, createDto);
  }

  async cancelOrder(user: User, orderId: string) {
    return this.updateOrderStatus(user, orderId, 'cancelled');
  }

  async getSellerOrders(user: User) {
    if (!user.default_account_id) {
      throw new BadRequestException({
        code: 400,
        status: 'error',
        message: 'No valid default account found.',
      });
    }

    const orders = await this.prisma.order.findMany({
      where: {
        seller_id: user.id,
        account_id: user.default_account_id,
      },
      include: {
        items: {
          include: {
            product: true,
          },
        },
      },
      orderBy: { created_at: 'desc' },
    });

    return {
      code: 200,
      status: 'success',
      message: 'Seller orders fetched successfully.',
      data: orders,
    };
  }

  async getSellerOrderDetails(user: User, orderId: string) {
    return this.getOrder(user, orderId);
  }

  async updateSellerOrderStatus(user: User, orderId: string, status: string) {
    return this.updateOrderStatus(user, orderId, status);
  }
}

