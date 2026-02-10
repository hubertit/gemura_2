import { Injectable, BadRequestException } from '@nestjs/common';
import { PrismaService } from '../../../prisma/prisma.service';
import { User } from '@prisma/client';

@Injectable()
export class ReportsService {
  constructor(private prisma: PrismaService) {}

  async getBalanceSheet(user: User, asOfDate?: string) {
    const date = asOfDate ? new Date(asOfDate) : new Date();

    // Get all accounts with balances
    const accounts = await this.prisma.chartOfAccount.findMany({
      where: { is_active: true },
      include: {
        transactions: {
          where: {
            transaction: {
              transaction_date: { lte: date },
            },
          },
        },
      },
    });

    const assets = accounts.filter((a) => a.account_type === 'Asset');
    const liabilities = accounts.filter((a) => a.account_type === 'Liability');
    const equity = accounts.filter((a) => a.account_type === 'Equity');

    return {
      code: 200,
      status: 'success',
      message: 'Balance sheet generated successfully.',
      data: {
        as_of_date: date,
        assets: assets.map((a) => ({
          code: a.code,
          name: a.name,
          balance: 0, // Calculate from transactions
        })),
        liabilities: liabilities.map((l) => ({
          code: l.code,
          name: l.name,
          balance: 0,
        })),
        equity: equity.map((e) => ({
          code: e.code,
          name: e.name,
          balance: 0,
        })),
      },
    };
  }

