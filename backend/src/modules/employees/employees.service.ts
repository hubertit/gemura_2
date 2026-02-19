import { Injectable, BadRequestException, NotFoundException, ForbiddenException } from '@nestjs/common';
import { PrismaService } from '../../prisma/prisma.service';
import { User } from '@prisma/client';
import * as bcrypt from 'bcrypt';
import { CreateEmployeeDto } from './dto/create-employee.dto';
import { UpdateEmployeeDto } from './dto/update-employee.dto';
import { InviteEmployeeDto } from './dto/invite-employee.dto';
import {
  ROLES,
  ROLE_LABELS,
  ROLE_DESCRIPTIONS,
  ROLE_DEFAULT_PERMISSIONS,
  PERMISSIONS,
  type RoleCode,
} from '../admin/roles-permissions.config';

@Injectable()
export class EmployeesService {
  constructor(private prisma: PrismaService) {}

  /** Resolve account ID and ensure current user can manage it (owner, admin, or manager). */
  private async ensureCanManageAccount(user: User, accountId?: string | null): Promise<string> {
    const resolved = accountId || user.default_account_id;
    if (!resolved) {
      throw new BadRequestException({
        code: 400,
        status: 'error',
        message: 'No valid default account found. Please set a default account.',
      });
    }
    const userAccount = await this.prisma.userAccount.findFirst({
      where: {
        user_id: user.id,
        account_id: resolved,
        role: { in: ['owner', 'admin', 'manager'] },
        status: 'active',
      },
    });
    if (!userAccount) {
      throw new ForbiddenException({
        code: 403,
        status: 'error',
        message: 'You do not have permission to manage this account.',
      });
    }
    return resolved;
  }

  async createEmployee(user: User, createDto: CreateEmployeeDto) {
    const accountId = await this.ensureCanManageAccount(user, createDto.account_id);

    // Check if employee already exists
    const existing = await this.prisma.userAccount.findFirst({
      where: {
        user_id: user.id,
        account_id: accountId,
        role: { in: ['owner', 'admin'] },
        status: 'active',
      },
    });

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

  async getEmployees(user: User, accountId?: string | null, status?: 'active' | 'inactive') {
    const resolvedAccountId = await this.ensureCanManageAccount(user, accountId);

    const where: { account_id: string; status?: string } = {
      account_id: resolvedAccountId,
    };
    if (status === 'active' || status === 'inactive') {
      where.status = status;
    }

    const employees = await this.prisma.userAccount.findMany({
      where,
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

  async updateEmployee(user: User, employeeId: string, updateDto: UpdateEmployeeDto, accountId?: string | null) {
    const resolvedAccountId = await this.ensureCanManageAccount(user, accountId);

    const employee = await this.prisma.userAccount.findFirst({
      where: {
        id: employeeId,
        account_id: resolvedAccountId,
      },
    });

    if (!employee) {
      throw new NotFoundException({
        code: 404,
        status: 'error',
        message: 'Employee not found.',
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

  async deleteEmployee(user: User, employeeId: string, accountId?: string | null) {
    const resolvedAccountId = await this.ensureCanManageAccount(user, accountId);

    const employee = await this.prisma.userAccount.findFirst({
      where: {
        id: employeeId,
        account_id: resolvedAccountId,
      },
    });

    if (!employee) {
      throw new NotFoundException({
        code: 404,
        status: 'error',
        message: 'Employee not found.',
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

  /** Add a user to the account by email/phone: create user if they have no account, then add to account. */
  async inviteEmployee(user: User, dto: InviteEmployeeDto) {
    const accountId = await this.ensureCanManageAccount(user, dto.account_id);

    if (!dto.email?.trim() && !dto.phone?.trim()) {
      throw new BadRequestException({
        code: 400,
        status: 'error',
        message: 'Email or phone is required.',
      });
    }

    const normalizedEmail = dto.email?.trim().toLowerCase();
    const normalizedPhone = dto.phone?.trim();

    let targetUser: User | null = null;
    if (normalizedEmail) {
      targetUser = await this.prisma.user.findFirst({
        where: { email: normalizedEmail },
      });
    }
    if (!targetUser && normalizedPhone) {
      targetUser = await this.prisma.user.findFirst({
        where: { phone: normalizedPhone },
      });
    }

    if (targetUser) {
      const existing = await this.prisma.userAccount.findFirst({
        where: {
          user_id: targetUser.id,
          account_id: accountId,
        },
      });
      if (existing) {
        throw new BadRequestException({
          code: 400,
          status: 'error',
          message: 'This user already has access to this account.',
        });
      }
    } else {
      if (!dto.password?.trim() || dto.password.length < 6) {
        throw new BadRequestException({
          code: 400,
          status: 'error',
          message: 'Password is required for new users (at least 6 characters). This person does not have an account yet.',
        });
      }
      const hashedPassword = await bcrypt.hash(dto.password, 10);
      targetUser = await this.prisma.user.create({
        data: {
          name: dto.name.trim(),
          email: normalizedEmail || null,
          phone: normalizedPhone || null,
          password_hash: hashedPassword,
          account_type: 'mcc',
          status: 'active',
          default_account_id: accountId,
          created_by: user.id,
        },
      });
    }

    const employee = await this.prisma.userAccount.create({
      data: {
        user_id: targetUser!.id,
        account_id: accountId,
        role: dto.role as any,
        permissions: dto.permissions?.length ? JSON.stringify(dto.permissions) : null,
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
      code: 201,
      status: 'success',
      message: 'Team member added successfully.',
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

  async getRoles(user: User, accountId?: string | null) {
    await this.ensureCanManageAccount(user, accountId);
    const roles = ROLES.filter((r) => r !== 'supplier' && r !== 'customer').map((role) => ({
      code: role,
      name: ROLE_LABELS[role as RoleCode],
      description: ROLE_DESCRIPTIONS[role as RoleCode],
      permissions: ROLE_DEFAULT_PERMISSIONS[role as RoleCode],
      permissionCount: ROLE_DEFAULT_PERMISSIONS[role as RoleCode].length,
    }));
    return {
      code: 200,
      status: 'success',
      message: 'Roles retrieved successfully.',
      data: { roles },
    };
  }

  async getPermissions(user: User, accountId?: string | null) {
    await this.ensureCanManageAccount(user, accountId);
    const businessRoles = ROLES.filter((r) => r !== 'supplier' && r !== 'customer');
    const permissions = PERMISSIONS.map((perm) => {
      const rolesWithPermission = businessRoles.filter((role) =>
        ROLE_DEFAULT_PERMISSIONS[role as RoleCode].includes(perm.code),
      );
      return {
        code: perm.code,
        name: perm.name,
        description: perm.description,
        category: perm.category,
        roles: rolesWithPermission.map((r) => ({
          code: r,
          name: ROLE_LABELS[r as RoleCode],
        })),
      };
    });
    return {
      code: 200,
      status: 'success',
      message: 'Permissions retrieved successfully.',
      data: { permissions },
    };
  }
}

