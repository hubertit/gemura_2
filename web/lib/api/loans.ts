import { apiClient } from './client';

export interface LoanRepayment {
  id: string;
  amount: number;
  repayment_date: string;
  notes: string | null;
  source: string;
  created_at: string;
}

export interface Loan {
  id: string;
  lender_account_id: string;
  borrower_type: string;
  borrower_account_id: string | null;
  borrower_account: { id: string; code: string; name: string } | null;
  borrower_name: string | null;
  borrower_label: string;
  principal: number;
  amount_repaid: number;
  outstanding: number;
  currency: string;
  status: string;
  disbursement_date: string;
  due_date: string | null;
  notes: string | null;
  created_at: string;
  updated_at: string;
  repayments?: LoanRepayment[];
}

export interface LoansFilters {
  account_id?: string;
  borrower_type?: string;
  status?: string;
  search?: string;
  date_from?: string;
  date_to?: string;
}

export interface CreateLoanData {
  account_id?: string;
  borrower_type: 'supplier' | 'customer' | 'other';
  borrower_account_id?: string;
  borrower_name?: string;
  borrower_phone?: string;
  principal: number;
  currency?: string;
  disbursement_date: string;
  due_date?: string;
  notes?: string;
}

export interface UpdateLoanData {
  status?: 'active' | 'closed';
  due_date?: string;
  notes?: string;
}

export interface RecordRepaymentData {
  amount: number;
  repayment_date?: string;
  notes?: string;
}

export interface LoansResponse {
  code: number;
  status: string;
  message: string;
  data: Loan[];
}

export interface LoanResponse {
  code: number;
  status: string;
  message: string;
  data: Loan;
}

export const loansApi = {
  getLoans: async (filters?: LoansFilters): Promise<LoansResponse> => {
    const params: Record<string, string> = {};
    if (filters?.account_id) params.account_id = filters.account_id;
    if (filters?.borrower_type) params.borrower_type = filters.borrower_type;
    if (filters?.status) params.status = filters.status;
    if (filters?.search) params.search = filters.search;
    if (filters?.date_from) params.date_from = filters.date_from;
    if (filters?.date_to) params.date_to = filters.date_to;
    const res = await apiClient.post<LoansResponse>('/loans/get', {}, { params });
    return res;
  },

  getLoanById: async (id: string): Promise<LoanResponse> => {
    const res = await apiClient.get<LoanResponse>(`/loans/by-id/${id}`);
    return res;
  },

  createLoan: async (data: CreateLoanData): Promise<LoanResponse> => {
    const res = await apiClient.post<LoanResponse>('/loans/create', data);
    return res;
  },

  updateLoan: async (id: string, data: UpdateLoanData): Promise<LoanResponse> => {
    const res = await apiClient.put<LoanResponse>(`/loans/update/${id}`, data);
    return res;
  },

  recordRepayment: async (id: string, data: RecordRepaymentData): Promise<LoanResponse> => {
    const res = await apiClient.post<LoanResponse>(`/loans/${id}/repayment`, data);
    return res;
  },

  downloadTemplate: async (): Promise<void> => {
    const token = typeof window !== 'undefined' ? localStorage.getItem('gemura-auth-token') : null;
    const baseURL = process.env.NEXT_PUBLIC_API_URL || 'http://localhost:3004/api';
    const res = await fetch(`${baseURL}/loans/template`, {
      headers: token ? { Authorization: `Bearer ${token}` } : {},
    });
    if (!res.ok) throw new Error('Failed to download template');
    const blob = await res.blob();
    const url = URL.createObjectURL(blob);
    const a = document.createElement('a');
    a.href = url;
    a.download = 'loans-template.csv';
    a.click();
    URL.revokeObjectURL(url);
  },

  bulkCreate: async (
    rows: CreateLoanData[],
  ): Promise<{ code: number; data: { success: number; failed: number; errors: { row: number; message: string }[] } }> => {
    const res = await apiClient.post('/loans/bulk', { rows });
    return res.data;
  },
};
