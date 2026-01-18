import { Controller, Post, Body, UseGuards, HttpCode } from '@nestjs/common';
import { ApiTags, ApiOperation, ApiResponse, ApiBearerAuth, ApiUnauthorizedResponse, ApiBadRequestResponse, ApiNotFoundResponse, ApiBody } from '@nestjs/swagger';
import { RelationshipsService } from './relationships.service';
import { TokenGuard } from '../../../common/guards/token.guard';
import { CurrentUser } from '../../../common/decorators/user.decorator';
import { User } from '@prisma/client';
import { FollowUserDto } from './dto/follow-user.dto';

@ApiTags('Feed Relationships')
@Controller('feed/follow')
@UseGuards(TokenGuard)
@ApiBearerAuth()
export class RelationshipsController {
  constructor(private readonly relationshipsService: RelationshipsService) {}

  @Post()
  @HttpCode(200)
  @ApiOperation({
    summary: 'Follow or unfollow a user',
    description: 'Follow a user to see their posts in your feed. If already following, this will unfollow the user (toggle behavior).',
  })
  @ApiBody({
    type: FollowUserDto,
    description: 'User to follow',
    examples: {
      followUser: {
        summary: 'Follow a user',
        value: {
          user_id: 'user-uuid-to-follow',
        },
      },
    },
  })
  @ApiResponse({
    status: 200,
    description: 'User followed successfully',
    example: {
      code: 200,
      status: 'success',
      message: 'User followed successfully.',
      data: {
        following: true,
        follower_id: 'current-user-uuid',
        following_id: 'user-uuid-to-follow',
      },
    },
  })
  @ApiResponse({
    status: 200,
    description: 'User unfollowed successfully (if already following)',
    example: {
      code: 200,
      status: 'success',
      message: 'User unfollowed successfully.',
      data: {
        following: false,
        follower_id: 'current-user-uuid',
        following_id: 'user-uuid-to-follow',
      },
    },
  })
  @ApiBadRequestResponse({
    description: 'Cannot follow yourself',
    example: {
      code: 400,
      status: 'error',
      message: 'Cannot follow yourself.',
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
  @ApiNotFoundResponse({
    description: 'User to follow not found',
    example: {
      code: 404,
      status: 'error',
      message: 'User to follow not found.',
    },
  })
  async followUser(@CurrentUser() user: User, @Body() followUserDto: FollowUserDto) {
    return this.relationshipsService.followUser(user.id, followUserDto.user_id);
  }
}
