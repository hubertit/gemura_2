'use client';

import { useEffect } from 'react';
import { useRouter, usePathname } from 'next/navigation';
import { useAuthStore } from '@/store/auth';
import { usePermission } from '@/hooks/usePermission';
import {
  isAdminRole,
  isBusinessAccount,
  isExternalSupplier,
  isExternalCustomer,
} from '@/lib/config/nav.config';

/** Path -> required permission (admin bypasses) */
const OPERATIONS_PATH_PERMISSION: Record<string, string> = {
  '/sales': 'view_sales',
  '/collections': 'view_collections',
  '/suppliers': 'view_suppliers',
  '/customers': 'view_customers',
  '/inventory': 'view_inventory',
  '/analytics': 'view_analytics',
};

/**
 * Redirects user if they hit an operations path without permission.
 * Admin routes are protected by (authenticated)/admin/layout.tsx.
 */
export default function RouteGuard({ children }: { children: React.ReactNode }) {
  const router = useRouter();
  const pathname = usePathname();
  const { currentAccount } = useAuthStore();
  const { hasPermission } = usePermission();
  const role = currentAccount?.role ?? '';
  const accountType = currentAccount?.account_type ?? '';

  useEffect(() => {
    if (!pathname) return;

    const pathKey = Object.keys(OPERATIONS_PATH_PERMISSION).find((p) => pathname === p || pathname.startsWith(p + '/'));
    const requiredPermission = pathKey ? OPERATIONS_PATH_PERMISSION[pathKey] : null;
    if (!requiredPermission) return;

    // Admin can access everything (admin layout handles /admin/*)
    if (isAdminRole(role) && isBusinessAccount(accountType)) return;

    // External users should not access operations paths at all
    if (isExternalSupplier(accountType) || isExternalCustomer(accountType)) {
      router.replace('/dashboard');
      return;
    }

    // Business account but no permission for this path
    if (isBusinessAccount(accountType) && !hasPermission(requiredPermission)) {
      router.replace('/dashboard');
    }
  }, [pathname, role, accountType, hasPermission, router]);

  return <>{children}</>;
}
