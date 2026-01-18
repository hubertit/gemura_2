import { Injectable, BadRequestException, NotFoundException } from '@nestjs/common';
import { PrismaService } from '../../../prisma/prisma.service';
import { User } from '@prisma/client';
import { CreateChartAccountDto } from './dto/create-chart-account.dto';
import { UpdateChartAccountDto } from './dto/update-chart-account.dto';

@Injectable()
export class ChartOfAccountsService {
  constructor(private prisma: PrismaService) {}

  async createAccount(user: User, createDto: CreateChartAccountDto) {
    const account = await this.prisma.chartOfAccount.create({
      data: {
        code: createDto.code,
        name: createDto.name,
        account_type: createDto.account_type,
        parent_id: createDto.parent_id || null,
        is_active: true,
      },
    });

    return {
      code: 200,
      status: 'success',
      message: 'Chart of account created successfully.',
      data: account,
    };
  }

  async getAccounts(user: User) {
    const accounts = await this.prisma.chartOfAccount.findMany({
      where: { is_active: true },
      include: { children: true },
      orderBy: { code: 'asc' },
    });

    return {
      code: 200,
      status: 'success',
      message: 'Chart of accounts fetched successfully.',
      data: accounts,
    };
  }

  async getAccount(user: User, accountId: string) {
    const account = await this.prisma.chartOfAccount.findUnique({
      where: { id: accountId },
      include: { children: true, parent: true },
    });

    if (!account) {
      throw new NotFoundException({
        code: 404,
        status: 'error',
        message: 'Account not found.',
      });
    }

    return {
      code: 200,
      status: 'success',
      message: 'Account fetched successfully.',
      data: account,
    };
  }

  async updateAccount(user: User, accountId: string, updateDto: UpdateChartAccountDto) {
    const account = await this.prisma.chartOfAccount.findUnique({ where: { id: accountId } });
    if (!account) {
      throw new NotFoundException({
        code: 404,
        status: 'error',
        message: 'Account not found.',
      });
    }

    const updated = await this.prisma.chartOfAccount.update({
      where: { id: accountId },
      data: {
        name: updateDto.name || account.name,
        account_type: updateDto.account_type || account.account_type,
        is_active: updateDto.is_active !== undefined ? updateDto.is_active : account.is_active,
      },
    });

    return {
      code: 200,
      status: 'success',
      message: 'Account updated successfully.',
      data: updated,
    };
  }

  async deleteAccount(user: User, accountId: string) {
    const account = await this.prisma.chartOfAccount.findUnique({ where: { id: accountId } });
    if (!account) {
      throw new NotFoundException({
        code: 404,
        status: 'error',
        message: 'Account not found.',
      });
    }

    await this.prisma.chartOfAccount.update({
      where: { id: accountId },
      data: { is_active: false },
    });

    return {
      code: 200,
      status: 'success',
      message: 'Account deleted successfully.',
    };
  }
}

