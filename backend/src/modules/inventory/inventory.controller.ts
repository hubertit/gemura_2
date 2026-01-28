import { Controller, Get, Post, Put, Delete, Body, Param, Query, UseGuards, HttpCode } from '@nestjs/common';
import { ApiTags, ApiOperation, ApiResponse, ApiBearerAuth, ApiParam, ApiQuery, ApiBody, ApiBadRequestResponse, ApiUnauthorizedResponse, ApiNotFoundResponse } from '@nestjs/swagger';
import { InventoryService } from './inventory.service';
import { TokenGuard } from '../../common/guards/token.guard';
import { CurrentUser } from '../../common/decorators/user.decorator';
import { User } from '@prisma/client';
import { CreateInventoryDto } from './dto/create-inventory.dto';
import { UpdateInventoryDto } from './dto/update-inventory.dto';
import { UpdateStockDto } from './dto/update-stock.dto';
import { ToggleListingDto } from './dto/toggle-listing.dto';
import { CreateInventorySaleDto } from './dto/create-inventory-sale.dto';

@ApiTags('Inventory')
@Controller('inventory')
@UseGuards(TokenGuard)
@ApiBearerAuth()
export class InventoryController {
  constructor(private readonly inventoryService: InventoryService) {}

  @Get()
  @ApiOperation({
    summary: 'Get inventory items',
    description: 'Retrieve a list of inventory items for the current user\'s default account. Can be filtered by status and low stock alerts. Data is scoped to the user\'s default account.',
  })
  @ApiQuery({
    name: 'status',
    required: false,
    enum: ['active', 'inactive', 'out_of_stock'],
    description: 'Filter by inventory status',
    example: 'active',
  })
  @ApiQuery({
    name: 'low_stock',
    required: false,
    type: Boolean,
    description: 'Filter items with low stock (set to true)',
    example: true,
  })
  @ApiResponse({
    status: 200,
    description: 'Inventory items retrieved successfully',
    example: {
      code: 200,
      status: 'success',
      message: 'Inventory items retrieved successfully.',
      data: [
        {
          id: 'cb9ad42f-12dc-401e-9ac9-05585b9b311e',
          name: 'Fresh Milk 500ml',
          description: 'Fresh pasteurized milk',
          category: 'Dairy',
          unit: 'bottle',
          quantity: 150,
          min_stock_level: 50,
          unit_price: 800,
          status: 'active',
          is_listed: true,
          created_at: '2025-01-20T10:00:00Z',
          updated_at: '2025-01-20T10:00:00Z',
        },
      ],
    },
  })
  @ApiBadRequestResponse({
    description: 'No default account found',
    example: {
      code: 400,
      status: 'error',
      message: 'No valid default account found. Please set a default account.',
    },
  })
  @ApiUnauthorizedResponse({
    description: 'Unauthorized - invalid or missing token',
    example: {
      code: 401,
      status: 'error',
      message: 'Access denied. Token is required.',
    },
  })
  async getInventory(
    @CurrentUser() user: User,
    @Query('status') status?: string,
    @Query('low_stock') lowStock?: string,
  ) {
    return this.inventoryService.getInventory(user, {
      status,
      low_stock: lowStock === 'true',
    });
  }

  @Get('stats')
  @ApiOperation({
    summary: 'Get inventory statistics',
    description: 'Retrieve aggregated statistics about inventory for the user\'s default account including total items, stock levels, low stock alerts, and value summaries.',
  })
  @ApiResponse({
    status: 200,
    description: 'Inventory statistics retrieved successfully',
    example: {
      code: 200,
      status: 'success',
      message: 'Inventory statistics retrieved successfully.',
      data: {
        total_items: 25,
        active_items: 20,
        inactive_items: 3,
        out_of_stock_items: 2,
        low_stock_items: 5,
        total_quantity: 1250,
        total_value: 1000000,
        low_stock_value: 150000,
        categories: ['Dairy', 'Beverages', 'Snacks'],
      },
    },
  })
  @ApiBadRequestResponse({
    description: 'No default account found',
    example: {
      code: 400,
      status: 'error',
      message: 'No valid default account found. Please set a default account.',
    },
  })
  @ApiUnauthorizedResponse({
    description: 'Unauthorized - invalid or missing token',
    example: {
      code: 401,
      status: 'error',
      message: 'Access denied. Token is required.',
    },
  })
  async getInventoryStats(@CurrentUser() user: User) {
    return this.inventoryService.getInventoryStats(user);
  }

