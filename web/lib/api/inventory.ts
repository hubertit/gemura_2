import { apiClient } from './client';

export interface InventoryItem {
  id: string;
  name: string;
  description?: string;
  price: number;
  stock_quantity: number;
  min_stock_level?: number | null;
  status: 'active' | 'inactive' | 'out_of_stock';
  is_listed_in_marketplace: boolean;
  categories: Array<{
    id: string;
    name: string;
    description?: string;
  }>;
  image?: string | null;
  created_at: string;
  updated_at: string;
}

export interface InventoryStats {
  total_items: number;
  active_items: number;
  out_of_stock_items: number;
  low_stock_items: number;
  listed_in_marketplace?: number;
  total_stock_value?: number;
  total_stock_quantity?: number;
}

export interface CreateInventoryData {
  inventory_item_id?: string;
  name?: string;
  description?: string;
  price: number;
  stock_quantity?: number;
  min_stock_level?: number;
  category_ids?: string[];
  is_listed_in_marketplace?: boolean;
}

export interface UpdateInventoryData {
  name?: string;
  description?: string;
  price?: number;
  stock_quantity?: number;
  min_stock_level?: number;
  category_ids?: string[];
  status?: string;
  is_listed_in_marketplace?: boolean;
}

export interface UpdateStockData {
  stock_quantity: number;
  notes?: string;
}

export type InventoryMovementType =
  | 'sale_out'
  | 'adjustment_in'
  | 'adjustment_out'
  | 'purchase_in'
  | 'transfer_in'
  | 'transfer_out';

export interface InventoryMovement {
  id: string;
  product_id: string;
  movement_type: InventoryMovementType;
  quantity: number;
  reference_type: string;
  reference_id: string | null;
  description: string | null;
  unit_price: number | null;
  created_at: string;
  created_by: { id: string; name: string } | null;
}

export interface InventoryMovementsResponse {
  code: number;
  status: string;
  message: string;
  data: {
    items: InventoryMovement[];
    pagination: { page: number; limit: number; total: number; total_pages: number };
  };
}

export interface CreateInventorySaleData {
  buyer_type: 'supplier' | 'customer' | 'other';
  buyer_account_id?: string;
  buyer_name?: string;
  buyer_phone?: string;
  quantity: number;
  unit_price: number;
  amount_paid: number;
  sale_date?: string;
  notes?: string;
}

export interface InventoryResponse {
  code: number;
  status: string;
  message: string;
  data: InventoryItem[];
}

export interface InventoryItemResponse {
  code: number;
  status: string;
  message: string;
  data: InventoryItem;
}

export interface InventoryStatsResponse {
  code: number;
  status: string;
  message: string;
  data: InventoryStats;
}

export interface ValuationOverTimePoint {
  date: string;
  total_value: number;
  total_quantity: number;
}

export interface TopItemByValue {
  id: string;
  name: string;
  price: number;
  stock_quantity: number;
  stock_value: number;
}

export interface StockMovementPoint {
  date: string;
  stock_in: number;
  stock_out: number;
}

