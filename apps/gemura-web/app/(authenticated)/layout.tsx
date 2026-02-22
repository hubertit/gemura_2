'use client';

import { useState, useEffect, useCallback } from 'react';
import { useRouter } from 'next/navigation';
import { useAuthStore, useAuthHydrated } from '@/store/auth';
import Sidebar from '@/app/components/Sidebar';
import Header from '@/app/components/Header';
import { ErrorBoundary } from '@/app/components/ErrorBoundary';
import Toast from '@/app/components/Toast';
import RouteGuard from '@/app/components/RouteGuard';

export default function AuthenticatedLayout({
  children,
}: {
  children: React.ReactNode;
}) {
  const router = useRouter();
  const { isAuthenticated, user } = useAuthStore();
  const hasHydrated = useAuthHydrated();
  const [sidebarOpen, setSidebarOpen] = useState(false);
  const [sidebarCollapsed, setSidebarCollapsed] = useState(false);

  useEffect(() => {
    // Load sidebar collapsed state from localStorage
    if (typeof window !== 'undefined') {
      const saved = localStorage.getItem('gemuraSidebarCollapsed');
      if (saved === 'true') {
        setSidebarCollapsed(true);
      }
    }
  }, []);

  useEffect(() => {
    // Wait for auth state to hydrate before checking authentication
    if (!hasHydrated) return;

    // Redirect if not authenticated
    if (!isAuthenticated || !user) {
      router.push('/auth/login');
      return;
    }
  }, [hasHydrated, isAuthenticated, user, router]);

  const handleSidebarClose = useCallback(() => {
    setSidebarOpen(false);
  }, []);

  const handleSidebarToggle = useCallback(() => {
    setSidebarOpen(prev => !prev);
  }, []);

  const handleSidebarCollapsedChange = useCallback((collapsed: boolean) => {
    setSidebarCollapsed(collapsed);
    if (typeof window !== 'undefined') {
      localStorage.setItem('gemuraSidebarCollapsed', collapsed.toString());
    }
  }, []);

  // Show loading state while hydrating
  if (!hasHydrated) {
    return (
      <div className="min-h-screen flex items-center justify-center bg-gray-100">
        <div className="text-center">
          <div className="w-16 h-16 bg-[var(--primary)] rounded-full flex items-center justify-center mx-auto mb-4 animate-spin">
            <span className="text-white font-bold text-2xl">G</span>
          </div>
          <p className="text-gray-600">Loading...</p>
        </div>
      </div>
    );
  }

  if (!isAuthenticated || !user) {
    return null;
  }

  return (
    <ErrorBoundary>
      <div className="flex h-screen bg-gray-100 overflow-hidden">
        <Sidebar
          isOpen={sidebarOpen}
          collapsed={sidebarCollapsed}
          onClose={handleSidebarClose}
          onCollapsedChange={handleSidebarCollapsedChange}
        />
        <div className={`flex-1 flex flex-col transition-all duration-300 ${sidebarCollapsed ? 'lg:ml-20' : 'lg:ml-64'}`}>
          <Header
            sidebarOpen={sidebarOpen}
            sidebarCollapsed={sidebarCollapsed}
            onMenuToggle={handleSidebarToggle}
          />
          <main className="flex-1 overflow-y-auto p-6">
            <RouteGuard>{children}</RouteGuard>
          </main>
          <Toast />
        </div>
      </div>
    </ErrorBoundary>
  );
}