  @Get(':id')
  @ApiOperation({
    summary: 'Get inventory item by ID',
    description: 'Retrieve detailed information about a specific inventory item by its ID. The item must belong to the user\'s default account.',
  })
  @ApiParam({
    name: 'id',
    description: 'Product ID (UUID)',
    example: 'cb9ad42f-12dc-401e-9ac9-05585b9b311e',
    type: String,
  })
  @ApiResponse({
    status: 200,
    description: 'Inventory item fetched successfully',
    example: {
      code: 200,
      status: 'success',
      message: 'Inventory item fetched successfully.',
      data: {
        id: 'cb9ad42f-12dc-401e-9ac9-05585b9b311e',
        name: 'Fresh Milk 500ml',
        description: 'Fresh pasteurized milk',
        category: 'Dairy',
        unit: 'bottle',
        quantity: 150,
        min_stock_level: 50,
        unit_price: 800,
        status: 'active',
        is_listed: true,
        created_at: '2025-01-20T10:00:00Z',
        updated_at: '2025-01-20T10:00:00Z',
      },
    },
  })
  @ApiBadRequestResponse({
    description: 'Invalid UUID format or no default account',
    example: {
      code: 400,
      status: 'error',
      message: 'No valid default account found. Please set a default account.',
    },
  })
  @ApiUnauthorizedResponse({
    description: 'Unauthorized - invalid or missing token',
    example: {
      code: 401,
      status: 'error',
      message: 'Access denied. Token is required.',
    },
  })
  @ApiNotFoundResponse({
    description: 'Inventory item not found',
    example: {
      code: 404,
      status: 'error',
      message: 'Inventory item not found.',
    },
  })
  async getInventoryItem(@CurrentUser() user: User, @Param('id') id: string) {
    return this.inventoryService.getInventoryItem(user, id);
  }

  @Post()
  @HttpCode(200)
  @ApiOperation({
    summary: 'Create inventory item',
    description: 'Create a new inventory item (product) in the system. The item will be associated with the current user\'s default account. Requires name, unit, and initial quantity.',
  })
  @ApiBody({
    type: CreateInventoryDto,
    description: 'Inventory item details',
    examples: {
      createItem: {
        summary: 'Create new inventory item',
        value: {
          name: 'Fresh Milk 500ml',
          description: 'Fresh pasteurized milk',
          category: 'Dairy',
          unit: 'bottle',
          quantity: 100,
          min_stock_level: 50,
          unit_price: 800,
        },
      },
      minimalItem: {
        summary: 'Create item with minimal info',
        value: {
          name: 'Yogurt 250ml',
          unit: 'bottle',
          quantity: 50,
        },
      },
    },
  })
  @ApiResponse({
    status: 200,
    description: 'Inventory item created successfully',
    example: {
      code: 200,
      status: 'success',
      message: 'Inventory item created successfully.',
      data: {
        id: 'cb9ad42f-12dc-401e-9ac9-05585b9b311e',
        name: 'Fresh Milk 500ml',
        description: 'Fresh pasteurized milk',
        category: 'Dairy',
        unit: 'bottle',
        quantity: 100,
        min_stock_level: 50,
        unit_price: 800,
        status: 'active',
        is_listed: false,
        created_at: '2025-01-28T10:00:00Z',
        updated_at: '2025-01-28T10:00:00Z',
      },
    },
  })
  @ApiBadRequestResponse({
    description: 'Bad request - validation failed or no default account',
    examples: {
      validationError: {
        summary: 'Validation failed',
        value: {
          code: 400,
          status: 'error',
          message: 'Name, unit, and quantity are required.',
        },
      },
      noDefaultAccount: {
        summary: 'No default account',
        value: {
          code: 400,
          status: 'error',
          message: 'No valid default account found. Please set a default account.',
        },
      },
    },
  })
  @ApiUnauthorizedResponse({
    description: 'Unauthorized - invalid or missing token',
    example: {
      code: 401,
      status: 'error',
      message: 'Access denied. Token is required.',
    },
  })
  async createInventoryItem(@CurrentUser() user: User, @Body() createDto: CreateInventoryDto) {
    return this.inventoryService.createInventoryItem(user, createDto);
  }

