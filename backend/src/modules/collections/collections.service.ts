import { Injectable, BadRequestException, NotFoundException, InternalServerErrorException } from '@nestjs/common';
import { PrismaService } from '../../prisma/prisma.service';
import { User } from '@prisma/client';
import { CreateCollectionDto } from './dto/create-collection.dto';
import { UpdateCollectionDto } from './dto/update-collection.dto';
import { CancelCollectionDto } from './dto/cancel-collection.dto';
import { TransactionsService } from '../accounting/transactions/transactions.service';
import { TransactionType } from '../accounting/transactions/dto/create-transaction.dto';

@Injectable()
export class CollectionsService {
  constructor(
    private prisma: PrismaService,
    private transactionsService: TransactionsService,
  ) {}

  async getRejectionReasons(includeInactive = false) {
    return this.prisma.milkRejectionReason.findMany({
      where: includeInactive ? {} : { is_active: true },
      orderBy: {
        sort_order: 'asc',
      },
      select: {
        id: true,
        name: true,
        description: true,
        is_active: true,
        sort_order: true,
        created_at: true,
        updated_at: true,
      },
    });
  }

  async getRejectionReasonById(id: string) {
    const reason = await this.prisma.milkRejectionReason.findUnique({
      where: { id },
      select: {
        id: true,
        name: true,
        description: true,
        is_active: true,
        sort_order: true,
        created_at: true,
        updated_at: true,
      },
    });

    if (!reason) {
      throw new NotFoundException({
        code: 404,
        status: 'error',
        message: 'Rejection reason not found',
      });
    }

    return reason;
  }

  async createRejectionReason(createDto: { name: string; description?: string; sort_order?: number }) {
    // Check if name already exists
    const existing = await this.prisma.milkRejectionReason.findUnique({
      where: { name: createDto.name },
    });

    if (existing) {
      throw new BadRequestException({
        code: 400,
        status: 'error',
        message: 'A rejection reason with this name already exists',
      });
    }

    // Get max sort_order if not provided
    let sortOrder = createDto.sort_order;
    if (sortOrder === undefined) {
      const maxOrder = await this.prisma.milkRejectionReason.findFirst({
        orderBy: { sort_order: 'desc' },
        select: { sort_order: true },
      });
      sortOrder = (maxOrder?.sort_order ?? 0) + 1;
    }

    return this.prisma.milkRejectionReason.create({
      data: {
        name: createDto.name,
        description: createDto.description,
        sort_order: sortOrder,
        is_active: true,
      },
      select: {
        id: true,
        name: true,
        description: true,
        is_active: true,
        sort_order: true,
        created_at: true,
        updated_at: true,
      },
    });
  }

  async updateRejectionReason(id: string, updateDto: { name?: string; description?: string; is_active?: boolean; sort_order?: number }) {
    // Check if reason exists
    await this.getRejectionReasonById(id);

    // If updating name, check if new name already exists
    if (updateDto.name) {
      const existing = await this.prisma.milkRejectionReason.findUnique({
        where: { name: updateDto.name },
      });

      if (existing && existing.id !== id) {
        throw new BadRequestException({
          code: 400,
          status: 'error',
          message: 'A rejection reason with this name already exists',
        });
      }
    }

    return this.prisma.milkRejectionReason.update({
      where: { id },
      data: updateDto,
      select: {
        id: true,
        name: true,
        description: true,
        is_active: true,
        sort_order: true,
        created_at: true,
        updated_at: true,
      },
    });
  }

  async deleteRejectionReason(id: string) {
    // Check if reason exists
    await this.getRejectionReasonById(id);

    // Soft delete by setting is_active to false
    return this.prisma.milkRejectionReason.update({
      where: { id },
      data: { is_active: false },
      select: {
        id: true,
        name: true,
        description: true,
        is_active: true,
        sort_order: true,
        created_at: true,
        updated_at: true,
      },
    });
  }

