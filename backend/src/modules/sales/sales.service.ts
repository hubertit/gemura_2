import { Injectable, BadRequestException, NotFoundException, ForbiddenException } from '@nestjs/common';
import { PrismaService } from '../../prisma/prisma.service';
import { User } from '@prisma/client';
import { GetSalesDto, SalesFiltersDto } from './dto/get-sales.dto';
import { UpdateSaleDto } from './dto/update-sale.dto';
import { CancelSaleDto } from './dto/cancel-sale.dto';
import { CreateSaleDto } from './dto/create-sale.dto';
import { TransactionsService } from '../accounting/transactions/transactions.service';
import { TransactionType } from '../accounting/transactions/dto/create-transaction.dto';

@Injectable()
export class SalesService {
  constructor(
    private prisma: PrismaService,
    private transactionsService: TransactionsService,
  ) {}

  async getSales(user: User, filters?: SalesFiltersDto) {
    if (!user.default_account_id) {
      throw new BadRequestException({
        code: 400,
        status: 'error',
        message: 'No valid default account found. Please set a default account.',
      });
    }

    const supplierAccountId = user.default_account_id;

    // Build query with filters
    // Sales are milk sales where the user is the supplier (selling to customers)
    // This matches the overview which shows sales from supplier perspective
    const where: any = {
      supplier_account_id: supplierAccountId,
      status: { not: 'deleted' },
    };

    if (filters) {
      // Filter by customer account code (since we're viewing sales to customers)
      if (filters.customer_account_code) {
        // Filter by customer account code when viewing sales
        const customerAccount = await this.prisma.account.findUnique({
          where: { code: filters.customer_account_code },
        });
        if (customerAccount) {
          where.customer_account_id = customerAccount.id;
        }
      }

      if (filters.status) {
        where.status = filters.status;
      }

      if (filters.date_from || filters.date_to) {
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

      if (filters.quantity_min !== undefined || filters.quantity_max !== undefined) {
        where.quantity = {};
        if (filters.quantity_min !== undefined) {
          where.quantity.gte = filters.quantity_min;
        }
        if (filters.quantity_max !== undefined) {
          where.quantity.lte = filters.quantity_max;
        }
      }

      if (filters.price_min !== undefined || filters.price_max !== undefined) {
        where.unit_price = {};
        if (filters.price_min !== undefined) {
          where.unit_price.gte = filters.price_min;
        }
        if (filters.price_max !== undefined) {
          where.unit_price.lte = filters.price_max;
        }
      }
    }

    const sales = await this.prisma.milkSale.findMany({
      where,
      include: {
        supplier_account: true,
        customer_account: true,
      },
      orderBy: {
        sale_at: 'desc',
      },
    });

    const formattedSales = sales.map((sale) => ({
      id: sale.id,
      quantity: Number(sale.quantity),
      unit_price: Number(sale.unit_price),
      total_amount: Number(sale.quantity) * Number(sale.unit_price),
      status: sale.status,
      sale_at: sale.sale_at,
      notes: sale.notes,
      created_at: sale.created_at,
      supplier_account: {
        id: sale.supplier_account.id,
        code: sale.supplier_account.code,
        name: sale.supplier_account.name,
        type: sale.supplier_account.type,
        status: sale.supplier_account.status,
      },
      customer_account: {
        id: sale.customer_account.id,
        code: sale.customer_account.code,
        name: sale.customer_account.name,
        type: sale.customer_account.type,
        status: sale.customer_account.status,
      },
    }));

    return {
      code: 200,
      status: 'success',
      message: 'Sales fetched successfully.',
      data: formattedSales,
    };
  }

  async updateSale(user: User, saleId: string, updateDto: UpdateSaleDto) {
    if (!user.default_account_id) {
      throw new BadRequestException({
        code: 400,
        status: 'error',
        message: 'No valid default account found. Please set a default account.',
      });
    }

    // Check if sale exists and belongs to supplier
    const sale = await this.prisma.milkSale.findFirst({
      where: {
        id: saleId,
        supplier_account_id: user.default_account_id,
      },
    });

    if (!sale) {
      throw new NotFoundException({
        code: 404,
        status: 'error',
        message: 'Sale not found or not owned by this supplier.',
      });
    }

    // Build update data
    const updateData: any = {
      updated_by: user.id,
    };

    // Support both UUID and code for customer account
    if (updateDto.customer_account_id) {
      // Validate UUID format
      const uuidRegex = /^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/i;
      if (!uuidRegex.test(updateDto.customer_account_id)) {
        throw new BadRequestException({
          code: 400,
          status: 'error',
          message: 'Invalid customer account ID format. Must be a valid UUID.',
        });
      }
      updateData.customer_account_id = updateDto.customer_account_id;
    } else if (updateDto.customer_account_code) {
      // Fallback: Find by code
      const customerAccount = await this.prisma.account.findUnique({
        where: { code: updateDto.customer_account_code },
      });
      if (customerAccount) {
        updateData.customer_account_id = customerAccount.id;
      }
    }

    if (updateDto.quantity !== undefined) {
      updateData.quantity = updateDto.quantity;
    }

    if (updateDto.status) {
      updateData.status = updateDto.status as any;
    }

    if (updateDto.sale_at) {
      updateData.sale_at = new Date(updateDto.sale_at);
    }

    if (updateDto.notes !== undefined) {
      updateData.notes = updateDto.notes;
    }

    if (Object.keys(updateData).length === 1) {
      // Only updated_by, no actual fields to update
      throw new BadRequestException({
        code: 400,
        status: 'error',
        message: 'No fields to update.',
      });
    }

    const updatedSale = await this.prisma.milkSale.update({
      where: { id: saleId },
      data: updateData,
      include: {
        supplier_account: true,
        customer_account: true,
      },
    });

    return {
      code: 200,
      status: 'success',
      message: 'Sale updated successfully.',
      data: {
        id: updatedSale.id,
        quantity: Number(updatedSale.quantity),
        unit_price: Number(updatedSale.unit_price),
        status: updatedSale.status,
        sale_at: updatedSale.sale_at,
        notes: updatedSale.notes,
      },
    };
  }

  async cancelSale(user: User, cancelDto: CancelSaleDto) {
    if (!user.default_account_id) {
      throw new BadRequestException({
        code: 400,
        status: 'error',
        message: 'No valid default account found. Please set a default account.',
      });
    }

    // Check if sale exists and belongs to supplier
    const sale = await this.prisma.milkSale.findFirst({
      where: {
        id: cancelDto.sale_id,
        supplier_account_id: user.default_account_id,
      },
    });

    if (!sale) {
      throw new NotFoundException({
        code: 404,
        status: 'error',
        message: 'Sale not found or not authorized.',
      });
    }

    // Update status to cancelled
    await this.prisma.milkSale.update({
      where: { id: cancelDto.sale_id },
      data: {
        status: 'cancelled',
        updated_by: user.id,
      },
    });

    return {
      code: 200,
      status: 'success',
      message: 'Sale cancelled successfully.',
    };
  }

  async createSale(user: User, createDto: CreateSaleDto) {
    const { customer_account_code, customer_account_id, quantity, unit_price, status, sale_at, notes, payment_status } = createDto;

    // Check if user has a valid default account
    if (!user.default_account_id) {
      throw new BadRequestException({
        code: 400,
        status: 'error',
        message: 'No valid default account found. Please set a default account.',
      });
    }

    // Validate that at least one customer identifier is provided
    if (!customer_account_code && !customer_account_id) {
      throw new BadRequestException({
        code: 400,
        status: 'error',
        message: 'Either customer_account_id (UUID) or customer_account_code must be provided.',
      });
    }

    const supplierAccountId = user.default_account_id;

    // Get customer account - prioritize UUID, fallback to code
    let customerAccount;
    if (customer_account_id) {
      // Validate UUID format
      const uuidRegex = /^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/i;
      if (!uuidRegex.test(customer_account_id)) {
        throw new BadRequestException({
          code: 400,
          status: 'error',
          message: 'Invalid customer account ID format. Must be a valid UUID.',
        });
      }
      
      // Find by UUID
      customerAccount = await this.prisma.account.findUnique({
        where: { id: customer_account_id },
      });
    } else if (customer_account_code) {
      // Fallback: Find by code
      customerAccount = await this.prisma.account.findUnique({
        where: { code: customer_account_code },
      });
    }

    if (!customerAccount || customerAccount.status !== 'active') {
      throw new NotFoundException({
        code: 404,
        status: 'error',
        message: 'Customer account not found.',
      });
    }

    const customerAccountId = customerAccount.id;

    // Get unit price from supplier-customer relationship if not provided
    let finalUnitPrice = unit_price;
    if (!finalUnitPrice) {
      const relationship = await this.prisma.supplierCustomer.findFirst({
        where: {
          supplier_account_id: supplierAccountId,
          customer_account_id: customerAccountId,
          relationship_status: 'active',
        },
      });
      finalUnitPrice = relationship ? Number(relationship.price_per_liter) : 0;
    }

    // Create milk sale
    try {
      const totalAmount = quantity * finalUnitPrice;
      const amountPaid = payment_status === 'paid' ? totalAmount : 0;
      const finalPaymentStatus = payment_status || 'unpaid';
      const paymentHistory = [];

      const milkSale = await this.prisma.milkSale.create({
        data: {
          supplier_account_id: supplierAccountId,
          customer_account_id: customerAccountId,
          quantity: quantity,
          unit_price: finalUnitPrice,
          status: (status || 'accepted') as any,
          sale_at: sale_at ? new Date(sale_at) : new Date(),
          notes: notes || null,
          amount_paid: amountPaid,
          payment_status: finalPaymentStatus,
          payment_history: paymentHistory,
          recorded_by: user.id,
          created_by: user.id,
        },
        include: {
          supplier_account: true,
          customer_account: true,
        },
      });

      // Create accounting entries based on payment status
      if (totalAmount > 0) {
        try {
          if (finalPaymentStatus === 'paid') {
            // Paid: Direct to Cash and Revenue
            await this.transactionsService.createTransaction(user, {
              type: TransactionType.REVENUE,
              amount: totalAmount,
              description: `Milk sale to ${customerAccount.name} - ${quantity}L @ ${finalUnitPrice} Frw/L`,
              transaction_date: (sale_at ? new Date(sale_at) : new Date()).toISOString().split('T')[0],
            });
          } else {
            // Unpaid: Create AR entry (DR AR, CR Revenue)
            await this.createAccountsReceivableEntry(user, {
              sale_id: milkSale.id,
              customer_account_id: customerAccountId,
              customer_name: customerAccount.name,
              amount: totalAmount,
              description: `Milk sale to ${customerAccount.name} - ${quantity}L @ ${finalUnitPrice} Frw/L`,
              sale_date: sale_at ? new Date(sale_at) : new Date(),
            });
          }
        } catch (error) {
          // Log error but don't fail the sale creation
          console.error('Failed to create finance transaction for sale:', error);
        }
      }

      return {
        code: 200,
        status: 'success',
        message: 'Sale created successfully.',
        data: {
          id: milkSale.id,
          quantity: Number(milkSale.quantity),
          unit_price: Number(milkSale.unit_price),
          total_amount: totalAmount,
          status: milkSale.status,
          sale_at: milkSale.sale_at,
          notes: milkSale.notes,
          amount_paid: amountPaid,
          payment_status: finalPaymentStatus,
          supplier_account: {
            id: milkSale.supplier_account.id,
            code: milkSale.supplier_account.code,
            name: milkSale.supplier_account.name,
            type: milkSale.supplier_account.type,
            status: milkSale.supplier_account.status,
          },
          customer_account: {
            id: milkSale.customer_account.id,
            code: milkSale.customer_account.code,
            name: milkSale.customer_account.name,
            type: milkSale.customer_account.type,
            status: milkSale.customer_account.status,
          },
        },
      };
    } catch (error) {
      throw new BadRequestException({
        code: 500,
        status: 'error',
        message: 'Failed to create sale.',
        error: error.message,
      });
    }
  }

  /**
   * Create Accounts Receivable journal entry for unpaid sales
   * DR Accounts Receivable, CR Revenue
   */
  private async createAccountsReceivableEntry(
    user: User,
    data: {
      sale_id: string;
      customer_account_id: string;
      customer_name: string;
      amount: number;
      description: string;
      sale_date: Date;
    },
  ) {
    // Get user's default account
    const defaultAccount = await this.prisma.account.findUnique({
      where: { id: user.default_account_id },
    });

    if (!defaultAccount) {
      throw new BadRequestException('Default account not found');
    }

    // Get or create AR account
    const arAccountCode = `AR-${defaultAccount.code || defaultAccount.id.substring(0, 8).toUpperCase()}`;
    let arAccount = await this.prisma.chartOfAccount.findFirst({
      where: {
        code: arAccountCode,
        account_type: 'Asset',
        is_active: true,
      },
    });

    if (!arAccount) {
      arAccount = await this.prisma.chartOfAccount.create({
        data: {
          code: arAccountCode,
          name: `Accounts Receivable - ${defaultAccount.name}`,
          account_type: 'Asset',
          is_active: true,
        },
      });
    }

    // Get or create Revenue account
    const revenueAccountCode = `REV-${defaultAccount.code || defaultAccount.id.substring(0, 8).toUpperCase()}`;
    let revenueAccount = await this.prisma.chartOfAccount.findFirst({
      where: {
        code: revenueAccountCode,
        account_type: 'Revenue',
        is_active: true,
      },
    });

    if (!revenueAccount) {
      revenueAccount = await this.prisma.chartOfAccount.create({
        data: {
          code: revenueAccountCode,
          name: `General Revenue - ${defaultAccount.name}`,
          account_type: 'Revenue',
          is_active: true,
        },
      });
    }

    // Create journal entry: DR AR, CR Revenue
    await this.prisma.accountingTransaction.create({
      data: {
        transaction_date: data.sale_date,
        description: data.description,
        total_amount: data.amount,
        created_by: user.id,
        entries: {
          create: [
            {
              account_id: arAccount.id,
              debit_amount: data.amount,
              credit_amount: null,
              description: `AR: ${data.description}`,
            },
            {
              account_id: revenueAccount.id,
              credit_amount: data.amount,
              debit_amount: null,
              description: `Revenue: ${data.description}`,
            },
          ],
        },
      },
    });
  }

  /**
   * Record payment for a sale (reduces AR)
   * DR Cash, CR Accounts Receivable
   */
  async recordPayment(user: User, saleId: string, paymentDto: { amount: number; payment_date?: string; notes?: string }) {
    const sale = await this.prisma.milkSale.findFirst({
      where: {
        id: saleId,
        supplier_account_id: user.default_account_id, // Verify ownership
      },
      include: {
        customer_account: true,
      },
    });

    if (!sale) {
      throw new NotFoundException({
        code: 404,
        status: 'error',
        message: 'Sale not found or you do not have permission to record payment for this sale.',
      });
    }

    const totalAmount = Number(sale.quantity) * Number(sale.unit_price);
    const currentPaid = Number(sale.amount_paid || 0);
    const newPayment = Number(paymentDto.amount);

    if (newPayment <= 0) {
      throw new BadRequestException({
        code: 400,
        status: 'error',
        message: 'Payment amount must be greater than 0.',
      });
    }

    const newTotalPaid = currentPaid + newPayment;

    if (newTotalPaid > totalAmount) {
      throw new BadRequestException({
        code: 400,
        status: 'error',
        message: `Payment amount exceeds outstanding balance. Outstanding: ${totalAmount - currentPaid}`,
      });
    }

    // Calculate payment status
    const paymentStatus = newTotalPaid >= totalAmount ? 'paid' : newTotalPaid > 0 ? 'partial' : 'unpaid';

    // Update payment history
    const paymentHistory = (sale.payment_history as any[]) || [];
    paymentHistory.push({
      date: paymentDto.payment_date || new Date().toISOString(),
      amount: newPayment,
      notes: paymentDto.notes || null,
    });

    // Update sale
    await this.prisma.milkSale.update({
      where: { id: saleId },
      data: {
        amount_paid: newTotalPaid,
        payment_status: paymentStatus,
        payment_history: paymentHistory,
      },
    });

    // Get user's default account
    const defaultAccount = await this.prisma.account.findUnique({
      where: { id: user.default_account_id },
    });

    if (!defaultAccount) {
      throw new BadRequestException('Default account not found');
    }

    // Get or create AR account
    const arAccountCode = `AR-${defaultAccount.code || defaultAccount.id.substring(0, 8).toUpperCase()}`;
    let arAccount = await this.prisma.chartOfAccount.findFirst({
      where: { 
        code: arAccountCode, 
        account_type: 'Asset',
        is_active: true,
      },
    });

    if (!arAccount) {
      // Create AR account if it doesn't exist (e.g., if sale was created as paid initially)
      arAccount = await this.prisma.chartOfAccount.create({
        data: {
          code: arAccountCode,
          name: `Accounts Receivable - ${defaultAccount.name}`,
          account_type: 'Asset',
          is_active: true,
        },
      });
    }

    const cashAccountCode = `CASH-${defaultAccount.code || defaultAccount.id.substring(0, 8).toUpperCase()}`;
    let cashAccount = await this.prisma.chartOfAccount.findFirst({
      where: { code: cashAccountCode, account_type: 'Asset' },
    });

    if (!cashAccount) {
      cashAccount = await this.prisma.chartOfAccount.create({
        data: {
          code: cashAccountCode,
          name: `Cash - ${defaultAccount.name}`,
          account_type: 'Asset',
          is_active: true,
        },
      });
    }

    // Create journal entry: DR Cash, CR AR
    const paymentDate = paymentDto.payment_date ? new Date(paymentDto.payment_date) : new Date();
    await this.prisma.accountingTransaction.create({
      data: {
        transaction_date: paymentDate,
        description: `Payment received from ${sale.customer_account.name} for sale ${saleId}${paymentDto.notes ? ` - ${paymentDto.notes}` : ''}`,
        total_amount: newPayment,
        created_by: user.id,
        entries: {
          create: [
            {
              account_id: cashAccount.id,
              debit_amount: newPayment,
              credit_amount: null,
              description: `Cash received: ${paymentDto.notes || ''}`,
            },
            {
              account_id: arAccount.id,
              credit_amount: newPayment,
              debit_amount: null,
              description: `AR reduced for sale ${saleId}`,
            },
          ],
        },
      },
    });

    return {
      code: 200,
      status: 'success',
      message: 'Payment recorded successfully',
      data: {
        sale_id: saleId,
        amount_paid: newTotalPaid,
        outstanding: totalAmount - newTotalPaid,
        payment_status: paymentStatus,
      },
    };
  }
}

