import { apiClient } from './client';

export interface Sale {
  id: string;
  quantity: number;
  unit_price: number;
  total_amount: number;
  status: 'pending' | 'accepted' | 'rejected' | 'cancelled' | 'deleted';
  sale_at: string;
  notes?: string;
  created_at: string;
  supplier_account: {
    id: string;
    code: string;
    name: string;
    type: string;
    status: string;
  };
  customer_account: {
    id: string;
    code: string;
    name: string;
    type: string;
    status: string;
  };
}

export interface SalesFilters {
  customer_account_code?: string;
  status?: string;
  date_from?: string;
  date_to?: string;
  quantity_min?: number;
  quantity_max?: number;
  price_min?: number;
  price_max?: number;
}

export interface CreateSaleData {
  customer_account_id?: string;
  customer_account_code?: string;
  quantity: number;
  unit_price?: number;
  status?: 'pending' | 'accepted' | 'rejected' | 'cancelled';
  sale_at?: string;
  notes?: string;
  payment_status?: 'paid' | 'unpaid';
}

export interface UpdateSaleData {
  sale_id: string;
  customer_account_id?: string;
  customer_account_code?: string;
  quantity?: number;
  unit_price?: number;
  status?: string;
  sale_at?: string;
  notes?: string;
}

export interface SalesResponse {
  code: number;
  status: string;
  message: string;
  data: Sale[];
}

export interface SaleResponse {
  code: number;
  status: string;
  message: string;
  data: Sale;
}

export const salesApi = {
  getSales: async (filters?: SalesFilters): Promise<SalesResponse> => {
    return apiClient.post('/sales/sales', { filters: filters || {} });
  },

  getSaleById: async (saleId: string): Promise<SaleResponse> => {
    // Note: There might not be a direct get by ID endpoint, 
    // so we'll filter by ID in the list endpoint
    const response = await apiClient.post('/sales/sales', { 
      filters: {} 
    }) as SalesResponse;
    if (response.code === 200 && response.data) {
      const sale = response.data.find((s: Sale) => s.id === saleId);
      if (sale) {
        return {
          code: 200,
          status: 'success',
          message: 'Sale fetched successfully',
          data: sale,
        };
      }
    }
    throw new Error('Sale not found');
  },

  createSale: async (data: CreateSaleData): Promise<SaleResponse> => {
    return apiClient.post('/sales/create', data);
  },

  updateSale: async (data: UpdateSaleData): Promise<SaleResponse> => {
    return apiClient.put('/sales/update', data);
  },

  cancelSale: async (saleId: string): Promise<{ code: number; status: string; message: string }> => {
    return apiClient.delete('/sales/cancel', {
      data: { sale_id: saleId },
    });
  },
};
