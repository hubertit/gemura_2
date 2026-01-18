import { Injectable, NotFoundException } from '@nestjs/common';
import { PrismaService } from '../../../prisma/prisma.service';
import { CreateStoryDto } from './dto/create-story.dto';

@Injectable()
export class StoriesService {
  constructor(private prisma: PrismaService) {}

  async create(userId: string, createStoryDto: CreateStoryDto) {
    // Stories expire after 24 hours
    const expiresAt = new Date();
    expiresAt.setHours(expiresAt.getHours() + 24);

    return this.prisma.feedStory.create({
      data: {
        user_id: userId,
        media_url: createStoryDto.media_url,
        content: createStoryDto.content,
        expires_at: expiresAt,
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
    const now = new Date();
    
    return this.prisma.feedStory.findMany({
      where: {
        status: 'active',
        expires_at: {
          gt: now, // Only active stories that haven't expired
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
          },
        },
        _count: {
          select: {
            interactions: true,
          },
        },
      },
    });
  }

  async findOne(id: string) {
    const story = await this.prisma.feedStory.findUnique({
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
        interactions: {
          include: {
            user: {
              select: {
                id: true,
                name: true,
              },
            },
          },
        },
      },
    });

    if (!story) {
      throw new NotFoundException('Story not found');
    }

    // Increment views count
    await this.prisma.feedStory.update({
      where: { id },
      data: {
        views_count: {
          increment: 1,
        },
      },
    });

    return {
      ...story,
      views_count: story.views_count + 1,
    };
  }
}

