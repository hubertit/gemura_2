import { Injectable, BadRequestException, NotFoundException, ConflictException } from '@nestjs/common';
import { PrismaService } from '../../../prisma/prisma.service';

@Injectable()
export class RelationshipsService {
  constructor(private prisma: PrismaService) {}

  async followUser(followerId: string, followingId: string) {
    // Prevent self-follow
    if (followerId === followingId) {
      throw new BadRequestException({
        code: 400,
        status: 'error',
        message: 'Cannot follow yourself.',
      });
    }

    // Check if user to follow exists and is active
    const userToFollow = await this.prisma.user.findUnique({
      where: { id: followingId },
    });

    if (!userToFollow) {
      throw new NotFoundException({
        code: 404,
        status: 'error',
        message: 'User to follow not found.',
      });
    }

    // Check if user is active
    if (userToFollow.status !== 'active') {
      throw new BadRequestException({
        code: 400,
        status: 'error',
        message: 'Cannot follow an inactive user.',
      });
    }

    // Check if relationship already exists
    const existingRelationship = await this.prisma.userRelationship.findUnique({
      where: {
        follower_id_following_id: {
          follower_id: followerId,
          following_id: followingId,
        },
      },
    });

    if (existingRelationship) {
      // Unfollow (remove relationship)
      await this.prisma.userRelationship.delete({
        where: {
          follower_id_following_id: {
            follower_id: followerId,
            following_id: followingId,
          },
        },
      });

      return {
        code: 200,
        status: 'success',
        message: 'User unfollowed successfully.',
        data: {
          following: false,
          follower_id: followerId,
          following_id: followingId,
        },
      };
    }

    // Create follow relationship
    await this.prisma.userRelationship.create({
      data: {
        follower_id: followerId,
        following_id: followingId,
      },
    });

    return {
      code: 200,
      status: 'success',
      message: 'User followed successfully.',
      data: {
        following: true,
        follower_id: followerId,
        following_id: followingId,
      },
    };
  }
}