  @Put(':id')
  @ApiOperation({
    summary: 'Update inventory item',
    description: 'Update details of an existing inventory item. Only items belonging to the user\'s default account can be updated.',
  })
  @ApiParam({
    name: 'id',
    description: 'Product ID (UUID)',
    example: 'cb9ad42f-12dc-401e-9ac9-05585b9b311e',
    type: String,
  })
  @ApiBody({
    type: UpdateInventoryDto,
    description: 'Inventory item update data',
    examples: {
      updatePrice: {
        summary: 'Update price',
        value: {
          unit_price: 850,
        },
      },
      updateAll: {
        summary: 'Update multiple fields',
        value: {
          name: 'Fresh Milk 500ml Premium',
          description: 'Premium fresh pasteurized milk',
          category: 'Dairy',
          min_stock_level: 75,
          unit_price: 900,
        },
      },
    },
  })
  @ApiResponse({
    status: 200,
    description: 'Inventory item updated successfully',
    example: {
      code: 200,
      status: 'success',
      message: 'Inventory item updated successfully.',
      data: {
        id: 'cb9ad42f-12dc-401e-9ac9-05585b9b311e',
        name: 'Fresh Milk 500ml Premium',
        unit_price: 900,
        updated_at: '2025-01-28T10:00:00Z',
      },
    },
  })
  @ApiBadRequestResponse({
    description: 'Invalid request or no default account',
    example: {
      code: 400,
      status: 'error',
      message: 'No valid default account found. Please set a default account.',
    },
  })
  @ApiUnauthorizedResponse({
    description: 'Unauthorized - invalid or missing token',
    example: {
      code: 401,
      status: 'error',
      message: 'Access denied. Token is required.',
    },
  })
  @ApiNotFoundResponse({
    description: 'Inventory item not found',
    example: {
      code: 404,
      status: 'error',
      message: 'Inventory item not found.',
    },
  })
  async updateInventoryItem(
    @CurrentUser() user: User,
    @Param('id') id: string,
    @Body() updateDto: UpdateInventoryDto,
  ) {
    return this.inventoryService.updateInventoryItem(user, id, updateDto);
  }

  @Put(':id/stock')
  @ApiOperation({
    summary: 'Update stock quantity',
    description: 'Update the stock quantity of an inventory item. Can be used to add stock (positive value) or adjust stock levels. Only items belonging to the user\'s default account can be updated.',
  })
  @ApiParam({
    name: 'id',
    description: 'Product ID (UUID)',
    example: 'cb9ad42f-12dc-401e-9ac9-05585b9b311e',
    type: String,
  })
  @ApiBody({
    type: UpdateStockDto,
    description: 'Stock update data',
    examples: {
      addStock: {
        summary: 'Add stock',
        value: {
          quantity: 50,
          notes: 'New shipment received',
        },
      },
      adjustStock: {
        summary: 'Adjust stock',
        value: {
          quantity: -10,
          notes: 'Damaged items removed',
        },
      },
    },
  })
  @ApiResponse({
    status: 200,
    description: 'Stock updated successfully',
    example: {
      code: 200,
      status: 'success',
      message: 'Stock updated successfully.',
      data: {
        id: 'cb9ad42f-12dc-401e-9ac9-05585b9b311e',
        name: 'Fresh Milk 500ml',
        quantity: 200,
        previous_quantity: 150,
        updated_at: '2025-01-28T10:00:00Z',
      },
    },
  })
  @ApiBadRequestResponse({
    description: 'Invalid request or insufficient stock',
    examples: {
      invalidQuantity: {
        summary: 'Invalid quantity',
        value: {
          code: 400,
          status: 'error',
          message: 'Quantity adjustment would result in negative stock.',
        },
      },
      noDefaultAccount: {
        summary: 'No default account',
        value: {
          code: 400,
          status: 'error',
          message: 'No valid default account found. Please set a default account.',
        },
      },
    },
  })
  @ApiUnauthorizedResponse({
    description: 'Unauthorized - invalid or missing token',
    example: {
      code: 401,
      status: 'error',
      message: 'Access denied. Token is required.',
    },
  })
  @ApiNotFoundResponse({
    description: 'Inventory item not found',
    example: {
      code: 404,
      status: 'error',
      message: 'Inventory item not found.',
    },
  })
  async updateStock(
    @CurrentUser() user: User,
    @Param('id') id: string,
    @Body() updateStockDto: UpdateStockDto,
  ) {
    return this.inventoryService.updateStock(user, id, updateStockDto);
  }

