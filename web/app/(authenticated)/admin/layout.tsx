'use client';

import { useEffect } from 'react';
import { useRouter } from 'next/navigation';
import { useAuthStore } from '@/store/auth';
import { isAdminRole, isBusinessAccount } from '@/lib/config/nav.config';

/**
 * Protects /admin/* routes: only admin roles on business accounts can access.
 * Others are redirected to /dashboard.
 */
export default function AdminLayout({
  children,
}: {
  children: React.ReactNode;
}) {
  const router = useRouter();
  const { currentAccount } = useAuthStore();
  const role = currentAccount?.role ?? '';
  const accountType = currentAccount?.account_type ?? '';

  useEffect(() => {
    const allowed = isAdminRole(role) && isBusinessAccount(accountType);
    if (!allowed) {
      router.replace('/dashboard');
    }
  }, [role, accountType, router]);

  const allowed = isAdminRole(role) && isBusinessAccount(accountType);
  if (!allowed) {
    return (
      <div className="flex items-center justify-center p-8">
        <p className="text-gray-500">Redirecting...</p>
      </div>
    );
  }

  return <>{children}</>;
}
