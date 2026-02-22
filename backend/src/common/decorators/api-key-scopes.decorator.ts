import { SetMetadata } from '@nestjs/common';
import { API_KEY_SCOPES_KEY } from '../guards/api-key.guard';

/**
 * Decorator to specify required API key scopes for an endpoint
 * @param scopes - Array of required scope strings (e.g., 'analytics:collections:read')
 */
export const ApiKeyScopes = (...scopes: string[]) =>
  SetMetadata(API_KEY_SCOPES_KEY, scopes);

/**
 * Available API Key Scopes:
 * 
 * Analytics Scopes:
 * - analytics:* - Full analytics access
 * - analytics:collections:read - Read milk collections analytics
 * - analytics:sales:read - Read milk sales analytics
 * - analytics:suppliers:read - Read suppliers analytics
 * - analytics:inventory:read - Read inventory analytics
 * - analytics:financial:read - Read financial analytics
 * - analytics:payroll:read - Read payroll analytics
 * - analytics:loans:read - Read loans analytics
 * - analytics:platform:read - Read platform-wide analytics (admin only)
 * 
 * Export Scopes:
 * - export:read - Export data to CSV/Excel
 */
export const AnalyticsScopes = {
  ALL: 'analytics:*',
  COLLECTIONS_READ: 'analytics:collections:read',
  SALES_READ: 'analytics:sales:read',
  SUPPLIERS_READ: 'analytics:suppliers:read',
  INVENTORY_READ: 'analytics:inventory:read',
  FINANCIAL_READ: 'analytics:financial:read',
  PAYROLL_READ: 'analytics:payroll:read',
  LOANS_READ: 'analytics:loans:read',
  PLATFORM_READ: 'analytics:platform:read',
  EXPORT_READ: 'export:read',
} as const;
