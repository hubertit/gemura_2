import { Injectable, BadRequestException, NotFoundException, ForbiddenException } from '@nestjs/common';
import { PrismaService } from '../../prisma/prisma.service';
import { User } from '@prisma/client';
import { CreateUserDto } from './dto/create-user.dto';
import { UpdateUserDto } from './dto/update-user.dto';
import * as bcrypt from 'bcrypt';

@Injectable()
export class AdminService {
  constructor(private prisma: PrismaService) {}

  /**
   * Check if user has admin permission
   */
  private async checkAdminPermission(user: User, accountId: string): Promise<void> {
    const userAccount = await this.prisma.userAccount.findFirst({
      where: {
        user_id: user.id,
        account_id: accountId,
        status: 'active',
      },
    });

    if (!userAccount) {
      throw new ForbiddenException({
        code: 403,
        status: 'error',
        message: 'No active account access found.',
      });
    }

    // Owner and admin have all permissions
    if (userAccount.role === 'owner' || userAccount.role === 'admin') {
      return;
    }

    // Check for manage_users permission
    let permissions: any = null;
    if (userAccount.permissions) {
      if (typeof userAccount.permissions === 'string') {
        try {
          permissions = JSON.parse(userAccount.permissions);
        } catch {
          permissions = null;
        }
      } else {
        permissions = userAccount.permissions;
      }
    }

    if (!permissions) {
      throw new ForbiddenException({
        code: 403,
        status: 'error',
        message: 'Insufficient permissions to manage users.',
      });
    }

    let hasPermission = false;
    if (Array.isArray(permissions)) {
      hasPermission = permissions.includes('manage_users');
    } else if (typeof permissions === 'object') {
      hasPermission = permissions['manage_users'] === true;
    }

    if (!hasPermission) {
      throw new ForbiddenException({
        code: 403,
        status: 'error',
        message: 'Insufficient permissions to manage users.',
      });
    }
  }

  /**
   * Get all users with pagination and filters
   */
  async getUsers(user: User, accountId: string, page: number = 1, limit: number = 20, search?: string) {
    await this.checkAdminPermission(user, accountId);

    const skip = (page - 1) * limit;

    const where: any = {};

    if (search) {
      where.OR = [
        { name: { contains: search, mode: 'insensitive' } },
        { email: { contains: search, mode: 'insensitive' } },
        { phone: { contains: search, mode: 'insensitive' } },
      ];
    }

    const [users, total] = await Promise.all([
      this.prisma.user.findMany({
        where,
        skip,
        take: limit,
        orderBy: { created_at: 'desc' },
        select: {
          id: true,
          name: true,
          email: true,
          phone: true,
          status: true,
          account_type: true,
          created_at: true,
          last_login: true,
          user_accounts: {
            where: {
              account_id: accountId,
              status: 'active',
            },
            select: {
              role: true,
              permissions: true,
              status: true,
            },
          },
        },
      }),
      this.prisma.user.count({ where }),
    ]);

    return {
      code: 200,
      status: 'success',
      message: 'Users retrieved successfully.',
      data: {
        users: users.map((u) => ({
          ...u,
          role: u.user_accounts[0]?.role || null,
          permissions: u.user_accounts[0]?.permissions || null,
        })),
        pagination: {
          page,
          limit,
          total,
          totalPages: Math.ceil(total / limit),
        },
      },
    };
  }

  /**
   * Get user by ID
   */
  async getUserById(user: User, accountId: string, userId: string) {
    await this.checkAdminPermission(user, accountId);

    const targetUser = await this.prisma.user.findUnique({
      where: { id: userId },
      include: {
        user_accounts: {
          where: {
            account_id: accountId,
          },
          include: {
            account: {
              select: {
                id: true,
                code: true,
                name: true,
              },
            },
          },
        },
      },
    });

    if (!targetUser) {
      throw new NotFoundException({
        code: 404,
        status: 'error',
        message: 'User not found.',
      });
    }

    return {
      code: 200,
      status: 'success',
      message: 'User retrieved successfully.',
      data: targetUser,
    };
  }

