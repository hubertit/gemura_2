import { Injectable, BadRequestException, InternalServerErrorException, NotFoundException } from '@nestjs/common';
import { PrismaService } from '../../prisma/prisma.service';
import { User } from '@prisma/client';
import { CreateSupplierDto } from './dto/create-supplier.dto';
import { UpdateSupplierDto } from './dto/update-supplier.dto';
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

    // Normalize phone (remove non-digits) - Phone is the primary identifier
    const normalizedPhone = phone.replace(/\D/g, '');

    // Find existing user by phone (primary identifier)
    // Phone number is the unique identifier for users
    const existingUser = await this.prisma.user.findUnique({
      where: { phone: normalizedPhone },
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

    if (existingUser) {
      // User exists - use existing user
      supplierName = existingUser.name;

      if (existingUser.user_accounts.length > 0) {
        // User has active account - use existing account
        supplierAccountId = existingUser.user_accounts[0].account_id;
        supplierAccountCode = existingUser.user_accounts[0].account.code || '';
      } else {
        // User exists but has no active accounts - create account for existing user
        const accountCode = `A_${randomBytes(3).toString('hex').toUpperCase()}`;
        const walletCode = `W_${randomBytes(3).toString('hex').toUpperCase()}`;

        // Create account for existing user
        const newAccount = await this.prisma.account.create({
          data: {
            code: accountCode,
            name: existingUser.name || name,
            type: 'tenant',
            status: 'active',
            created_by: user.id,
          },
        });

        // Link existing user to new account
        await this.prisma.userAccount.create({
          data: {
            user_id: existingUser.id,
            account_id: newAccount.id,
            role: 'supplier',
            status: 'active',
            created_by: user.id,
          },
        });

        // Create wallet for the account
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
      }
    } else {
      // User doesn't exist - create new user + account + wallet
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

  async getAllSuppliers(user: User) {
    if (!user.default_account_id) {
      throw new BadRequestException({
        code: 400,
        status: 'error',
        message: 'No valid default account found. Please set a default account.',
      });
    }

    const customerAccountId = user.default_account_id;

    // Get all supplier relationships for this customer
    const relationships = await this.prisma.supplierCustomer.findMany({
      where: {
        customer_account_id: customerAccountId,
        relationship_status: 'active',
      },
      include: {
        supplier_account: {
          include: {
            user_accounts: {
              where: { status: 'active' },
              include: {
                user: {
                  select: {
                    id: true,
                    code: true,
                    name: true,
                    phone: true,
                    email: true,
                    nid: true,
                    address: true,
                    account_type: true,
                  },
                },
              },
              take: 1,
            },
          },
        },
      },
      orderBy: {
        created_at: 'desc',
      },
    });

    const suppliers = relationships.map((rel) => {
      const supplierUser = rel.supplier_account.user_accounts[0]?.user;
      return {
        relationship_id: rel.id,
        code: supplierUser?.code || '',
        name: supplierUser?.name || rel.supplier_account.name,
        phone: supplierUser?.phone || '',
        email: supplierUser?.email || null,
        nid: supplierUser?.nid || null,
        address: supplierUser?.address || null,
        account: {
          code: rel.supplier_account.code,
          name: rel.supplier_account.name,
        },
        price_per_liter: Number(rel.price_per_liter),
        average_supply_quantity: Number(rel.average_supply_quantity),
        relationship_status: rel.relationship_status,
        created_at: rel.created_at,
        updated_at: rel.updated_at,
      };
    });

    return {
      code: 200,
      status: 'success',
      message: 'Suppliers fetched successfully.',
      data: suppliers,
    };
  }

  async getSupplier(user: User, supplierAccountCode: string) {
    if (!user.default_account_id) {
      throw new BadRequestException({
        code: 400,
        status: 'error',
        message: 'No valid default account found. Please set a default account.',
      });
    }

    const customerAccountId = user.default_account_id;

    // Get supplier account by code
    const supplierAccount = await this.prisma.account.findUnique({
      where: { code: supplierAccountCode },
      include: {
        user_accounts: {
          where: { status: 'active' },
          include: {
            user: {
              select: {
                id: true,
                name: true,
                phone: true,
                email: true,
                nid: true,
                address: true,
                account_type: true,
              },
            },
          },
          take: 1,
        },
      },
    });

    if (!supplierAccount) {
      throw new BadRequestException({
        code: 404,
        status: 'error',
        message: 'Supplier account not found.',
      });
    }

    // Get supplier-customer relationship
    const relationship = await this.prisma.supplierCustomer.findFirst({
      where: {
        supplier_account_id: supplierAccount.id,
        customer_account_id: customerAccountId,
      },
      include: {
        supplier_account: true,
        customer_account: true,
      },
    });

    const supplierUser = supplierAccount.user_accounts[0]?.user;

    return {
      code: 200,
      status: 'success',
      message: 'Supplier fetched successfully.',
      data: {
        supplier: {
          account_id: supplierAccount.id,
          account_code: supplierAccount.code,
          name: supplierAccount.name,
          type: supplierAccount.type,
          status: supplierAccount.status,
          user: supplierUser ? {
            id: supplierUser.id,
            name: supplierUser.name,
            phone: supplierUser.phone,
            email: supplierUser.email,
            nid: supplierUser.nid,
            address: supplierUser.address,
            account_type: supplierUser.account_type,
          } : null,
          relationship: relationship ? {
            price_per_liter: Number(relationship.price_per_liter),
            average_supply_quantity: Number(relationship.average_supply_quantity),
            relationship_status: relationship.relationship_status,
            created_at: relationship.created_at,
            updated_at: relationship.updated_at,
          } : null,
        },
      },
    };
  }

  async updateSupplier(user: User, updateDto: UpdateSupplierDto) {
    if (!user.default_account_id) {
      throw new BadRequestException({
        code: 400,
        status: 'error',
        message: 'No valid default account found. Please set a default account.',
      });
    }

    const customerAccountId = user.default_account_id;

    // Get supplier account by code
    const supplierAccount = await this.prisma.account.findUnique({
      where: { code: updateDto.supplier_account_code },
    });

    if (!supplierAccount) {
      throw new BadRequestException({
        code: 404,
        status: 'error',
        message: 'Supplier account not found.',
      });
    }

    // Find existing relationship
    const relationship = await this.prisma.supplierCustomer.findFirst({
      where: {
        supplier_account_id: supplierAccount.id,
        customer_account_id: customerAccountId,
      },
    });

    if (!relationship) {
      throw new BadRequestException({
        code: 404,
        status: 'error',
        message: 'Supplier relationship not found.',
      });
    }

    // Build update data
    const updateData: any = {
      updated_by: user.id,
    };

    if (updateDto.price_per_liter !== undefined) {
      updateData.price_per_liter = updateDto.price_per_liter;
    }

    if (updateDto.relationship_status) {
      updateData.relationship_status = updateDto.relationship_status as any;
    }

    if (Object.keys(updateData).length === 1) {
      // Only updated_by, no actual fields to update
      throw new BadRequestException({
        code: 400,
        status: 'error',
        message: 'No fields to update.',
      });
    }

    const updatedRelationship = await this.prisma.supplierCustomer.update({
      where: { id: relationship.id },
      data: updateData,
      include: {
        supplier_account: true,
        customer_account: true,
      },
    });

    return {
      code: 200,
      status: 'success',
      message: 'Supplier updated successfully.',
      data: {
        supplier: {
          account_code: updatedRelationship.supplier_account.code,
          price_per_liter: Number(updatedRelationship.price_per_liter),
          relationship_status: updatedRelationship.relationship_status,
        },
      },
    };
  }

  async deleteSupplier(user: User, supplierAccountCode: string) {
    if (!user.default_account_id) {
      throw new BadRequestException({
        code: 400,
        status: 'error',
        message: 'No valid default account found. Please set a default account.',
      });
    }

    const customerAccountId = user.default_account_id;

    // Get supplier account by code
    const supplierAccount = await this.prisma.account.findUnique({
      where: { code: supplierAccountCode },
    });

    if (!supplierAccount) {
      throw new BadRequestException({
        code: 404,
        status: 'error',
        message: 'Supplier account not found.',
      });
    }

    // Find and delete relationship (soft delete by setting status to inactive)
    const relationship = await this.prisma.supplierCustomer.findFirst({
      where: {
        supplier_account_id: supplierAccount.id,
        customer_account_id: customerAccountId,
      },
    });

    if (!relationship) {
      throw new BadRequestException({
        code: 404,
        status: 'error',
        message: 'Supplier relationship not found.',
      });
    }

    // Set relationship status to inactive (soft delete)
    await this.prisma.supplierCustomer.update({
      where: { id: relationship.id },
      data: {
        relationship_status: 'inactive',
        updated_by: user.id,
      },
    });

    return {
      code: 200,
      status: 'success',
      message: 'Supplier relationship deleted successfully.',
    };
  }
}

