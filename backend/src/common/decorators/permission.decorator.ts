import { SetMetadata } from '@nestjs/common';

export const PERMISSION_KEY = 'permission';
export const ROLE_KEY = 'role';

/**
 * Require a specific permission to access the endpoint
 * @param permission Permission code (e.g., 'manage_users', 'view_sales')
 */
export const RequirePermission = (permission: string) => SetMetadata(PERMISSION_KEY, permission);

/**
 * Require a specific role to access the endpoint
 * @param role Role name (e.g., 'admin', 'manager')
 */
export const RequireRole = (role: string) => SetMetadata(ROLE_KEY, role);
