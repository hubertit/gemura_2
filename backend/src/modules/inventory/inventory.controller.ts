import { Controller, Get, Post, Put, Delete, Body, Param, Query, UseGuards } from '@nestjs/common';
import { ApiTags, ApiOperation, ApiResponse, ApiBearerAuth, ApiParam, ApiQuery } from '@nestjs/swagger';
import { InventoryService } from './inventory.service';
import { TokenGuard } from '../../common/guards/token.guard';
import { CurrentUser } from '../../common/decorators/user.decorator';
import { User } from '@prisma/client';
import { CreateInventoryDto } from './dto/create-inventory.dto';
import { UpdateInventoryDto } from './dto/update-inventory.dto';
import { UpdateStockDto } from './dto/update-stock.dto';
import { ToggleListingDto } from './dto/toggle-listing.dto';

@ApiTags('Inventory')
@Controller('inventory')
@UseGuards(TokenGuard)
@ApiBearerAuth()
export class InventoryController {
  constructor(private readonly inventoryService: InventoryService) {}

  @Get()
  @ApiOperation({ summary: 'Get inventory items' })
  @ApiQuery({ name: 'status', required: false, enum: ['active', 'inactive', 'out_of_stock'] })
  @ApiQuery({ name: 'low_stock', required: false, type: Boolean })
  @ApiResponse({ status: 200, description: 'Inventory fetched successfully' })
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
  @ApiOperation({ summary: 'Get inventory statistics' })
  @ApiResponse({ status: 200, description: 'Inventory statistics fetched successfully' })
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
  @ApiOperation({ summary: 'Create inventory item' })
  @ApiResponse({ status: 200, description: 'Inventory item created successfully' })
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
}
