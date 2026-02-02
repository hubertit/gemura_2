import { Injectable, NotFoundException } from '@nestjs/common';
import { PrismaService } from '../../prisma/prisma.service';

@Injectable()
export class InventoryItemsService {
  constructor(private prisma: PrismaService) {}

  /**
   * List all inventory item categories (for grouping in UI).
   */
  async getCategories() {
    const categories = await this.prisma.inventoryItemCategory.findMany({
      orderBy: { sort_order: 'asc' },
      include: {
        _count: { select: { items: true } },
      },
    });

    return {
      code: 200,
      status: 'success',
      message: 'Inventory item categories retrieved successfully.',
      data: categories.map((c) => ({
        id: c.id,
        name: c.name,
        description: c.description,
        sort_order: c.sort_order,
        items_count: c._count.items,
        created_at: c.created_at,
        updated_at: c.updated_at,
      })),
    };
  }

  /**
   * List predefined inventory items. Optional filter by category_id.
   * Use group_by_category=true to return structure grouped by category (for dropdowns).
   */
  async getItems(options?: {
    category_id?: string;
    group_by_category?: boolean;
    active_only?: boolean;
  }) {
    const where: { category_id?: string; is_active?: boolean } = {};
    if (options?.category_id) where.category_id = options.category_id;
    if (options?.active_only !== false) where.is_active = true;

    const items = await this.prisma.inventoryItem.findMany({
      where,
      include: { category: true },
      orderBy: [{ category: { sort_order: 'asc' } }, { sort_order: 'asc' }, { name: 'asc' }],
    });

    if (options?.group_by_category === true) {
      const byCategory = new Map<
        string,
        { id: string; name: string; description: string | null; sort_order: number; items: any[] }
      >();
      for (const item of items) {
        const cat = item.category;
        if (!byCategory.has(cat.id)) {
          byCategory.set(cat.id, {
            id: cat.id,
            name: cat.name,
            description: cat.description,
            sort_order: cat.sort_order,
            items: [],
          });
        }
        byCategory.get(cat.id)!.items.push({
          id: item.id,
          name: item.name,
          code: item.code,
          unit: item.unit,
          description: item.description,
          is_active: item.is_active,
          sort_order: item.sort_order,
        });
      }
      const categories = Array.from(byCategory.values()).sort((a, b) => a.sort_order - b.sort_order);

      return {
        code: 200,
        status: 'success',
        message: 'Inventory items retrieved successfully (grouped by category).',
        data: { categories },
      };
    }

    return {
      code: 200,
      status: 'success',
      message: 'Inventory items retrieved successfully.',
      data: items.map((item) => ({
        id: item.id,
        name: item.name,
        code: item.code,
        unit: item.unit,
        description: item.description,
        is_active: item.is_active,
        sort_order: item.sort_order,
        category_id: item.category_id,
        category_name: item.category.name,
        created_at: item.created_at,
        updated_at: item.updated_at,
      })),
    };
  }

  /**
   * Get a single inventory item by ID (e.g. for validation when creating product).
   */
  async getItemById(id: string) {
    const item = await this.prisma.inventoryItem.findFirst({
      where: { id, is_active: true },
      include: { category: true },
    });

    if (!item) {
      throw new NotFoundException({
        code: 404,
        status: 'error',
        message: 'Inventory item not found.',
      });
    }

    return {
      code: 200,
      status: 'success',
      message: 'Inventory item retrieved successfully.',
      data: {
        id: item.id,
        name: item.name,
        code: item.code,
        unit: item.unit,
        description: item.description,
        category_id: item.category_id,
        category_name: item.category.name,
        sort_order: item.sort_order,
        created_at: item.created_at,
        updated_at: item.updated_at,
      },
    };
  }
}