  /**
   * Create new user
   */
  async createUser(user: User, accountId: string, createDto: CreateUserDto) {
    await this.checkAdminPermission(user, accountId);

    // Check if email or phone already exists
    if (createDto.email) {
      const existingEmail = await this.prisma.user.findFirst({
        where: { email: createDto.email.toLowerCase() },
      });
      if (existingEmail) {
        throw new BadRequestException({
          code: 400,
          status: 'error',
          message: 'Email already exists.',
        });
      }
    }

    if (createDto.phone) {
      const existingPhone = await this.prisma.user.findFirst({
        where: { phone: createDto.phone },
      });
      if (existingPhone) {
        throw new BadRequestException({
          code: 400,
          status: 'error',
          message: 'Phone number already exists.',
        });
      }
    }

    // Hash password
    const hashedPassword = await bcrypt.hash(createDto.password, 10);

    // Create user
    const newUser = await this.prisma.user.create({
      data: {
        name: createDto.name,
        email: createDto.email?.toLowerCase(),
        phone: createDto.phone,
        password_hash: hashedPassword,
        account_type: createDto.account_type || 'mcc',
        status: createDto.status || 'active',
        default_account_id: accountId,
        created_by: user.id,
      },
    });

    // Create user account access
    if (createDto.role || createDto.permissions) {
      await this.prisma.userAccount.create({
        data: {
          user_id: newUser.id,
          account_id: accountId,
          role: createDto.role || 'viewer',
          permissions: createDto.permissions ? JSON.stringify(createDto.permissions) : null,
          status: 'active',
          created_by: user.id,
        },
      });
    }

    return {
      code: 201,
      status: 'success',
      message: 'User created successfully.',
      data: newUser,
    };
  }

  /**
   * Update user
   */
  async updateUser(user: User, accountId: string, userId: string, updateDto: UpdateUserDto) {
    await this.checkAdminPermission(user, accountId);

    const targetUser = await this.prisma.user.findUnique({
      where: { id: userId },
    });

    if (!targetUser) {
      throw new NotFoundException({
        code: 404,
        status: 'error',
        message: 'User not found.',
      });
    }

    // Check email uniqueness if updating
    if (updateDto.email && updateDto.email !== targetUser.email) {
      const existingEmail = await this.prisma.user.findFirst({
        where: { email: updateDto.email.toLowerCase() },
      });
      if (existingEmail) {
        throw new BadRequestException({
          code: 400,
          status: 'error',
          message: 'Email already exists.',
        });
      }
    }

    // Check phone uniqueness if updating
    if (updateDto.phone && updateDto.phone !== targetUser.phone) {
      const existingPhone = await this.prisma.user.findFirst({
        where: { phone: updateDto.phone },
      });
      if (existingPhone) {
        throw new BadRequestException({
          code: 400,
          status: 'error',
          message: 'Phone number already exists.',
        });
      }
    }

    // Hash password if provided
    const updateData: any = {
      ...updateDto,
      updated_by: user.id,
    };

    if (updateDto.password) {
      updateData.password_hash = await bcrypt.hash(updateDto.password, 10);
      delete updateData.password;
    }

    if (updateDto.email) {
      updateData.email = updateDto.email.toLowerCase();
    }

    const updatedUser = await this.prisma.user.update({
      where: { id: userId },
      data: updateData,
    });

    // Update user account access if role/permissions provided
    if (updateDto.role !== undefined || updateDto.permissions !== undefined) {
      const userAccount = await this.prisma.userAccount.findFirst({
        where: {
          user_id: userId,
          account_id: accountId,
        },
      });

      if (userAccount) {
        await this.prisma.userAccount.update({
          where: { id: userAccount.id },
          data: {
            role: updateDto.role || userAccount.role,
            permissions: updateDto.permissions ? JSON.stringify(updateDto.permissions) : userAccount.permissions,
            updated_by: user.id,
          },
        });
      } else if (updateDto.role || updateDto.permissions) {
        // Create new user account access
        await this.prisma.userAccount.create({
          data: {
            user_id: userId,
            account_id: accountId,
            role: updateDto.role || 'viewer',
            permissions: updateDto.permissions ? JSON.stringify(updateDto.permissions) : null,
            status: 'active',
            created_by: user.id,
          },
        });
      }
    }

    return {
      code: 200,
      status: 'success',
      message: 'User updated successfully.',
      data: updatedUser,
    };
  }

  /**
   * Delete user (soft delete by setting status to inactive)
   */
  async deleteUser(user: User, accountId: string, userId: string) {
    await this.checkAdminPermission(user, accountId);

    const targetUser = await this.prisma.user.findUnique({
      where: { id: userId },
    });

    if (!targetUser) {
      throw new NotFoundException({
        code: 404,
        status: 'error',
        message: 'User not found.',
      });
    }

    // Soft delete
    await this.prisma.user.update({
      where: { id: userId },
      data: {
        status: 'inactive',
        updated_by: user.id,
      },
    });

    return {
      code: 200,
      status: 'success',
      message: 'User deleted successfully.',
    };
  }

