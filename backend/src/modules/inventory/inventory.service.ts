import { Injectable, BadRequestException, NotFoundException } from '@nestjs/common';
import { PrismaService } from '../../prisma/prisma.service';
import { User } from '@prisma/client';
import { CreateInventoryDto } from './dto/create-inventory.dto';
import { UpdateInventoryDto } from './dto/update-inventory.dto';
import { UpdateStockDto } from './dto/update-stock.dto';
import { ToggleListingDto } from './dto/toggle-listing.dto';

@Injectable()
export class InventoryService {
  constructor(private prisma: PrismaService) {}

  async getInventory(user: User, filters?: { status?: string; low_stock?: boolean }) {
    if (!user.default_account_id) {
      throw new BadRequestException({
        code: 400,
        status: 'error',
        message: 'No valid default account found.',
      });
    }

    const where: any = {
      account_id: user.default_account_id,
    };

    // By default, exclude inactive items (soft-deleted items)
    // Only include inactive items if explicitly requested via status filter
    if (filters?.status) {
      where.status = filters.status;
    } else {
      // Exclude inactive items by default
      where.status = { not: 'inactive' };
    }

    // Note: Low stock filtering will be done in application logic
    // Prisma doesn't easily support comparing two columns in where clause

    const products = await this.prisma.product.findMany({
      where,
      include: {
        categories: { include: { category: true } },
        images: { where: { is_primary: true }, take: 1 },
      },
      orderBy: { created_at: 'desc' },
    });

    let filteredProducts = products;

    // Filter low stock items if requested
    if (filters?.low_stock) {
      filteredProducts = products.filter((p) => {
        if (p.min_stock_level !== null) {
          return p.stock_quantity <= p.min_stock_level;
        }
        return p.stock_quantity <= 0;
      });
    }

    return {
      code: 200,
      status: 'success',
      message: 'Inventory fetched successfully.',
      data: filteredProducts.map((p) => ({
        id: p.id,
        name: p.name,
        description: p.description,
        price: Number(p.price),
        stock_quantity: p.stock_quantity,
        min_stock_level: p.min_stock_level,
        status: p.status,
        is_listed_in_marketplace: p.is_listed_in_marketplace,
        categories: p.categories.map((c) => c.category),
        image: p.images[0]?.image_url || null,
        created_at: p.created_at,
        updated_at: p.updated_at,
      })),
    };
  }

  async getInventoryItem(user: User, productId: string) {
    if (!user.default_account_id) {
      throw new BadRequestException({
        code: 400,
        status: 'error',
        message: 'No valid default account found.',
      });
    }

    const product = await this.prisma.product.findFirst({
      where: {
        id: productId,
        account_id: user.default_account_id,
      },
      include: {
        categories: { include: { category: true } },
        images: { orderBy: { sort_order: 'asc' } },
      },
    });

    if (!product) {
      throw new NotFoundException({
        code: 404,
        status: 'error',
        message: 'Inventory item not found.',
      });
    }

    return {
      code: 200,
      status: 'success',
      message: 'Inventory item fetched successfully.',
      data: {
        id: product.id,
        name: product.name,
        description: product.description,
        price: Number(product.price),
        stock_quantity: product.stock_quantity,
        min_stock_level: product.min_stock_level,
        status: product.status,
        is_listed_in_marketplace: product.is_listed_in_marketplace,
        categories: product.categories.map((c) => c.category),
        images: product.images.map((img) => ({
          id: img.id,
          image_url: img.image_url,
          is_primary: img.is_primary,
        })),
        created_at: product.created_at,
        updated_at: product.updated_at,
      },
    };
  }

