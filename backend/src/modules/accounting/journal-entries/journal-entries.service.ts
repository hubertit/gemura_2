import { Injectable, BadRequestException, NotFoundException } from '@nestjs/common';
import { PrismaService } from '../../../prisma/prisma.service';
import { User } from '@prisma/client';
import { CreateJournalEntryDto } from './dto/create-journal-entry.dto';
import { UpdateJournalEntryDto } from './dto/update-journal-entry.dto';

@Injectable()
export class JournalEntriesService {
  constructor(private prisma: PrismaService) {}

  async createEntry(user: User, createDto: CreateJournalEntryDto) {
    // Validate debits = credits
    const totalDebits = createDto.entries.reduce((sum, e) => sum + (Number(e.debit_amount) || 0), 0);
    const totalCredits = createDto.entries.reduce((sum, e) => sum + (Number(e.credit_amount) || 0), 0);

    if (Math.abs(totalDebits - totalCredits) > 0.01) {
      throw new BadRequestException({
        code: 400,
        status: 'error',
        message: 'Total debits must equal total credits.',
      });
    }

    const transaction = await this.prisma.accountingTransaction.create({
      data: {
        transaction_date: new Date(createDto.transaction_date),
        reference_number: createDto.reference_number,
        description: createDto.description,
        total_amount: totalDebits,
        created_by: user.id,
      },
    });

    await Promise.all(
      createDto.entries.map((entry) =>
        this.prisma.accountingTransactionEntry.create({
          data: {
            transaction_id: transaction.id,
            account_id: entry.account_id,
            debit_amount: entry.debit_amount || null,
            credit_amount: entry.credit_amount || null,
            description: entry.description,
          },
        }),
      ),
    );

    return {
      code: 200,
      status: 'success',
      message: 'Journal entry created successfully.',
      data: {
        id: transaction.id,
        total_amount: Number(transaction.total_amount),
      },
    };
  }

  async getEntries(user: User, filters?: any) {
    const transactions = await this.prisma.accountingTransaction.findMany({
      where: {
        ...(filters?.date_from && { transaction_date: { gte: new Date(filters.date_from) } }),
        ...(filters?.date_to && { transaction_date: { lte: new Date(filters.date_to) } }),
      },
      include: {
        entries: {
          include: {
            account: true,
          },
        },
      },
      orderBy: { transaction_date: 'desc' },
      take: filters?.limit || 100,
    });

    return {
      code: 200,
      status: 'success',
      message: 'Journal entries fetched successfully.',
      data: transactions.map((t) => ({
        id: t.id,
        transaction_date: t.transaction_date,
        reference_number: t.reference_number,
        description: t.description,
        total_amount: Number(t.total_amount),
        entries: t.entries.map((e) => ({
          account: e.account.name,
          debit_amount: e.debit_amount ? Number(e.debit_amount) : null,
          credit_amount: e.credit_amount ? Number(e.credit_amount) : null,
        })),
      })),
    };
  }

  async updateEntry(user: User, entryId: string, updateDto: UpdateJournalEntryDto) {
    const transaction = await this.prisma.accountingTransaction.findUnique({
      where: { id: entryId },
      include: { entries: true },
    });

    if (!transaction) {
      throw new NotFoundException({
        code: 404,
        status: 'error',
        message: 'Journal entry not found.',
      });
    }

    const updated = await this.prisma.accountingTransaction.update({
      where: { id: entryId },
      data: {
        description: updateDto.description || transaction.description,
        reference_number: updateDto.reference_number || transaction.reference_number,
      },
    });

    return {
      code: 200,
      status: 'success',
      message: 'Journal entry updated successfully.',
      data: updated,
    };
  }
}