  @Post(':id/toggle-listing')
  @HttpCode(200)
  @ApiOperation({
    summary: 'Toggle marketplace listing',
    description: 'Toggle whether an inventory item is listed on the marketplace. When listed, the item becomes visible to other users for purchase.',
  })
  @ApiParam({
    name: 'id',
    description: 'Product ID (UUID)',
    example: 'cb9ad42f-12dc-401e-9ac9-05585b9b311e',
    type: String,
  })
  @ApiBody({
    type: ToggleListingDto,
    description: 'Listing toggle data',
    examples: {
      listItem: {
        summary: 'List item on marketplace',
        value: {
          is_listed: true,
        },
      },
      unlistItem: {
        summary: 'Remove item from marketplace',
        value: {
          is_listed: false,
        },
      },
    },
  })
  @ApiResponse({
    status: 200,
    description: 'Marketplace listing toggled successfully',
    example: {
      code: 200,
      status: 'success',
      message: 'Marketplace listing toggled successfully.',
      data: {
        id: 'cb9ad42f-12dc-401e-9ac9-05585b9b311e',
        name: 'Fresh Milk 500ml',
        is_listed: true,
        updated_at: '2025-01-28T10:00:00Z',
      },
    },
  })
  @ApiBadRequestResponse({
    description: 'Invalid request or no default account',
    example: {
      code: 400,
      status: 'error',
      message: 'No valid default account found. Please set a default account.',
    },
  })
  @ApiUnauthorizedResponse({
    description: 'Unauthorized - invalid or missing token',
    example: {
      code: 401,
      status: 'error',
      message: 'Access denied. Token is required.',
    },
  })
  @ApiNotFoundResponse({
    description: 'Inventory item not found',
    example: {
      code: 404,
      status: 'error',
      message: 'Inventory item not found.',
    },
  })
  async toggleMarketplaceListing(
    @CurrentUser() user: User,
    @Param('id') id: string,
    @Body() toggleDto: ToggleListingDto,
  ) {
    return this.inventoryService.toggleMarketplaceListing(user, id, toggleDto);
  }

  @Delete(':id')
  @ApiOperation({
    summary: 'Delete inventory item (soft delete)',
    description: 'Soft delete an inventory item by setting its status to inactive. The item will no longer appear in active listings but can be restored. Only items belonging to the user\'s default account can be deleted.',
  })
  @ApiParam({
    name: 'id',
    description: 'Product ID (UUID)',
    example: 'cb9ad42f-12dc-401e-9ac9-05585b9b311e',
    type: String,
  })
  @ApiResponse({
    status: 200,
    description: 'Inventory item deleted successfully',
    example: {
      code: 200,
      status: 'success',
      message: 'Inventory item deleted successfully.',
      data: {
        id: 'cb9ad42f-12dc-401e-9ac9-05585b9b311e',
        name: 'Fresh Milk 500ml',
        status: 'inactive',
        deleted_at: '2025-01-28T10:00:00Z',
      },
    },
  })
  @ApiBadRequestResponse({
    description: 'Invalid request or no default account',
    example: {
      code: 400,
      status: 'error',
      message: 'No valid default account found. Please set a default account.',
    },
  })
  @ApiUnauthorizedResponse({
    description: 'Unauthorized - invalid or missing token',
    example: {
      code: 401,
      status: 'error',
      message: 'Access denied. Token is required.',
    },
  })
  @ApiNotFoundResponse({
    description: 'Inventory item not found',
    example: {
      code: 404,
      status: 'error',
      message: 'Inventory item not found.',
    },
  })
  async deleteInventoryItem(@CurrentUser() user: User, @Param('id') id: string) {
    return this.inventoryService.deleteInventoryItem(user, id);
  }

