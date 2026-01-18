import { Injectable } from '@nestjs/common';
import { PrismaService } from '../../prisma/prisma.service';
import { User } from '@prisma/client';

@Injectable()
export class PointsService {
  constructor(private prisma: PrismaService) {}

  async getPointsBalance(user: User) {
    // Get points breakdown by reason
    const pointsBreakdown = await this.prisma.userPoint.groupBy({
      by: ['reason'],
      where: { user_id: user.id },
      _sum: {
        points: true,
      },
      _count: {
        id: true,
      },
    });

    const breakdown = pointsBreakdown.map((item) => ({
      source: item.reason || 'general',
      points: item._sum.points || 0,
      activities: item._count.id || 0,
    }));

    // Get recent points activities
    const recentActivities = await this.prisma.userPoint.findMany({
      where: { user_id: user.id },
      take: 10,
      orderBy: { created_at: 'desc' },
      select: {
        points: true,
        reason: true,
        created_at: true,
      },
    });

    const activities = recentActivities.map((activity) => ({
      points: activity.points,
      source: activity.reason || 'general',
      description: activity.reason || 'Points earned',
      date: activity.created_at,
    }));

    // Get leaderboard position
    const usersWithMorePoints = await this.prisma.user.count({
      where: {
        total_points: {
          gt: user.total_points || 0,
        },
        status: 'active',
      },
    });

    const leaderboardPosition = usersWithMorePoints + 1;

    return {
      code: 200,
      status: 'success',
      message: 'Points balance retrieved successfully.',
      data: {
        user_info: {
          name: user.name,
          total_points: user.total_points || 0,
          available_points: user.available_points || 0,
          referral_count: user.referral_count || 0,
          onboarded_count: user.onboarded_count || 0,
          leaderboard_position: leaderboardPosition,
        },
        points_breakdown: breakdown,
        recent_activities: activities,
      },
    };
  }
}
