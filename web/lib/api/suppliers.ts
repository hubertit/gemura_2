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

export interface SupplierDetails {
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

export interface CreateSupplierData {
  name: string;
  phone: string;
  price_per_liter: number;
  email?: string;
  nid?: string;
  address?: string;
}

export interface UpdateSupplierData {
  supplier_account_code: string;
  price_per_liter?: number;
  relationship_status?: 'active' | 'inactive';
}

export interface SuppliersResponse {
  code: number;
  status: string;
  message: string;
  data: Supplier[];
}

export interface SupplierResponse {
  code: number;
  status: string;
  message: string;
  data: {
    supplier: SupplierDetails;
  };
}

export const suppliersApi = {
  getAllSuppliers: async (): Promise<SuppliersResponse> => {
    return apiClient.post('/suppliers/get', {});
  },

  getSupplierById: async (id: string): Promise<SupplierResponse> => {
    return apiClient.get(`/suppliers/by-id/${id}`);
  },

  getSupplierByCode: async (code: string): Promise<SupplierResponse> => {
    return apiClient.get(`/suppliers/${code}`);
  },

  createSupplier: async (data: CreateSupplierData): Promise<SupplierResponse> => {
    return apiClient.post('/suppliers/create', data);
  },

  updateSupplier: async (data: UpdateSupplierData): Promise<SupplierResponse> => {
    return apiClient.put('/suppliers/update', data);
  },
};
