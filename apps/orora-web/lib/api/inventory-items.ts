import { apiClient } from './client';

export interface PredefinedInventoryItem {
  id: string;
  name: string;
  code?: string | null;
  unit?: string | null;
  description?: string | null;
  is_active?: boolean;
  sort_order?: number;
}

export interface PredefinedCategoryGroup {
  id: string;
  name: string;
  description?: string | null;
  sort_order: number;
  items: PredefinedInventoryItem[];
}

export interface InventoryItemsGroupedResponse {
  code: number;
  status: string;
  message: string;
  data: {
    categories: PredefinedCategoryGroup[];
  };
}

export const inventoryItemsApi = {
  /** Get predefined inventory items grouped by category (for Add item dropdown). */
  getGroupedByCategory: async (): Promise<InventoryItemsGroupedResponse> => {
    return apiClient.get('/inventory-items?group_by_category=true');
  },
};
