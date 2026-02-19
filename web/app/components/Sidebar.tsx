'use client';

import { useState, useEffect, useCallback, useMemo } from 'react';
import { usePathname } from 'next/navigation';
import Link from 'next/link';
import Image from 'next/image';
import { useAuthStore } from '@/store/auth';
import { usePermission } from '@/hooks/usePermission';
import Icon, { faBars, faChevronRight, faChevronDown, faUser } from './Icon';
import type { NavItem } from '@/lib/config/nav.config';
import {
  ADMIN_NAV_ITEMS,
  OPERATIONS_NAV_ITEMS,
  EXTERNAL_SUPPLIER_NAV_ITEMS,
  EXTERNAL_CUSTOMER_NAV_ITEMS,
  isAdminAccount,
  isBusinessAccount,
  isAdminRole,
  isOperationsRole,
  isExternalSupplier,
  isExternalCustomer,
} from '@/lib/config/nav.config';

interface SidebarProps {
  isOpen: boolean;
  collapsed: boolean;
  onClose: () => void;
  onCollapsedChange: (collapsed: boolean) => void;
}

export default function Sidebar({ isOpen, collapsed, onClose, onCollapsedChange }: SidebarProps) {
  const pathname = usePathname();
  const { user, currentAccount } = useAuthStore();
  const { canManageUsers, isAdmin, hasPermission } = usePermission();
  const [userName, setUserName] = useState('User');
  const [userEmail, setUserEmail] = useState('');
  const [userRole, setUserRole] = useState('User');
  // Collapsible sections: set of parent hrefs that are expanded (only when they have children)
  const [expandedKeys, setExpandedKeys] = useState<Set<string>>(() => new Set());

  const role = currentAccount?.role ?? '';
  const accountType = currentAccount?.account_type ?? '';

  useEffect(() => {
    if (user) {
      setUserName(`${user.firstName} ${user.lastName}`);
      setUserEmail(user.email);
      setUserRole(currentAccount?.role || 'User');
    }
  }, [user, currentAccount]);

  // Build menu by account type first; then role/permissions for user (non-admin) accounts
  const menuItems = useMemo(() => {
    const items: NavItem[] = [];

    // Admin account type → admin menu and features only
    if (isAdminAccount(accountType)) {
      ADMIN_NAV_ITEMS.forEach((item) => {
        if (item.href === '/admin/users' && !canManageUsers() && !isAdmin()) return;
        items.push(item);
      });
      return items;
    }

    // User accounts: menu by role and permissions (active/default account)
    // Operations: business account types, filter by role/permissions
    if (isOperationsRole(role) && isBusinessAccount(accountType)) {
      OPERATIONS_NAV_ITEMS.forEach((item) => {
        if (item.requiresPermission && !hasPermission(item.requiresPermission)) return;
        items.push(item);
      });
      return items;
    }

    // Owner/admin role on non-admin account (tenant/branch etc.) → operations menu by permissions
    if (isAdminRole(role) && isBusinessAccount(accountType)) {
      OPERATIONS_NAV_ITEMS.forEach((item) => {
        if (item.requiresPermission && !hasPermission(item.requiresPermission)) return;
        items.push(item);
      });
      return items;
    }

    // External: supplier account
    if (isExternalSupplier(accountType)) {
      EXTERNAL_SUPPLIER_NAV_ITEMS.forEach((item) => items.push(item));
      return items;
    }

    // External: customer / farmer
    if (isExternalCustomer(accountType)) {
      EXTERNAL_CUSTOMER_NAV_ITEMS.forEach((item) => items.push(item));
      return items;
    }

    // Fallback: business account type, unknown role — show operations by permissions
    if (isBusinessAccount(accountType)) {
      OPERATIONS_NAV_ITEMS.forEach((item) => {
        if (item.requiresPermission && !hasPermission(item.requiresPermission) && !isAdmin()) return;
        items.push(item);
      });
      if (items.length > 0) return items;
    }

    // Last resort: minimal menu
    items.push(
      { icon: ADMIN_NAV_ITEMS[0].icon, label: 'Dashboard', href: '/dashboard', section: 'admin' },
      { icon: ADMIN_NAV_ITEMS[4].icon, label: 'Settings', href: '/settings', section: 'admin' },
    );
    return items;
  }, [role, accountType, canManageUsers, isAdmin, hasPermission]);

  // Keep the section that contains the current route expanded (only add, never remove, to avoid loop)
  useEffect(() => {
    if (!pathname || collapsed) return;
    const key = menuItems.find(
      (item) => item.href === pathname || item.children?.some((c) => pathname.startsWith(c.href))
    )?.href;
    if (key) {
      setExpandedKeys((prev) => {
        if (prev.has(key)) return prev;
        const next = new Set(prev);
        next.add(key);
        return next;
      });
    }
  }, [pathname, collapsed, menuItems]);

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

  const toggleExpanded = (key: string) => {
    setExpandedKeys((prev) => {
      const next = new Set(prev);
      if (next.has(key)) next.delete(key);
      else next.add(key);
      return next;
    });
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
          bg-[#052a54]
          border-r border-[#031a3a]
          text-white
        `}
      >
        {/* Logo Section - ResolveIT v2 darker */}
        <div className="p-5 border-b border-[#031a3a] flex-shrink-0 mb-4">
          <div className={`flex items-center ${collapsed ? 'justify-center' : 'gap-3'}`}>
            <Link
              href="/dashboard"
              className={`flex items-center gap-3 ${collapsed ? 'flex-1 justify-center' : 'flex-1'}`}
              onClick={handleLinkClick}
            >
              <div className="relative flex-shrink-0 bg-transparent flex items-center justify-center overflow-hidden rounded-full">
                <Image
                  src="/logo.png"
                  alt="Gemura"
                  width={collapsed ? 32 : 40}
                  height={collapsed ? 32 : 40}
                  className="object-contain"
                  priority
                />
              </div>
              {!collapsed && (
                <div className="flex flex-col min-w-0">
                  <span className="text-xl font-semibold text-white leading-tight truncate">Gemura</span>
                  <span className="text-xs text-white/80 leading-tight">Financial Services</span>
                </div>
              )}
            </Link>
            {collapsed ? (
              <button
                type="button"
                onClick={handleCollapseToggle}
                className="p-1.5 hover:bg-[#031a3a] rounded-sm transition-colors text-gray-300 hover:text-white"
                aria-label="Expand sidebar"
                title="Expand sidebar"
              >
                <Icon icon={faChevronRight} size="sm" />
              </button>
            ) : (
              <button
                type="button"
                onClick={handleCollapseToggle}
                className="p-1.5 hover:bg-[#031a3a] rounded-sm transition-colors text-gray-300 hover:text-white"
                aria-label="Collapse sidebar"
              >
                <Icon icon={faBars} size="sm" />
              </button>
            )}
          </div>
        </div>

        {/* User Information - ResolveIT v2 darker avatar */}
        <div className={`flex-shrink-0 flex flex-col items-center gap-4 mb-4 p-6 ${collapsed ? 'px-3' : ''}`}>
          <div
            className={`
              rounded-full flex items-center justify-center text-white
              bg-black/20 border-2 border-white/30
              transition-all duration-300 ease-in-out
              hover:bg-black/30 hover:border-white/50 hover:scale-105
              ${collapsed ? 'w-12 h-12' : 'w-24 h-24'}
            `}
          >
            <Icon icon={faUser} className="text-white" size={collapsed ? 'sm' : '2x'} />
          </div>
          {!collapsed && (
            <div className="text-center w-full min-w-0">
              <div className="text-sm font-semibold text-white mb-1 truncate">
                {userName}
              </div>
              {userEmail && (
                <div className="text-xs text-gray-300 mb-1 truncate max-w-[200px] mx-auto">
                  {userEmail}
                </div>
              )}
              <div className="text-xs text-white/80 font-medium uppercase tracking-wide">
                {userRole}
              </div>
            </div>
          )}
        </div>

        {/* Navigation */}
        <nav className="flex-1 py-0 overflow-y-auto min-h-0">
          <ul className="list-none p-0 m-0 flex flex-col gap-0">
            {menuItems.map((item, index) => {
              const hasChildren = !collapsed && item.children && item.children.length > 0;
              const parentActive = isActive(item.href) || (item.children?.some((c) => isActive(c.href)) ?? false);
              const isExpanded = hasChildren && expandedKeys.has(item.href);
              const rowClass = `
                flex items-center gap-3 px-7 py-4 w-full text-left
                transition-all duration-200
                ${collapsed ? 'justify-center px-3' : ''}
                ${parentActive && !hasChildren
                  ? 'bg-[#031a3a] text-white border-l-4 border-white/30'
                  : parentActive && hasChildren
                    ? 'text-white border-l-4 border-white/30'
                    : 'text-gray-300 hover:bg-[#031a3a] hover:text-white'
                }
              `;
              return (
                <li key={index} className="my-0.5">
                  {hasChildren ? (
                    <>
                      <button
                        type="button"
                        onClick={() => toggleExpanded(item.href)}
                        className={rowClass}
                        title={collapsed ? item.label : undefined}
                        aria-expanded={isExpanded}
                      >
                        <Icon
                          icon={item.icon}
                          className={parentActive ? 'text-white' : 'text-gray-300'}
                          size="sm"
                        />
                        {!collapsed && (
                          <>
                            <span className="text-sm font-medium flex-1 whitespace-nowrap overflow-hidden text-ellipsis">
                              {item.label}
                            </span>
                            <Icon
                              icon={faChevronDown}
                              size="sm"
                              className={`text-gray-400 transition-transform duration-200 ${isExpanded ? 'rotate-180' : ''}`}
                            />
                          </>
                        )}
                      </button>
                      {isExpanded && (
                        <ul className="list-none pl-0 mt-0 mb-1">
                          {item.children!.map((child, childIndex) => {
                            const childActive = isActive(child.href);
                            return (
                              <li key={childIndex} className="my-0">
                                <Link
                                  href={child.href}
                                  onClick={handleLinkClick}
                                  className={`
                                    flex items-center gap-2 py-2.5 pl-12 pr-4 text-sm
                                    transition-all duration-200
                                    ${childActive
                                      ? 'bg-[#031a3a] text-white border-l-4 border-white/30 -ml-0.5 pl-[3.25rem]'
                                      : 'text-gray-400 hover:bg-[#031a3a] hover:text-white'
                                    }
                                  `}
                                >
                                  <span className="whitespace-nowrap overflow-hidden text-ellipsis">{child.label}</span>
                                </Link>
                              </li>
                            );
                          })}
                        </ul>
                      )}
                    </>
                  ) : (
                    <Link
                      href={item.href || '#'}
                      onClick={handleLinkClick}
                      className={rowClass}
                      title={collapsed ? item.label : undefined}
                    >
                      <Icon
                        icon={item.icon}
                        className={parentActive ? 'text-white' : 'text-gray-300'}
                        size="sm"
                      />
                      {!collapsed && (
                        <span className="text-sm font-medium flex-1 whitespace-nowrap overflow-hidden text-ellipsis">
                          {item.label}
                        </span>
                      )}
                    </Link>
                  )}
                </li>
              );
            })}
          </ul>
        </nav>
      </aside>
    </>
  );
}
