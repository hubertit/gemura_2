import { Controller, Get, Post, Put, Delete, Body, Param, Query, UseGuards, HttpCode } from '@nestjs/common';
import { ApiTags, ApiOperation, ApiResponse, ApiBearerAuth, ApiParam, ApiQuery } from '@nestjs/swagger';
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
    description: 'Retrieve a list of inventory items for the current user\'s account. Can be filtered by status and low stock alerts.',
  })
  @ApiQuery({
    name: 'status',
    required: false,
    enum: ['active', 'inactive', 'out_of_stock'],
    description: 'Filter by inventory status',
  })
  @ApiQuery({
    name: 'low_stock',
    required: false,
    type: Boolean,
    description: 'Filter items with low stock (set to true)',
  })
  @ApiResponse({
    status: 200,
    description: 'Inventory items retrieved successfully',
  })
  @ApiResponse({ status: 401, description: 'Unauthorized - invalid or missing token' })
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
    description: 'Retrieve aggregated statistics about inventory including total items, stock levels, low stock alerts, and value summaries.',
  })
  @ApiResponse({
    status: 200,
    description: 'Inventory statistics retrieved successfully',
  })
  @ApiResponse({ status: 401, description: 'Unauthorized - invalid or missing token' })
  async getInventoryStats(@CurrentUser() user: User) {
    return this.inventoryService.getInventoryStats(user);
  }

  @Get(':id')
  @ApiOperation({ summary: 'Get inventory item by ID' })
  @ApiParam({ name: 'id', description: 'Product ID' })
  @ApiResponse({ status: 200, description: 'Inventory item fetched successfully' })
  async getInventoryItem(@CurrentUser() user: User, @Param('id') id: string) {
    return this.inventoryService.getInventoryItem(user, id);
  }

  @Post()
  @HttpCode(200)
  @ApiOperation({
    summary: 'Create inventory item',
    description: 'Create a new inventory item (product) in the system. The item will be associated with the current user\'s account.',
  })
  @ApiResponse({
    status: 200,
    description: 'Inventory item created successfully',
  })
  @ApiResponse({ status: 400, description: 'Bad request - validation failed' })
  @ApiResponse({ status: 401, description: 'Unauthorized - invalid or missing token' })
  async createInventoryItem(@CurrentUser() user: User, @Body() createDto: CreateInventoryDto) {
    return this.inventoryService.createInventoryItem(user, createDto);
  }

  @Put(':id')
  @ApiOperation({ summary: 'Update inventory item' })
  @ApiParam({ name: 'id', description: 'Product ID' })
  @ApiResponse({ status: 200, description: 'Inventory item updated successfully' })
  async updateInventoryItem(
    @CurrentUser() user: User,
    @Param('id') id: string,
    @Body() updateDto: UpdateInventoryDto,
  ) {
    return this.inventoryService.updateInventoryItem(user, id, updateDto);
  }

  @Put(':id/stock')
  @ApiOperation({ summary: 'Update stock quantity' })
  @ApiParam({ name: 'id', description: 'Product ID' })
  @ApiResponse({ status: 200, description: 'Stock updated successfully' })
  async updateStock(
    @CurrentUser() user: User,
    @Param('id') id: string,
    @Body() updateStockDto: UpdateStockDto,
  ) {
    return this.inventoryService.updateStock(user, id, updateStockDto);
  }

  @Post(':id/toggle-listing')
  @HttpCode(200)
  @ApiOperation({ summary: 'Toggle marketplace listing' })
  @ApiParam({ name: 'id', description: 'Product ID' })
  @ApiResponse({ status: 200, description: 'Marketplace listing toggled successfully' })
  async toggleMarketplaceListing(
    @CurrentUser() user: User,
    @Param('id') id: string,
    @Body() toggleDto: ToggleListingDto,
  ) {
    return this.inventoryService.toggleMarketplaceListing(user, id, toggleDto);
  }

  @Delete(':id')
  @ApiOperation({ summary: 'Delete inventory item (soft delete)' })
  @ApiParam({ name: 'id', description: 'Product ID' })
  @ApiResponse({ status: 200, description: 'Inventory item deleted successfully' })
  async deleteInventoryItem(@CurrentUser() user: User, @Param('id') id: string) {
    return this.inventoryService.deleteInventoryItem(user, id);
  }

  @Post(':id/sell')
  @HttpCode(200)
  @ApiOperation({
    summary: 'Sell inventory item',
    description: 'Record a sale of an inventory item to a customer. This will update stock levels and create a sales record.',
  })
  @ApiParam({ name: 'id', description: 'Product ID (UUID)' })
  @ApiResponse({
    status: 200,
    description: 'Inventory item sold successfully',
  })
  @ApiResponse({ status: 400, description: 'Bad request - validation failed or business rule violation (e.g., insufficient stock)' })
  @ApiResponse({ status: 401, description: 'Unauthorized - invalid or missing token' })
  @ApiResponse({ status: 404, description: 'Inventory item or buyer account not found' })
  async sellInventoryItem(
    @CurrentUser() user: User,
    @Param('id') id: string,
    @Body() createSaleDto: CreateInventorySaleDto,
  ) {
    return this.inventoryService.sellInventoryItem(user, id, createSaleDto);
  }
}
