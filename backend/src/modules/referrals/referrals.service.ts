import { Injectable, BadRequestException, NotFoundException, ConflictException } from '@nestjs/common';
import { PrismaService } from '../../prisma/prisma.service';
import { User } from '@prisma/client';
import { UseReferralCodeDto } from './dto/use-referral-code.dto';
import * as crypto from 'crypto';

@Injectable()
export class ReferralsService {
  constructor(private prisma: PrismaService) {}

  async getReferralCode(user: User) {
    // Generate referral code if user doesn't have one
    let referralCode = user.referral_code;

    if (!referralCode) {
      // Generate unique referral code
      referralCode = this.generateReferralCode(user.id);

      // Ensure code is unique
      let existingUser = await this.prisma.user.findUnique({
        where: { referral_code: referralCode },
      });

      let attempts = 0;
      while (existingUser && attempts < 10) {
        referralCode = this.generateReferralCode(user.id);
        existingUser = await this.prisma.user.findUnique({
          where: { referral_code: referralCode },
        });
        attempts++;
      }

      // Update user with referral code
      await this.prisma.user.update({
        where: { id: user.id },
        data: { referral_code: referralCode },
      });
    }

    // Get referral statistics
    const referralStats = await this.prisma.userReferral.aggregate({
      where: { referrer_id: user.id },
      _count: {
        id: true,
      },
    });

    const recentReferrals = await this.prisma.userReferral.count({
      where: {
        referrer_id: user.id,
        created_at: {
          gte: new Date(Date.now() - 30 * 24 * 60 * 60 * 1000), // Last 30 days
        },
      },
    });

    return {
      code: 200,
      status: 'success',
      message: 'Referral code retrieved successfully.',
      data: {
        user_id: user.id,
        user_name: user.name,
        referral_code: referralCode,
        total_referrals: referralStats._count.id || 0,
        recent_referrals: recentReferrals,
        total_points: user.total_points || 0,
        referral_url: `https://app.gemura.rw/register?ref=${referralCode}`,
      },
    };
  }

  async getReferralStats(user: User) {
    // Get referral statistics
    const totalReferrals = await this.prisma.userReferral.count({
      where: { referrer_id: user.id },
    });

    const now = new Date();
    const recentWeek = await this.prisma.userReferral.count({
      where: {
        referrer_id: user.id,
        created_at: {
          gte: new Date(now.getTime() - 7 * 24 * 60 * 60 * 1000),
        },
      },
    });

    const recentMonth = await this.prisma.userReferral.count({
      where: {
        referrer_id: user.id,
        created_at: {
          gte: new Date(now.getTime() - 30 * 24 * 60 * 60 * 1000),
        },
      },
    });

    const recentQuarter = await this.prisma.userReferral.count({
      where: {
        referrer_id: user.id,
        created_at: {
          gte: new Date(now.getTime() - 90 * 24 * 60 * 60 * 1000),
        },
      },
    });

    // Get recent referrals
    const recentReferralsList = await this.prisma.userReferral.findMany({
      where: { referrer_id: user.id },
      take: 10,
      orderBy: { created_at: 'desc' },
      include: {
        referred: {
          select: {
            id: true,
            name: true,
            phone: true,
          },
        },
      },
    });

    const recent_list = recentReferralsList.map((ref) => ({
      name: ref.referred.name,
      phone: ref.referred.phone,
      joined_at: ref.created_at,
      points_earned: 1, // Default points per referral
    }));

    // Get points history
    const pointsHistory = await this.prisma.userPoint.findMany({
      where: { user_id: user.id },
      take: 20,
      orderBy: { created_at: 'desc' },
      select: {
        points: true,
        reason: true,
        created_at: true,
      },
    });

    const points_list = pointsHistory.map((point) => ({
      points: point.points,
      source: point.reason || 'general',
      description: point.reason || 'Points earned',
      earned_at: point.created_at,
    }));

    return {
      code: 200,
      status: 'success',
      message: 'Referral statistics retrieved successfully.',
      data: {
        user_info: {
          name: user.name,
          referral_code: user.referral_code || 'Not generated',
          total_points: user.total_points || 0,
          available_points: user.available_points || 0,
        },
        statistics: {
          total_referrals: totalReferrals,
          recent_week: recentWeek,
          recent_month: recentMonth,
          recent_quarter: recentQuarter,
        },
        recent_referrals: recent_list,
        points_history: points_list,
      },
    };
  }

  async useReferralCode(user: User, useReferralCodeDto: UseReferralCodeDto) {
    // Normalize referral code (uppercase, trim)
    const normalizedCode = useReferralCodeDto.referral_code.trim().toUpperCase();

    // Check if user already has a referrer
    if (user.referred_by) {
      throw new BadRequestException({
        code: 400,
        status: 'error',
        message: 'User already has a referrer.',
      });
    }

    // Find the referrer by code
    const referrer = await this.prisma.user.findUnique({
      where: {
        referral_code: normalizedCode,
      },
    });

    if (!referrer) {
      throw new NotFoundException({
        code: 404,
        status: 'error',
        message: 'Invalid referral code.',
      });
    }

    // Check if referrer is active
    if (referrer.status !== 'active') {
      throw new BadRequestException({
        code: 400,
        status: 'error',
        message: 'Referral code belongs to an inactive user.',
      });
    }

    // Prevent self-referral
    if (referrer.id === user.id) {
      throw new BadRequestException({
        code: 400,
        status: 'error',
        message: 'Cannot use your own referral code.',
      });
    }

    // Check if referral relationship already exists
    const existingReferral = await this.prisma.userReferral.findFirst({
      where: {
        referrer_id: referrer.id,
        referred_id: user.id,
      },
    });

    if (existingReferral) {
      throw new ConflictException({
        code: 409,
        status: 'error',
        message: 'Referral relationship already exists.',
      });
    }

    // Start transaction
    return await this.prisma.$transaction(async (tx) => {
      // Update user's referred_by field (using legacy_id as integer reference)
      const referrerLegacyId = referrer.legacy_id ? parseInt(referrer.legacy_id.toString()) : null;
      if (referrerLegacyId) {
        await tx.user.update({
          where: { id: user.id },
          data: {
            referred_by: referrerLegacyId,
            registration_type: 'referred',
          },
        });
      }

      // Create referral record
      await tx.userReferral.create({
        data: {
          referrer_id: referrer.id,
          referred_id: user.id,
        },
      });

      // Award points to referrer
      await tx.userPoint.create({
        data: {
          user_id: referrer.id,
          points: 1,
          reason: `referral:${user.id}`,
        },
      });

      // Update referrer's stats
      await tx.user.update({
        where: { id: referrer.id },
        data: {
          referral_count: { increment: 1 },
          total_points: { increment: 1 },
          available_points: { increment: 1 },
        },
      });

      return {
        code: 200,
        status: 'success',
        message: 'Referral code applied successfully.',
        data: {
          referrer_name: referrer.name,
          referral_code: normalizedCode,
          points_awarded: 1,
          applied_at: new Date().toISOString(),
        },
      };
    });
  }

  private generateReferralCode(userId: string): string {
    const hash = crypto.createHash('md5').update(userId + Date.now().toString()).digest('hex');
    return hash.substring(0, 8).toUpperCase();
  }
}