export const inventoryApi = {
  getInventory: async (accountId?: string, status?: string, lowStock?: boolean): Promise<InventoryResponse> => {
    const params = new URLSearchParams();
    if (accountId) params.append('account_id', accountId);
    if (status) params.append('status', status);
    if (lowStock) params.append('low_stock', 'true');
    return apiClient.get(`/inventory?${params.toString()}`);
  },

  getInventoryStats: async (accountId?: string): Promise<InventoryStatsResponse> => {
    const params = new URLSearchParams();
    if (accountId) params.append('account_id', accountId);
    const url = params.toString() ? `/inventory/stats?${params.toString()}` : '/inventory/stats';
    return apiClient.get(url);
  },

  getValuationOverTime: async (
    dateFrom: string,
    dateTo: string,
    accountId?: string
  ): Promise<{ code: number; data: { series: ValuationOverTimePoint[] } }> => {
    const params = new URLSearchParams({ date_from: dateFrom, date_to: dateTo });
    if (accountId) params.append('account_id', accountId);
    return apiClient.get(`/inventory/stats/valuation-over-time?${params.toString()}`);
  },

  getTopByValue: async (
    limit?: number,
    accountId?: string
  ): Promise<{ code: number; data: { items: TopItemByValue[] } }> => {
    const params = new URLSearchParams();
    if (limit != null) params.append('limit', String(limit));
    if (accountId) params.append('account_id', accountId);
    const q = params.toString();
    return apiClient.get(q ? `/inventory/stats/top-by-value?${q}` : '/inventory/stats/top-by-value');
  },

  getStockMovement: async (
    dateFrom: string,
    dateTo: string,
    accountId?: string
  ): Promise<{ code: number; data: { series: StockMovementPoint[] } }> => {
    const params = new URLSearchParams({ date_from: dateFrom, date_to: dateTo });
    if (accountId) params.append('account_id', accountId);
    return apiClient.get(`/inventory/stats/stock-movement?${params.toString()}`);
  },

  getInventoryItem: async (id: string, accountId?: string): Promise<InventoryItemResponse> => {
    const params = new URLSearchParams();
    if (accountId) params.append('account_id', accountId);
    const url = params.toString() ? `/inventory/${id}?${params.toString()}` : `/inventory/${id}`;
    return apiClient.get(url);
  },

  getProductMovements: async (
    productId: string,
    params?: { page?: number; limit?: number; movement_type?: string; date_from?: string; date_to?: string }
  ): Promise<InventoryMovementsResponse> => {
    const search = new URLSearchParams();
    if (params?.page != null) search.append('page', String(params.page));
    if (params?.limit != null) search.append('limit', String(params.limit));
    if (params?.movement_type) search.append('movement_type', params.movement_type);
    if (params?.date_from) search.append('date_from', params.date_from);
    if (params?.date_to) search.append('date_to', params.date_to);
    const q = search.toString();
    return apiClient.get(`/inventory/${productId}/movements${q ? `?${q}` : ''}`);
  },

  createInventoryItem: async (data: CreateInventoryData): Promise<InventoryItemResponse> => {
    return apiClient.post('/inventory', data);
  },

  downloadTemplate: async (): Promise<void> => {
    const token = typeof window !== 'undefined' ? localStorage.getItem('gemura-auth-token') : null;
    const baseURL = process.env.NEXT_PUBLIC_API_URL || 'http://159.198.65.38:3004/api';
    const res = await fetch(`${baseURL}/inventory/template`, {
      headers: token ? { Authorization: `Bearer ${token}` } : {},
    });
    if (!res.ok) throw new Error('Failed to download template');
    const blob = await res.blob();
    const url = URL.createObjectURL(blob);
    const a = document.createElement('a');
    a.href = url;
    a.download = 'inventory-template.csv';
    a.click();
    URL.revokeObjectURL(url);
  },

  bulkCreate: async (
    rows: CreateInventoryData[],
  ): Promise<{ code: number; data: { success: number; failed: number; errors: { row: number; phone: string; message: string }[] } }> => {
    return apiClient.post('/inventory/bulk', { rows });
  },

  updateInventoryItem: async (id: string, data: UpdateInventoryData): Promise<InventoryItemResponse> => {
    return apiClient.put(`/inventory/${id}`, data);
  },

  updateStock: async (id: string, data: UpdateStockData): Promise<InventoryItemResponse> => {
    return apiClient.put(`/inventory/${id}/stock`, data);
  },

  toggleMarketplaceListing: async (id: string, isListed: boolean): Promise<InventoryItemResponse> => {
    return apiClient.post(`/inventory/${id}/toggle-listing`, { is_listed_in_marketplace: isListed });
  },

  deleteInventoryItem: async (id: string): Promise<{ code: number; status: string; message: string }> => {
    return apiClient.delete(`/inventory/${id}`);
  },

  sellInventoryItem: async (id: string, data: CreateInventorySaleData): Promise<any> => {
    return apiClient.post(`/inventory/${id}/sell`, data);
  },
};
