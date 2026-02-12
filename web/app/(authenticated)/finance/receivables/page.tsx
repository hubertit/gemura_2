'use client';

import { useState, useEffect, useCallback } from 'react';
import Link from 'next/link';
import { accountingApi, ReceivablesSummary, Receivable } from '@/lib/api/accounting';
import { salesApi } from '@/lib/api/sales';
import { loansApi } from '@/lib/api/loans';
import { useToastStore } from '@/store/toast';
import Icon, {
  faArrowLeft,
  faSpinner,
  faArrowsRotate,
  faTriangleExclamation,
  faCheckCircle,
} from '@/app/components/Icon';
import Modal from '@/app/components/Modal';
import { ListPageSkeleton } from '@/app/components/SkeletonLoader';

function formatDate(str: string): string {
  try {
    return new Date(str).toLocaleDateString('en-US', { month: 'short', day: 'numeric', year: 'numeric' });
  } catch {
    return str;
  }
}

function formatAmount(amount: number): string {
  return new Intl.NumberFormat('en-RW', { style: 'currency', currency: 'RWF', minimumFractionDigits: 0 }).format(amount);
}

export default function FinanceReceivablesPage() {
  const [fromDate, setFromDate] = useState(() => {
    const d = new Date();
    d.setDate(d.getDate() - 30);
    return d.toISOString().slice(0, 10);
  });
  const [toDate, setToDate] = useState(() => new Date().toISOString().slice(0, 10));
  const [summary, setSummary] = useState<ReceivablesSummary | null>(null);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);
  const [paymentModal, setPaymentModal] = useState<{
    rec: Receivable;
  } | null>(null);
  const [payAmount, setPayAmount] = useState('');
  const [payDate, setPayDate] = useState(() => new Date().toISOString().slice(0, 10));
  const [payNotes, setPayNotes] = useState('');
  const [paySubmitting, setPaySubmitting] = useState(false);

  const load = useCallback(async () => {
    setLoading(true);
    setError(null);
    try {
      const data = await accountingApi.getReceivables({ date_from: fromDate, date_to: toDate });
      setSummary(data);
    } catch (e: unknown) {
      const msg =
        (e as { response?: { data?: { message?: string } }; message?: string })?.response?.data?.message ??
        (e as Error)?.message ??
        'Failed to load receivables';
      setError(msg);
      setSummary(null);
    } finally {
      setLoading(false);
    }
  }, [fromDate, toDate]);

  useEffect(() => {
    load();
  }, [load]);

  const openPaymentModal = (rec: Receivable) => {
    setPaymentModal({ rec });
    setPayAmount(String(Math.round(rec.outstanding)));
    setPayDate(new Date().toISOString().slice(0, 10));
    setPayNotes('');
  };

  const submitPayment = async () => {
    if (!paymentModal) return;
    const amount = Number(payAmount);
    if (Number.isNaN(amount) || amount <= 0) {
      useToastStore.getState().error('Enter a valid amount');
      return;
    }
    if (amount > paymentModal.rec.outstanding) {
      useToastStore.getState().error('Amount cannot exceed outstanding balance');
      return;
    }
    const rec = paymentModal.rec;
    const source = rec.source || 'milk_sale';
    setPaySubmitting(true);
    try {
      if (source === 'loan') {
        await loansApi.recordRepayment(rec.sale_id, {
          amount,
          repayment_date: payDate,
          notes: payNotes.trim() || undefined,
        });
      } else if (source === 'inventory_sale') {
        await accountingApi.recordInventoryReceivablePayment(rec.sale_id, {
          amount,
          payment_date: payDate,
          notes: payNotes.trim() || undefined,
        });
      } else {
        await salesApi.recordPayment(rec.sale_id, {
          amount,
          payment_date: payDate,
          notes: payNotes.trim() || undefined,
        });
      }
      useToastStore.getState().success('Payment recorded');
      setPaymentModal(null);
      load();
    } catch (e: unknown) {
      const msg =
        (e as { response?: { data?: { message?: string } }; message?: string })?.response?.data?.message ??
        (e as Error)?.message ??
        'Failed to record payment';
      useToastStore.getState().error(msg);
    } finally {
      setPaySubmitting(false);
    }
  };

  const aging = summary?.aging_summary;
  const hasAging = aging && (aging.current > 0 || aging.days_31_60 > 0 || aging.days_61_90 > 0 || aging.days_90_plus > 0);

  return (
    <div className="space-y-4">
      <div className="flex flex-wrap items-center justify-between gap-4">
        <div>
          <Link href="/finance" className="text-sm text-gray-600 hover:text-[var(--primary)] mb-2 inline-flex items-center">
            <Icon icon={faArrowLeft} size="sm" className="mr-2" />
            Back to Finance
          </Link>
          <h1 className="text-2xl font-bold text-gray-900">Receivables</h1>
        </div>
        <div className="flex items-center gap-2">
          <div className="flex">
            <span className="inline-flex items-center rounded-l border border-gray-300 border-r-0 bg-gray-100 px-3 py-1.5 text-sm font-medium text-gray-700">
              From
            </span>
            <input
              type="date"
              value={fromDate}
              onChange={(e) => setFromDate(e.target.value)}
              className="rounded-r border border-gray-300 px-2 py-1.5 text-sm"
              aria-label="From date"
            />
          </div>
          <div className="flex">
            <span className="inline-flex items-center rounded-l border border-gray-300 border-r-0 bg-gray-100 px-3 py-1.5 text-sm font-medium text-gray-700">
              To
            </span>
            <input
              type="date"
              value={toDate}
              onChange={(e) => setToDate(e.target.value)}
              className="rounded-r border border-gray-300 px-2 py-1.5 text-sm"
              aria-label="To date"
            />
          </div>
          <button type="button" onClick={() => load()} className="btn btn-secondary" disabled={loading}>
            <Icon icon={loading ? faSpinner : faArrowsRotate} size="sm" className={`mr-2 ${loading ? 'animate-spin' : ''}`} />
            Refresh
          </button>
        </div>
      </div>

      {error && (
        <div className="flex items-center gap-2 rounded border border-red-200 bg-red-50 p-3 text-red-800">
          <Icon icon={faTriangleExclamation} size="sm" />
          <span>{error}</span>
          <button type="button" onClick={() => load()} className="ml-2 text-sm underline">
            Retry
          </button>
        </div>
      )}

      {loading && !summary ? (
        <ListPageSkeleton title="Receivables" filterFields={2} tableRows={10} tableCols={5} />
      ) : summary ? (
        <>
          {/* Summary card */}
          <div className="rounded-sm border border-gray-200 bg-white p-4">
            <div className="flex justify-between">
              <span className="text-sm text-gray-500">Total Receivables</span>
              <span className="text-xl font-bold text-emerald-700">{formatAmount(summary.total_receivables)}</span>
            </div>
            <div className="mt-2 flex justify-between border-t border-gray-100 pt-2 text-sm text-gray-500">
              <span>Total Invoices</span>
              <span className="font-medium text-gray-700">{summary.total_invoices}</span>
            </div>
          </div>

          {/* Aging summary */}
          {hasAging && aging && (
            <div className="rounded-sm border border-gray-200 bg-white p-4">
              <h2 className="text-sm font-semibold text-gray-900">Aging Summary</h2>
              <div className="mt-3 space-y-2">
                <div className="flex justify-between text-sm">
                  <span className="text-gray-500">Current (0–30 days)</span>
                  <span className="font-medium text-emerald-600">{formatAmount(aging.current)}</span>
                </div>
                <div className="flex justify-between text-sm">
                  <span className="text-gray-500">31–60 days</span>
                  <span className="font-medium text-red-600">{formatAmount(aging.days_31_60)}</span>
                </div>
                <div className="flex justify-between text-sm">
                  <span className="text-gray-500">61–90 days</span>
                  <span className="font-medium text-red-600">{formatAmount(aging.days_61_90)}</span>
                </div>
                <div className="flex justify-between text-sm">
                  <span className="text-gray-500">90+ days</span>
                  <span className="font-medium text-red-600">{formatAmount(aging.days_90_plus)}</span>
                </div>
              </div>
            </div>
          )}

          {/* By customer */}
          {summary.by_customer.length > 0 && (
            <div>
              <h2 className="text-sm font-semibold text-gray-900 mb-2">By Customer</h2>
              <div className="grid gap-3 sm:grid-cols-2">
                {summary.by_customer.map((cr) => (
                  <div key={cr.customer.id} className="rounded-sm border border-gray-200 bg-white p-4">
                    <p className="font-medium text-gray-900">{cr.customer.name}</p>
                    <p className="text-xs text-gray-500">{cr.customer.code}</p>
                    <p className="mt-2 font-semibold text-emerald-600">{formatAmount(cr.total_outstanding)}</p>
                    <p className="text-xs text-gray-500">{cr.invoice_count} invoice(s)</p>
                  </div>
                ))}
              </div>
            </div>
          )}

          {/* All receivables */}
          <div>
            <h2 className="text-sm font-semibold text-gray-900 mb-2">All Receivables</h2>
            {summary.all_receivables.length === 0 ? (
              <div className="rounded-sm border border-gray-200 bg-gray-50 p-6 text-center text-gray-500">
                No receivables in this period.
              </div>
            ) : (
              <ul className="space-y-2">
                {summary.all_receivables.map((rec) => (
                  <li key={rec.sale_id} className="rounded-sm border border-gray-200 bg-white p-4">
                    <div className="flex flex-wrap items-start justify-between gap-4">
                      <div>
                        <p className="font-medium text-gray-900">{rec.customer.name}</p>
                        <p className="text-xs text-gray-500">{formatDate(rec.sale_date)}</p>
                        <p className="mt-1 text-xs text-gray-500">
                          Total: {formatAmount(rec.total_amount)} · Paid: {formatAmount(rec.amount_paid)}
                        </p>
                      </div>
                      <div className="text-right">
                        <p className="font-semibold text-emerald-600">{formatAmount(rec.outstanding)}</p>
                        <span className="inline-block rounded bg-gray-100 px-2 py-0.5 text-xs text-gray-600">
                          {rec.aging_bucket === 'current' ? 'Current' : `${rec.days_outstanding} days`}
                        </span>
                        {rec.outstanding > 0 && (
                          <button
                            type="button"
                            onClick={() => openPaymentModal(rec)}
                            className="mt-2 block w-full rounded bg-emerald-600 px-3 py-1.5 text-sm font-medium text-white hover:bg-emerald-700"
                          >
                            Record Payment
                          </button>
                        )}
                      </div>
                    </div>
                  </li>
                ))}
              </ul>
            )}
          </div>
        </>
      ) : null}

      {/* Record payment modal */}
      <Modal
        open={!!paymentModal}
        onClose={() => !paySubmitting && setPaymentModal(null)}
        title="Record Payment (Receivable)"
        maxWidth="max-w-md"
        footer={
          <div className="flex justify-end gap-2">
            <button type="button" onClick={() => setPaymentModal(null)} className="btn btn-secondary" disabled={paySubmitting}>
              Cancel
            </button>
            <button type="button" onClick={submitPayment} className="btn btn-primary" disabled={paySubmitting}>
              {paySubmitting ? <Icon icon={faSpinner} spin size="sm" className="mr-2" /> : <Icon icon={faCheckCircle} size="sm" className="mr-2" />}
              Record Payment
            </button>
          </div>
        }
      >
        {paymentModal && (
          <div className="space-y-4">
            <div className="rounded bg-gray-50 p-3 text-sm">
              <p className="text-gray-500">Customer</p>
              <p className="font-medium text-gray-900">{paymentModal.rec.customer.name}</p>
              <p className="text-gray-500 mt-1">Outstanding: <span className="font-semibold text-emerald-600">{formatAmount(paymentModal.rec.outstanding)}</span></p>
            </div>
            <div>
              <label className="block text-sm font-medium text-gray-700">Amount (RWF)</label>
              <input
                type="number"
                min="1"
                max={paymentModal.rec.outstanding}
                value={payAmount}
                onChange={(e) => setPayAmount(e.target.value)}
                className="mt-1 w-full rounded border border-gray-300 px-3 py-2"
              />
              <button
                type="button"
                onClick={() => setPayAmount(String(Math.round(paymentModal.rec.outstanding)))}
                className="mt-1 text-xs text-[var(--primary)] hover:underline"
              >
                Use full outstanding
              </button>
            </div>
            <div>
              <label className="block text-sm font-medium text-gray-700">Payment Date</label>
              <input type="date" value={payDate} onChange={(e) => setPayDate(e.target.value)} className="mt-1 w-full rounded border border-gray-300 px-3 py-2" />
            </div>
            <div>
              <label className="block text-sm font-medium text-gray-700">Notes (optional)</label>
              <input
                type="text"
                value={payNotes}
                onChange={(e) => setPayNotes(e.target.value)}
                className="mt-1 w-full rounded border border-gray-300 px-3 py-2"
                placeholder="e.g. Payment via mobile money"
              />
            </div>
          </div>
        )}
      </Modal>
    </div>
  );
}
