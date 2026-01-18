import { Injectable, BadRequestException, NotFoundException } from '@nestjs/common';
import { PrismaService } from '../../../prisma/prisma.service';
import { User } from '@prisma/client';
import { CreateProductDto } from './dto/create-product.dto';
import { UpdateProductDto } from './dto/update-product.dto';

@Injectable()
export class ProductsService {
  constructor(private prisma: PrismaService) {}

  async createProduct(user: User, createDto: CreateProductDto) {
    const product = await this.prisma.product.create({
      data: {
        name: createDto.name,
        description: createDto.description,
        price: createDto.price,
        stock_quantity: createDto.stock_quantity || 0,
        status: 'active',
        created_by: user.id,
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
      message: 'Product created successfully.',
      data: { id: product.id, ...product, price: Number(product.price) },
    };
  }

  async getProducts(user: User, filters?: any) {
    const products = await this.prisma.product.findMany({
      where: {
        status: filters?.status || 'active',
      },
      include: {
        categories: { include: { category: true } },
        images: { where: { is_primary: true }, take: 1 },
      },
      orderBy: { created_at: 'desc' },
      take: filters?.limit || 100,
    });

    return {
      code: 200,
      status: 'success',
      message: 'Products fetched successfully.',
      data: products.map((p) => ({
        id: p.id,
        name: p.name,
        description: p.description,
        price: Number(p.price),
        stock_quantity: p.stock_quantity,
        status: p.status,
        categories: p.categories.map((c) => c.category),
        image: p.images[0]?.image_url || null,
      })),
    };
  }

  async getProduct(user: User, productId: string) {
    const product = await this.prisma.product.findUnique({
      where: { id: productId },
      include: {
        categories: { include: { category: true } },
        images: { orderBy: { sort_order: 'asc' } },
      },
    });

    if (!product) {
      throw new NotFoundException({
        code: 404,
        status: 'error',
        message: 'Product not found.',
      });
    }

    return {
      code: 200,
      status: 'success',
      message: 'Product fetched successfully.',
      data: {
        id: product.id,
        name: product.name,
        description: product.description,
        price: Number(product.price),
        stock_quantity: product.stock_quantity,
        status: product.status,
        categories: product.categories.map((c) => c.category),
        images: product.images.map((i) => ({
          id: i.id,
          image_url: i.image_url,
          is_primary: i.is_primary,
        })),
      },
    };
  }

  async updateProduct(user: User, productId: string, updateDto: UpdateProductDto) {
    const product = await this.prisma.product.findUnique({ where: { id: productId } });
    if (!product) {
      throw new NotFoundException({
        code: 404,
        status: 'error',
        message: 'Product not found.',
      });
    }

    const updateData: any = { updated_by: user.id };
    if (updateDto.name) updateData.name = updateDto.name;
    if (updateDto.description !== undefined) updateData.description = updateDto.description;
    if (updateDto.price !== undefined) updateData.price = updateDto.price;
    if (updateDto.stock_quantity !== undefined) updateData.stock_quantity = updateDto.stock_quantity;
    if (updateDto.status) updateData.status = updateDto.status as any;

    const updated = await this.prisma.product.update({
      where: { id: productId },
      data: updateData,
    });

    // Update categories if provided
    if (updateDto.category_ids) {
      await this.prisma.productCategory.deleteMany({ where: { product_id: productId } });
      await Promise.all(
        updateDto.category_ids.map((catId) =>
          this.prisma.productCategory.create({
            data: { product_id: productId, category_id: catId },
          }),
        ),
      );
    }

    return {
      code: 200,
      status: 'success',
      message: 'Product updated successfully.',
      data: { id: updated.id, ...updated, price: Number(updated.price) },
    };
  }

  async deleteProduct(user: User, productId: string) {
    const product = await this.prisma.product.findUnique({ where: { id: productId } });
    if (!product) {
      throw new NotFoundException({
        code: 404,
        status: 'error',
        message: 'Product not found.',
      });
    }

    await this.prisma.product.update({
      where: { id: productId },
      data: { status: 'inactive', updated_by: user.id },
    });

    return {
      code: 200,
      status: 'success',
      message: 'Product deleted successfully.',
    };
  }

  async searchProducts(user: User, query: string) {
    const products = await this.prisma.product.findMany({
      where: {
        status: 'active',
        OR: [
          { name: { contains: query, mode: 'insensitive' } },
          { description: { contains: query, mode: 'insensitive' } },
        ],
      },
      include: {
        categories: { include: { category: true } },
        images: { where: { is_primary: true }, take: 1 },
      },
      take: 50,
    });

    return {
      code: 200,
      status: 'success',
      message: 'Products searched successfully.',
      data: products.map((p) => ({
        id: p.id,
        name: p.name,
        price: Number(p.price),
        image: p.images[0]?.image_url || null,
      })),
    };
  }

  async getFeaturedProducts(user: User) {
    const products = await this.prisma.product.findMany({
      where: { status: 'active' },
      include: {
        categories: { include: { category: true } },
        images: { where: { is_primary: true }, take: 1 },
      },
      orderBy: { created_at: 'desc' },
      take: 10,
    });

    return {
      code: 200,
      status: 'success',
      message: 'Featured products fetched successfully.',
      data: products.map((p) => ({
        id: p.id,
        name: p.name,
        price: Number(p.price),
        image: p.images[0]?.image_url || null,
      })),
    };
  }

  async getRecentProducts(user: User) {
    const products = await this.prisma.product.findMany({
      where: { status: 'active' },
      include: {
        categories: { include: { category: true } },
        images: { where: { is_primary: true }, take: 1 },
      },
      orderBy: { created_at: 'desc' },
      take: 20,
    });

    return {
      code: 200,
      status: 'success',
      message: 'Recent products fetched successfully.',
      data: products.map((p) => ({
        id: p.id,
        name: p.name,
        price: Number(p.price),
        image: p.images[0]?.image_url || null,
      })),
    };
  }
}

