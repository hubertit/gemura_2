import { Controller, Get, Post, Body, UseGuards } from '@nestjs/common';
import { ApiTags, ApiOperation, ApiResponse, ApiBearerAuth } from '@nestjs/swagger';
import { AccountsService } from './accounts.service';
import { TokenGuard } from '../../common/guards/token.guard';
import { CurrentUser } from '../../common/decorators/user.decorator';
import { User } from '@prisma/client';
import { SwitchAccountDto } from './dto/switch-account.dto';

@ApiTags('Accounts')
@Controller('accounts')
@UseGuards(TokenGuard)
@ApiBearerAuth()
export class AccountsController {
  constructor(private readonly accountsService: AccountsService) {}

  @Get()
  @ApiOperation({ summary: 'Get user accounts' })
  @ApiResponse({ status: 200, description: 'User accounts fetched successfully' })
  async getAccounts(@CurrentUser() user: User) {
    return this.accountsService.getUserAccounts(user);
  }

  @Get('list')
  @ApiOperation({ summary: 'List user accounts (alias for GET /accounts)' })
  @ApiResponse({ status: 200, description: 'User accounts fetched successfully' })
  async listAccounts(@CurrentUser() user: User) {
    return this.accountsService.getUserAccounts(user);
  }

  @Post('switch')
  @ApiOperation({ summary: 'Switch default account' })
  @ApiResponse({ status: 200, description: 'Default account switched successfully' })
  @ApiResponse({ status: 403, description: 'Access denied' })
  async switchAccount(@CurrentUser() user: User, @Body() switchDto: SwitchAccountDto) {
    return this.accountsService.switchAccount(user, switchDto);
  }
}

