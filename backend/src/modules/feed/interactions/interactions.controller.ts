import { Controller, Get, Post, Body, Query, UseGuards } from '@nestjs/common';
import { ApiTags, ApiOperation, ApiResponse, ApiBearerAuth } from '@nestjs/swagger';
import { InteractionsService } from './interactions.service';
import { CreateInteractionDto } from './dto/create-interaction.dto';
import { TokenGuard } from '../../../common/guards/token.guard';
import { CurrentUser } from '../../../common/decorators/user.decorator';
import { User } from '@prisma/client';

@ApiTags('Feed Interactions')
@ApiBearerAuth()
@Controller('feed/interactions')
@UseGuards(TokenGuard)
export class InteractionsController {
  constructor(private readonly interactionsService: InteractionsService) {}

  @Post()
  @ApiOperation({ summary: 'Create an interaction (like/share/bookmark)' })
  @ApiResponse({ status: 201, description: 'Interaction created successfully' })
  create(@CurrentUser() user: User, @Body() createInteractionDto: CreateInteractionDto) {
    return this.interactionsService.create(user.id, createInteractionDto);
  }

  @Get()
  @ApiOperation({ summary: 'Get interactions' })
  @ApiResponse({ status: 200, description: 'List of interactions' })
  findAll(
    @Query('post_id') postId?: string,
    @Query('story_id') storyId?: string,
    @Query('limit') limit?: string,
    @Query('offset') offset?: string,
  ) {
    return this.interactionsService.findAll(
      postId,
      storyId,
      limit ? parseInt(limit) : 50,
      offset ? parseInt(offset) : 0,
    );
  }

  @Get('my')
  @ApiOperation({ summary: 'Get my interactions' })
  @ApiResponse({ status: 200, description: 'List of my interactions' })
  getMyInteractions(
    @CurrentUser() user: User,
    @Query('type') type?: string,
  ) {
    return this.interactionsService.getMyInteractions(user.id, type);
  }
}