  @Post(':id/sell')
  @HttpCode(200)
  @ApiOperation({
    summary: 'Sell inventory item',
    description: 'Record a sale of an inventory item to a customer. This will update stock levels, create a sales record, and update accounting transactions. The sale is scoped to the user\'s default account.',
  })
  @ApiParam({
    name: 'id',
    description: 'Product ID (UUID)',
    example: 'cb9ad42f-12dc-401e-9ac9-05585b9b311e',
    type: String,
  })
  @ApiBody({
    type: CreateInventorySaleDto,
    description: 'Sale details',
    examples: {
      sellItem: {
        summary: 'Sell inventory item',
        value: {
          buyer_account_id: '550e8400-e29b-41d4-a716-446655440000',
          quantity: 10,
          unit_price: 800,
          notes: 'Sale to customer',
        },
      },
      sellWithCode: {
        summary: 'Sell using account code',
        value: {
          buyer_account_code: 'A_XYZ789',
          quantity: 5,
          unit_price: 850,
        },
      },
    },
  })
  @ApiResponse({
    status: 200,
    description: 'Inventory item sold successfully',
    example: {
      code: 200,
      status: 'success',
      message: 'Inventory item sold successfully.',
      data: {
        sale_id: 'cb9ad42f-12dc-401e-9ac9-05585b9b311e',
        inventory_item_id: 'cb9ad42f-12dc-401e-9ac9-05585b9b311e',
        buyer_account_id: '550e8400-e29b-41d4-a716-446655440000',
        quantity: 10,
        unit_price: 800,
        total_amount: 8000,
        remaining_stock: 140,
        sale_date: '2025-01-28T10:00:00Z',
      },
    },
  })
  @ApiBadRequestResponse({
    description: 'Bad request - validation failed or business rule violation',
    examples: {
      insufficientStock: {
        summary: 'Insufficient stock',
        value: {
          code: 400,
          status: 'error',
          message: 'Insufficient stock. Available: 5, Requested: 10',
        },
      },
      noDefaultAccount: {
        summary: 'No default account',
        value: {
          code: 400,
          status: 'error',
          message: 'No valid default account found. Please set a default account.',
        },
      },
      missingBuyer: {
        summary: 'Missing buyer identifier',
        value: {
          code: 400,
          status: 'error',
          message: 'Either buyer_account_id or buyer_account_code is required.',
        },
      },
    },
  })
  @ApiUnauthorizedResponse({
    description: 'Unauthorized - invalid or missing token',
    example: {
      code: 401,
      status: 'error',
      message: 'Access denied. Token is required.',
    },
  })
  @ApiNotFoundResponse({
    description: 'Inventory item or buyer account not found',
    examples: {
      itemNotFound: {
        summary: 'Item not found',
        value: {
          code: 404,
          status: 'error',
          message: 'Inventory item not found.',
        },
      },
      buyerNotFound: {
        summary: 'Buyer not found',
        value: {
          code: 404,
          status: 'error',
          message: 'Buyer account not found.',
        },
      },
    },
  })
  async sellInventoryItem(
    @CurrentUser() user: User,
    @Param('id') id: string,
    @Body() createSaleDto: CreateInventorySaleDto,
  ) {
    return this.inventoryService.sellInventoryItem(user, id, createSaleDto);
  }
}
