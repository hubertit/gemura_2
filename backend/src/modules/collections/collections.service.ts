import { Injectable, BadRequestException, NotFoundException, InternalServerErrorException } from '@nestjs/common';
import { PrismaService } from '../../prisma/prisma.service';
import { User } from '@prisma/client';
import { CreateCollectionDto } from './dto/create-collection.dto';
import { UpdateCollectionDto } from './dto/update-collection.dto';
import { CancelCollectionDto } from './dto/cancel-collection.dto';

@Injectable()
export class CollectionsService {
  constructor(private prisma: PrismaService) {}

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

    const customerAccountId = user.default_account_id;

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

