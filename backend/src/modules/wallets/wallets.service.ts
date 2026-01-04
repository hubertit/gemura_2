import { Injectable, BadRequestException, NotFoundException } from '@nestjs/common';
import { PrismaService } from '../../prisma/prisma.service';
import { User } from '@prisma/client';

@Injectable()
export class WalletsService {
  constructor(private prisma: PrismaService) {}

  async getWallets(user: User) {
    if (!user.default_account_id) {
      throw new BadRequestException({
        code: 400,
        status: 'error',
        message: 'No valid default account found. Please set a default account.',
      });
    }

    const wallets = await this.prisma.wallet.findMany({
      where: {
        account_id: user.default_account_id,
      },
      include: {
        account: true,
      },
    });

    if (wallets.length === 0) {
      throw new NotFoundException({
        code: 404,
        status: 'error',
        message: 'No wallets found for this account.',
      });
    }

    const formattedWallets = wallets.map((wallet) => ({
      wallet_code: wallet.code,
      type: wallet.type,
      is_joint: wallet.is_joint,
      is_default: wallet.is_default,
      balance: Number(wallet.balance),
      currency: wallet.currency,
      status: wallet.status,
      account: {
        code: wallet.account.code,
        name: wallet.account.name,
        type: wallet.account.type,
      },
    }));

    return {
      code: 200,
      status: 'success',
      message: 'Wallets fetched successfully.',
      data: formattedWallets,
    };
  }
}

