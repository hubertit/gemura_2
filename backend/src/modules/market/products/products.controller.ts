import { Controller, Post, Get, Put, Delete, Body, UseGuards, Param, Query } from '@nestjs/common';
import { ApiTags, ApiOperation, ApiResponse, ApiBearerAuth, ApiBody, ApiParam, ApiQuery } from '@nestjs/swagger';
import { ProductsService } from './products.service';
import { TokenGuard } from '../../../common/guards/token.guard';
import { CurrentUser } from '../../../common/decorators/user.decorator';
import { User } from '@prisma/client';
import { CreateProductDto } from './dto/create-product.dto';
import { UpdateProductDto } from './dto/update-product.dto';

@ApiTags('Market - Products')
@Controller('market/products')
@UseGuards(TokenGuard)
@ApiBearerAuth()
export class ProductsController {
  constructor(private readonly productsService: ProductsService) {}

  @Post()
  @ApiOperation({ summary: 'Create product' })
  @ApiBody({ type: CreateProductDto })
  @ApiResponse({ status: 200, description: 'Product created successfully' })
  async createProduct(@CurrentUser() user: User, @Body() createDto: CreateProductDto) {
    return this.productsService.createProduct(user, createDto);
  }

  @Get()
  @ApiOperation({ summary: 'List products' })
  @ApiQuery({ name: 'status', required: false })
  @ApiResponse({ status: 200, description: 'Products fetched successfully' })
  async getProducts(@CurrentUser() user: User, @Query('status') status?: string) {
    return this.productsService.getProducts(user, { status });
  }

  @Get(':id')
  @ApiOperation({ summary: 'Get product' })
  @ApiParam({ name: 'id' })
  @ApiResponse({ status: 200, description: 'Product fetched successfully' })
  async getProduct(@CurrentUser() user: User, @Param('id') id: string) {
    return this.productsService.getProduct(user, id);
  }

  @Put(':id')
  @ApiOperation({ summary: 'Update product' })
  @ApiParam({ name: 'id' })
  @ApiBody({ type: UpdateProductDto })
  @ApiResponse({ status: 200, description: 'Product updated successfully' })
  async updateProduct(@CurrentUser() user: User, @Param('id') id: string, @Body() updateDto: UpdateProductDto) {
    return this.productsService.updateProduct(user, id, updateDto);
  }

  @Delete(':id')
  @ApiOperation({ summary: 'Delete product' })
  @ApiParam({ name: 'id' })
  @ApiResponse({ status: 200, description: 'Product deleted successfully' })
  async deleteProduct(@CurrentUser() user: User, @Param('id') id: string) {
    return this.productsService.deleteProduct(user, id);
  }

  @Get('search')
  @ApiOperation({ summary: 'Search products' })
  @ApiQuery({ name: 'q', description: 'Search query' })
  @ApiResponse({ status: 200, description: 'Products searched successfully' })
  async searchProducts(@CurrentUser() user: User, @Query('q') query: string) {
    return this.productsService.searchProducts(user, query);
  }

  @Get('featured')
  @ApiOperation({ summary: 'Get featured products' })
  @ApiResponse({ status: 200, description: 'Featured products fetched successfully' })
  async getFeaturedProducts(@CurrentUser() user: User) {
    return this.productsService.getFeaturedProducts(user);
  }

  @Get('recent')
  @ApiOperation({ summary: 'Get recent products' })
  @ApiResponse({ status: 200, description: 'Recent products fetched successfully' })
  async getRecentProducts(@CurrentUser() user: User) {
    return this.productsService.getRecentProducts(user);
  }
}

