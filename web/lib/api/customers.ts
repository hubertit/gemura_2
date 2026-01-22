import { apiClient } from './client';

export interface Customer {
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

export interface CustomersResponse {
  code: number;
  status: string;
  message: string;
  data: Customer[];
}

export const customersApi = {
  getAllCustomers: async (): Promise<CustomersResponse> => {
    return apiClient.post('/customers/get', {});
  },
};