  async getIncomeStatement(user: User, fromDate: string, toDate: string) {
    const from = new Date(fromDate);
    const to = new Date(toDate);

    // Scope to user's default account: only include transactions that use chart of accounts
    // belonging to this account (CASH-*, REV-*, EXP-* with account prefix, same as transactions module).
    let accountScopedChartIds: string[] = [];
    if (user.default_account_id) {
      const defaultAccount = await this.prisma.account.findUnique({
        where: { id: user.default_account_id },
      });
      if (defaultAccount) {
        const prefix = defaultAccount.code || defaultAccount.id.substring(0, 8).toUpperCase();
        const accountCharts = await this.prisma.chartOfAccount.findMany({
          where: {
            is_active: true,
            OR: [
              { code: { startsWith: `CASH-${prefix}` } },
              { code: { startsWith: `REV-${prefix}` } },
              { code: { startsWith: `EXP-${prefix}` } },
            ],
          },
          select: { id: true },
        });
        accountScopedChartIds = accountCharts.map((c) => c.id);
      }
    }

    // If no default account or no chart accounts for it, return zeros (do not show global totals).
    const transactions =
      accountScopedChartIds.length === 0
        ? []
        : await this.prisma.accountingTransaction.findMany({
            where: {
              transaction_date: { gte: from, lte: to },
              entries: {
                some: {
                  account_id: { in: accountScopedChartIds },
                },
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

    // Revenue: direct Revenue account credits + AR payment (DR Cash, CR AR) - money received
    const revenueFromAccounts = transactions
      .flatMap((t) => t.entries)
      .filter((e) => e.account.account_type === 'Revenue')
      .reduce((sum, e) => sum + (Number(e.credit_amount) || 0), 0);
    const revenueFromArPayments = transactions
      .flatMap((t) => t.entries)
      .filter(
        (e) =>
          e.account.account_type === 'Asset' &&
          e.account.code?.startsWith('AR-') &&
          e.credit_amount,
      )
      .reduce((sum, e) => sum + (Number(e.credit_amount) || 0), 0);
    const revenue = revenueFromAccounts + revenueFromArPayments;

    // Expenses: direct Expense account debits + AP payment (DR AP, CR Cash) - money paid
    const expensesFromAccounts = transactions
      .flatMap((t) => t.entries)
      .filter((e) => e.account.account_type === 'Expense')
      .reduce((sum, e) => sum + (Number(e.debit_amount) || 0), 0);
    const expensesFromApPayments = transactions
      .flatMap((t) => t.entries)
      .filter(
        (e) =>
          e.account.account_type === 'Liability' &&
          e.account.code?.startsWith('AP-') &&
          e.debit_amount,
      )
      .reduce((sum, e) => sum + (Number(e.debit_amount) || 0), 0);
    const expenses = expensesFromAccounts + expensesFromApPayments;

    return {
      code: 200,
      status: 'success',
      message: 'Income statement generated successfully.',
      data: {
        from_date: from,
        to_date: to,
        revenue,
        expenses,
        net_income: revenue - expenses,
      },
    };
  }

  async getTrialBalance(user: User, asOfDate?: string) {
    const date = asOfDate ? new Date(asOfDate) : new Date();

    const accounts = await this.prisma.chartOfAccount.findMany({
      where: { is_active: true },
      include: {
        transactions: {
          where: {
            transaction: {
              transaction_date: { lte: date },
            },
          },
        },
      },
    });

    return {
      code: 200,
      status: 'success',
      message: 'Trial balance generated successfully.',
      data: {
        as_of_date: date,
        accounts: accounts.map((a) => ({
          code: a.code,
          name: a.name,
          debit_balance: 0,
          credit_balance: 0,
        })),
      },
    };
  }

  /**
   * Revenue and expenses grouped by day for the date range (for charts).
   */
  async getRevenueExpensesOverTime(user: User, fromDate: string, toDate: string) {
    const from = new Date(fromDate);
    const to = new Date(toDate);
    to.setHours(23, 59, 59, 999);

    let accountScopedChartIds: string[] = [];
    if (user.default_account_id) {
      const defaultAccount = await this.prisma.account.findUnique({
        where: { id: user.default_account_id },
      });
      if (defaultAccount) {
        const prefix = defaultAccount.code || defaultAccount.id.substring(0, 8).toUpperCase();
        const accountCharts = await this.prisma.chartOfAccount.findMany({
          where: {
            is_active: true,
            OR: [
              { code: { startsWith: `CASH-${prefix}` } },
              { code: { startsWith: `REV-${prefix}` } },
              { code: { startsWith: `EXP-${prefix}` } },
            ],
          },
          select: { id: true, account_type: true, code: true },
        });
        accountScopedChartIds = accountCharts.map((c) => c.id);
      }
    }

    const transactions =
      accountScopedChartIds.length === 0
        ? []
        : await this.prisma.accountingTransaction.findMany({
            where: {
              transaction_date: { gte: from, lte: to },
              entries: {
                some: { account_id: { in: accountScopedChartIds } },
              },
            },
            include: {
              entries: {
                include: { account: true },
              },
            },
          });

    const byDate: Record<
      string,
      { revenue: number; expenses: number }
    > = {};
    for (const t of transactions) {
      const d = t.transaction_date.toISOString().slice(0, 10);
      if (!byDate[d]) byDate[d] = { revenue: 0, expenses: 0 };
      for (const e of t.entries) {
        if (!accountScopedChartIds.includes(e.account_id)) continue;
        const acc = e.account;
        if (acc.account_type === 'Revenue') {
          byDate[d].revenue += Number(e.credit_amount) || 0;
        } else if (acc.account_type === 'Asset' && acc.code?.startsWith('AR-') && e.credit_amount) {
          byDate[d].revenue += Number(e.credit_amount) || 0;
        } else if (acc.account_type === 'Expense') {
          byDate[d].expenses += Number(e.debit_amount) || 0;
        } else if (acc.account_type === 'Liability' && acc.code?.startsWith('AP-') && e.debit_amount) {
          byDate[d].expenses += Number(e.debit_amount) || 0;
        }
      }
    }
    const series = Object.entries(byDate)
      .map(([date, v]) => ({ date, revenue: v.revenue, expenses: v.expenses }))
      .sort((a, b) => a.date.localeCompare(b.date));

    return {
      code: 200,
      status: 'success',
      message: 'Revenue and expenses over time.',
      data: { series },
    };
  }

  /**
   * Expense grouped by category (chart of account name) for the date range.
   */
  async getExpenseByCategory(user: User, fromDate: string, toDate: string) {
    const from = new Date(fromDate);
    const to = new Date(toDate);
    to.setHours(23, 59, 59, 999);

    let accountScopedChartIds: string[] = [];
    if (user.default_account_id) {
      const defaultAccount = await this.prisma.account.findUnique({
        where: { id: user.default_account_id },
      });
      if (defaultAccount) {
        const prefix = defaultAccount.code || defaultAccount.id.substring(0, 8).toUpperCase();
        const accountCharts = await this.prisma.chartOfAccount.findMany({
          where: {
            is_active: true,
            account_type: 'Expense',
            code: { startsWith: `EXP-${prefix}` },
          },
          select: { id: true, name: true },
        });
        accountScopedChartIds = accountCharts.map((c) => c.id);
      }
    }

    const transactions =
      accountScopedChartIds.length === 0
        ? []
        : await this.prisma.accountingTransaction.findMany({
            where: {
              transaction_date: { gte: from, lte: to },
              entries: {
                some: {
                  account_id: { in: accountScopedChartIds },
                  debit_amount: { not: null },
                },
              },
            },
            include: {
              entries: {
                where: { account_id: { in: accountScopedChartIds } },
                include: { account: true },
              },
            },
          });

    const byCategory: Record<string, number> = {};
    for (const t of transactions) {
      for (const e of t.entries) {
        if (e.account.account_type !== 'Expense') continue;
        const name = e.account.name || 'Other';
        byCategory[name] = (byCategory[name] || 0) + (Number(e.debit_amount) || 0);
      }
    }
    const series = Object.entries(byCategory).map(([category_name, amount]) => ({
      category_name,
      amount,
    }));

    return {
      code: 200,
      status: 'success',
      message: 'Expense by category.',
      data: { series },
    };
  }
}

