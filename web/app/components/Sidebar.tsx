'use client';

import { useState, useEffect, useCallback } from 'react';
import { usePathname, useRouter } from 'next/navigation';
import Link from 'next/link';
import { useAuthStore } from '@/store/auth';
import { usePermission } from '@/hooks/usePermission';
import Icon, {
  faHome,
  faUsers,
  faFileAlt,
  faCog,
  faUserShield,
  faBars,
  faChevronRight,
  faUser,
  faClipboardList,
  faCalendar,
  faDollarSign,
  faWarehouse,
  faShoppingCart,
  faBox,
  faChartBar,
  faReceipt,
  faBuilding,
  faStore,
} from './Icon';

interface SidebarProps {
  isOpen: boolean;
  collapsed: boolean;
  onClose: () => void;
  onCollapsedChange: (collapsed: boolean) => void;
}

interface MenuItem {
  icon: any;
  label: string;
  href?: string;
  roles?: string[];
  requiresPermission?: string;
}

export default function Sidebar({ isOpen, collapsed, onClose, onCollapsedChange }: SidebarProps) {
  const pathname = usePathname();
  const router = useRouter();
  const { user, currentAccount } = useAuthStore();
  const { canManageUsers, canViewDashboard, isAdmin, hasPermission } = usePermission();
  const [userName, setUserName] = useState('User');
  const [userEmail, setUserEmail] = useState('');
  const [userRole, setUserRole] = useState('User');

  useEffect(() => {
    if (user) {
      setUserName(`${user.firstName} ${user.lastName}`);
      setUserEmail(user.email);
      setUserRole(currentAccount?.role || 'User');
    }
  }, [user, currentAccount]);

  // All menu items with permission checks
  const allMenuItems: MenuItem[] = [
    {
      icon: faHome,
      label: 'Dashboard',
      href: isAdmin() || canViewDashboard() ? '/admin/dashboard' : '/dashboard',
      roles: ['admin', 'merchant', 'supplier', 'customer'],
    },
    {
      icon: faUsers,
      label: 'Users',
      href: '/admin/users',
      roles: ['admin'],
      requiresPermission: 'manage_users',
    },
    {
      icon: faReceipt,
      label: 'Sales',
      href: '/sales',
      roles: ['admin', 'merchant'],
      requiresPermission: 'view_sales',
    },
    {
      icon: faBox,
      label: 'Collections',
      href: '/collections',
      roles: ['admin', 'merchant'],
      requiresPermission: 'view_collections',
    },
    {
      icon: faBuilding,
      label: 'Suppliers',
      href: '/suppliers',
      roles: ['admin', 'merchant'],
      requiresPermission: 'view_suppliers',
    },
    {
      icon: faStore,
      label: 'Customers',
      href: '/customers',
      roles: ['admin', 'merchant'],
      requiresPermission: 'view_customers',
    },
    {
      icon: faWarehouse,
      label: 'Inventory',
      href: '/inventory',
      roles: ['admin', 'merchant'],
      requiresPermission: 'view_inventory',
    },
    {
      icon: faDollarSign,
      label: 'Accounts',
      href: '/accounts',
      roles: ['admin', 'merchant', 'supplier', 'customer'],
    },
    {
      icon: faChartBar,
      label: 'Analytics',
      href: '/analytics',
      roles: ['admin', 'merchant'],
      requiresPermission: 'view_analytics',
    },
    {
      icon: faCog,
      label: 'Settings',
      href: '/settings',
      roles: ['admin', 'merchant', 'supplier', 'customer'],
    },
  ];

  // Filter menu items based on user role and permissions
  const menuItems = allMenuItems.filter(item => {
    // Check role first
    if (item.roles && item.roles.length > 0) {
      const userRole = currentAccount?.role;
      if (!userRole) return false;
      if (!item.roles.includes(userRole) && !isAdmin()) return false;
    }

    // Check permission if required
    if (item.requiresPermission) {
      if (!hasPermission(item.requiresPermission) && !isAdmin()) {
        return false;
      }
    }

    // Special check for Users menu
    if (item.href === '/admin/users') {
      return canManageUsers() || isAdmin();
    }

    return true;
  });

  const isActive = (href?: string) => {
    if (!href) return false;
    return pathname?.startsWith(href);
  };

  const handleCollapseToggle = useCallback(() => {
    const newCollapsed = !collapsed;
    onCollapsedChange(newCollapsed);
    if (typeof window !== 'undefined') {
      localStorage.setItem('gemuraSidebarCollapsed', newCollapsed.toString());
    }
  }, [collapsed, onCollapsedChange]);

  const handleLinkClick = () => {
    if (window.innerWidth < 1024) {
      onClose();
    }
  };

  return (
    <>
      {/* Overlay for mobile */}
      {isOpen && (
        <div
          className="fixed inset-0 bg-black/50 z-40 lg:hidden"
          onClick={onClose}
        />
      )}

      <aside
        className={`
          fixed top-0 left-0 h-full z-50
          flex flex-col overflow-y-auto
          transition-all duration-300 ease-in-out
          lg:translate-x-0
          ${isOpen ? 'translate-x-0' : '-translate-x-full'}
          ${collapsed ? 'w-20' : 'w-64'}
          bg-[var(--primary)]
          border-r border-[#003d8f]
          text-white
        `}
      >
        {/* Logo Section */}
        <div className="p-5 border-b border-[#003d8f] flex-shrink-0 mb-4">
          <div className={`flex items-center ${collapsed ? 'justify-center' : 'gap-3'}`}>
            <Link
              href="/dashboard"
              className={`flex items-center gap-3 ${collapsed ? 'flex-1 justify-center' : 'flex-1'}`}
              onClick={handleLinkClick}
            >
              <div className="w-8 h-8 bg-transparent rounded-full flex items-center justify-center flex-shrink-0">
                <span className="text-white font-bold text-lg">G</span>
              </div>
              {!collapsed && (
                <div className="flex flex-col">
                  <span className="text-2xl font-semibold text-white leading-tight">Gemura</span>
                  <span className="text-xs text-white/80 leading-tight">Financial Services</span>
                </div>
              )}
            </Link>
            {collapsed ? (
              <button
                type="button"
                onClick={handleCollapseToggle}
                className="p-1.5 hover:bg-[#003d8f] rounded-sm transition-colors text-white/80 hover:text-white"
                aria-label="Expand sidebar"
                title="Expand sidebar"
              >
                <Icon icon={faChevronRight} size="sm" />
              </button>
            ) : (
              <button
                type="button"
                onClick={handleCollapseToggle}
                className="p-1.5 hover:bg-[#003d8f] rounded-sm transition-colors text-white/80 hover:text-white"
                aria-label="Collapse sidebar"
              >
                <Icon icon={faBars} size="sm" />
              </button>
            )}
          </div>
        </div>

        {/* User Information */}
        <div className={`px-6 py-6 flex-shrink-0 flex flex-col items-center gap-4 mb-4 ${collapsed ? 'px-3' : ''}`}>
          <div className={`rounded-full bg-white/35 flex items-center justify-center border-3 border-white/50 transition-all ${collapsed ? 'w-12 h-12' : 'w-24 h-24'} hover:border-white/70 hover:bg-white/45 hover:scale-105`}>
            <Icon icon={faUserShield} className="text-white" size={collapsed ? 'sm' : '2x'} />
          </div>
          {!collapsed && (
            <div className="text-center w-full">
              <div className="text-lg font-semibold text-white mb-1 truncate text-shadow-sm">
                {userName}
              </div>
              {userEmail && (
                <div className="text-sm text-white/80 mb-1 truncate max-w-[200px]">
                  {userEmail}
                </div>
              )}
              <div className="text-sm text-white/80 font-medium uppercase tracking-wide">
                {userRole}
              </div>
            </div>
          )}
        </div>

        {/* Navigation */}
        <nav className="flex-1 py-0 overflow-y-auto min-h-0">
          <ul className="list-none p-0 m-0 flex flex-col gap-0">
            {menuItems.map((item, index) => {
              const active = isActive(item.href);
              return (
                <li key={index} className="my-0.5">
                  <Link
                    href={item.href || '#'}
                    onClick={handleLinkClick}
                    className={`
                      flex items-center gap-3 px-7 py-4
                      transition-all duration-200
                      ${collapsed ? 'justify-center px-3' : ''}
                      ${active
                        ? 'bg-[#003d8f] text-white border-l-4 border-white/30'
                        : 'text-white/80 hover:bg-[#003d8f] hover:text-white'
                      }
                    `}
                    title={collapsed ? item.label : undefined}
                  >
                    <Icon
                      icon={item.icon}
                      className={active ? 'text-white' : 'text-white/80'}
                      size="sm"
                    />
                    {!collapsed && (
                      <span className="text-sm font-medium flex-1 whitespace-nowrap overflow-hidden text-ellipsis">
                        {item.label}
                      </span>
                    )}
                  </Link>
                </li>
              );
            })}
          </ul>
        </nav>
      </aside>
    </>
  );
}
