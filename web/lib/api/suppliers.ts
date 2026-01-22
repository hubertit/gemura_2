import { apiClient } from './client';

export interface Supplier {
  relationship_id: string;
  code: string;
  name: string;
  phone: string;
  email?: string;
  nid?: string;
  address?: string;
  account: {
    code: string;
    name: string;
  };
  price_per_liter?: number;
  average_supply_quantity?: number;
  relationship_status: string;
  created_at: string;
  updated_at: string;
}

export interface SuppliersResponse {
  code: number;
  status: string;
  message: string;
  data: Supplier[];
}

export const suppliersApi = {
  getAllSuppliers: async (): Promise<SuppliersResponse> => {
    return apiClient.post('/suppliers/get', {});
  },
};
