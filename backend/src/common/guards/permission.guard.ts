import {
  Injectable,
  CanActivate,
  ExecutionContext,
  ForbiddenException,
} from '@nestjs/common';
import { PrismaService } from '../../prisma/prisma.service';
import { PERMISSION_KEY, ROLE_KEY } from '../decorators/permission.decorator';

@Injectable()
export class PermissionGuard implements CanActivate {
  constructor(private prisma: PrismaService) {}

  async canActivate(context: ExecutionContext): Promise<boolean> {
    const request = context.switchToHttp().getRequest();
    const user = request.user;

    if (!user) {
      throw new ForbiddenException({
        code: 403,
        status: 'error',
        message: 'User not authenticated.',
      });
    }

    // Get required permission from metadata (set by decorator)
    const requiredPermission = this.reflectPermission(context);
    const requiredRole = this.reflectRole(context);

    if (!requiredPermission && !requiredRole) {
      // No permission/role required, allow access
      return true;
    }

    // Get user's active account access
    const accountId = request.body?.account_id || request.query?.account_id || user.default_account_id;

    if (!accountId) {
      throw new ForbiddenException({
        code: 403,
        status: 'error',
        message: 'No account context found.',
      });
    }

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

    // Check role first
    if (requiredRole) {
      if (userAccount.role === requiredRole || userAccount.role === 'owner' || userAccount.role === 'admin') {
        // Owner and admin have all permissions
        if (userAccount.role === 'owner' || userAccount.role === 'admin') {
          return true;
        }
        // Check specific role
        if (userAccount.role === requiredRole) {
          return true;
        }
      }
    }

    // Check permission
    if (requiredPermission) {
      // Owner and admin have all permissions
      if (userAccount.role === 'owner' || userAccount.role === 'admin') {
        return true;
      }

      // Parse permissions
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
          message: 'No permissions found for this account.',
        });
      }

      // Check if permissions is array or object
      let hasPermission = false;
      if (Array.isArray(permissions)) {
        // Array format: ["manage_users", "view_sales"]
        hasPermission = permissions.includes(requiredPermission);
      } else if (typeof permissions === 'object') {
        // Object format: {"manage_users": true, "view_sales": true}
        hasPermission = permissions[requiredPermission] === true;
      }

      if (!hasPermission) {
        throw new ForbiddenException({
          code: 403,
          status: 'error',
          message: `Insufficient permissions. Required: ${requiredPermission}`,
        });
      }
    }

    return true;
  }

  private reflectPermission(context: ExecutionContext): string | undefined {
    // Get permission from handler metadata (set by @RequirePermission decorator)
    const handler = context.getHandler();
    return Reflect.getMetadata(PERMISSION_KEY, handler);
  }

  private reflectRole(context: ExecutionContext): string | undefined {
    // Get role from handler metadata (set by @RequireRole decorator)
    const handler = context.getHandler();
    return Reflect.getMetadata(ROLE_KEY, handler);
  }
}
