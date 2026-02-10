/**
 * Navigation menu configuration by account type and role.
 *
 * Backend sends:
 * - account_type: from Account.type (tenant | branch) OR from User.account_type (mcc, supplier, etc.) depending on API
 * - role: from UserAccount.role (owner, admin, manager, collector, supplier, customer, agent, viewer)
 *
 * We treat tenant/branch as "business" accounts (MCC-like). User-level types mcc/owner/agent also = business.
 * External: supplier, customer, farmer (when API sends User.account_type per account).
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
  faChartBar,
} from '@/app/components/Icon';

/** Account.type from API (tenant/branch) + User.account_type (mcc, owner, agent) — show business menus */
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
  { icon: faDollarSign, label: 'Accounts', href: '/accounts', section: 'operations' },
  { icon: faChartBar, label: 'Analytics', href: '/analytics', section: 'operations', requiresPermission: 'view_analytics' },
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
