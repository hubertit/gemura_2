import { Controller, Get, UseGuards } from '@nestjs/common';
import { ApiTags, ApiOperation, ApiResponse, ApiBearerAuth, ApiUnauthorizedResponse } from '@nestjs/swagger';
import { AnalyticsService } from './analytics.service';
import { TokenGuard } from '../../common/guards/token.guard';
import { CurrentUser } from '../../common/decorators/user.decorator';
import { User } from '@prisma/client';

@ApiTags('Analytics')
@Controller('analytics')
@UseGuards(TokenGuard)
@ApiBearerAuth()
export class AnalyticsController {
  constructor(private readonly analyticsService: AnalyticsService) {}

  @Get('collections')
  @ApiOperation({
    summary: 'Get collection analytics',
    description: 'Retrieve analytics data for milk collections including total volume, trends, and statistics for the authenticated user\'s account.',
  })
  @ApiResponse({
    status: 200,
    description: 'Collection analytics fetched successfully',
    example: {
      code: 200,
      status: 'success',
      message: 'Analytics fetched successfully.',
      data: {
        total_collections: 150,
        total_volume: 12500.5,
        average_per_collection: 83.34,
        trends: [],
      },
    },
  })
  @ApiUnauthorizedResponse({
    description: 'Invalid or missing authentication token',
    example: {
      code: 401,
      status: 'error',
      message: 'Access denied. Token is required.',
    },
  })
  async getCollectionAnalytics(@CurrentUser() user: User) {
    return this.analyticsService.getCollectionAnalytics(user);
  }

  @Get('customers')
  @ApiOperation({
    summary: 'Get customer analytics',
    description: 'Retrieve analytics data for customers including customer count, active customers, and customer-related statistics.',
  })
  @ApiResponse({
    status: 200,
    description: 'Customer analytics fetched successfully',
    example: {
      code: 200,
      status: 'success',
      message: 'Analytics fetched successfully.',
      data: {
        total_customers: 45,
        active_customers: 38,
        new_customers: 5,
        trends: [],
      },
    },
  })
  @ApiUnauthorizedResponse({
    description: 'Invalid or missing authentication token',
    example: {
      code: 401,
      status: 'error',
      message: 'Access denied. Token is required.',
    },
  })
  async getCustomerAnalytics(@CurrentUser() user: User) {
    return this.analyticsService.getCustomerAnalytics(user);
  }

  @Get('metrics')
  @ApiOperation({
    summary: 'Get general metrics',
    description: 'Retrieve general business metrics including sales, collections, customers, and other key performance indicators.',
  })
  @ApiResponse({
    status: 200,
    description: 'Metrics fetched successfully',
    example: {
      code: 200,
      status: 'success',
      message: 'Metrics fetched successfully.',
      data: {
        total_sales: 2500000,
        total_collections: 150,
        total_customers: 45,
        revenue: 2000000,
      },
    },
  })
  @ApiUnauthorizedResponse({
    description: 'Invalid or missing authentication token',
    example: {
      code: 401,
      status: 'error',
      message: 'Access denied. Token is required.',
    },
  })
  async getMetrics(@CurrentUser() user: User) {
    return this.analyticsService.getMetrics(user);
  }
}

