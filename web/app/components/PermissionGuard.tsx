'use client';

import { useEffect } from 'react';
import { useRouter } from 'next/navigation';
import { usePermission } from '@/hooks/usePermission';

interface PermissionGuardProps {
  children: React.ReactNode;
  requiredPermission?: string | (() => boolean);
  requiredRole?: string;
  requireAdmin?: boolean;
  requireManageUsers?: boolean;
  requireViewDashboard?: boolean;
  redirectTo?: string;
  fallback?: React.ReactNode;
}

/**
 * PermissionGuard component that protects routes based on permissions
 * 
 * @example
 * <PermissionGuard requireAdmin>
 *   <AdminContent />
 * </PermissionGuard>
 * 
 * @example
 * <PermissionGuard requiredPermission="manage_users">
 *   <UserManagement />
 * </PermissionGuard>
 */
export default function PermissionGuard({
  children,
  requiredPermission,
  requiredRole,
  requireAdmin = false,
  requireManageUsers = false,
  requireViewDashboard = false,
  redirectTo = '/dashboard',
  fallback = null,
}: PermissionGuardProps) {
  const router = useRouter();
  const {
    hasPermission,
    hasRole,
    isAdmin,
    canManageUsers,
    canViewDashboard,
  } = usePermission();

  useEffect(() => {
    let hasAccess = true;

    // Check admin requirement
    if (requireAdmin && !isAdmin()) {
      hasAccess = false;
    }

    // Check manage users requirement
    if (requireManageUsers && !canManageUsers() && !isAdmin()) {
      hasAccess = false;
    }

    // Check view dashboard requirement
    if (requireViewDashboard && !canViewDashboard() && !isAdmin()) {
      hasAccess = false;
    }

    // Check role requirement
    if (requiredRole && !hasRole(requiredRole) && !isAdmin()) {
      hasAccess = false;
    }

    // Check permission requirement
    if (requiredPermission) {
      if (typeof requiredPermission === 'function') {
        if (!requiredPermission() && !isAdmin()) {
          hasAccess = false;
        }
      } else {
        if (!hasPermission(requiredPermission) && !isAdmin()) {
          hasAccess = false;
        }
      }
    }

    if (!hasAccess) {
      router.push(redirectTo);
    }
  }, [
    router,
    redirectTo,
    requiredPermission,
    requiredRole,
    requireAdmin,
    requireManageUsers,
    requireViewDashboard,
    hasPermission,
    hasRole,
    isAdmin,
    canManageUsers,
    canViewDashboard,
  ]);

  // Check if user has access (client-side check)
  let hasAccess = true;

  if (requireAdmin && !isAdmin()) {
    hasAccess = false;
  }

  if (requireManageUsers && !canManageUsers() && !isAdmin()) {
    hasAccess = false;
  }

  if (requireViewDashboard && !canViewDashboard() && !isAdmin()) {
    hasAccess = false;
  }

  if (requiredRole && !hasRole(requiredRole) && !isAdmin()) {
    hasAccess = false;
  }

  if (requiredPermission) {
    if (typeof requiredPermission === 'function') {
      if (!requiredPermission() && !isAdmin()) {
        hasAccess = false;
      }
    } else {
      if (!hasPermission(requiredPermission) && !isAdmin()) {
        hasAccess = false;
      }
    }
  }

  if (!hasAccess) {
    return fallback as React.ReactElement;
  }

  return <>{children}</>;
}
