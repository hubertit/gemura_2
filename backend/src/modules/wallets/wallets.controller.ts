import { Controller, Get, UseGuards } from '@nestjs/common';
import { ApiTags, ApiOperation, ApiResponse, ApiBearerAuth, ApiUnauthorizedResponse, ApiBadRequestResponse, ApiNotFoundResponse } from '@nestjs/swagger';
import { WalletsService } from './wallets.service';
import { TokenGuard } from '../../common/guards/token.guard';
import { CurrentUser } from '../../common/decorators/user.decorator';
import { User } from '@prisma/client';

@ApiTags('Wallets')
@Controller('wallets')
@UseGuards(TokenGuard)
@ApiBearerAuth()
export class WalletsController {
  constructor(private readonly walletsService: WalletsService) {}

  @Get('get')
  @ApiOperation({
    summary: 'Get wallets for default account',
    description: 'Retrieve all wallets associated with the user\'s default account, including balance, currency, type, and status information.',
  })
  @ApiResponse({
    status: 200,
    description: 'Wallets fetched successfully',
    example: {
      code: 200,
      status: 'success',
      message: 'Wallets fetched successfully.',
      data: [
        {
          wallet_code: 'W_ABC123',
          type: 'regular',
          is_joint: false,
          is_default: true,
          balance: 150000.0,
          currency: 'RWF',
          status: 'active',
          account: {
            code: 'A_XYZ789',
            name: 'Main Account',
            type: 'tenant',
          },
        },
      ],
    },
  })
  @ApiBadRequestResponse({
    description: 'No default account found',
    example: {
      code: 400,
      status: 'error',
      message: 'No valid default account found. Please set a default account.',
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
    description: 'No wallets found for the account',
    example: {
      code: 404,
      status: 'error',
      message: 'No wallets found for this account.',
    },
  })
  async getWallets(@CurrentUser() user: User) {
    return this.walletsService.getWallets(user);
  }
}
