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
    id: string;
    code: string;
    name: string;
  };
  price_per_liter?: number;
  average_supply_quantity?: number;
  relationship_status: string;
  created_at: string;
  updated_at: string;
}

export interface CustomerDetails {
  account_id: string;
  account_code: string;
  name: string;
  type: string;
  status: string;
  user: {
    id: string;
    name: string;
    phone: string;
    email?: string;
    nid?: string;
    address?: string;
    account_type: string;
  };
  relationship: {
    price_per_liter: number;
    average_supply_quantity?: number;
    relationship_status: string;
    created_at: string;
    updated_at: string;
  };
}

export interface CreateCustomerData {
  name: string;
  phone: string;
  email?: string;
  nid?: string;
  address?: string;
  price_per_liter?: number;
}

export interface UpdateCustomerData {
  customer_account_code: string;
  name?: string;
  phone?: string;
  email?: string;
  nid?: string;
  address?: string;
  price_per_liter?: number;
  relationship_status?: 'active' | 'inactive';
}

export interface CustomersResponse {
  code: number;
  status: string;
  message: string;
  data: Customer[];
}

export interface CustomerResponse {
  code: number;
  status: string;
  message: string;
  data: {
    customer: CustomerDetails;
  };
}

export const customersApi = {
  getAllCustomers: async (accountId?: string): Promise<CustomersResponse> => {
    return apiClient.post('/customers/get', accountId ? { account_id: accountId } : {});
  },

  getCustomerById: async (id: string): Promise<CustomerResponse> => {
    return apiClient.get(`/customers/by-id/${id}`);
  },

  getCustomerByCode: async (code: string): Promise<CustomerResponse> => {
    return apiClient.get(`/customers/${code}`);
  },

  createCustomer: async (data: CreateCustomerData): Promise<CustomerResponse> => {
    return apiClient.post('/customers', data);
  },

  updateCustomer: async (data: UpdateCustomerData): Promise<CustomerResponse> => {
    return apiClient.put('/customers/update', data);
  },
};
