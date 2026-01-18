import { Controller, Post, UseGuards, HttpCode } from '@nestjs/common';
import { ApiTags, ApiOperation, ApiResponse, ApiBearerAuth, ApiUnauthorizedResponse } from '@nestjs/swagger';
import { StatsService } from './stats.service';
import { TokenGuard } from '../../common/guards/token.guard';
import { CurrentUser } from '../../common/decorators/user.decorator';
import { User } from '@prisma/client';

@ApiTags('Stats')
@Controller('stats')
@UseGuards(TokenGuard)
@ApiBearerAuth()
export class StatsController {
  constructor(private readonly statsService: StatsService) {}

  @Post('overview')
  @HttpCode(200)
  @ApiOperation({ summary: 'Get overview statistics' })
  @ApiResponse({ status: 200, description: 'Stats fetched successfully' })
  @ApiUnauthorizedResponse({ description: 'Unauthorized' })
  async getOverview(@CurrentUser() user: User) {
    return this.statsService.getOverview(user);
  }

  @Post()
  @HttpCode(200)
  @ApiOperation({ summary: 'Get general statistics' })
  @ApiResponse({ status: 200, description: 'Stats fetched successfully' })
  @ApiUnauthorizedResponse({ description: 'Unauthorized' })
  async getStats(@CurrentUser() user: User) {
    return this.statsService.getStats(user);
  }
}

