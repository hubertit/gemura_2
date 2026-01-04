import { Controller, Get, UseGuards } from '@nestjs/common';
import { ApiTags, ApiOperation, ApiResponse, ApiBearerAuth } from '@nestjs/swagger';
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
  @ApiOperation({ summary: 'Get wallets for default account' })
  @ApiResponse({ status: 200, description: 'Wallets fetched successfully' })
  @ApiResponse({ status: 404, description: 'No wallets found' })
  async getWallets(@CurrentUser() user: User) {
    return this.walletsService.getWallets(user);
  }
}

