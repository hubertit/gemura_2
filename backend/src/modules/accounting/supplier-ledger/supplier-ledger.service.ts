import { Injectable, BadRequestException } from '@nestjs/common';
import { PrismaService } from '../../../prisma/prisma.service';
import { User } from '@prisma/client';

@Injectable()
export class SupplierLedgerService {
  constructor(private prisma: PrismaService) {}

  async getSupplierLedger(user: User, supplierAccountId: string) {
    if (!user.default_account_id) {
      throw new BadRequestException({
        code: 400,
        status: 'error',
        message: 'No valid default account found.',
      });
    }

    const ledger = await this.prisma.supplierLedger.findMany({
      where: {
        supplier_account_id: supplierAccountId,
      },
      include: {
        milk_sale: true,
        transaction: true,
      },
      orderBy: { created_at: 'desc' },
    });

    return {
      code: 200,
      status: 'success',
      message: 'Supplier ledger fetched successfully.',
      data: ledger.map((l) => ({
        id: l.id,
        entry_type: l.entry_type,
        amount: Number(l.amount),
        balance: Number(l.balance),
        description: l.description,
        created_at: l.created_at,
      })),
    };
  }
}

