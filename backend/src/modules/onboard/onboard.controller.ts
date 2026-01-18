import { Controller, Post, Body, UseGuards } from '@nestjs/common';
import { ApiTags, ApiOperation, ApiResponse, ApiBearerAuth, ApiUnauthorizedResponse, ApiBadRequestResponse, ApiBody, ApiConflictResponse } from '@nestjs/swagger';
import { OnboardService } from './onboard.service';
import { TokenGuard } from '../../common/guards/token.guard';
import { CurrentUser } from '../../common/decorators/user.decorator';
import { User } from '@prisma/client';
import { CreateUserDto } from './dto/create-user.dto';

@ApiTags('Onboard')
@Controller('onboard')
@UseGuards(TokenGuard)
@ApiBearerAuth()
export class OnboardController {
  constructor(private readonly onboardService: OnboardService) {}

  @Post('create-user')
  @ApiOperation({
    summary: 'Onboard a new user',
    description: 'Create a new user account through the onboarding process. The onboarder (current user) will receive points for onboarding the new user.',
  })
  @ApiBody({
    type: CreateUserDto,
    description: 'New user details',
    examples: {
      minimalUser: {
        summary: 'Create user with minimal info',
        value: {
          name: 'John Doe',
          phone_number: '+250788123456',
          password: 'SecurePassword123!',
        },
      },
      fullUser: {
        summary: 'Create user with all fields',
        value: {
          name: 'Jane Smith',
          phone_number: '+250788654321',
          email: 'jane@example.com',
          location: 'Kigali, Rwanda',
          password: 'SecurePassword123!',
        },
      },
    },
  })
  @ApiResponse({
    status: 201,
    description: 'User onboarded successfully',
    example: {
      code: 201,
      status: 'success',
      message: 'User onboarded successfully.',
      data: {
        onboarded_user: {
          id: 'user-uuid',
          name: 'John Doe',
          phone_number: '+250788123456',
          email: 'user@example.com',
          location: 'Kigali, Rwanda',
          token: 'auth-token-here',
          created_at: '2025-01-04T10:00:00Z',
        },
        onboarder: {
          name: 'Onboarder Name',
          points_earned: 1,
        },
        onboarded_at: '2025-01-04T10:00:00Z',
      },
    },
  })
  @ApiBadRequestResponse({
    description: 'Invalid request data',
    example: {
      code: 400,
      status: 'error',
      message: 'Token, name, and phone_number are required.',
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
  @ApiConflictResponse({
    description: 'Phone number already exists',
    example: {
      code: 400,
      status: 'error',
      message: 'Phone number already exists.',
    },
  })
  async createUser(@CurrentUser() user: User, @Body() createUserDto: CreateUserDto) {
    return this.onboardService.createUser(user, createUserDto);
  }
}
