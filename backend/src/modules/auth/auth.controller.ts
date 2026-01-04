import { Controller, Post, Body, HttpCode, HttpStatus, Req } from '@nestjs/common';
import { ApiTags, ApiOperation, ApiResponse, ApiBody, ApiBadRequestResponse, ApiUnauthorizedResponse } from '@nestjs/swagger';
import { AuthService } from './auth.service';
import { LoginDto } from './dto/login.dto';
import { AuthResponseDto } from './dto/auth-response.dto';

@ApiTags('Authentication')
@Controller('auth')
export class AuthController {
  constructor(private readonly authService: AuthService) {}

  @Post('login')
  @HttpCode(HttpStatus.OK)
  @ApiOperation({
    summary: 'User login',
    description: 'Authenticate user with email/phone and password. Returns user data, accounts, and authentication token.',
  })
  @ApiBody({
    type: LoginDto,
    description: 'User credentials',
    examples: {
      emailLogin: {
        summary: 'Login with email',
        value: {
          identifier: 'user@example.com',
          password: 'SecurePassword123!',
        },
      },
      phoneLogin: {
        summary: 'Login with phone',
        value: {
          identifier: '250788123456',
          password: 'SecurePassword123!',
        },
      },
    },
  })
  @ApiResponse({
    status: 200,
    description: 'Login successful. Returns user data, accounts, and authentication token.',
    type: AuthResponseDto,
    example: {
      code: 200,
      status: 'success',
      message: 'Login successful.',
      data: {
        user: {
          id: 'uuid-here',
          name: 'John Doe',
          email: 'user@example.com',
          phone: '250788123456',
          account_type: 'mcc',
          status: 'active',
          token: 'auth-token-here',
        },
        account: {
          id: 'account-uuid',
          code: 'ACC001',
          name: 'Main Account',
          type: 'tenant',
        },
        accounts: [],
        total_accounts: 1,
        profile_completion: 75,
      },
    },
  })
  @ApiBadRequestResponse({
    description: 'Invalid request - missing or invalid fields',
    example: {
      code: 400,
      status: 'error',
      message: 'Email/phone and password are required.',
    },
  })
  @ApiUnauthorizedResponse({
    description: 'Invalid credentials',
    example: {
      code: 401,
      status: 'error',
      message: 'Invalid credentials.',
    },
  })
  async login(
    @Body() loginDto: LoginDto,
    @Req() request: any,
  ): Promise<AuthResponseDto> {
    const ipAddress = request.ip || request.headers['x-forwarded-for'] || request.connection.remoteAddress;
    const userAgent = request.headers['user-agent'];

    return this.authService.login(loginDto, ipAddress, userAgent);
  }
}

