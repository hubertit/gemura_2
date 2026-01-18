import { Injectable, BadRequestException, NotFoundException, ForbiddenException } from '@nestjs/common';
import { PrismaService } from '../../prisma/prisma.service';
import { User } from '@prisma/client';
import { CreateEmployeeDto } from './dto/create-employee.dto';
import { UpdateEmployeeDto } from './dto/update-employee.dto';

@Injectable()
export class EmployeesService {
  constructor(private prisma: PrismaService) {}

  async createEmployee(user: User, createDto: CreateEmployeeDto) {
    if (!user.default_account_id) {
      throw new BadRequestException({
        code: 400,
        status: 'error',
        message: 'No valid default account found. Please set a default account.',
      });
    }

    const accountId = createDto.account_id || user.default_account_id;

    // Check if user has permission to add employees (must be owner or admin)
    const userAccount = await this.prisma.userAccount.findFirst({
      where: {
        user_id: user.id,
        account_id: accountId,
        role: { in: ['owner', 'admin'] },
        status: 'active',
      },
    });

    if (!userAccount) {
      throw new ForbiddenException({
        code: 403,
        status: 'error',
        message: 'You do not have permission to add employees to this account.',
      });
    }

    // Check if employee already exists
    const existing = await this.prisma.userAccount.findFirst({
      where: {
        user_id: createDto.user_id,
        account_id: accountId,
      },
    });

    if (existing) {
      throw new BadRequestException({
        code: 400,
        status: 'error',
        message: 'User is already an employee of this account.',
      });
    }

    const employee = await this.prisma.userAccount.create({
      data: {
        user_id: createDto.user_id,
        account_id: accountId,
        role: createDto.role as any,
        permissions: createDto.permissions ? JSON.stringify(createDto.permissions) : null,
        status: 'active',
        created_by: user.id,
      },
      include: {
        user: {
          select: {
            id: true,
            name: true,
            email: true,
            phone: true,
          },
        },
        account: {
          select: {
            id: true,
            code: true,
            name: true,
          },
        },
      },
    });

    return {
      code: 200,
      status: 'success',
      message: 'Employee added successfully.',
      data: {
        id: employee.id,
        user: employee.user,
        account: employee.account,
        role: employee.role,
        permissions: employee.permissions || null,
        status: employee.status,
      },
    };
  }

  async getEmployees(user: User) {
    if (!user.default_account_id) {
      throw new BadRequestException({
        code: 400,
        status: 'error',
        message: 'No valid default account found. Please set a default account.',
      });
    }

    const employees = await this.prisma.userAccount.findMany({
      where: {
        account_id: user.default_account_id,
        status: 'active',
      },
      include: {
        user: {
          select: {
            id: true,
            name: true,
            email: true,
            phone: true,
            account_type: true,
          },
        },
      },
      orderBy: {
        created_at: 'desc',
      },
    });

    return {
      code: 200,
      status: 'success',
      message: 'Employees fetched successfully.',
      data: employees.map((e) => ({
        id: e.id,
        user: e.user,
        role: e.role,
        permissions: e.permissions || null,
        status: e.status,
        created_at: e.created_at,
      })),
    };
  }

  async updateEmployee(user: User, employeeId: string, updateDto: UpdateEmployeeDto) {
    if (!user.default_account_id) {
      throw new BadRequestException({
        code: 400,
        status: 'error',
        message: 'No valid default account found.',
      });
    }

    const employee = await this.prisma.userAccount.findFirst({
      where: {
        id: employeeId,
        account_id: user.default_account_id,
      },
    });

    if (!employee) {
      throw new NotFoundException({
        code: 404,
        status: 'error',
        message: 'Employee not found.',
      });
    }

    // Check permissions
    const userAccount = await this.prisma.userAccount.findFirst({
      where: {
        user_id: user.id,
        account_id: user.default_account_id,
        role: { in: ['owner', 'admin'] },
      },
    });

    if (!userAccount) {
      throw new ForbiddenException({
        code: 403,
        status: 'error',
        message: 'You do not have permission to update employees.',
      });
    }

    const updateData: any = { updated_by: user.id };
    if (updateDto.role) updateData.role = updateDto.role as any;
    if (updateDto.permissions) updateData.permissions = JSON.stringify(updateDto.permissions);
    if (updateDto.status) updateData.status = updateDto.status as any;

    const updated = await this.prisma.userAccount.update({
      where: { id: employeeId },
      data: updateData,
      include: {
        user: {
          select: {
            id: true,
            name: true,
            email: true,
            phone: true,
          },
        },
      },
    });

    return {
      code: 200,
      status: 'success',
      message: 'Employee updated successfully.',
      data: {
        id: updated.id,
        user: updated.user,
        role: updated.role,
        permissions: updated.permissions || null,
        status: updated.status,
      },
    };
  }

  async deleteEmployee(user: User, employeeId: string) {
    if (!user.default_account_id) {
      throw new BadRequestException({
        code: 400,
        status: 'error',
        message: 'No valid default account found.',
      });
    }

    const employee = await this.prisma.userAccount.findFirst({
      where: {
        id: employeeId,
        account_id: user.default_account_id,
      },
    });

    if (!employee) {
      throw new NotFoundException({
        code: 404,
        status: 'error',
        message: 'Employee not found.',
      });
    }

    // Check permissions
    const userAccount = await this.prisma.userAccount.findFirst({
      where: {
        user_id: user.id,
        account_id: user.default_account_id,
        role: { in: ['owner', 'admin'] },
      },
    });

    if (!userAccount) {
      throw new ForbiddenException({
        code: 403,
        status: 'error',
        message: 'You do not have permission to remove employees.',
      });
    }

    // Soft delete by setting status to inactive
    await this.prisma.userAccount.update({
      where: { id: employeeId },
      data: {
        status: 'inactive',
        updated_by: user.id,
      },
    });

    return {
      code: 200,
      status: 'success',
      message: 'Employee removed successfully.',
    };
  }
}

