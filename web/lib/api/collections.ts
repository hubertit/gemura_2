import { apiClient } from './client';

export interface Collection {
  id: string;
  quantity: number;
  unit_price: number;
  total_amount: number;
  status: 'pending' | 'accepted' | 'rejected' | 'cancelled' | 'deleted';
  collection_at: string;
  notes?: string;
  created_at: string;
  updated_at?: string;
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
  recorded_by?: {
    id: string;
    name: string;
    phone: string;
  };
}

export interface CollectionsFilters {
  supplier_account_code?: string;
  status?: string;
  date_from?: string;
  date_to?: string;
  quantity_min?: number;
  quantity_max?: number;
  price_min?: number;
  price_max?: number;
}

export interface CreateCollectionData {
  supplier_account_code: string;
  quantity: number;
  status?: 'pending' | 'accepted' | 'rejected' | 'cancelled';
  collection_at: string;
  notes?: string;
  payment_status?: 'paid' | 'unpaid';
}

export interface UpdateCollectionData {
  collection_id: string;
  quantity?: number;
  status?: string;
  collection_at?: string;
  notes?: string;
}

export interface CollectionsResponse {
  code: number;
  status: string;
  message: string;
  data: Collection[];
}

export interface CollectionResponse {
  code: number;
  status: string;
  message: string;
  data: Collection;
}

export const collectionsApi = {
  getCollections: async (filters?: CollectionsFilters, accountId?: string): Promise<CollectionsResponse> => {
    const params = new URLSearchParams();
    if (accountId) params.append('account_id', accountId);
    if (filters?.supplier_account_code) params.append('supplier_account_code', filters.supplier_account_code);
    if (filters?.status) params.append('status', filters.status);
    if (filters?.date_from) params.append('date_from', filters.date_from);
    if (filters?.date_to) params.append('date_to', filters.date_to);
    if (filters?.quantity_min) params.append('quantity_min', filters.quantity_min.toString());
    if (filters?.quantity_max) params.append('quantity_max', filters.quantity_max.toString());
    if (filters?.price_min) params.append('price_min', filters.price_min.toString());
    if (filters?.price_max) params.append('price_max', filters.price_max.toString());
    
    return apiClient.get(`/collections?${params.toString()}`);
  },

  getCollectionById: async (collectionId: string): Promise<CollectionResponse> => {
    const response = await apiClient.get(`/collections/${collectionId}`);
    return response as CollectionResponse;
  },

  createCollection: async (data: CreateCollectionData): Promise<CollectionResponse> => {
    return apiClient.post('/collections/create', data);
  },

  updateCollection: async (data: UpdateCollectionData): Promise<CollectionResponse> => {
    return apiClient.put('/collections/update', data);
  },

  cancelCollection: async (collectionId: string): Promise<{ code: number; status: string; message: string }> => {
    return apiClient.delete('/collections/cancel', {
      data: { collection_id: collectionId },
    });
  },
};
