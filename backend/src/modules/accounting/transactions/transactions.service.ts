import { Injectable, BadRequestException } from '@nestjs/common';
import { PrismaService } from '../../../prisma/prisma.service';
import { User } from '@prisma/client';
import { CreateTransactionDto, TransactionType } from './dto/create-transaction.dto';

@Injectable()
export class TransactionsService {
  constructor(private prisma: PrismaService) {}

  async createTransaction(user: User, createDto: CreateTransactionDto) {
    if (!user.default_account_id) {
      throw new BadRequestException({
        code: 400,
        status: 'error',
        message: 'No valid default account found. Please set a default account first.',
      });
    }

    // Get user's default account
    const defaultAccount = await this.prisma.account.findUnique({
      where: { id: user.default_account_id },
    });

    if (!defaultAccount) {
      throw new BadRequestException({
        code: 400,
        status: 'error',
        message: 'Default account not found.',
      });
    }

    // Find or create Cash/Asset account for this account
    const cashAccountCode = `CASH-${defaultAccount.code || defaultAccount.id.substring(0, 8).toUpperCase()}`;
    let cashAccount = await this.prisma.chartOfAccount.findFirst({
      where: {
        code: cashAccountCode,
        account_type: 'Asset',
        is_active: true,
      },
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

    // Find or get the revenue/expense account
    let categoryAccount: any;
    if (createDto.account_id) {
      // Use provided account
      categoryAccount = await this.prisma.chartOfAccount.findUnique({
        where: { id: createDto.account_id },
      });
      if (!categoryAccount) {
        throw new BadRequestException({
          code: 400,
          status: 'error',
          message: 'Specified account not found.',
        });
      }
      // Validate account type matches transaction type
      if (
        (createDto.type === TransactionType.REVENUE && categoryAccount.account_type !== 'Revenue') ||
        (createDto.type === TransactionType.EXPENSE && categoryAccount.account_type !== 'Expense')
      ) {
        throw new BadRequestException({
          code: 400,
          status: 'error',
          message: `Account type mismatch. Expected ${createDto.type === TransactionType.REVENUE ? 'Revenue' : 'Expense'} account.`,
        });
      }
    } else {
      // Find or create default revenue/expense account
      const accountType = createDto.type === TransactionType.REVENUE ? 'Revenue' : 'Expense';
      const defaultAccountName = createDto.type === TransactionType.REVENUE ? 'General Revenue' : 'General Expense';
      const defaultAccountCode = createDto.type === TransactionType.REVENUE 
        ? `REV-${defaultAccount.code || defaultAccount.id.substring(0, 8).toUpperCase()}`
        : `EXP-${defaultAccount.code || defaultAccount.id.substring(0, 8).toUpperCase()}`;

      categoryAccount = await this.prisma.chartOfAccount.findFirst({
        where: {
          code: defaultAccountCode,
          account_type: accountType,
          is_active: true,
        },
      });

      if (!categoryAccount) {
        categoryAccount = await this.prisma.chartOfAccount.create({
          data: {
            code: defaultAccountCode,
            name: `${defaultAccountName} - ${defaultAccount.name}`,
            account_type: accountType,
            is_active: true,
          },
        });
      }
    }

    // Create journal entry
    // For Revenue: Credit Revenue account, Debit Cash account
    // For Expense: Debit Expense account, Credit Cash account
    const transactionDate = new Date(createDto.transaction_date);
    const amount = Number(createDto.amount);

    const transaction = await this.prisma.accountingTransaction.create({
      data: {
        transaction_date: transactionDate,
        description: createDto.description,
        total_amount: amount,
        created_by: user.id,
        entries: {
          create: [
            // Revenue entry
            ...(createDto.type === TransactionType.REVENUE
              ? [
                  {
                    account_id: categoryAccount.id,
                    credit_amount: amount,
                    debit_amount: null,
                    description: createDto.description,
                  },
                  {
                    account_id: cashAccount.id,
                    debit_amount: amount,
                    credit_amount: null,
                    description: createDto.description,
                  },
                ]
              : [
                  // Expense entry
                  {
                    account_id: categoryAccount.id,
                    debit_amount: amount,
                    credit_amount: null,
                    description: createDto.description,
                  },
                  {
                    account_id: cashAccount.id,
                    credit_amount: amount,
                    debit_amount: null,
                    description: createDto.description,
                  },
                ]),
          ],
        },
      },
      include: {
        entries: {
          include: {
            account: true,
          },
        },
      },
    });

    return {
      code: 200,
      status: 'success',
      message: `${createDto.type === TransactionType.REVENUE ? 'Revenue' : 'Expense'} recorded successfully.`,
      data: {
        id: transaction.id,
        type: createDto.type,
        amount: amount,
        description: createDto.description,
        transaction_date: transaction.transaction_date,
        account: defaultAccount.name,
        category_account: categoryAccount.name,
        cash_account: cashAccount.name,
      },
    };
  }

  async getTransactions(user: User, filters?: { type?: TransactionType; date_from?: string; date_to?: string; limit?: number }) {
    if (!user.default_account_id) {
      throw new BadRequestException({
        code: 400,
        status: 'error',
        message: 'No valid default account found.',
      });
    }

    // Get cash account for this user's default account
    const defaultAccount = await this.prisma.account.findUnique({
      where: { id: user.default_account_id },
    });

    if (!defaultAccount) {
      throw new BadRequestException({
        code: 400,
        status: 'error',
        message: 'Default account not found.',
      });
    }

    const cashAccountCode = `CASH-${defaultAccount.code || defaultAccount.id.substring(0, 8).toUpperCase()}`;
    const cashAccount = await this.prisma.chartOfAccount.findFirst({
      where: {
        code: cashAccountCode,
        account_type: 'Asset',
        is_active: true,
      },
    });

    if (!cashAccount) {
      return {
        code: 200,
        status: 'success',
        message: 'Transactions fetched successfully.',
        data: [],
      };
    }

    // Find transactions that involve the cash account
    const transactions = await this.prisma.accountingTransaction.findMany({
      where: {
        entries: {
          some: {
            account_id: cashAccount.id,
          },
        },
        ...(filters?.date_from && { transaction_date: { gte: new Date(filters.date_from) } }),
        ...(filters?.date_to && { transaction_date: { lte: new Date(filters.date_to) } }),
        created_by: user.id,
      },
      include: {
        entries: {
          include: {
            account: true,
          },
        },
      },
      orderBy: { transaction_date: 'desc' },
      take: filters?.limit || 50,
    });

    // Filter and format transactions
    const formattedTransactions = transactions
      .map((t) => {
        // Determine if it's revenue or expense based on entries
        const revenueEntry = t.entries.find((e) => e.account.account_type === 'Revenue' && e.credit_amount);
        const expenseEntry = t.entries.find((e) => e.account.account_type === 'Expense' && e.debit_amount);

        // Receivable payment: DR Cash, CR AR (Asset) - money received
        const arPaymentEntry = t.entries.find(
          (e) =>
            e.account.account_type === 'Asset' &&
            e.account.code?.startsWith('AR-') &&
            e.credit_amount,
        );
        // Payable payment: DR AP (Liability), CR Cash - money paid
        const apPaymentEntry = t.entries.find(
          (e) =>
            e.account.account_type === 'Liability' &&
            e.account.code?.startsWith('AP-') &&
            e.debit_amount,
        );

        let type: TransactionType;
        let amount: number;
        let categoryAccount: string;

        if (revenueEntry) {
          type = TransactionType.REVENUE;
          amount = Number(revenueEntry.credit_amount);
          categoryAccount = revenueEntry.account.name;
        } else if (expenseEntry) {
          type = TransactionType.EXPENSE;
          amount = Number(expenseEntry.debit_amount);
          categoryAccount = expenseEntry.account.name;
        } else if (arPaymentEntry) {
          type = TransactionType.REVENUE;
          amount = Number(arPaymentEntry.credit_amount);
          categoryAccount = arPaymentEntry.account.name;
        } else if (apPaymentEntry) {
          type = TransactionType.EXPENSE;
          amount = Number(apPaymentEntry.debit_amount);
          categoryAccount = apPaymentEntry.account.name;
        } else {
          return null;
        }

        // Apply type filter if provided
        if (filters?.type && filters.type !== type) return null;

        return {
          id: t.id,
          type,
          amount,
          description: t.description,
          transaction_date: t.transaction_date,
          category_account: categoryAccount,
        };
      })
      .filter((t) => t !== null);

    return {
      code: 200,
      status: 'success',
      message: 'Transactions fetched successfully.',
      data: formattedTransactions,
    };
  }

  async getTransaction(user: User, transactionId: string) {
    if (!user.default_account_id) {
      throw new BadRequestException({
        code: 400,
        status: 'error',
        message: 'No valid default account found.',
      });
    }

    const transaction = await this.prisma.accountingTransaction.findUnique({
      where: { id: transactionId },
      include: {
        entries: {
          include: {
            account: true,
          },
        },
      },
    });

    if (!transaction) {
      throw new BadRequestException({
        code: 404,
        status: 'error',
        message: 'Transaction not found.',
      });
    }

    // Verify transaction belongs to user
    if (transaction.created_by !== user.id) {
      throw new BadRequestException({
        code: 403,
        status: 'error',
        message: 'Access denied.',
      });
    }

    // Determine type
    const revenueEntry = transaction.entries.find((e) => e.account.account_type === 'Revenue' && e.credit_amount);
    const expenseEntry = transaction.entries.find((e) => e.account.account_type === 'Expense' && e.debit_amount);
    const arPaymentEntry = transaction.entries.find(
      (e) =>
        e.account.account_type === 'Asset' &&
        e.account.code?.startsWith('AR-') &&
        e.credit_amount,
    );
    const apPaymentEntry = transaction.entries.find(
      (e) =>
        e.account.account_type === 'Liability' &&
        e.account.code?.startsWith('AP-') &&
        e.debit_amount,
    );

    let type: TransactionType;
    let amount: number;
    let categoryAccount: string;

    if (revenueEntry) {
      type = TransactionType.REVENUE;
      amount = Number(revenueEntry.credit_amount);
      categoryAccount = revenueEntry.account.name;
    } else if (expenseEntry) {
      type = TransactionType.EXPENSE;
      amount = Number(expenseEntry.debit_amount);
      categoryAccount = expenseEntry.account.name;
    } else if (arPaymentEntry) {
      type = TransactionType.REVENUE;
      amount = Number(arPaymentEntry.credit_amount);
      categoryAccount = arPaymentEntry.account.name;
    } else if (apPaymentEntry) {
      type = TransactionType.EXPENSE;
      amount = Number(apPaymentEntry.debit_amount);
      categoryAccount = apPaymentEntry.account.name;
    } else {
      throw new BadRequestException({
        code: 400,
        status: 'error',
        message: 'Invalid transaction type.',
      });
    }

    return {
      code: 200,
      status: 'success',
      message: 'Transaction fetched successfully.',
      data: {
        id: transaction.id,
        type,
        amount,
        description: transaction.description,
        transaction_date: transaction.transaction_date,
        category_account: categoryAccount,
        cash_account: transaction.entries.find((e) => e.account.account_type === 'Asset')?.account.name,
        entries: transaction.entries.map((e) => ({
          account_name: e.account.name,
          account_type: e.account.account_type,
          debit_amount: e.debit_amount ? Number(e.debit_amount) : null,
          credit_amount: e.credit_amount ? Number(e.credit_amount) : null,
        })),
      },
    };
  }
}