  async createCollection(user: User, createDto: CreateCollectionDto) {
    const { supplier_account_code, quantity, status, collection_at, notes, payment_status } = createDto;

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

      const totalAmount = quantity * Number(unitPrice);

      // If payment status is "paid", create an expense transaction in finance
      if (payment_status === 'paid' && totalAmount > 0) {
        try {
          await this.transactionsService.createTransaction(user, {
            type: TransactionType.EXPENSE,
            amount: totalAmount,
            description: `Milk collection from ${supplierAccount.name} - ${quantity}L @ ${unitPrice} Frw/L`,
            transaction_date: new Date(collection_at).toISOString().split('T')[0],
          });
        } catch (error) {
          // Log error but don't fail the collection creation
          console.error('Failed to create finance transaction for collection:', error);
        }
      }

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
          total_amount: totalAmount,
          status: status,
          collection_at: collection_at,
          payment_status: payment_status || 'unpaid',
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

  async getCollections(user: User, filters?: {
    supplier_account_code?: string;
    status?: string;
    date_from?: string;
    date_to?: string;
    quantity_min?: number;
    quantity_max?: number;
    price_min?: number;
    price_max?: number;
  }) {
    if (!user.default_account_id) {
      throw new BadRequestException({
        code: 400,
        status: 'error',
        message: 'No valid default account found. Please set a default account.',
      });
    }

    const customerAccountId = user.default_account_id;

    // Build query with filters
    const where: any = {
      customer_account_id: customerAccountId,
      status: { not: 'deleted' },
    };

    if (filters) {
      // Filter by supplier account code
      if (filters.supplier_account_code) {
        const supplierAccount = await this.prisma.account.findUnique({
          where: { code: filters.supplier_account_code },
        });
        if (supplierAccount) {
          where.supplier_account_id = supplierAccount.id;
        }
      }

      if (filters.status) {
        where.status = filters.status;
      }

      if (filters.date_from || filters.date_to) {
        where.sale_at = {};
        if (filters.date_from) {
          where.sale_at.gte = new Date(filters.date_from);
        }
        if (filters.date_to) {
          const dateTo = new Date(filters.date_to);
          dateTo.setHours(23, 59, 59, 999);
          where.sale_at.lte = dateTo;
        }
      }

      if (filters.quantity_min !== undefined || filters.quantity_max !== undefined) {
        where.quantity = {};
        if (filters.quantity_min !== undefined) {
          where.quantity.gte = filters.quantity_min;
        }
        if (filters.quantity_max !== undefined) {
          where.quantity.lte = filters.quantity_max;
        }
      }

      if (filters.price_min !== undefined || filters.price_max !== undefined) {
        where.unit_price = {};
        if (filters.price_min !== undefined) {
          where.unit_price.gte = filters.price_min;
        }
        if (filters.price_max !== undefined) {
          where.unit_price.lte = filters.price_max;
        }
      }
    }

    const collections = await this.prisma.milkSale.findMany({
      where,
      include: {
        supplier_account: true,
        customer_account: true,
        recorded_by_user: {
          select: {
            id: true,
            name: true,
            phone: true,
          },
        },
      },
      orderBy: {
        sale_at: 'desc',
      },
    });

    const formattedCollections = collections.map((collection) => ({
      id: collection.id,
      quantity: Number(collection.quantity),
      unit_price: Number(collection.unit_price),
      total_amount: Number(collection.quantity) * Number(collection.unit_price),
      status: collection.status,
      sale_at: collection.sale_at,
      collection_at: collection.sale_at,
      notes: collection.notes,
      created_at: collection.created_at,
      updated_at: collection.updated_at,
      supplier_account: {
        code: collection.supplier_account.code,
        name: collection.supplier_account.name,
        type: collection.supplier_account.type,
        status: collection.supplier_account.status,
      },
      customer_account: {
        code: collection.customer_account.code,
        name: collection.customer_account.name,
        type: collection.customer_account.type,
        status: collection.customer_account.status,
      },
      recorded_by: {
        id: collection.recorded_by_user.id,
        name: collection.recorded_by_user.name,
        phone: collection.recorded_by_user.phone,
      },
    }));

    return {
      code: 200,
      status: 'success',
      message: 'Collections fetched successfully.',
      data: formattedCollections,
    };
  }

  async getCollection(user: User, collectionId: string) {
    if (!user.default_account_id) {
      throw new BadRequestException({
        code: 400,
        status: 'error',
        message: 'No valid default account found. Please set a default account.',
      });
    }

    const customerAccountId = user.default_account_id;

    // Find collection (milk sale) where customer is the user's default account
    const collection = await this.prisma.milkSale.findFirst({
      where: {
        id: collectionId,
        customer_account_id: customerAccountId,
        status: { not: 'deleted' },
      },
      include: {
        supplier_account: true,
        customer_account: true,
        recorded_by_user: {
          select: {
            id: true,
            name: true,
            phone: true,
          },
        },
      },
    });

    if (!collection) {
      throw new NotFoundException({
        code: 404,
        status: 'error',
        message: 'Collection not found or not authorized.',
      });
    }

    return {
      code: 200,
      status: 'success',
      message: 'Collection fetched successfully.',
      data: {
        id: collection.id,
        quantity: Number(collection.quantity),
        unit_price: Number(collection.unit_price),
        total_amount: Number(collection.quantity) * Number(collection.unit_price),
        status: collection.status,
        collection_at: collection.sale_at,
        notes: collection.notes,
        created_at: collection.created_at,
        updated_at: collection.updated_at,
        supplier_account: {
          code: collection.supplier_account.code,
          name: collection.supplier_account.name,
          type: collection.supplier_account.type,
          status: collection.supplier_account.status,
        },
        customer_account: {
          code: collection.customer_account.code,
          name: collection.customer_account.name,
          type: collection.customer_account.type,
          status: collection.customer_account.status,
        },
        recorded_by: {
          id: collection.recorded_by_user.id,
          name: collection.recorded_by_user.name,
          phone: collection.recorded_by_user.phone,
        },
      },
    };
  }

  async updateCollection(user: User, updateDto: UpdateCollectionDto) {
    if (!user.default_account_id) {
      throw new BadRequestException({
        code: 400,
        status: 'error',
        message: 'No valid default account found. Please set a default account.',
      });
    }

    // Validate collection_id is a valid UUID
    const uuidRegex = /^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/i;
    if (!uuidRegex.test(updateDto.collection_id)) {
      throw new BadRequestException({
        code: 400,
        status: 'error',
        message: 'Invalid collection ID format. Collection ID must be a valid UUID.',
      });
    }

    const customerAccountId = user.default_account_id;

    try {
      // Check if collection exists and belongs to customer
      const collection = await this.prisma.milkSale.findFirst({
        where: {
          id: updateDto.collection_id,
          customer_account_id: customerAccountId,
          status: { not: 'deleted' },
        },
      });

      if (!collection) {
        throw new NotFoundException({
          code: 404,
          status: 'error',
          message: 'Collection not found or not authorized.',
        });
      }

      // Build update data
      const updateData: any = {
        updated_by: user.id,
      };

      if (updateDto.quantity !== undefined) {
        updateData.quantity = updateDto.quantity;
      }

      if (updateDto.status) {
        // Validate status is a valid enum value
        const validStatuses = ['pending', 'accepted', 'rejected', 'cancelled'];
        if (!validStatuses.includes(updateDto.status as string)) {
          throw new BadRequestException({
            code: 400,
            status: 'error',
            message: `Invalid status. Must be one of: ${validStatuses.join(', ')}`,
          });
        }
        updateData.status = updateDto.status as any;
      }

      if (updateDto.collection_at) {
        updateData.sale_at = new Date(updateDto.collection_at);
      }

      if (updateDto.notes !== undefined) {
        updateData.notes = updateDto.notes;
      }

      if (Object.keys(updateData).length === 1) {
        // Only updated_by, no actual fields to update
        throw new BadRequestException({
          code: 400,
          status: 'error',
          message: 'No fields to update.',
        });
      }

      const updatedCollection = await this.prisma.milkSale.update({
        where: { id: updateDto.collection_id },
        data: updateData,
        include: {
          supplier_account: true,
          customer_account: true,
        },
      });

      return {
        code: 200,
        status: 'success',
        message: 'Collection updated successfully.',
        data: {
          id: updatedCollection.id,
          quantity: Number(updatedCollection.quantity),
          unit_price: Number(updatedCollection.unit_price),
          total_amount: Number(updatedCollection.quantity) * Number(updatedCollection.unit_price),
          status: updatedCollection.status,
          collection_at: updatedCollection.sale_at,
          notes: updatedCollection.notes,
        },
      };
    } catch (error) {
      // If it's already a known exception, rethrow it
      if (error instanceof BadRequestException || error instanceof NotFoundException) {
        throw error;
      }

      // Log the error for debugging
      console.error('Error updating collection:', error);

      // Return a proper error response
      throw new InternalServerErrorException({
        code: 500,
        status: 'error',
        message: 'Failed to update collection.',
        error: error.message || 'Unknown error occurred',
      });
    }
  }

  async cancelCollection(user: User, cancelDto: CancelCollectionDto) {
    if (!user.default_account_id) {
      throw new BadRequestException({
        code: 400,
        status: 'error',
        message: 'No valid default account found. Please set a default account.',
      });
    }

    const customerAccountId = user.default_account_id;

    // Check if collection exists and belongs to customer
    const collection = await this.prisma.milkSale.findFirst({
      where: {
        id: cancelDto.collection_id,
        customer_account_id: customerAccountId,
        status: { not: 'deleted' },
      },
    });

    if (!collection) {
      throw new NotFoundException({
        code: 404,
        status: 'error',
        message: 'Collection not found or not authorized.',
      });
    }

    // Update status to cancelled
    await this.prisma.milkSale.update({
      where: { id: cancelDto.collection_id },
      data: {
        status: 'cancelled',
        updated_by: user.id,
      },
    });

    return {
      code: 200,
      status: 'success',
      message: 'Collection cancelled successfully.',
    };
  }
}

