import { Injectable, BadRequestException, NotFoundException, InternalServerErrorException } from '@nestjs/common';
import { PrismaService } from '../../prisma/prisma.service';
import { User } from '@prisma/client';
import { CreateCollectionDto } from './dto/create-collection.dto';

@Injectable()
export class CollectionsService {
  constructor(private prisma: PrismaService) {}

  async createCollection(user: User, createDto: CreateCollectionDto) {
    const { supplier_account_code, quantity, status, collection_at, notes } = createDto;

    // Check if user has a valid default account
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
      where: { code: supplier_account_code },
    });

    if (!supplierAccount || supplierAccount.status !== 'active') {
      throw new NotFoundException({
        code: 404,
        status: 'error',
        message: 'Supplier account not found.',
      });
    }

    const supplierAccountId = supplierAccount.id;

    // Get unit price from supplier-customer relationship
    const relationship = await this.prisma.supplierCustomer.findFirst({
      where: {
        supplier_account_id: supplierAccountId,
        customer_account_id: customerAccountId,
        relationship_status: 'active',
      },
    });

    const unitPrice = relationship?.price_per_liter || 0;

    // Create milk sale (collection)
    try {
      const milkSale = await this.prisma.milkSale.create({
        data: {
          supplier_account_id: supplierAccountId,
          customer_account_id: customerAccountId,
          quantity: quantity,
          unit_price: unitPrice,
          status: status as any,
          sale_at: new Date(collection_at),
          notes: notes || null,
          recorded_by: user.id,
          created_by: user.id,
        },
      });

      return {
        code: 200,
        status: 'success',
        message: 'Milk collection recorded successfully.',
        data: {
          collection_id: milkSale.id,
          supplier_account_code: supplier_account_code,
          customer_account_id: customerAccountId,
          quantity: quantity,
          unit_price: unitPrice,
          total_amount: quantity * Number(unitPrice),
          status: status,
          collection_at: collection_at,
        },
      };
    } catch (error) {
      throw new InternalServerErrorException({
        code: 500,
        status: 'error',
        message: 'Failed to record milk collection.',
        error: error.message,
      });
    }
  }
}

