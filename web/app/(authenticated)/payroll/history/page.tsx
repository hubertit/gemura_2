'use client';

import { useState, useEffect, useCallback } from 'react';
import Link from 'next/link';
import { payrollApi, PayrollRun } from '@/lib/api/payroll';
import { useToastStore } from '@/store/toast';
import Icon, { faArrowLeft, faSpinner, faCheckCircle, faCalendar, faUsers, faFileAlt, faClipboardList, faArrowsRotate } from '@/app/components/Icon';
import Modal from '@/app/components/Modal';

export default function PayrollHistoryPage() {
  const [runs, setRuns] = useState<PayrollRun[]>([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState('');
  const [markingId, setMarkingId] = useState<string | null>(null);
  const [exportingId, setExportingId] = useState<string | null>(null);
  const [detailRun, setDetailRun] = useState<PayrollRun | null>(null);

  const loadRuns = useCallback(async () => {
    try {
      setLoading(true);
      setError('');
      const res = await payrollApi.getPayrollRuns();
      if (res.code === 200 && res.data) setRuns(res.data);
      else setRuns([]);
    } catch (err: any) {
      setError(err?.response?.data?.message || err?.message || 'Failed to load payroll runs');
      setRuns([]);
    } finally {
      setLoading(false);
    }
  }, []);

  useEffect(() => {
    loadRuns();
  }, [loadRuns]);

  const handleMarkPaid = async (runId: string) => {
    if (!confirm('Mark this payroll as paid? This will create an expense transaction in finance.')) return;
    setMarkingId(runId);
    try {
      await payrollApi.markPayrollAsPaid(runId);
      useToastStore.getState().success('Payroll marked as paid');
      loadRuns();
    } catch (err: any) {
      useToastStore.getState().error(err?.response?.data?.message || 'Failed to mark as paid');
    } finally {
      setMarkingId(null);
    }
  };

  const handleExport = async (runId: string, format: 'excel' | 'pdf') => {
    setExportingId(runId);
    try {
      await payrollApi.exportPayroll(runId, format);
      useToastStore.getState().success(`Exported as ${format}`);
    } catch (err: any) {
      useToastStore.getState().error(err?.response?.data?.message || `Export ${format} failed`);
    } finally {
      setExportingId(null);
    }
  };

  const formatAmount = (amount: number) =>
    new Intl.NumberFormat('en-RW', { style: 'currency', currency: 'RWF', minimumFractionDigits: 0 }).format(amount);

  const formatDateTime = (dateStr: string) => {
    try {
      return new Date(dateStr).toLocaleString(undefined, {
        month: 'short',
        day: 'numeric',
        year: 'numeric',
        hour: '2-digit',
        minute: '2-digit',
      });
    } catch {
      return dateStr;
    }
  };

  const formatDate = (dateStr: string) => {
    try {
      return new Date(dateStr).toLocaleDateString();
    } catch {
      return dateStr;
    }
  };

  const statusColor = (status: string) => {
    const s = (status || '').toLowerCase();
    if (s === 'completed') return 'bg-green-100 text-green-700';
    if (s === 'draft') return 'bg-amber-100 text-amber-700';
    if (s === 'processing') return 'bg-blue-100 text-blue-700';
    return 'bg-gray-100 text-gray-700';
  };

  const isAllPaid = (run: PayrollRun) => {
    const payslips = run.payslips || [];
    return payslips.length > 0 && payslips.every((p) => (p.status || '').toLowerCase() === 'paid');
  };

  const canMarkPaid = (run: PayrollRun) =>
    (run.status || '').toLowerCase() === 'completed' && !isAllPaid(run) && !markingId;

  if (loading) {
    return (
      <div className="flex items-center justify-center min-h-[300px]">
        <Icon icon={faSpinner} size="lg" spin className="text-[var(--primary)]" />
      </div>
    );
  }

  return (
    <div className="space-y-4">
      <div className="flex items-center justify-between">
        <div>
          <Link href="/payroll" className="text-sm text-gray-600 hover:text-[var(--primary)] mb-2 inline-flex items-center">
            <Icon icon={faArrowLeft} size="sm" className="mr-2" />
            Back to Payroll
          </Link>
          <h1 className="text-2xl font-bold text-gray-900">Payroll History</h1>
        </div>
        {runs.length > 0 && (
          <button type="button" onClick={() => loadRuns()} className="btn btn-secondary" disabled={loading}>
            <Icon icon={loading ? faSpinner : faArrowsRotate} size="sm" className={`mr-2 ${loading ? 'animate-spin' : ''}`} />
            Refresh
          </button>
        )}
      </div>

      {error && (
        <div className="bg-red-50 border border-red-200 rounded-sm p-4">
          <p className="text-sm text-red-600">{error}</p>
          <button type="button" onClick={loadRuns} className="mt-2 text-sm font-medium text-red-700 hover:underline">
            Retry
          </button>
        </div>
      )}

      {!loading && !error && runs.length === 0 && (
        <div className="bg-white border border-gray-200 rounded-sm p-12 text-center">
          <Icon icon={faClipboardList} className="text-gray-300 mx-auto mb-4" size="2x" />
          <p className="text-gray-600 font-medium">No payroll runs found</p>
          <p className="text-sm text-gray-500 mt-1">Generate your first payroll from the Payroll page</p>
          <Link href="/payroll" className="btn btn-primary mt-4 inline-flex">
            Go to Payroll
          </Link>
        </div>
      )}

      {runs.length > 0 && (
        <div className="space-y-3">
          {runs.map((run) => (
            <div
              key={run.id}
              role="button"
              tabIndex={0}
              onClick={() => setDetailRun(run)}
              onKeyDown={(e) => e.key === 'Enter' && setDetailRun(run)}
              className="bg-white border border-gray-200 rounded-sm p-4 hover:border-gray-300 transition-colors cursor-pointer"
            >
              <div className="flex flex-wrap items-start justify-between gap-3">
                <div>
                  <p className="font-semibold text-gray-900">Payroll Run</p>
                  <p className="text-sm text-gray-500">{formatDateTime(run.run_date)}</p>
                  {run.period_start && run.period_end && (
                    <p className="text-sm text-gray-600 mt-1 flex items-center gap-1">
                      <Icon icon={faCalendar} size="sm" className="text-gray-400" />
                      {formatDate(run.period_start)} – {formatDate(run.period_end)}
                    </p>
                  )}
                  <p className="text-sm text-gray-600 flex items-center gap-1 mt-1">
                    <Icon icon={faUsers} size="sm" className="text-gray-400" />
                    {run.payslips_count} supplier{run.payslips_count !== 1 ? 's' : ''}
                  </p>
                </div>
                <div className="flex items-center gap-2">
                  <span className={`px-2 py-1 rounded text-xs font-medium ${statusColor(run.status)}`}>
                    {(run.status || '').toUpperCase()}
                  </span>
                  <span className="text-lg font-bold text-[var(--primary)]">{formatAmount(run.total_amount)}</span>
                </div>
              </div>
              <div className="flex flex-wrap gap-2 mt-4 pt-3 border-t border-gray-100" onClick={(e) => e.stopPropagation()}>
                <div className="flex gap-2">
                  <button
                    type="button"
                    onClick={() => handleExport(run.id, 'excel')}
                    disabled={!!exportingId}
                    className="btn btn-secondary text-sm inline-flex items-center"
                  >
                    {exportingId === run.id ? (
                      <Icon icon={faSpinner} size="sm" spin className="mr-1" />
                    ) : (
                      <Icon icon={faFileAlt} size="sm" className="mr-1" />
                    )}
                    Excel
                  </button>
                  <button
                    type="button"
                    onClick={() => handleExport(run.id, 'pdf')}
                    disabled={!!exportingId}
                    className="btn btn-secondary text-sm inline-flex items-center"
                  >
                    {exportingId === run.id ? (
                      <Icon icon={faSpinner} size="sm" spin className="mr-1" />
                    ) : (
                      <Icon icon={faFileAlt} size="sm" className="mr-1" />
                    )}
                    PDF
                  </button>
                </div>
                {canMarkPaid(run) && (
                  <button
                    type="button"
                    onClick={() => handleMarkPaid(run.id)}
                    disabled={!!markingId}
                    className="btn btn-primary text-sm inline-flex items-center"
                  >
                    {markingId === run.id ? (
                      <Icon icon={faSpinner} size="sm" spin className="mr-1" />
                    ) : (
                      <Icon icon={faCheckCircle} size="sm" className="mr-1" />
                    )}
                    Mark as Paid
                  </button>
                )}
              </div>
            </div>
          ))}
        </div>
      )}

      {/* Payroll run detail modal (same as mobile bottom sheet) */}
      <Modal
        open={!!detailRun}
        onClose={() => setDetailRun(null)}
        title="Payroll Details"
        maxWidth="max-w-lg"
        footer={
          detailRun ? (
            <div className="flex flex-wrap gap-2 justify-end">
              <button
                type="button"
                onClick={() => { handleExport(detailRun.id, 'excel'); }}
                disabled={!!exportingId}
                className="btn btn-secondary text-sm"
              >
                Export Excel
              </button>
              <button
                type="button"
                onClick={() => { handleExport(detailRun.id, 'pdf'); }}
                disabled={!!exportingId}
                className="btn btn-secondary text-sm"
              >
                Export PDF
              </button>
              {canMarkPaid(detailRun) && (
                <button
                  type="button"
                  onClick={() => { handleMarkPaid(detailRun.id); setDetailRun(null); }}
                  disabled={!!markingId}
                  className="btn btn-primary text-sm"
                >
                  Mark as Paid
                </button>
              )}
            </div>
          ) : null
        }
      >
        {detailRun && (
          <div className="space-y-4">
            <div className="grid grid-cols-1 sm:grid-cols-2 gap-3 text-sm">
              <div>
                <p className="text-gray-500 font-medium">Status</p>
                <span className={`inline-flex px-2 py-1 rounded text-xs font-medium ${statusColor(detailRun.status || '')}`}>
                  {(detailRun.status || '').toUpperCase()}
                </span>
              </div>
              <div>
                <p className="text-gray-500 font-medium">Run Date</p>
                <p className="text-gray-900">{detailRun.run_date ? formatDateTime(detailRun.run_date) : '—'}</p>
              </div>
              {detailRun.period_start && detailRun.period_end && (
                <div className="sm:col-span-2">
                  <p className="text-gray-500 font-medium">Period</p>
                  <p className="text-gray-900">{formatDate(detailRun.period_start)} – {formatDate(detailRun.period_end)}</p>
                </div>
              )}
              <div>
                <p className="text-gray-500 font-medium">Total Amount</p>
                <p className="text-gray-900 font-semibold text-[var(--primary)]">{formatAmount(detailRun.total_amount ?? 0)}</p>
              </div>
              {detailRun.payment_terms_days != null && (
                <div>
                  <p className="text-gray-500 font-medium">Payment Terms</p>
                  <p className="text-gray-900">{detailRun.payment_terms_days} days</p>
                </div>
              )}
            </div>
            <div>
              <h3 className="text-sm font-semibold text-gray-900 mb-2">Payslips ({detailRun.payslips?.length ?? 0})</h3>
              <div className="border border-gray-200 rounded-sm divide-y divide-gray-100 max-h-64 overflow-y-auto">
                {(detailRun.payslips || []).map((p) => (
                  <div key={p.id} className="p-3 flex items-center justify-between bg-gray-50/50">
                    <span className="font-medium text-gray-900">{p.supplier ?? p.supplier_code ?? 'Unknown'}</span>
                    <span className="text-sm text-gray-600">
                      {p.milk_sales_count ?? 0} collections · {formatAmount(p.net_amount ?? 0)}
                    </span>
                  </div>
                ))}
              </div>
            </div>
          </div>
        )}
      </Modal>
    </div>
  );
}