  /**
   * Get dashboard statistics with comprehensive metrics
   */
  async getDashboardStats(user: User, accountId: string) {
    await this.checkAdminPermission(user, accountId);

    // Get date ranges for trends
    const now = new Date();
    const last30Days = new Date(now.getTime() - 30 * 24 * 60 * 60 * 1000);
    const last7Days = new Date(now.getTime() - 7 * 24 * 60 * 60 * 1000);
    const today = new Date(now.setHours(0, 0, 0, 0));

    // Basic counts
    const [
      totalUsers,
      activeUsers,
      totalAccounts,
      totalSales,
      totalCollections,
      totalSuppliers,
      totalCustomers,
    ] = await Promise.all([
      this.prisma.user.count(),
      this.prisma.user.count({ where: { status: 'active' } }),
      this.prisma.account.count({ where: { status: 'active' } }),
      this.prisma.milkSale.count({ where: { status: 'accepted' } }),
      this.prisma.milkSale.count({ where: { status: 'accepted' } }),
      this.prisma.supplierCustomer.count({ where: { relationship_status: 'active' } }),
      this.prisma.supplierCustomer.count({ where: { relationship_status: 'active' } }),
    ]);

    // Get sales data for revenue calculations
    const allSales = await this.prisma.milkSale.findMany({
      where: {
        status: 'accepted',
      },
      select: {
        quantity: true,
        unit_price: true,
        sale_at: true,
      },
    });

    // Calculate revenue metrics
    const totalRevenue = allSales.reduce(
      (sum, sale) => sum + Number(sale.quantity) * Number(sale.unit_price),
      0,
    );

    const salesLast30Days = allSales.filter(
      (sale) => new Date(sale.sale_at) >= last30Days,
    );
    const revenueLast30Days = salesLast30Days.reduce(
      (sum, sale) => sum + Number(sale.quantity) * Number(sale.unit_price),
      0,
    );

    const salesLast7Days = allSales.filter(
      (sale) => new Date(sale.sale_at) >= last7Days,
    );
    const revenueLast7Days = salesLast7Days.reduce(
      (sum, sale) => sum + Number(sale.quantity) * Number(sale.unit_price),
      0,
    );

    const salesToday = allSales.filter(
      (sale) => new Date(sale.sale_at) >= today,
    );
    const revenueToday = salesToday.reduce(
      (sum, sale) => sum + Number(sale.quantity) * Number(sale.unit_price),
      0,
    );

    // Generate daily breakdown for last 30 days
    const dailyBreakdown = new Map<string, { date: string; revenue: number; sales: number }>();
    
    // Initialize last 30 days
    for (let i = 29; i >= 0; i--) {
      const date = new Date(now);
      date.setDate(date.getDate() - i);
      const dateStr = date.toISOString().split('T')[0];
      dailyBreakdown.set(dateStr, { date: dateStr, revenue: 0, sales: 0 });
    }

    // Populate with actual data
    allSales.forEach((sale) => {
      const dateStr = new Date(sale.sale_at).toISOString().split('T')[0];
      if (dailyBreakdown.has(dateStr)) {
        const dayData = dailyBreakdown.get(dateStr)!;
        dayData.revenue += Number(sale.quantity) * Number(sale.unit_price);
        dayData.sales += Number(sale.quantity);
      }
    });

    const dailyTrend = Array.from(dailyBreakdown.values()).map((day) => ({
      date: day.date,
      label: new Date(day.date).toLocaleDateString('en-US', { month: 'short', day: 'numeric' }),
      revenue: day.revenue,
      sales: day.sales,
    }));

    // Get sales by status
    const salesByStatus = await this.prisma.milkSale.groupBy({
      by: ['status'],
      _count: true,
    });

    // Get recent sales (last 10)
    const recentSales = await this.prisma.milkSale.findMany({
      where: {
        status: { not: 'deleted' },
      },
      take: 10,
      orderBy: { sale_at: 'desc' },
      select: {
        id: true,
        quantity: true,
        unit_price: true,
        status: true,
        sale_at: true,
        supplier_account: {
          select: { name: true },
        },
        customer_account: {
          select: { name: true },
        },
      },
    });

    return {
      code: 200,
      status: 'success',
      message: 'Dashboard statistics retrieved successfully.',
      data: {
        users: {
          total: totalUsers,
          active: activeUsers,
          inactive: totalUsers - activeUsers,
        },
        accounts: {
          total: totalAccounts,
        },
        sales: {
          total: totalSales,
          last30Days: salesLast30Days.length,
          last7Days: salesLast7Days.length,
          today: salesToday.length,
        },
        collections: {
          total: totalCollections,
        },
        suppliers: {
          total: totalSuppliers,
        },
        customers: {
          total: totalCustomers,
        },
        revenue: {
          total: totalRevenue,
          last30Days: revenueLast30Days,
          last7Days: revenueLast7Days,
          today: revenueToday,
        },
        trends: {
          daily: dailyTrend,
        },
        salesByStatus: salesByStatus.map((s) => ({
          status: s.status,
          count: s._count,
        })),
        recentSales: recentSales.map((sale) => ({
          id: sale.id,
          quantity: Number(sale.quantity),
          unitPrice: Number(sale.unit_price),
          total: Number(sale.quantity) * Number(sale.unit_price),
          status: sale.status,
          date: sale.sale_at.toISOString(),
          supplier: sale.supplier_account?.name || 'N/A',
          customer: sale.customer_account?.name || 'N/A',
        })),
      },
    };
  }
}
