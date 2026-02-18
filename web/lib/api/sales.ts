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
  getSales: async (filters?: SalesFilters, accountId?: string): Promise<SalesResponse> => {
    return apiClient.post('/sales/sales', {
      filters: filters || {},
      ...(accountId && { account_id: accountId }),
    });
  },

  getSaleById: async (saleId: string, accountId?: string): Promise<SaleResponse> => {
    const response = await apiClient.post('/sales/sales', {
      filters: {},
      ...(accountId && { account_id: accountId }),
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
    return apiClient.post('/sales', data);
  },

  downloadTemplate: async (): Promise<void> => {
    const token = typeof window !== 'undefined' ? localStorage.getItem('gemura-auth-token') : null;
    const baseURL = process.env.NEXT_PUBLIC_API_URL || 'http://159.198.65.38:3004/api';
    const res = await fetch(`${baseURL}/sales/template`, {
      headers: token ? { Authorization: `Bearer ${token}` } : {},
    });
    if (!res.ok) throw new Error('Failed to download template');
    const blob = await res.blob();
    const url = URL.createObjectURL(blob);
    const a = document.createElement('a');
    a.href = url;
    a.download = 'sales-template.csv';
    a.click();
    URL.revokeObjectURL(url);
  },

  bulkCreate: async (
    rows: CreateSaleData[],
  ): Promise<{ code: number; data: { success: number; failed: number; errors: { row: number; phone: string; message: string }[] } }> => {
    return apiClient.post('/sales/bulk', { rows });
  },

  updateSale: async (data: UpdateSaleData): Promise<SaleResponse> => {
    return apiClient.put('/sales/update', data);
  },

  cancelSale: async (saleId: string): Promise<{ code: number; status: string; message: string }> => {
    return apiClient.delete('/sales/cancel', {
      data: { sale_id: saleId },
    });
  },

  /** Record payment for a sale (reduces receivables). Milk sales only; use accounting receivables for inventory. */
  recordPayment: async (
    saleId: string,
    data: { amount: number; payment_date?: string; notes?: string }
  ): Promise<{ code: number; status: string; message: string; data?: { payment_status: string } }> => {
    return apiClient.post(`/sales/${saleId}/payment`, data);
  },
};
