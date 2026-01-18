import { Injectable, NotFoundException, BadRequestException } from '@nestjs/common';
import { PrismaService } from '../../../prisma/prisma.service';
import { CreateCommentDto } from './dto/create-comment.dto';
import { UpdateCommentDto } from './dto/update-comment.dto';

@Injectable()
export class CommentsService {
  constructor(private prisma: PrismaService) {}

  async create(userId: string, createCommentDto: CreateCommentDto) {
    // Verify post exists
    const post = await this.prisma.feedPost.findUnique({
      where: { id: createCommentDto.post_id },
    });

    if (!post) {
      throw new NotFoundException('Post not found');
    }

    return this.prisma.feedComment.create({
      data: {
        post_id: createCommentDto.post_id,
        user_id: userId,
        content: createCommentDto.content,
      },
      include: {
        user: {
          select: {
            id: true,
            name: true,
          },
        },
        post: {
          select: {
            id: true,
            content: true,
          },
        },
      },
    });
  }

  async findAll(postId: string, limit: number = 50, offset: number = 0) {
    return this.prisma.feedComment.findMany({
      where: {
        post_id: postId,
      },
      take: limit,
      skip: offset,
      orderBy: { created_at: 'desc' },
      include: {
        user: {
          select: {
            id: true,
            name: true,
            email: true,
            phone: true,
          },
        },
      },
    });
  }

  async findOne(id: string) {
    const comment = await this.prisma.feedComment.findUnique({
      where: { id },
      include: {
        user: {
          select: {
            id: true,
            name: true,
            email: true,
            phone: true,
          },
        },
        post: {
          select: {
            id: true,
            content: true,
          },
        },
      },
    });

    if (!comment) {
      throw new NotFoundException('Comment not found');
    }

    return comment;
  }

  async update(id: string, userId: string, updateCommentDto: UpdateCommentDto) {
    const comment = await this.prisma.feedComment.findUnique({
      where: { id },
    });

    if (!comment) {
      throw new NotFoundException('Comment not found');
    }

    if (comment.user_id !== userId) {
      throw new BadRequestException('You can only update your own comments');
    }

    return this.prisma.feedComment.update({
      where: { id },
      data: updateCommentDto,
      include: {
        user: {
          select: {
            id: true,
            name: true,
          },
        },
      },
    });
  }

  async remove(id: string, userId: string) {
    const comment = await this.prisma.feedComment.findUnique({
      where: { id },
    });

    if (!comment) {
      throw new NotFoundException('Comment not found');
    }

    if (comment.user_id !== userId) {
      throw new BadRequestException('You can only delete your own comments');
    }

    return this.prisma.feedComment.delete({
      where: { id },
    });
  }

  async getReplies(userId: string, commentId: string, limit: number = 20, offset: number = 0) {
    try {
      // Check if parent comment exists
      const parentComment = await this.prisma.feedComment.findUnique({
        where: { id: commentId },
      });

      if (!parentComment) {
        throw new NotFoundException({
          code: 404,
          status: 'error',
          message: 'Parent comment not found.',
        });
      }

      // Get replies for the comment
      const replies = await this.prisma.feedComment.findMany({
        where: {
          parent_comment_id: commentId,
        },
        take: limit,
        skip: offset,
        orderBy: { created_at: 'asc' },
        include: {
          user: {
            select: {
              id: true,
              name: true,
              email: true,
              phone: true,
              account_type: true,
              kyc_status: true,
            },
          },
        },
      });

    // Check which replies the user has liked
    const likedIds = new Set<string>();

    const formattedReplies = replies.map((reply) => ({
      id: reply.id,
      post_id: reply.post_id,
      user_id: reply.user_id,
      user_name: reply.user.name,
      user_avatar: null,
      account_type: reply.user.account_type,
      kyc_status: reply.user.kyc_status,
      content: reply.content,
      parent_comment_id: reply.parent_comment_id,
      likes_count: reply.likes_count || 0,
      is_liked: likedIds.has(reply.id),
      status: reply.status,
      created_at: reply.created_at,
      updated_at: reply.updated_at,
    }));

      return {
        code: 200,
        status: 'success',
        message: 'Comment replies fetched successfully.',
        data: formattedReplies,
      };
    } catch (error) {
      // Handle Prisma errors (e.g., column doesn't exist)
      if (error.code === 'P2022' || error.message?.includes('does not exist')) {
        throw new BadRequestException({
          code: 400,
          status: 'error',
          message: 'Database schema error. Please contact support.',
        });
      }
      // Re-throw known exceptions
      if (error instanceof NotFoundException) {
        throw error;
      }
      // Handle other errors
      throw new BadRequestException({
        code: 400,
        status: 'error',
        message: 'Failed to fetch comment replies.',
      });
    }
  }
}

