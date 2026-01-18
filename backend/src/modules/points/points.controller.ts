import { Controller, Get, UseGuards } from '@nestjs/common';
import { ApiTags, ApiOperation, ApiResponse, ApiBearerAuth, ApiUnauthorizedResponse } from '@nestjs/swagger';
import { PointsService } from './points.service';
import { TokenGuard } from '../../common/guards/token.guard';
import { CurrentUser } from '../../common/decorators/user.decorator';
import { User } from '@prisma/client';

@ApiTags('Points')
@Controller('points')
@UseGuards(TokenGuard)
@ApiBearerAuth()
export class PointsController {
  constructor(private readonly pointsService: PointsService) {}

  @Get('balance')
  @ApiOperation({
    summary: 'Get points balance',
    description: 'Retrieve the user\'s points balance including total points, available points, breakdown by source, recent activities, and leaderboard position.',
  })
  @ApiResponse({
    status: 200,
    description: 'Points balance retrieved successfully',
    example: {
      code: 200,
      status: 'success',
      message: 'Points balance retrieved successfully.',
      data: {
        user_info: {
          name: 'John Doe',
          total_points: 250,
          available_points: 200,
          referral_count: 15,
          onboarded_count: 8,
          leaderboard_position: 42,
        },
        points_breakdown: [
          {
            source: 'referral',
            points: 150,
            activities: 15,
          },
          {
            source: 'onboarding',
            points: 80,
            activities: 8,
          },
          {
            source: 'transaction',
            points: 20,
            activities: 5,
          },
        ],
        recent_activities: [
          {
            points: 1,
            source: 'referral',
            description: 'Referred user: Jane Smith',
            date: '2025-01-04T10:00:00Z',
          },
          {
            points: 1,
            source: 'onboarding',
            description: 'Onboarded user: Bob Johnson',
            date: '2025-01-03T14:30:00Z',
          },
        ],
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
  async getPointsBalance(@CurrentUser() user: User) {
    return this.pointsService.getPointsBalance(user);
  }
}
