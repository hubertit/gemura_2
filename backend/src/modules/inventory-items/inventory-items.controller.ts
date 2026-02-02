import { Controller, Get, Param, Query, UseGuards } from '@nestjs/common';
import {
  ApiTags,
  ApiOperation,
  ApiResponse,
  ApiBearerAuth,
  ApiParam,
  ApiQuery,
} from '@nestjs/swagger';
import { InventoryItemsService } from './inventory-items.service';
import { TokenGuard } from '../../common/guards/token.guard';

@ApiTags('Inventory Items (predefined list)')
@Controller('inventory-items')
@UseGuards(TokenGuard)
@ApiBearerAuth()
export class InventoryItemsController {
  constructor(private readonly inventoryItemsService: InventoryItemsService) {}

  @Get('categories')
  @ApiOperation({
    summary: 'List inventory item categories',
    description:
      'Returns all categories used to group predefined inventory items. Use for tabs or first-level selection.',
  })
  @ApiResponse({
    status: 200,
    description: 'Categories retrieved successfully',
    example: {
      code: 200,
      status: 'success',
      message: 'Inventory item categories retrieved successfully.',
      data: [
        { id: 'uuid', name: 'Dairy', description: null, sort_order: 0, items_count: 5 },
      ],
    },
  })
  async getCategories() {
    return this.inventoryItemsService.getCategories();
  }

  @Get()
  @ApiOperation({
    summary: 'List predefined inventory items',
    description:
      'Returns the predefined list of inventory items. Use category_id to filter, or group_by_category=true to get structure grouped by category for dropdowns.',
  })
  @ApiQuery({
    name: 'category_id',
    required: false,
    type: String,
    description: 'Filter items by category UUID',
  })
  @ApiQuery({
    name: 'group_by_category',
    required: false,
    type: Boolean,
    description: 'If true, returns { categories: [ { id, name, items: [...] } ] }',
  })
  @ApiQuery({
    name: 'active_only',
    required: false,
    type: Boolean,
    description: 'Include only active items (default true)',
  })
  @ApiResponse({
    status: 200,
    description: 'Inventory items retrieved successfully',
  })
  async getItems(
    @Query('category_id') categoryId?: string,
    @Query('group_by_category') groupByCategory?: string,
    @Query('active_only') activeOnly?: string,
  ) {
    return this.inventoryItemsService.getItems({
      category_id: categoryId || undefined,
      group_by_category: groupByCategory === 'true',
      active_only: activeOnly === 'false' ? false : true,
    });
  }

  @Get(':id')
  @ApiOperation({
    summary: 'Get inventory item by ID',
    description: 'Returns a single predefined inventory item by UUID.',
  })
  @ApiParam({ name: 'id', description: 'Inventory item UUID', type: String })
  @ApiResponse({
    status: 200,
    description: 'Inventory item retrieved successfully',
  })
  @ApiResponse({
    status: 404,
    description: 'Inventory item not found',
  })
  async getItemById(@Param('id') id: string) {
    return this.inventoryItemsService.getItemById(id);
  }
}
