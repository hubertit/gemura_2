import { Injectable, BadRequestException, NotFoundException } from '@nestjs/common';
import { PrismaService } from '../../../prisma/prisma.service';
import { User } from '@prisma/client';
import { CreateCategoryDto } from './dto/create-category.dto';
import { UpdateCategoryDto } from './dto/update-category.dto';

@Injectable()
export class CategoriesService {
  constructor(private prisma: PrismaService) {}

  async createCategory(user: User, createDto: CreateCategoryDto) {
    const category = await this.prisma.category.create({
      data: {
        name: createDto.name,
        description: createDto.description,
      },
    });

    return {
      code: 200,
      status: 'success',
      message: 'Category created successfully.',
      data: category,
    };
  }

  async getCategories(user: User) {
    const categories = await this.prisma.category.findMany({
      orderBy: { name: 'asc' },
    });

    return {
      code: 200,
      status: 'success',
      message: 'Categories fetched successfully.',
      data: categories,
    };
  }

  async getCategory(user: User, categoryId: string) {
    const category = await this.prisma.category.findUnique({
      where: { id: categoryId },
      include: {
        products: {
          include: {
            product: {
              include: {
                images: { where: { is_primary: true }, take: 1 },
              },
            },
          },
        },
      },
    });

    if (!category) {
      throw new NotFoundException({
        code: 404,
        status: 'error',
        message: 'Category not found.',
      });
    }

    return {
      code: 200,
      status: 'success',
      message: 'Category fetched successfully.',
      data: {
        ...category,
        products: category.products.map((p) => ({
          id: p.product.id,
          name: p.product.name,
          price: Number(p.product.price),
          image: p.product.images[0]?.image_url || null,
        })),
      },
    };
  }

  async updateCategory(user: User, categoryId: string, updateDto: UpdateCategoryDto) {
    const category = await this.prisma.category.findUnique({ where: { id: categoryId } });
    if (!category) {
      throw new NotFoundException({
        code: 404,
        status: 'error',
        message: 'Category not found.',
      });
    }

    const updated = await this.prisma.category.update({
      where: { id: categoryId },
      data: {
        name: updateDto.name || category.name,
        description: updateDto.description !== undefined ? updateDto.description : category.description,
      },
    });

    return {
      code: 200,
      status: 'success',
      message: 'Category updated successfully.',
      data: updated,
    };
  }

  async deleteCategory(user: User, categoryId: string) {
    const category = await this.prisma.category.findUnique({ where: { id: categoryId } });
    if (!category) {
      throw new NotFoundException({
        code: 404,
        status: 'error',
        message: 'Category not found.',
      });
    }

    await this.prisma.category.delete({ where: { id: categoryId } });

    return {
      code: 200,
      status: 'success',
      message: 'Category deleted successfully.',
    };
  }
}

