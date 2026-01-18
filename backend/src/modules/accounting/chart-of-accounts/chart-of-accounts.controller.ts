import { Controller, Post, Get, Put, Delete, Body, UseGuards, Param } from '@nestjs/common';
import { ApiTags, ApiOperation, ApiResponse, ApiBearerAuth, ApiBody, ApiParam } from '@nestjs/swagger';
import { ChartOfAccountsService } from './chart-of-accounts.service';
import { TokenGuard } from '../../../common/guards/token.guard';
import { CurrentUser } from '../../../common/decorators/user.decorator';
import { User } from '@prisma/client';
import { CreateChartAccountDto } from './dto/create-chart-account.dto';
import { UpdateChartAccountDto } from './dto/update-chart-account.dto';

@ApiTags('Accounting - Chart of Accounts')
@Controller('accounting/chart-of-accounts')
@UseGuards(TokenGuard)
@ApiBearerAuth()
export class ChartOfAccountsController {
  constructor(private readonly chartOfAccountsService: ChartOfAccountsService) {}

  @Post()
  @ApiOperation({ summary: 'Create chart of account' })
  @ApiBody({ type: CreateChartAccountDto })
  @ApiResponse({ status: 200, description: 'Account created successfully' })
  async createAccount(@CurrentUser() user: User, @Body() createDto: CreateChartAccountDto) {
    return this.chartOfAccountsService.createAccount(user, createDto);
  }

  @Get()
  @ApiOperation({ summary: 'List chart of accounts' })
  @ApiResponse({ status: 200, description: 'Accounts fetched successfully' })
  async getAccounts(@CurrentUser() user: User) {
    return this.chartOfAccountsService.getAccounts(user);
  }

  @Get(':id')
  @ApiOperation({ summary: 'Get chart of account' })
  @ApiParam({ name: 'id' })
  @ApiResponse({ status: 200, description: 'Account fetched successfully' })
  async getAccount(@CurrentUser() user: User, @Param('id') id: string) {
    return this.chartOfAccountsService.getAccount(user, id);
  }

  @Put(':id')
  @ApiOperation({ summary: 'Update chart of account' })
  @ApiParam({ name: 'id' })
  @ApiBody({ type: UpdateChartAccountDto })
  @ApiResponse({ status: 200, description: 'Account updated successfully' })
  async updateAccount(@CurrentUser() user: User, @Param('id') id: string, @Body() updateDto: UpdateChartAccountDto) {
    return this.chartOfAccountsService.updateAccount(user, id, updateDto);
  }

  @Delete(':id')
  @ApiOperation({ summary: 'Delete chart of account' })
  @ApiParam({ name: 'id' })
  @ApiResponse({ status: 200, description: 'Account deleted successfully' })
  async deleteAccount(@CurrentUser() user: User, @Param('id') id: string) {
    return this.chartOfAccountsService.deleteAccount(user, id);
  }
}

