import { Controller, Post, Body, UseGuards, HttpCode } from '@nestjs/common';
import { ApiTags, ApiOperation, ApiResponse, ApiBearerAuth, ApiUnauthorizedResponse, ApiBadRequestResponse } from '@nestjs/swagger';
import { StatsService } from './stats.service';
import { TokenGuard } from '../../common/guards/token.guard';
import { CurrentUser } from '../../common/decorators/user.decorator';
import { User } from '@prisma/client';
import { GetOverviewDto } from './dto/get-overview.dto';

@ApiTags('Stats')
@Controller('stats')
@UseGuards(TokenGuard)
@ApiBearerAuth()
export class StatsController {
  constructor(private readonly statsService: StatsService) {}

  @Post('overview')
  @HttpCode(200)
  @ApiOperation({
    summary: 'Get overview statistics',
    description: 'Retrieve comprehensive overview statistics for the authenticated user\'s default account, including collections, sales, suppliers, customers, and daily breakdowns.',
  })
  @ApiResponse({
    status: 200,
    description: 'Overview statistics fetched successfully',
    example: {
      code: 200,
      status: 'success',
      message: 'Overview fetched successfully.',
      data: {
        collections: {
          total_quantity: 12500.5,
          total_count: 150,
          total_value: 4375175.0,
        },
        sales: {
          total_quantity: 8500.0,
          total_value: 3315000.0,
        },
        suppliers: {
          active: 25,
          inactive: 5,
          total: 30,
        },
        customers: {
          active: 45,
          inactive: 8,
          total: 53,
        },
        daily_breakdown: [
          {
            date: '2025-01-23',
            collections: { quantity: 200.0, value: 70000.0 },
            sales: { quantity: 150.0, value: 58500.0 },
          },
        ],
      },
    },
  })
  @ApiBadRequestResponse({
    description: 'No default account found',
    example: {
      code: 400,
      status: 'error',
      message: 'No valid default account found.',
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
  async getOverview(@CurrentUser() user: User, @Body() dto?: GetOverviewDto) {
    return this.statsService.getOverview(user, dto?.account_id, dto?.date_from, dto?.date_to);
  }

  @Post()
  @HttpCode(200)
  @ApiOperation({
    summary: 'Get general statistics',
    description: 'Retrieve general statistics for the authenticated user\'s default account, including collections, sales, and relationship counts.',
  })
  @ApiResponse({
    status: 200,
    description: 'Statistics fetched successfully',
    example: {
      code: 200,
      status: 'success',
      message: 'Stats fetched successfully.',
      data: {
        collections: {
          total: 150,
          total_quantity: 12500.5,
        },
        sales: {
          total: 120,
          total_quantity: 8500.0,
        },
        suppliers: 30,
        customers: 53,
      },
    },
  })
  @ApiBadRequestResponse({
    description: 'No default account found',
    example: {
      code: 400,
      status: 'error',
      message: 'No valid default account found.',
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
  async getStats(@CurrentUser() user: User) {
    return this.statsService.getStats(user);
  }
}

