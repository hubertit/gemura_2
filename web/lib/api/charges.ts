import { apiClient } from './client';

export interface ChargeSupplierRef {
  id: string;
  code: string | null;
  name: string;
}

export interface Charge {
  id: string;
  name: string;
  description: string | null;
  kind: string;
  amount_type: string;
  amount: number;
  recurrence: string | null;
  apply_to_all_suppliers: boolean;
  effective_from: string | null;
  effective_to: string | null;
  is_active: boolean;
  created_at: string;
  selected_suppliers?: ChargeSupplierRef[];
}

export interface CreateChargeData {
  name: string;
  description?: string;
  kind: 'one_time' | 'recurring';
  amount_type: 'fixed' | 'percentage';
  amount: number;
  recurrence?: 'monthly' | 'per_payroll';
  apply_to_all_suppliers?: boolean;
  supplier_account_ids?: string[];
  effective_from?: string;
  effective_to?: string;
  is_active?: boolean;
}

export interface UpdateChargeData extends Partial<CreateChargeData> {}

export interface ChargesListParams {
  account_id?: string;
  active_only?: boolean;
}

export interface ChargesResponse {
  code: number;
  status: string;
  message: string;
  data: Charge[];
}

export interface ChargeResponse {
  code: number;
  status: string;
  message: string;
  data: Charge;
}

export const chargesApi = {
  getCharges: async (params?: ChargesListParams): Promise<ChargesResponse> => {
    const body = {
      ...(params?.account_id && { account_id: params.account_id }),
      ...(params?.active_only !== undefined && { active_only: params.active_only }),
    };
    return apiClient.post<ChargesResponse>('/charges/get', body);
  },

  getChargeById: async (id: string, accountId?: string): Promise<ChargeResponse> => {
    const url = accountId ? `/charges/by-id/${id}?account_id=${encodeURIComponent(accountId)}` : `/charges/by-id/${id}`;
    return apiClient.get<ChargeResponse>(url);
  },

  createCharge: async (data: CreateChargeData & { account_id?: string }): Promise<ChargeResponse> => {
    return apiClient.post<ChargeResponse>('/charges/create', data);
  },

  updateCharge: async (id: string, data: UpdateChargeData & { account_id?: string }): Promise<ChargeResponse> => {
    return apiClient.put<ChargeResponse>(`/charges/update/${id}`, data);
  },

  deleteCharge: async (id: string, accountId?: string): Promise<{ code: number; status: string; message: string }> => {
    const url = accountId ? `/charges/delete/${id}?account_id=${encodeURIComponent(accountId)}` : `/charges/delete/${id}`;
    return apiClient.delete(url);
  },
};
