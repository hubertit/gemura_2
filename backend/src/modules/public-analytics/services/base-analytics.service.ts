import { Injectable, ForbiddenException, BadRequestException } from '@nestjs/common';
import { PrismaService } from '../../../prisma/prisma.service';
import { AnalyticsQueryDto, GroupByPeriod, AnalyticsResponseMeta } from '../dto/analytics-query.dto';
import { ApiKey, Account } from '@prisma/client';

export interface AnalyticsContext {
  accountIds: string[];
  isPlatformWide: boolean;
  startDate: Date;
  endDate: Date;
  groupBy: GroupByPeriod;
  page: number;
  limit: number;
}

@Injectable()
export class BaseAnalyticsService {
  constructor(protected prisma: PrismaService) {}

  /**
   * Resolve account IDs based on API key scope and query parameters
   */
  async resolveAccountContext(
    apiKey: ApiKey & { account?: Account | null },
    query: AnalyticsQueryDto,
  ): Promise<AnalyticsContext> {
    const isPlatformWide = !apiKey.account_id;
    let accountIds: string[] = [];

    if (isPlatformWide) {
      // Platform-wide API key can query any accounts
      if (query.account_ids && query.account_ids.length > 0) {
        accountIds = query.account_ids;
      } else if (query.account_id) {
        accountIds = [query.account_id];
      }
      // Empty accountIds means query all accounts
    } else {
      // Account-scoped API key can only query its own account
      if (query.account_id && query.account_id !== apiKey.account_id) {
        throw new ForbiddenException({
          code: 403,
          status: 'error',
          message: 'API key does not have access to the specified account.',
        });
      }
      if (query.account_ids && query.account_ids.length > 0) {
        const hasUnauthorized = query.account_ids.some((id) => id !== apiKey.account_id);
        if (hasUnauthorized) {
          throw new ForbiddenException({
            code: 403,
            status: 'error',
            message: 'API key does not have access to one or more specified accounts.',
          });
        }
      }
      accountIds = [apiKey.account_id!];
    }

    // Parse dates with defaults
    const now = new Date();
    const startDate = query.start_date
      ? new Date(query.start_date)
      : new Date(now.getFullYear(), 0, 1); // Default: start of current year
    const endDate = query.end_date
      ? new Date(query.end_date + 'T23:59:59.999Z')
      : new Date(now.getFullYear(), 11, 31, 23, 59, 59, 999); // Default: end of current year

    if (startDate > endDate) {
      throw new BadRequestException({
        code: 400,
        status: 'error',
        message: 'start_date must be before or equal to end_date.',
      });
    }

    return {
      accountIds,
      isPlatformWide,
      startDate,
      endDate,
      groupBy: query.group_by || GroupByPeriod.MONTH,
      page: query.page || 1,
      limit: query.limit || 100,
    };
  }

  /**
   * Build response metadata
   */
  buildMeta(
    context: AnalyticsContext,
    account?: Account | null,
    total?: number,
  ): AnalyticsResponseMeta {
    return {
      account_id: context.accountIds.length === 1 ? context.accountIds[0] : null,
      account_name: account?.name,
      start_date: context.startDate.toISOString().split('T')[0],
      end_date: context.endDate.toISOString().split('T')[0],
      generated_at: new Date().toISOString(),
      api_version: 'v1',
      page: context.page,
      limit: context.limit,
      total,
    };
  }

  /**
   * Get date grouping SQL expression based on group_by parameter
   */
  getDateGroupExpression(dateField: string, groupBy: GroupByPeriod): string {
    switch (groupBy) {
      case GroupByPeriod.DAY:
        return `DATE(${dateField})`;
      case GroupByPeriod.WEEK:
        return `DATE_TRUNC('week', ${dateField})::DATE`;
      case GroupByPeriod.MONTH:
        return `DATE_TRUNC('month', ${dateField})::DATE`;
      case GroupByPeriod.QUARTER:
        return `DATE_TRUNC('quarter', ${dateField})::DATE`;
      case GroupByPeriod.YEAR:
        return `DATE_TRUNC('year', ${dateField})::DATE`;
      default:
        return `DATE_TRUNC('month', ${dateField})::DATE`;
    }
  }

  /**
   * Calculate percentage change between two values
   */
  calculatePercentageChange(current: number, previous: number): number {
    if (previous === 0) {
      return current > 0 ? 100 : 0;
    }
    return Number((((current - previous) / previous) * 100).toFixed(2));
  }

  /**
   * Get the previous period dates based on current period
   */
  getPreviousPeriodDates(startDate: Date, endDate: Date): { start: Date; end: Date } {
    const duration = endDate.getTime() - startDate.getTime();
    const previousEnd = new Date(startDate.getTime() - 1);
    const previousStart = new Date(previousEnd.getTime() - duration);
    return { start: previousStart, end: previousEnd };
  }

  /**
   * Format decimal values from Prisma
   */
  formatDecimal(value: any): number {
    if (value === null || value === undefined) return 0;
    return Number(value);
  }

  /**
   * Build account filter for queries
   */
  buildAccountFilter(context: AnalyticsContext, accountField: string): any {
    if (context.accountIds.length === 0) {
      return {}; // No filter for platform-wide
    }
    if (context.accountIds.length === 1) {
      return { [accountField]: context.accountIds[0] };
    }
    return { [accountField]: { in: context.accountIds } };
  }
}
