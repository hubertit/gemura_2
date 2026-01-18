import { Injectable, NotFoundException, BadRequestException } from '@nestjs/common';
import { PrismaService } from '../../../prisma/prisma.service';
import { CreatePostDto } from './dto/create-post.dto';
import { UpdatePostDto } from './dto/update-post.dto';

@Injectable()
export class PostsService {
  constructor(private prisma: PrismaService) {}

  async create(userId: string, createPostDto: CreatePostDto) {
    return this.prisma.feedPost.create({
      data: {
        user_id: userId,
        content: createPostDto.content,
        media_url: createPostDto.media_url,
        hashtags: createPostDto.hashtags,
        location: createPostDto.location,
        created_by: userId,
      },
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

  async findAll(userId: string, limit: number = 20, offset: number = 0) {
    const posts = await this.prisma.feedPost.findMany({
      where: {
        status: 'active',
        user: {
          status: 'active',
        },
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
            kyc_status: true,
            account_type: true,
          },
        },
        _count: {
          select: {
            comments: true,
            interactions: true,
          },
        },
        interactions: {
          where: {
            user_id: userId,
            interaction_type: 'like',
          },
          select: {
            id: true,
          },
        },
        bookmarks: {
          where: {
            user_id: userId,
          },
          select: {
            id: true,
          },
        },
      },
    });

    // Transform posts to match Flutter app expected format
    return posts.map((post) => {
      // Parse hashtags if it's a JSON string
      let hashtags = [];
      if (post.hashtags) {
        try {
          hashtags = JSON.parse(post.hashtags);
        } catch {
          // If not JSON, treat as comma-separated
          hashtags = post.hashtags.split(',').map((h) => h.trim()).filter((h) => h);
        }
      }

      return {
        id: post.id,
        user_id: post.user_id,
        user_name: post.user.name || 'Unknown User',
        user_avatar: null, // Profile picture field not available in User model
        account_type: post.user.account_type || null,
        kyc_status: post.user.kyc_status || null,
        content: post.content || '',
        media_url: post.media_url || null,
        hashtags: hashtags,
        location: post.location || null,
        likes_count: post.likes_count || 0,
        shares_count: post.shares_count || 0,
        bookmarks_count: post.bookmarks_count || 0,
        comments_count: (post as any)._count?.comments || 0,
        is_liked: ((post as any).interactions?.length || 0) > 0,
        is_bookmarked: ((post as any).bookmarks?.length || 0) > 0,
        status: post.status,
        created_at: post.created_at.toISOString(),
        updated_at: post.updated_at.toISOString(),
      };
    });
  }

  async findOne(id: string, userId?: string) {
    const post = await this.prisma.feedPost.findUnique({
      where: { id },
      include: {
        user: {
          select: {
            id: true,
            name: true,
            email: true,
            phone: true,
            kyc_status: true,
            account_type: true,
          },
        },
        _count: {
          select: {
            comments: true,
            interactions: true,
          },
        },
        interactions: userId ? {
          where: {
            user_id: userId,
            interaction_type: 'like',
          },
          select: {
            id: true,
          },
        } : false,
        bookmarks: userId ? {
          where: {
            user_id: userId,
          },
          select: {
            id: true,
          },
        } : false,
      },
    });

    if (!post) {
      throw new NotFoundException('Post not found');
    }

    // Transform post to match Flutter app expected format
    let hashtags = [];
    if (post.hashtags) {
      try {
        hashtags = JSON.parse(post.hashtags);
      } catch {
        hashtags = post.hashtags.split(',').map((h) => h.trim()).filter((h) => h);
      }
    }

    return {
      id: post.id,
      user_id: post.user_id,
      user_name: post.user.name || 'Unknown User',
      user_avatar: null, // Profile picture field not available in User model
      account_type: post.user.account_type || null,
      kyc_status: post.user.kyc_status || null,
      content: post.content || '',
      media_url: post.media_url || null,
      hashtags: hashtags,
      location: post.location || null,
      likes_count: post.likes_count || 0,
      shares_count: post.shares_count || 0,
      bookmarks_count: post.bookmarks_count || 0,
      comments_count: (post as any)._count?.comments || 0,
      is_liked: userId ? (((post as any).interactions as any)?.length || 0) > 0 : false,
      is_bookmarked: userId ? (((post as any).bookmarks as any)?.length || 0) > 0 : false,
      status: post.status,
      created_at: post.created_at.toISOString(),
      updated_at: post.updated_at.toISOString(),
    };
  }

  async update(id: string, userId: string, updatePostDto: UpdatePostDto) {
    const post = await this.prisma.feedPost.findUnique({
      where: { id },
    });

    if (!post) {
      throw new NotFoundException('Post not found');
    }

    if (post.user_id !== userId) {
      throw new BadRequestException('You can only update your own posts');
    }

    return this.prisma.feedPost.update({
      where: { id },
      data: {
        ...updatePostDto,
        updated_by: userId,
      },
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

  async remove(id: string, userId: string) {
    const post = await this.prisma.feedPost.findUnique({
      where: { id },
    });

    if (!post) {
      throw new NotFoundException('Post not found');
    }

    if (post.user_id !== userId) {
      throw new BadRequestException('You can only delete your own posts');
    }

    return this.prisma.feedPost.update({
      where: { id },
      data: {
        status: 'deleted',
        updated_by: userId,
      },
    });
  }
}