  async createInventoryItem(user: User, createDto: CreateInventoryDto) {
    if (!user.default_account_id) {
      throw new BadRequestException({
        code: 400,
        status: 'error',
        message: 'No valid default account found.',
      });
    }

    // Determine status based on stock
    let status: 'active' | 'inactive' | 'out_of_stock' = 'active';
    if ((createDto.stock_quantity || 0) === 0) {
      status = 'out_of_stock';
    }

    const product = await this.prisma.product.create({
      data: {
        name: createDto.name,
        description: createDto.description,
        price: createDto.price,
        stock_quantity: createDto.stock_quantity || 0,
        min_stock_level: createDto.min_stock_level || null,
        status: status as any,
        account_id: user.default_account_id,
        is_listed_in_marketplace: createDto.is_listed_in_marketplace || false,
        created_by: user.id,
        updated_by: user.id,
      },
    });

    // Add categories if provided
    if (createDto.category_ids && createDto.category_ids.length > 0) {
      await Promise.all(
        createDto.category_ids.map((catId) =>
          this.prisma.productCategory.create({
            data: {
              product_id: product.id,
              category_id: catId,
            },
          }),
        ),
      );
    }

    return {
      code: 200,
      status: 'success',
      message: 'Inventory item created successfully.',
      data: {
        id: product.id,
        name: product.name,
        description: product.description,
        price: Number(product.price),
        stock_quantity: product.stock_quantity,
        min_stock_level: product.min_stock_level,
        status: product.status,
        is_listed_in_marketplace: product.is_listed_in_marketplace,
      },
    };
  }

  async updateInventoryItem(user: User, productId: string, updateDto: UpdateInventoryDto) {
    if (!user.default_account_id) {
      throw new BadRequestException({
        code: 400,
        status: 'error',
        message: 'No valid default account found.',
      });
    }

    // Verify ownership
    const existing = await this.prisma.product.findFirst({
      where: {
        id: productId,
        account_id: user.default_account_id,
      },
    });

    if (!existing) {
      throw new NotFoundException({
        code: 404,
        status: 'error',
        message: 'Inventory item not found.',
      });
    }

    // Determine status if stock_quantity is being updated
    let status = updateDto.status || existing.status;
    if (updateDto.stock_quantity !== undefined) {
      if (updateDto.stock_quantity === 0) {
        status = 'out_of_stock';
      } else if (status === 'out_of_stock' && updateDto.stock_quantity > 0) {
        status = 'active';
      }
    }

    // Can't list if out of stock
    if (updateDto.is_listed_in_marketplace && 
        (updateDto.stock_quantity !== undefined ? updateDto.stock_quantity === 0 : existing.stock_quantity === 0)) {
      throw new BadRequestException({
        code: 400,
        status: 'error',
        message: 'Cannot list item in marketplace when stock is 0.',
      });
    }

    const product = await this.prisma.product.update({
      where: { id: productId },
      data: {
        ...(updateDto.name && { name: updateDto.name }),
        ...(updateDto.description !== undefined && { description: updateDto.description }),
        ...(updateDto.price !== undefined && { price: updateDto.price }),
        ...(updateDto.stock_quantity !== undefined && { stock_quantity: updateDto.stock_quantity }),
        ...(updateDto.min_stock_level !== undefined && { min_stock_level: updateDto.min_stock_level }),
        ...(updateDto.is_listed_in_marketplace !== undefined && { is_listed_in_marketplace: updateDto.is_listed_in_marketplace }),
        ...(status && { status: status as any }),
        updated_by: user.id,
      },
    });

    // Update categories if provided
    if (updateDto.category_ids !== undefined) {
      // Delete existing categories
      await this.prisma.productCategory.deleteMany({
        where: { product_id: productId },
      });

      // Add new categories
      if (updateDto.category_ids.length > 0) {
        await Promise.all(
          updateDto.category_ids.map((catId) =>
            this.prisma.productCategory.create({
              data: {
                product_id: productId,
                category_id: catId,
              },
            }),
          ),
        );
      }
    }

    return {
      code: 200,
      status: 'success',
      message: 'Inventory item updated successfully.',
      data: {
        id: product.id,
        name: product.name,
        description: product.description,
        price: Number(product.price),
        stock_quantity: product.stock_quantity,
        min_stock_level: product.min_stock_level,
        status: product.status,
        is_listed_in_marketplace: product.is_listed_in_marketplace,
      },
    };
  }

  async updateStock(user: User, productId: string, updateStockDto: UpdateStockDto) {
    if (!user.default_account_id) {
      throw new BadRequestException({
        code: 400,
        status: 'error',
        message: 'No valid default account found.',
      });
    }

    // Verify ownership
    const existing = await this.prisma.product.findFirst({
      where: {
        id: productId,
        account_id: user.default_account_id,
      },
    });

    if (!existing) {
      throw new NotFoundException({
        code: 404,
        status: 'error',
        message: 'Inventory item not found.',
      });
    }

    // Determine status based on new stock
    let status = existing.status;
    if (updateStockDto.stock_quantity === 0) {
      status = 'out_of_stock';
    } else if (existing.status === 'out_of_stock' && updateStockDto.stock_quantity > 0) {
      status = 'active';
    }

    const product = await this.prisma.product.update({
      where: { id: productId },
      data: {
        stock_quantity: updateStockDto.stock_quantity,
        status: status as any,
        updated_by: user.id,
      },
    });

    return {
      code: 200,
      status: 'success',
      message: 'Stock updated successfully.',
      data: {
        id: product.id,
        stock_quantity: product.stock_quantity,
        status: product.status,
      },
    };
  }

