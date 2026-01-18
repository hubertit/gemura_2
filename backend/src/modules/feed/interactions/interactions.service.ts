import { Injectable, NotFoundException, BadRequestException } from '@nestjs/common';
import { PrismaService } from '../../../prisma/prisma.service';
import { CreateInteractionDto } from './dto/create-interaction.dto';

@Injectable()
export class InteractionsService {
  constructor(private prisma: PrismaService) {}

  async create(userId: string, createInteractionDto: CreateInteractionDto) {
    // Check if interaction already exists
    const existing = await this.prisma.feedInteraction.findFirst({
      where: {
        user_id: userId,
        post_id: createInteractionDto.post_id || null,
        story_id: createInteractionDto.story_id || null,
        interaction_type: createInteractionDto.interaction_type,
      },
    });

    if (existing) {
      // Remove existing interaction (toggle off)
      await this.prisma.feedInteraction.delete({
        where: { id: existing.id },
      });

      // Update counts
      await this.updateCounts(createInteractionDto, -1);

      return { message: 'Interaction removed', removed: true };
    }

    // Create new interaction
    const interaction = await this.prisma.feedInteraction.create({
      data: {
        user_id: userId,
        post_id: createInteractionDto.post_id,
        story_id: createInteractionDto.story_id,
        interaction_type: createInteractionDto.interaction_type,
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
        story: {
          select: {
            id: true,
            content: true,
          },
        },
      },
    });

    // Update counts
    await this.updateCounts(createInteractionDto, 1);

    return interaction;
  }

  private async updateCounts(dto: CreateInteractionDto, increment: number) {
    if (dto.post_id) {
      const updateData: any = {};
      if (dto.interaction_type === 'like') {
        updateData.likes_count = { increment };
      } else if (dto.interaction_type === 'share') {
        updateData.shares_count = { increment };
      } else if (dto.interaction_type === 'bookmark') {
        updateData.bookmarks_count = { increment };
      }

      if (Object.keys(updateData).length > 0) {
        await this.prisma.feedPost.update({
          where: { id: dto.post_id },
          data: updateData,
        });
      }
    }
  }

  async findAll(
    postId?: string,
    storyId?: string,
    limit: number = 50,
    offset: number = 0,
  ) {
    const where: any = {};
    if (postId) where.post_id = postId;
    if (storyId) where.story_id = storyId;

    return this.prisma.feedInteraction.findMany({
      where,
      take: limit,
      skip: offset,
      orderBy: { created_at: 'desc' },
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

  async getMyInteractions(userId: string, type?: string) {
    const where: any = { user_id: userId };
    if (type) {
      where.interaction_type = type;
    }

    return this.prisma.feedInteraction.findMany({
      where,
      orderBy: { created_at: 'desc' },
      include: {
        post: {
          select: {
            id: true,
            content: true,
            media_url: true,
          },
        },
        story: {
          select: {
            id: true,
            content: true,
            media_url: true,
          },
        },
      },
    });
  }
}

