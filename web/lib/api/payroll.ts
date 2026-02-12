import { apiClient } from './client';

export interface GeneratePayrollParams {
  supplier_account_codes: string[];
  period_start: string; // YYYY-MM-DD
  period_end: string;   // YYYY-MM-DD
  payment_terms_days?: number;
  run_name?: string;    // Optional custom name for the payroll run
}

export interface GeneratePayrollResult {
  run_id: string;
  period_start: string;
  period_end: string;
  suppliers_processed: number;
  total_amount: number;
  payslips: Array<{
    id?: string;
    supplier?: string;
    supplier_code?: string;
    milk_sales_count?: number;
    net_amount?: number;
    gross_amount?: number;
    deductions?: number;
    status?: string;
  }>;
}

export interface PayrollRun {
  id: string;
  period_name?: string;
  run_date: string;
  period_start: string | null;
  period_end: string | null;
  payment_terms_days?: number | null;
  total_amount: number;
  status: string;
  payslips_count: number;
  payslips: Array<{
    id: string;
    supplier?: string;
    supplier_code?: string;
    milk_sales_count?: number;
    gross_amount?: number;
    deductions?: number;
    net_amount?: number;
    status?: string;
  }>;
}

export interface PayrollRunsResponse {
  code: number;
  status: string;
  message: string;
  data: PayrollRun[];
}

export interface GeneratePayrollResponse {
  code: number;
  status: string;
  message: string;
  data: GeneratePayrollResult;
}

export const payrollApi = {
  generatePayroll: async (params: GeneratePayrollParams): Promise<GeneratePayrollResponse> => {
    return apiClient.post('/payroll/runs/generate', {
      supplier_account_codes: params.supplier_account_codes,
      period_start: params.period_start,
      period_end: params.period_end,
      ...(params.payment_terms_days != null && { payment_terms_days: params.payment_terms_days }),
      ...(params.run_name != null && params.run_name.trim() !== '' && { run_name: params.run_name.trim() }),
    });
  },

  getPayrollRuns: async (periodId?: string): Promise<PayrollRunsResponse> => {
    const params = periodId ? `?period_id=${encodeURIComponent(periodId)}` : '';
    return apiClient.get(`/payroll/runs${params}`);
  },

  markPayrollAsPaid: async (
    runId: string,
    options?: { payment_date?: string; payslip_id?: string }
  ): Promise<{ code: number; status: string; message: string; data?: unknown }> => {
    return apiClient.post(`/payroll/runs/${runId}/mark-paid`, {
      ...(options?.payment_date && { payment_date: options.payment_date }),
      ...(options?.payslip_id && { payslip_id: options.payslip_id }),
    });
  },

  /** Export payroll run as Excel or PDF. Triggers browser download. */
  exportPayroll: async (runId: string, format: 'excel' | 'pdf'): Promise<void> => {
    const blob = await apiClient.get<Blob>(`/payroll/runs/${runId}/export?format=${format}`, {
      responseType: 'blob',
    });
    const ext = format === 'pdf' ? 'pdf' : 'xlsx';
    const filename = `payroll_${runId.slice(0, 8)}_${Date.now()}.${ext}`;
    const url = URL.createObjectURL(blob);
    const a = document.createElement('a');
    a.href = url;
    a.download = filename;
    document.body.appendChild(a);
    a.click();
    document.body.removeChild(a);
    URL.revokeObjectURL(url);
  },
};
