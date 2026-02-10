/**
 * Navigation: admin vs user is based on account type (active/default account).
 *
 * - account_type === 'admin' (Account.type) → admin menu and features only.
 * - Else → user menu and features; what they see is based on role + permissions (unchanged).
 *
 * Backend sends account_type from Account.type (tenant | branch | admin) and role from UserAccount.role.
 */

import type { IconDefinition } from '@fortawesome/fontawesome-svg-core';
import {
  faHome,
  faUsers,
  faCog,
  faUserShield,
  faLock,
  faReceipt,
  faBox,
  faBuilding,
  faStore,
  faWarehouse,
  faDollarSign,
  faChartLine,
  faClipboardList,
} from '@/app/components/Icon';

/** Account type that sees only admin menu/features */
export const ADMIN_ACCOUNT_TYPE = 'admin' as const;

/** Account types that see user/operations menu (filtered by role + permissions) */
export const BUSINESS_ACCOUNT_TYPES = ['mcc', 'owner', 'agent', 'tenant', 'branch'] as const;
export const ADMIN_ROLES = ['owner', 'admin'] as const;
export const OPERATIONS_ROLES = ['manager', 'collector', 'viewer', 'employee', 'agent'] as const;
export const EXTERNAL_ACCOUNT_TYPES = ['supplier', 'customer', 'farmer'] as const;

export type Section = 'admin' | 'operations' | 'external_supplier' | 'external_customer';

export interface NavItem {
  icon: IconDefinition;
  label: string;
  href: string;
  section: Section;
  /** Permission key required (for operations section). Owner/admin bypass. */
  requiresPermission?: string;
}

/**
 * Admin section: only for role in [owner, admin] and account_type in [mcc, owner, agent].
 * Dashboard goes to admin dashboard; Users, Roles, Permissions, Settings.
 */
export const ADMIN_NAV_ITEMS: NavItem[] = [
  { icon: faHome, label: 'Dashboard', href: '/admin/dashboard', section: 'admin' },
  { icon: faUsers, label: 'Users', href: '/admin/users', section: 'admin' },
  { icon: faUserShield, label: 'Roles', href: '/admin/roles', section: 'admin' },
  { icon: faLock, label: 'Permissions', href: '/admin/permissions', section: 'admin' },
  { icon: faCog, label: 'Settings', href: '/settings', section: 'admin' },
];

/**
 * Operations section: for role in [manager, collector, viewer, employee] (and optionally owner/admin if we allow both).
 * account_type in [mcc, owner, agent]. Permission checks apply.
 */
export const OPERATIONS_NAV_ITEMS: NavItem[] = [
  { icon: faHome, label: 'Dashboard', href: '/dashboard', section: 'operations' },
  { icon: faReceipt, label: 'Sales', href: '/sales', section: 'operations', requiresPermission: 'view_sales' },
  { icon: faBox, label: 'Collections', href: '/collections', section: 'operations', requiresPermission: 'view_collections' },
  { icon: faBuilding, label: 'Suppliers', href: '/suppliers', section: 'operations', requiresPermission: 'view_suppliers' },
  { icon: faStore, label: 'Customers', href: '/customers', section: 'operations', requiresPermission: 'view_customers' },
  { icon: faWarehouse, label: 'Inventory', href: '/inventory', section: 'operations', requiresPermission: 'view_inventory' },
  { icon: faClipboardList, label: 'Payroll', href: '/payroll', section: 'operations' },
  { icon: faChartLine, label: 'Finance', href: '/finance', section: 'operations' },
  { icon: faDollarSign, label: 'Accounts', href: '/accounts', section: 'operations' },
  { icon: faCog, label: 'Settings', href: '/settings', section: 'operations' },
];

/**
 * External (supplier account): Dashboard, Accounts, Settings.
 */
export const EXTERNAL_SUPPLIER_NAV_ITEMS: NavItem[] = [
  { icon: faHome, label: 'Dashboard', href: '/dashboard', section: 'external_supplier' },
  { icon: faDollarSign, label: 'Accounts', href: '/accounts', section: 'external_supplier' },
  { icon: faCog, label: 'Settings', href: '/settings', section: 'external_supplier' },
];

/**
 * External (customer / farmer): Dashboard, Accounts, Settings.
 */
export const EXTERNAL_CUSTOMER_NAV_ITEMS: NavItem[] = [
  { icon: faHome, label: 'Dashboard', href: '/dashboard', section: 'external_customer' },
  { icon: faDollarSign, label: 'Accounts', href: '/accounts', section: 'external_customer' },
  { icon: faCog, label: 'Settings', href: '/settings', section: 'external_customer' },
];

/** True when current account is admin type → admin menu only */
export function isAdminAccount(accountType: string): boolean {
  return (accountType || '').toLowerCase() === ADMIN_ACCOUNT_TYPE;
}

export function isBusinessAccount(accountType: string): boolean {
  const t = (accountType || '').toLowerCase();
  return BUSINESS_ACCOUNT_TYPES.some((a) => a === t);
}

export function isAdminRole(role: string): boolean {
  const r = (role || '').toLowerCase();
  return ADMIN_ROLES.some((a) => a === r);
}

export function isOperationsRole(role: string): boolean {
  const r = (role || '').toLowerCase();
  return OPERATIONS_ROLES.some((a) => a === r);
}

export function isExternalSupplier(accountType: string): boolean {
  return (accountType || '').toLowerCase() === 'supplier';
}

export function isExternalCustomer(accountType: string): boolean {
  const t = (accountType || '').toLowerCase();
  return t === 'customer' || t === 'farmer';
}
