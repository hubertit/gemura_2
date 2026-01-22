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
  total_stock_value: number;
  total_stock_quantity: number;
}

export interface CreateInventoryData {
  name: string;
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

export const inventoryApi = {
  getInventory: async (status?: string, lowStock?: boolean): Promise<InventoryResponse> => {
    const params = new URLSearchParams();
    if (status) params.append('status', status);
    if (lowStock) params.append('low_stock', 'true');
    return apiClient.get(`/inventory?${params.toString()}`);
  },

  getInventoryStats: async (): Promise<InventoryStatsResponse> => {
    return apiClient.get('/inventory/stats');
  },

  getInventoryItem: async (id: string): Promise<InventoryItemResponse> => {
    return apiClient.get(`/inventory/${id}`);
  },

  createInventoryItem: async (data: CreateInventoryData): Promise<InventoryItemResponse> => {
    return apiClient.post('/inventory', data);
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
