import { Injectable, BadRequestException, NotFoundException, ConflictException } from '@nestjs/common';
import { PrismaService } from '../../prisma/prisma.service';
import { User } from '@prisma/client';
import { CreateWalletDto } from './dto/create-wallet.dto';
import { GetWalletDetailsDto } from './dto/get-wallet-details.dto';

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

    // Return empty array instead of throwing error when no wallets found
    // This allows the mobile app to handle empty state gracefully
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

  async createWallet(user: User, createWalletDto: CreateWalletDto) {
    if (!user.default_account_id) {
      throw new BadRequestException({
        code: 400,
        status: 'error',
        message: 'No valid default account found. Please set a default account.',
      });
    }

    // Check wallet limit (optional - can be configured)
    const existingWallets = await this.prisma.wallet.count({
      where: { account_id: user.default_account_id },
    });

    // Optional: Set a reasonable limit (e.g., 10 wallets per account)
    const MAX_WALLETS_PER_ACCOUNT = 10;
    if (existingWallets >= MAX_WALLETS_PER_ACCOUNT) {
      throw new BadRequestException({
        code: 400,
        status: 'error',
        message: `Maximum wallet limit (${MAX_WALLETS_PER_ACCOUNT}) reached for this account.`,
      });
    }

    // Generate wallet code with retry logic
    let walletCode: string;
    let attempts = 0;
    const MAX_ATTEMPTS = 5;

    do {
      walletCode = `W_${Date.now().toString(36).toUpperCase()}_${Math.random().toString(36).substring(2, 6).toUpperCase()}`;
      const existingWallet = await this.prisma.wallet.findUnique({
        where: { code: walletCode },
      });
      if (!existingWallet) break;
      attempts++;
    } while (attempts < MAX_ATTEMPTS);

    if (attempts >= MAX_ATTEMPTS) {
      throw new BadRequestException({
        code: 500,
        status: 'error',
        message: 'Failed to generate unique wallet code. Please try again.',
      });
    }

    return this.createWalletWithCode(user, createWalletDto, walletCode);
  }

  private async createWalletWithCode(user: User, createWalletDto: CreateWalletDto, walletCode: string) {
    // Check if this should be default wallet (first wallet for account)
    const existingWallets = await this.prisma.wallet.findMany({
      where: { account_id: user.default_account_id },
    });

    const isDefault = existingWallets.length === 0;

    // If setting as default, unset other default wallets
    if (isDefault) {
      await this.prisma.wallet.updateMany({
        where: {
          account_id: user.default_account_id,
          is_default: true,
        },
        data: { is_default: false },
      });
    }

    const wallet = await this.prisma.wallet.create({
      data: {
        account_id: user.default_account_id,
        code: walletCode,
        type: createWalletDto.type,
        is_joint: createWalletDto.is_joint || false,
        is_default: isDefault,
        balance: 0,
        currency: createWalletDto.currency || 'RWF',
        status: 'active',
        created_by: user.id,
      },
      include: {
        account: true,
      },
    });

    return {
      code: 200,
      status: 'success',
      message: 'Wallet created successfully.',
      data: {
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
      },
    };
  }

  async getWalletDetails(user: User, getWalletDetailsDto: GetWalletDetailsDto) {
    if (!user.default_account_id) {
      throw new BadRequestException({
        code: 400,
        status: 'error',
        message: 'No valid default account found. Please set a default account.',
      });
    }

    const wallet = await this.prisma.wallet.findFirst({
      where: {
        code: getWalletDetailsDto.wallet_code,
        account_id: user.default_account_id,
      },
      include: {
        account: true,
      },
    });

    if (!wallet) {
      throw new NotFoundException({
        code: 404,
        status: 'error',
        message: 'Wallet not found.',
      });
    }

    return {
      code: 200,
      status: 'success',
      message: 'Wallet details retrieved successfully.',
      data: {
        wallet_code: wallet.code,
        type: wallet.type,
        is_joint: wallet.is_joint,
        is_default: wallet.is_default,
        balance: Number(wallet.balance),
        currency: wallet.currency,
        status: wallet.status,
        created_at: wallet.created_at,
        updated_at: wallet.updated_at,
        account: {
          code: wallet.account.code,
          name: wallet.account.name,
          type: wallet.account.type,
        },
      },
    };
  }
}