  async toggleMarketplaceListing(user: User, productId: string, toggleDto: ToggleListingDto) {
    if (!user.default_account_id) {
      throw new BadRequestException({
        code: 400,
        status: 'error',
        message: 'No valid default account found.',
      });
    }

    // Verify ownership
    const existing = await this.prisma.product.findFirst({
      where: {
        id: productId,
        account_id: user.default_account_id,
      },
    });

    if (!existing) {
      throw new NotFoundException({
        code: 404,
        status: 'error',
        message: 'Inventory item not found.',
      });
    }

    // Can't list if out of stock
    if (toggleDto.is_listed_in_marketplace && existing.stock_quantity === 0) {
      throw new BadRequestException({
        code: 400,
        status: 'error',
        message: 'Cannot list item in marketplace when stock is 0.',
      });
    }

    const product = await this.prisma.product.update({
      where: { id: productId },
      data: {
        is_listed_in_marketplace: toggleDto.is_listed_in_marketplace,
        updated_by: user.id,
      },
    });

    return {
      code: 200,
      status: 'success',
      message: toggleDto.is_listed_in_marketplace
        ? 'Item listed in marketplace successfully.'
        : 'Item removed from marketplace successfully.',
      data: {
        id: product.id,
        is_listed_in_marketplace: product.is_listed_in_marketplace,
      },
    };
  }

  async deleteInventoryItem(user: User, productId: string) {
    if (!user.default_account_id) {
      throw new BadRequestException({
        code: 400,
        status: 'error',
        message: 'No valid default account found.',
      });
    }

    // Verify ownership
    const existing = await this.prisma.product.findFirst({
      where: {
        id: productId,
        account_id: user.default_account_id,
      },
    });

    if (!existing) {
      throw new NotFoundException({
        code: 404,
        status: 'error',
        message: 'Inventory item not found.',
      });
    }

    // Soft delete by setting status to inactive
    await this.prisma.product.update({
      where: { id: productId },
      data: {
        status: 'inactive',
        is_listed_in_marketplace: false,
        updated_by: user.id,
      },
    });

    return {
      code: 200,
      status: 'success',
      message: 'Inventory item deleted successfully.',
    };
  }

  async getInventoryStats(user: User) {
    if (!user.default_account_id) {
      throw new BadRequestException({
        code: 400,
        status: 'error',
        message: 'No valid default account found.',
      });
    }

    const [totalItems, activeItems, outOfStockItems, listedItems, lowStockItems] = await Promise.all([
      this.prisma.product.count({
        where: { account_id: user.default_account_id, status: { not: 'inactive' } },
      }),
      this.prisma.product.count({
        where: { account_id: user.default_account_id, status: 'active' },
      }),
      this.prisma.product.count({
        where: { account_id: user.default_account_id, status: 'out_of_stock' },
      }),
      this.prisma.product.count({
        where: { 
          account_id: user.default_account_id, 
          is_listed_in_marketplace: true,
          status: { not: 'inactive' }, // Exclude deleted/inactive items
        },
      }),
      // Count low stock items (fetch and filter in memory, excluding inactive items)
      (async () => {
        const allProducts = await this.prisma.product.findMany({
          where: { 
            account_id: user.default_account_id,
            status: { not: 'inactive' }, // Exclude deleted/inactive items
          },
          select: { stock_quantity: true, min_stock_level: true },
        });
        return allProducts.filter((p) => {
          if (p.min_stock_level !== null) {
            return p.stock_quantity <= p.min_stock_level;
          }
          return p.stock_quantity <= 0;
        }).length;
      })(),
    ]);

    return {
      code: 200,
      status: 'success',
      message: 'Inventory statistics fetched successfully.',
      data: {
        total_items: totalItems,
        active_items: activeItems,
        out_of_stock_items: outOfStockItems,
        listed_in_marketplace: listedItems,
        low_stock_items: lowStockItems,
      },
    };
  }
}
