import { Injectable, BadRequestException, InternalServerErrorException } from '@nestjs/common';
import { PrismaService } from '../../prisma/prisma.service';
import { User } from '@prisma/client';
import { CreateSupplierDto } from './dto/create-supplier.dto';
import * as bcrypt from 'bcrypt';
import { randomBytes } from 'crypto';

@Injectable()
export class SuppliersService {
  constructor(private prisma: PrismaService) {}

  async createOrUpdateSupplier(user: User, createDto: CreateSupplierDto) {
    const { name, phone, price_per_liter, email, nid, address } = createDto;

    // Check if user has a valid default account
    if (!user.default_account_id) {
      throw new BadRequestException({
        code: 400,
        status: 'error',
        message: 'No valid default account found. Please set a default account.',
      });
    }

    const customerAccountId = user.default_account_id;

    // Normalize phone (remove non-digits)
    const normalizedPhone = phone.replace(/\D/g, '');

    // Find existing supplier by phone, email, or nid
    const existingSupplier = await this.prisma.user.findFirst({
      where: {
        OR: [
          { phone: normalizedPhone },
          ...(email ? [{ email: email.toLowerCase() }] : []),
          ...(nid ? [{ nid }] : []),
        ],
      },
      include: {
        user_accounts: {
          where: { status: 'active' },
          include: { account: true },
          take: 1,
        },
      },
    });

    let supplierAccountId: string;
    let supplierAccountCode: string;
    let supplierName: string;

    if (existingSupplier && existingSupplier.user_accounts.length > 0) {
      // Use existing supplier account
      supplierAccountId = existingSupplier.user_accounts[0].account_id;
      supplierAccountCode = existingSupplier.user_accounts[0].account.code || '';
      supplierName = existingSupplier.name;
    } else {
      // Create new supplier (user + account + wallet)
      const userCode = `U_${randomBytes(3).toString('hex').toUpperCase()}`;
      const accountCode = `A_${randomBytes(3).toString('hex').toUpperCase()}`;
      const walletCode = `W_${randomBytes(3).toString('hex').toUpperCase()}`;
      const token = randomBytes(32).toString('hex');
      const passwordHash = await bcrypt.hash('default123', 10);

      // Create user
      const newUser = await this.prisma.user.create({
        data: {
          code: userCode,
          name,
          phone: normalizedPhone,
          email: email?.toLowerCase(),
          nid,
          address,
          password_hash: passwordHash,
          token,
          status: 'active',
          account_type: 'supplier',
          created_by: user.id,
        },
      });

      // Create account
      const newAccount = await this.prisma.account.create({
        data: {
          code: accountCode,
          name,
          type: 'tenant',
          status: 'active',
          created_by: user.id,
        },
      });

      // Link user to account
      await this.prisma.userAccount.create({
        data: {
          user_id: newUser.id,
          account_id: newAccount.id,
          role: 'supplier',
          status: 'active',
          created_by: user.id,
        },
      });

      // Create wallet
      await this.prisma.wallet.create({
        data: {
          code: walletCode,
          account_id: newAccount.id,
          type: 'regular',
          is_default: true,
          balance: 0,
          currency: 'RWF',
          status: 'active',
          created_by: user.id,
        },
      });

      supplierAccountId = newAccount.id;
      supplierAccountCode = accountCode;
      supplierName = name;
    }

    // Create or update supplier-customer relationship
    const existingRelationship = await this.prisma.supplierCustomer.findFirst({
      where: {
        supplier_account_id: supplierAccountId,
        customer_account_id: customerAccountId,
      },
    });

    if (existingRelationship) {
      // Update existing relationship
      await this.prisma.supplierCustomer.update({
        where: { id: existingRelationship.id },
        data: {
          price_per_liter: price_per_liter,
          relationship_status: 'active',
          updated_by: user.id,
        },
      });
    } else {
      // Create new relationship
      await this.prisma.supplierCustomer.create({
        data: {
          supplier_account_id: supplierAccountId,
          customer_account_id: customerAccountId,
          price_per_liter: price_per_liter,
          relationship_status: 'active',
          created_by: user.id,
        },
      });
    }

    return {
      code: 200,
      status: 'success',
      message: 'Supplier created/updated successfully.',
      data: {
        supplier: {
          account_id: supplierAccountId,
          account_code: supplierAccountCode,
          name: supplierName,
          phone: normalizedPhone,
          price_per_liter: price_per_liter,
        },
      },
    };
  }
}

