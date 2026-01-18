import { Injectable, BadRequestException, NotFoundException } from '@nestjs/common';
import { PrismaService } from '../../../prisma/prisma.service';
import { User } from '@prisma/client';
import { CreateReceiptDto } from './dto/create-receipt.dto';

@Injectable()
export class ReceiptsService {
  constructor(private prisma: PrismaService) {}

  async createReceipt(user: User, createDto: CreateReceiptDto) {
    if (!user.default_account_id) {
      throw new BadRequestException({
        code: 400,
        status: 'error',
        message: 'No valid default account found.',
      });
    }

    const receipt = await this.prisma.receipt.create({
      data: {
        receipt_number: createDto.receipt_number,
        supplier_account_id: createDto.supplier_account_id || null,
        customer_account_id: createDto.customer_account_id || user.default_account_id,
        payment_date: new Date(createDto.payment_date),
        amount: createDto.amount,
        payment_method: createDto.payment_method || null,
        reference: createDto.reference || null,
        created_by: user.id,
      },
    });

    return {
      code: 200,
      status: 'success',
      message: 'Receipt created successfully.',
      data: {
        id: receipt.id,
        receipt_number: receipt.receipt_number,
        amount: Number(receipt.amount),
        payment_date: receipt.payment_date,
      },
    };
  }

  async getReceipts(user: User, filters?: any) {
    if (!user.default_account_id) {
      throw new BadRequestException({
        code: 400,
        status: 'error',
        message: 'No valid default account found.',
      });
    }

    const receipts = await this.prisma.receipt.findMany({
      where: {
        OR: [
          { supplier_account_id: user.default_account_id },
          { customer_account_id: user.default_account_id },
        ],
      },
      include: {
        supplier_account: true,
        customer_account: true,
      },
      orderBy: { payment_date: 'desc' },
      take: filters?.limit || 100,
    });

    return {
      code: 200,
      status: 'success',
      message: 'Receipts fetched successfully.',
      data: receipts.map((r) => ({
        id: r.id,
        receipt_number: r.receipt_number,
        amount: Number(r.amount),
        payment_method: r.payment_method,
        payment_date: r.payment_date,
        supplier: r.supplier_account?.name,
        customer: r.customer_account?.name,
      })),
    };
  }

  async getReceipt(user: User, receiptId: string) {
    const receipt = await this.prisma.receipt.findUnique({
      where: { id: receiptId },
      include: {
        supplier_account: true,
        customer_account: true,
      },
    });

    if (!receipt) {
      throw new NotFoundException({
        code: 404,
        status: 'error',
        message: 'Receipt not found.',
      });
    }

    return {
      code: 200,
      status: 'success',
      message: 'Receipt fetched successfully.',
      data: {
        id: receipt.id,
        receipt_number: receipt.receipt_number,
        amount: Number(receipt.amount),
        payment_method: receipt.payment_method,
        payment_date: receipt.payment_date,
        supplier: receipt.supplier_account,
        customer: receipt.customer_account,
      },
    };
  }
}

