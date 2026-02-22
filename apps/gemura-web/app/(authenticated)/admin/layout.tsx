'use client';

import { useEffect } from 'react';
import { useRouter } from 'next/navigation';
import { useAuthStore } from '@/store/auth';
import { isAdminAccount } from '@/lib/config/nav.config';

/**
 * Protects /admin/* routes: only current account with account_type === 'admin' can access.
 * Others are redirected to /dashboard.
 */
export default function AdminLayout({
  children,
}: {
  children: React.ReactNode;
}) {
  const router = useRouter();
  const { currentAccount } = useAuthStore();
  const accountType = currentAccount?.account_type ?? '';

  useEffect(() => {
    if (!isAdminAccount(accountType)) {
      router.replace('/dashboard');
    }
    // Only re-run when account type changes; router is stable in behavior
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [accountType]);

  if (!isAdminAccount(accountType)) {
    return (
      <div className="flex items-center justify-center p-8">
        <p className="text-gray-500">Redirecting...</p>
      </div>
    );
  }

  return <>{children}</>;
}
