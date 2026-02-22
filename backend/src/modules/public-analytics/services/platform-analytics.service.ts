import { Injectable } from '@nestjs/common';
import { PrismaService } from '../../../prisma/prisma.service';
import { BaseAnalyticsService, AnalyticsContext } from './base-analytics.service';

export interface PlatformSummary {
  total_accounts: number;
  active_accounts: number;
  total_users: number;
  active_users: number;
  verified_users: number;
  total_milk_volume: number;
  total_milk_value: number;
  total_transactions: number;
  total_suppliers: number;
  total_loans_outstanding: number;
  total_payroll_disbursed: number;
}

export interface PlatformBreakdown {
  date: string;
  new_accounts: number;
  new_users: number;
  milk_volume: number;
  milk_value: number;
  transaction_count: number;
}

export interface PlatformGrowth {
  account_growth_percent: number;
  user_growth_percent: number;
  transaction_growth_percent: number;
  volume_growth_percent: number;
  period: string;
}

export interface AccountOverview {
  account_id: string;
  account_code: string;
  account_name: string;
  account_type: string;
  status: string;
  user_count: number;
  supplier_count: number;
  customer_count: number;
  total_collections_volume: number;
  total_sales_volume: number;
  total_payroll_disbursed: number;
  created_at: string;
}

export interface GeographyDistribution {
  province: string;
  account_count: number;
  user_count: number;
  total_volume: number;
  total_value: number;
}

@Injectable()
export class PlatformAnalyticsService extends BaseAnalyticsService {
  constructor(prisma: PrismaService) {
    super(prisma);
  }

  /**
   * Get platform-wide summary
   */
  async getSummary(context: AnalyticsContext): Promise<PlatformSummary> {
    const [
      accountStats,
      userStats,
      kycStats,
      milkStats,
      supplierCount,
      loanStats,
      payrollStats,
    ] = await Promise.all([
      // Account stats
      this.prisma.account.aggregate({
        _count: { id: true },
      }),
      // User stats
      this.prisma.user.aggregate({
        _count: { id: true },
      }),
      // KYC verified users
      this.prisma.user.count({
        where: { kyc_status: 'verified' },
      }),
      // Milk transaction stats
      this.prisma.$queryRaw<{ total_volume: number; total_value: number; count: number }[]>`
        SELECT 
          COALESCE(SUM(quantity), 0) as total_volume,
          COALESCE(SUM(quantity * unit_price), 0) as total_value,
          COUNT(*) as count
        FROM milk_sales
        WHERE sale_at >= ${context.startDate}
          AND sale_at <= ${context.endDate}
          AND status != 'deleted'
      `,
      // Total supplier relationships
      this.prisma.supplierCustomer.count({
        where: { relationship_status: 'active' },
      }),
      // Loan stats
      this.prisma.loan.aggregate({
        where: { status: 'active' },
        _sum: { principal: true, amount_repaid: true },
      }),
      // Payroll stats
      this.prisma.payrollRun.aggregate({
        where: {
          run_date: {
            gte: context.startDate,
            lte: context.endDate,
          },
          status: 'processed',
        },
        _sum: { total_amount: true },
      }),
    ]);

    const activeAccounts = await this.prisma.account.count({
      where: { status: 'active' },
    });

    const activeUsers = await this.prisma.user.count({
      where: { status: 'active' },
    });

    const loanOutstanding = this.formatDecimal(loanStats._sum.principal) - this.formatDecimal(loanStats._sum.amount_repaid);

    return {
      total_accounts: accountStats._count.id || 0,
      active_accounts: activeAccounts,
      total_users: userStats._count.id || 0,
      active_users: activeUsers,
      verified_users: kycStats,
      total_milk_volume: this.formatDecimal(milkStats[0]?.total_volume || 0),
      total_milk_value: this.formatDecimal(milkStats[0]?.total_value || 0),
      total_transactions: Number(milkStats[0]?.count || 0),
      total_suppliers: supplierCount,
      total_loans_outstanding: loanOutstanding,
      total_payroll_disbursed: this.formatDecimal(payrollStats._sum.total_amount),
    };
  }

