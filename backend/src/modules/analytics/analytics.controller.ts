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
  @ApiOperation({ summary: 'Get collection analytics' })
  @ApiResponse({ status: 200, description: 'Analytics fetched successfully' })
  @ApiUnauthorizedResponse({ description: 'Unauthorized' })
  async getCollectionAnalytics(@CurrentUser() user: User) {
    return this.analyticsService.getCollectionAnalytics(user);
  }

  @Get('customers')
  @ApiOperation({ summary: 'Get customer analytics' })
  @ApiResponse({ status: 200, description: 'Analytics fetched successfully' })
  @ApiUnauthorizedResponse({ description: 'Unauthorized' })
  async getCustomerAnalytics(@CurrentUser() user: User) {
    return this.analyticsService.getCustomerAnalytics(user);
  }

  @Get('metrics')
  @ApiOperation({ summary: 'Get general metrics' })
  @ApiResponse({ status: 200, description: 'Metrics fetched successfully' })
  @ApiUnauthorizedResponse({ description: 'Unauthorized' })
  async getMetrics(@CurrentUser() user: User) {
    return this.analyticsService.getMetrics(user);
  }
}

