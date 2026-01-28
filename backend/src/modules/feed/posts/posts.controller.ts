import {
  Controller,
  Get,
  Post,
  Body,
  Patch,
  Param,
  Delete,
  Query,
  UseGuards,
} from '@nestjs/common';
import { ApiTags, ApiOperation, ApiResponse, ApiBearerAuth, ApiBody, ApiParam, ApiQuery, ApiBadRequestResponse, ApiUnauthorizedResponse, ApiNotFoundResponse } from '@nestjs/swagger';
import { PostsService } from './posts.service';
import { CreatePostDto } from './dto/create-post.dto';
import { UpdatePostDto } from './dto/update-post.dto';
import { TokenGuard } from '../../../common/guards/token.guard';
import { CurrentUser } from '../../../common/decorators/user.decorator';
import { User } from '@prisma/client';

@ApiTags('Feed Posts')
@ApiBearerAuth()
@Controller('feed/posts')
@UseGuards(TokenGuard)
export class PostsController {
  constructor(private readonly postsService: PostsService) {}

  @Post()
  @ApiOperation({
    summary: 'Create a new post',
    description: 'Create a new post in the feed. Posts can include text content, images, and other media.',
  })
  @ApiBody({
    type: CreatePostDto,
    description: 'Post creation data',
  })
  @ApiResponse({
    status: 201,
    description: 'Post created successfully',
    example: {
      code: 201,
      status: 'success',
      message: 'Post created successfully.',
      data: {
        id: 'cb9ad42f-12dc-401e-9ac9-05585b9b311e',
        content: 'Post content here',
        author_id: '550e8400-e29b-41d4-a716-446655440000',
        created_at: '2025-01-28T10:00:00Z',
      },
    },
  })
  @ApiBadRequestResponse({
    description: 'Invalid request data',
    example: {
      code: 400,
      status: 'error',
      message: 'Content is required.',
    },
  })
  @ApiUnauthorizedResponse({
    description: 'Unauthorized - invalid or missing token',
    example: {
      code: 401,
      status: 'error',
      message: 'Access denied. Token is required.',
    },
  })
  create(@CurrentUser() user: User, @Body() createPostDto: CreatePostDto) {
    return this.postsService.create(user.id, createPostDto);
  }

  @Get()
  @ApiOperation({
    summary: 'Get all posts',
    description: 'Retrieve a paginated list of all posts in the feed. Supports limit and offset for pagination.',
  })
  @ApiQuery({
    name: 'limit',
    required: false,
    type: Number,
    description: 'Number of posts to return (default: 20)',
    example: 20,
  })
  @ApiQuery({
    name: 'offset',
    required: false,
    type: Number,
    description: 'Number of posts to skip (default: 0)',
    example: 0,
  })
  @ApiResponse({
    status: 200,
    description: 'List of posts',
    example: {
      code: 200,
      status: 'success',
      message: 'Posts fetched successfully.',
      data: [],
    },
  })
  @ApiUnauthorizedResponse({
    description: 'Unauthorized - invalid or missing token',
    example: {
      code: 401,
      status: 'error',
      message: 'Access denied. Token is required.',
    },
  })
  async findAll(
    @CurrentUser() user: User,
    @Query('limit') limit?: string,
    @Query('offset') offset?: string,
  ) {
    try {
      const posts = await this.postsService.findAll(
        user.id,
        limit ? parseInt(limit) : 20,
        offset ? parseInt(offset) : 0,
      );
      
      return {
        code: 200,
        status: 'success',
        message: 'Posts fetched successfully.',
        data: posts,
      };
    } catch (error) {
      throw error;
    }
  }

  @Get(':id')
  @ApiOperation({
    summary: 'Get a post by ID',
    description: 'Retrieve detailed information about a specific post by its ID.',
  })
  @ApiParam({
    name: 'id',
    description: 'Post ID (UUID)',
    example: 'cb9ad42f-12dc-401e-9ac9-05585b9b311e',
  })
  @ApiResponse({
    status: 200,
    description: 'Post details',
    example: {
      code: 200,
      status: 'success',
      message: 'Post fetched successfully.',
      data: {
        id: 'cb9ad42f-12dc-401e-9ac9-05585b9b311e',
        content: 'Post content',
        author_id: '550e8400-e29b-41d4-a716-446655440000',
        created_at: '2025-01-28T10:00:00Z',
      },
    },
  })
  @ApiNotFoundResponse({
    description: 'Post not found',
    example: {
      code: 404,
      status: 'error',
      message: 'Post not found.',
    },
  })
  @ApiUnauthorizedResponse({
    description: 'Unauthorized - invalid or missing token',
    example: {
      code: 401,
      status: 'error',
      message: 'Access denied. Token is required.',
    },
  })
  findOne(@Param('id') id: string, @CurrentUser() user: User) {
    return this.postsService.findOne(id, user.id);
  }

  @Patch(':id')
  @ApiOperation({
    summary: 'Update a post',
    description: 'Update a post. Only the post author can update their own posts.',
  })
  @ApiParam({
    name: 'id',
    description: 'Post ID (UUID)',
    example: 'cb9ad42f-12dc-401e-9ac9-05585b9b311e',
  })
  @ApiBody({
    type: UpdatePostDto,
    description: 'Post update data',
  })
  @ApiResponse({
    status: 200,
    description: 'Post updated successfully',
    example: {
      code: 200,
      status: 'success',
      message: 'Post updated successfully.',
      data: {
        id: 'cb9ad42f-12dc-401e-9ac9-05585b9b311e',
        content: 'Updated content',
        updated_at: '2025-01-28T10:00:00Z',
      },
    },
  })
  @ApiBadRequestResponse({
    description: 'Invalid request or unauthorized',
    example: {
      code: 400,
      status: 'error',
      message: 'You can only update your own posts.',
    },
  })
  @ApiNotFoundResponse({
    description: 'Post not found',
    example: {
      code: 404,
      status: 'error',
      message: 'Post not found.',
    },
  })
  @ApiUnauthorizedResponse({
    description: 'Unauthorized - invalid or missing token',
    example: {
      code: 401,
      status: 'error',
      message: 'Access denied. Token is required.',
    },
  })
  update(
    @Param('id') id: string,
    @CurrentUser() user: User,
    @Body() updatePostDto: UpdatePostDto,
  ) {
    return this.postsService.update(id, user.id, updatePostDto);
  }

  @Delete(':id')
  @ApiOperation({
    summary: 'Delete a post',
    description: 'Delete a post permanently. Only the post author can delete their own posts.',
  })
  @ApiParam({
    name: 'id',
    description: 'Post ID (UUID)',
    example: 'cb9ad42f-12dc-401e-9ac9-05585b9b311e',
  })
  @ApiResponse({
    status: 200,
    description: 'Post deleted successfully',
    example: {
      code: 200,
      status: 'success',
      message: 'Post deleted successfully.',
    },
  })
  @ApiBadRequestResponse({
    description: 'Unauthorized - cannot delete other users\' posts',
    example: {
      code: 400,
      status: 'error',
      message: 'You can only delete your own posts.',
    },
  })
  @ApiNotFoundResponse({
    description: 'Post not found',
    example: {
      code: 404,
      status: 'error',
      message: 'Post not found.',
    },
  })
  @ApiUnauthorizedResponse({
    description: 'Unauthorized - invalid or missing token',
    example: {
      code: 401,
      status: 'error',
      message: 'Access denied. Token is required.',
    },
  })
  remove(@Param('id') id: string, @CurrentUser() user: User) {
    return this.postsService.remove(id, user.id);
  }
}