  /**
   * Get platform breakdown by time period
   */
  async getBreakdown(context: AnalyticsContext): Promise<PlatformBreakdown[]> {
    const accountDateGroupExpr = this.getDateGroupExpression('created_at', context.groupBy);
    const saleDateGroupExpr = this.getDateGroupExpression('sale_at', context.groupBy);

    // New accounts per period
    const accountsQuery = `
      SELECT 
        ${accountDateGroupExpr} as period_date,
        COUNT(*) as new_accounts
      FROM accounts
      WHERE created_at >= $1
        AND created_at <= $2
      GROUP BY ${accountDateGroupExpr}
      ORDER BY period_date ASC
    `;

    // New users per period
    const usersQuery = `
      SELECT 
        ${accountDateGroupExpr} as period_date,
        COUNT(*) as new_users
      FROM users
      WHERE created_at >= $1
        AND created_at <= $2
      GROUP BY ${accountDateGroupExpr}
      ORDER BY period_date ASC
    `;

    // Milk transactions per period
    const transactionsQuery = `
      SELECT 
        ${saleDateGroupExpr} as period_date,
        COALESCE(SUM(quantity), 0) as milk_volume,
        COALESCE(SUM(quantity * unit_price), 0) as milk_value,
        COUNT(*) as transaction_count
      FROM milk_sales
      WHERE sale_at >= $1
        AND sale_at <= $2
        AND status != 'deleted'
      GROUP BY ${saleDateGroupExpr}
      ORDER BY period_date ASC
    `;

    const [accountsResults, usersResults, transactionsResults] = await Promise.all([
      this.prisma.$queryRawUnsafe<any[]>(accountsQuery, context.startDate, context.endDate),
      this.prisma.$queryRawUnsafe<any[]>(usersQuery, context.startDate, context.endDate),
      this.prisma.$queryRawUnsafe<any[]>(transactionsQuery, context.startDate, context.endDate),
    ]);

    // Merge results
    const resultMap = new Map<string, PlatformBreakdown>();

    for (const row of transactionsResults) {
      const dateKey = row.period_date instanceof Date 
        ? row.period_date.toISOString().split('T')[0] 
        : String(row.period_date);
      resultMap.set(dateKey, {
        date: dateKey,
        new_accounts: 0,
        new_users: 0,
        milk_volume: this.formatDecimal(row.milk_volume),
        milk_value: this.formatDecimal(row.milk_value),
        transaction_count: Number(row.transaction_count),
      });
    }

    for (const row of accountsResults) {
      const dateKey = row.period_date instanceof Date 
        ? row.period_date.toISOString().split('T')[0] 
        : String(row.period_date);
      const existing = resultMap.get(dateKey);
      if (existing) {
        existing.new_accounts = Number(row.new_accounts);
      } else {
        resultMap.set(dateKey, {
          date: dateKey,
          new_accounts: Number(row.new_accounts),
          new_users: 0,
          milk_volume: 0,
          milk_value: 0,
          transaction_count: 0,
        });
      }
    }

    for (const row of usersResults) {
      const dateKey = row.period_date instanceof Date 
        ? row.period_date.toISOString().split('T')[0] 
        : String(row.period_date);
      const existing = resultMap.get(dateKey);
      if (existing) {
        existing.new_users = Number(row.new_users);
      } else {
        resultMap.set(dateKey, {
          date: dateKey,
          new_accounts: 0,
          new_users: Number(row.new_users),
          milk_volume: 0,
          milk_value: 0,
          transaction_count: 0,
        });
      }
    }

    return Array.from(resultMap.values()).sort((a, b) => a.date.localeCompare(b.date));
  }

  /**
   * Get growth metrics compared to previous period
   */
  async getGrowth(context: AnalyticsContext): Promise<PlatformGrowth> {
    const previousPeriod = this.getPreviousPeriodDates(context.startDate, context.endDate);

    const [currentSummary, previousSummary] = await Promise.all([
      this.getSummary(context),
      this.getSummary({
        ...context,
        startDate: previousPeriod.start,
        endDate: previousPeriod.end,
      }),
    ]);

    return {
      account_growth_percent: this.calculatePercentageChange(
        currentSummary.total_accounts,
        previousSummary.total_accounts,
      ),
      user_growth_percent: this.calculatePercentageChange(
        currentSummary.total_users,
        previousSummary.total_users,
      ),
      transaction_growth_percent: this.calculatePercentageChange(
        currentSummary.total_transactions,
        previousSummary.total_transactions,
      ),
      volume_growth_percent: this.calculatePercentageChange(
        currentSummary.total_milk_volume,
        previousSummary.total_milk_volume,
      ),
      period: 'period_over_period',
    };
  }

