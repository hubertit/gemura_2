import { Injectable, BadRequestException, NotFoundException } from '@nestjs/common';
import { PrismaService } from '../../../prisma/prisma.service';
import { User } from '@prisma/client';
import { CreateInvoiceDto } from './dto/create-invoice.dto';
import { UpdateInvoiceDto } from './dto/update-invoice.dto';

@Injectable()
export class InvoicesService {
  constructor(private prisma: PrismaService) {}

  async createInvoice(user: User, createDto: CreateInvoiceDto) {
    if (!user.default_account_id) {
      throw new BadRequestException({
        code: 400,
        status: 'error',
        message: 'No valid default account found.',
      });
    }

    const totalAmount = createDto.items.reduce((sum, item) => sum + Number(item.total_amount), 0);
    const taxAmount = createDto.tax_amount || 0;

    const invoice = await this.prisma.invoice.create({
      data: {
        invoice_number: createDto.invoice_number,
        supplier_account_id: createDto.supplier_account_id || user.default_account_id,
        issue_date: new Date(createDto.issue_date),
        due_date: createDto.due_date ? new Date(createDto.due_date) : null,
        total_amount: totalAmount,
        tax_amount: taxAmount,
        status: 'draft',
        created_by: user.id,
      },
    });

    await Promise.all(
      createDto.items.map((item) =>
        this.prisma.invoiceItem.create({
          data: {
            invoice_id: invoice.id,
            description: item.description,
            quantity: item.quantity || null,
            unit_price: item.unit_price,
            total_amount: item.total_amount,
          },
        }),
      ),
    );

    return {
      code: 200,
      status: 'success',
      message: 'Invoice created successfully.',
      data: {
        id: invoice.id,
        invoice_number: invoice.invoice_number,
        total_amount: Number(invoice.total_amount),
        status: invoice.status,
      },
    };
  }

  async getInvoices(user: User, filters?: any) {
    if (!user.default_account_id) {
      throw new BadRequestException({
        code: 400,
        status: 'error',
        message: 'No valid default account found.',
      });
    }

    const invoices = await this.prisma.invoice.findMany({
      where: {
        supplier_account_id: user.default_account_id,
        ...(filters?.status && { status: filters.status }),
      },
      include: {
        items: true,
      },
      orderBy: { issue_date: 'desc' },
      take: filters?.limit || 100,
    });

    return {
      code: 200,
      status: 'success',
      message: 'Invoices fetched successfully.',
      data: invoices.map((i) => ({
        id: i.id,
        invoice_number: i.invoice_number,
        total_amount: Number(i.total_amount),
        tax_amount: Number(i.tax_amount),
        status: i.status,
        issue_date: i.issue_date,
        items: i.items,
      })),
    };
  }

  async getInvoice(user: User, invoiceId: string) {
    const invoice = await this.prisma.invoice.findUnique({
      where: { id: invoiceId },
      include: {
        items: true,
        supplier_account: true,
      },
    });

    if (!invoice) {
      throw new NotFoundException({
        code: 404,
        status: 'error',
        message: 'Invoice not found.',
      });
    }

    return {
      code: 200,
      status: 'success',
      message: 'Invoice fetched successfully.',
      data: {
        id: invoice.id,
        invoice_number: invoice.invoice_number,
        supplier: invoice.supplier_account.name,
        total_amount: Number(invoice.total_amount),
        tax_amount: Number(invoice.tax_amount),
        status: invoice.status,
        issue_date: invoice.issue_date,
        due_date: invoice.due_date,
        items: invoice.items,
      },
    };
  }

  async updateInvoice(user: User, invoiceId: string, updateDto: UpdateInvoiceDto) {
    const invoice = await this.prisma.invoice.findUnique({ where: { id: invoiceId } });
    if (!invoice) {
      throw new NotFoundException({
        code: 404,
        status: 'error',
        message: 'Invoice not found.',
      });
    }

    const updated = await this.prisma.invoice.update({
      where: { id: invoiceId },
      data: {
        status: updateDto.status || invoice.status,
        due_date: updateDto.due_date ? new Date(updateDto.due_date) : invoice.due_date,
      },
    });

    return {
      code: 200,
      status: 'success',
      message: 'Invoice updated successfully.',
      data: updated,
    };
  }
}