  /**
   * Get account overview list
   */
  async getAccountOverviews(context: AnalyticsContext): Promise<AccountOverview[]> {
    const accounts = await this.prisma.account.findMany({
      include: {
        user_accounts: {
          where: { status: 'active' },
        },
        suppliers: {
          where: { relationship_status: 'active' },
        },
        customers: {
          where: { relationship_status: 'active' },
        },
      },
      orderBy: { created_at: 'desc' },
      take: context.limit,
      skip: (context.page - 1) * context.limit,
    });

    const accountIds = accounts.map((a) => a.id);

    // Get collections and sales volumes
    const [collectionsData, salesData, payrollData] = await Promise.all([
      this.prisma.$queryRaw<{ customer_account_id: string; total_volume: number }[]>`
        SELECT 
          customer_account_id,
          COALESCE(SUM(quantity), 0) as total_volume
        FROM milk_sales
        WHERE customer_account_id = ANY(${accountIds}::uuid[])
          AND sale_at >= ${context.startDate}
          AND sale_at <= ${context.endDate}
          AND status != 'deleted'
        GROUP BY customer_account_id
      `,
      this.prisma.$queryRaw<{ supplier_account_id: string; total_volume: number }[]>`
        SELECT 
          supplier_account_id,
          COALESCE(SUM(quantity), 0) as total_volume
        FROM milk_sales
        WHERE supplier_account_id = ANY(${accountIds}::uuid[])
          AND sale_at >= ${context.startDate}
          AND sale_at <= ${context.endDate}
          AND status != 'deleted'
        GROUP BY supplier_account_id
      `,
      this.prisma.$queryRaw<{ account_id: string; total_amount: number }[]>`
        SELECT 
          account_id,
          COALESCE(SUM(total_amount), 0) as total_amount
        FROM payroll_runs
        WHERE account_id = ANY(${accountIds}::uuid[])
          AND run_date >= ${context.startDate}
          AND run_date <= ${context.endDate}
          AND status = 'processed'
        GROUP BY account_id
      `,
    ]);

    const collectionsMap = new Map(collectionsData.map((c) => [c.customer_account_id, this.formatDecimal(c.total_volume)]));
    const salesMap = new Map(salesData.map((s) => [s.supplier_account_id, this.formatDecimal(s.total_volume)]));
    const payrollMap = new Map(payrollData.map((p) => [p.account_id, this.formatDecimal(p.total_amount)]));

    return accounts.map((a) => ({
      account_id: a.id,
      account_code: a.code || '',
      account_name: a.name,
      account_type: a.type,
      status: a.status,
      user_count: a.user_accounts.length,
      supplier_count: a.customers.length,
      customer_count: a.suppliers.length,
      total_collections_volume: collectionsMap.get(a.id) || 0,
      total_sales_volume: salesMap.get(a.id) || 0,
      total_payroll_disbursed: payrollMap.get(a.id) || 0,
      created_at: a.created_at.toISOString().split('T')[0],
    }));
  }

  /**
   * Get geography distribution (based on user provinces)
   */
  async getGeographyDistribution(context: AnalyticsContext): Promise<GeographyDistribution[]> {
    const distribution = await this.prisma.$queryRaw<any[]>`
      SELECT 
        COALESCE(u.province, 'Unknown') as province,
        COUNT(DISTINCT a.id) as account_count,
        COUNT(DISTINCT u.id) as user_count
      FROM users u
      LEFT JOIN user_accounts ua ON ua.user_id = u.id AND ua.status = 'active'
      LEFT JOIN accounts a ON a.id = ua.account_id
      WHERE u.status = 'active'
      GROUP BY COALESCE(u.province, 'Unknown')
      ORDER BY user_count DESC
    `;

    // Get transaction volumes by province
    const volumeData = await this.prisma.$queryRaw<any[]>`
      SELECT 
        COALESCE(u.province, 'Unknown') as province,
        COALESCE(SUM(ms.quantity), 0) as total_volume,
        COALESCE(SUM(ms.quantity * ms.unit_price), 0) as total_value
      FROM milk_sales ms
      JOIN accounts a ON a.id = ms.customer_account_id
      JOIN user_accounts ua ON ua.account_id = a.id AND ua.status = 'active'
      JOIN users u ON u.id = ua.user_id
      WHERE ms.sale_at >= ${context.startDate}
        AND ms.sale_at <= ${context.endDate}
        AND ms.status != 'deleted'
      GROUP BY COALESCE(u.province, 'Unknown')
    `;

    const volumeMap = new Map(volumeData.map((v) => [v.province, {
      total_volume: this.formatDecimal(v.total_volume),
      total_value: this.formatDecimal(v.total_value),
    }]));

    return distribution.map((d) => {
      const volumes = volumeMap.get(d.province) || { total_volume: 0, total_value: 0 };
      return {
        province: d.province,
        account_count: Number(d.account_count),
        user_count: Number(d.user_count),
        total_volume: volumes.total_volume,
        total_value: volumes.total_value,
      };
    });
  }

  /**
   * Get total account count for pagination
   */
  async getTotalCount(): Promise<number> {
    return this.prisma.account.count();
  }
}
