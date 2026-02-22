'use client';

import { useState, useEffect, useCallback } from 'react';
import Link from 'next/link';
import { accountingApi, PayablesSummary, Payable } from '@/lib/api/accounting';
import { collectionsApi } from '@/lib/api/collections';
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

export default function FinancePayablesPage() {
  const [fromDate, setFromDate] = useState(() => {
    const d = new Date();
    d.setDate(d.getDate() - 30);
    return d.toISOString().slice(0, 10);
  });
  const [toDate, setToDate] = useState(() => new Date().toISOString().slice(0, 10));
  const [summary, setSummary] = useState<PayablesSummary | null>(null);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);
  const [paymentModal, setPaymentModal] = useState<{ pay: Payable } | null>(null);
  const [payAmount, setPayAmount] = useState('');
  const [payDate, setPayDate] = useState(() => new Date().toISOString().slice(0, 10));
  const [payNotes, setPayNotes] = useState('');
  const [paySubmitting, setPaySubmitting] = useState(false);

  const load = useCallback(async () => {
    setLoading(true);
    setError(null);
    try {
      const data = await accountingApi.getPayables({ date_from: fromDate, date_to: toDate });
      setSummary(data);
    } catch (e: unknown) {
      const msg =
        (e as { response?: { data?: { message?: string } }; message?: string })?.response?.data?.message ??
        (e as Error)?.message ??
        'Failed to load payables';
      setError(msg);
      setSummary(null);
    } finally {
      setLoading(false);
    }
  }, [fromDate, toDate]);

  useEffect(() => {
    load();
  }, [load]);

  const openPaymentModal = (pay: Payable) => {
    setPaymentModal({ pay });
    setPayAmount(String(Math.round(pay.outstanding)));
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
    if (amount > paymentModal.pay.outstanding) {
      useToastStore.getState().error('Amount cannot exceed outstanding balance');
      return;
    }
    setPaySubmitting(true);
    try {
      await collectionsApi.recordPayment(paymentModal.pay.collection_id, {
        amount,
        payment_date: payDate,
        notes: payNotes.trim() || undefined,
      });
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
    <div className="space-y-3">
      <div className="flex flex-wrap items-center justify-between gap-2">
        <div>
          <Link href="/finance" className="text-xs text-gray-600 hover:text-[var(--primary)] mb-1 inline-flex items-center">
            <Icon icon={faArrowLeft} size="sm" className="mr-1.5" />
            Back to Finance
          </Link>
          <h1 className="text-xl font-bold text-gray-900">Payables</h1>
        </div>
        <div className="flex items-center gap-1.5">
          <div className="flex">
            <span className="inline-flex items-center rounded-l border border-gray-300 border-r-0 bg-gray-100 px-2 py-1 text-xs font-medium text-gray-700">
              From
            </span>
            <input
              type="date"
              value={fromDate}
              onChange={(e) => setFromDate(e.target.value)}
              className="rounded-r border border-gray-300 px-1.5 py-1 text-xs w-[130px]"
              aria-label="From date"
            />
          </div>
          <div className="flex">
            <span className="inline-flex items-center rounded-l border border-gray-300 border-r-0 bg-gray-100 px-2 py-1 text-xs font-medium text-gray-700">
              To
            </span>
            <input
              type="date"
              value={toDate}
              onChange={(e) => setToDate(e.target.value)}
              className="rounded-r border border-gray-300 px-1.5 py-1 text-xs w-[130px]"
              aria-label="To date"
            />
          </div>
          <button type="button" onClick={() => load()} className="btn btn-secondary text-sm py-1.5 px-2.5" disabled={loading}>
            <Icon icon={loading ? faSpinner : faArrowsRotate} size="sm" className={`mr-1.5 ${loading ? 'animate-spin' : ''}`} />
            Refresh
          </button>
        </div>
      </div>

      {error && (
        <div className="flex items-center gap-2 rounded border border-red-200 bg-red-50 p-2 text-sm text-red-800">
          <Icon icon={faTriangleExclamation} size="sm" />
          <span>{error}</span>
          <button type="button" onClick={() => load()} className="ml-2 text-sm underline">
            Retry
          </button>
        </div>
      )}

      {loading && !summary ? (
        <ListPageSkeleton title="Payables" filterFields={2} tableRows={10} tableCols={5} />
      ) : summary ? (
        <>
          {/* Summary card */}
          <div className="rounded-sm border border-gray-200 bg-white p-3">
            <div className="flex justify-between items-baseline">
              <span className="text-xs text-gray-500">Total Payables</span>
              <span className="text-lg font-bold text-red-700">{formatAmount(summary.total_payables)}</span>
            </div>
            <div className="flex justify-between border-t border-gray-100 pt-1.5 mt-1.5 text-xs text-gray-500">
              <span>Total Invoices</span>
              <span className="font-medium text-gray-700">{summary.total_invoices}</span>
            </div>
          </div>

          {/* Aging summary */}
          {hasAging && aging && (
            <div className="rounded-sm border border-gray-200 bg-white p-3">
              <h2 className="text-xs font-semibold text-gray-900">Aging Summary</h2>
              <div className="mt-2 space-y-1">
                <div className="flex justify-between text-xs">
                  <span className="text-gray-500">Current (0–30 days)</span>
                  <span className="font-medium text-emerald-600">{formatAmount(aging.current)}</span>
                </div>
                <div className="flex justify-between text-xs">
                  <span className="text-gray-500">31–60 days</span>
                  <span className="font-medium text-red-600">{formatAmount(aging.days_31_60)}</span>
                </div>
                <div className="flex justify-between text-xs">
                  <span className="text-gray-500">61–90 days</span>
                  <span className="font-medium text-red-600">{formatAmount(aging.days_61_90)}</span>
                </div>
                <div className="flex justify-between text-xs">
                  <span className="text-gray-500">90+ days</span>
                  <span className="font-medium text-red-600">{formatAmount(aging.days_90_plus)}</span>
                </div>
              </div>
            </div>
          )}

          {/* By supplier */}
          {summary.by_supplier.length > 0 && (
            <div>
              <h2 className="text-xs font-semibold text-gray-900 mb-1.5">By Supplier</h2>
              <div className="grid gap-2 sm:grid-cols-2">
                {summary.by_supplier.map((sp) => (
                  <div key={sp.supplier.id} className="rounded-sm border border-gray-200 bg-white p-2.5">
                    <p className="font-medium text-sm text-gray-900">{sp.supplier.name}</p>
                    <p className="text-xs text-gray-500">{sp.supplier.code}</p>
                    <p className="mt-1 font-semibold text-sm text-red-600">{formatAmount(sp.total_outstanding)}</p>
                    <p className="text-xs text-gray-500">{sp.invoice_count} invoice(s)</p>
                  </div>
                ))}
              </div>
            </div>
          )}

          {/* All payables */}
          <div>
            <h2 className="text-xs font-semibold text-gray-900 mb-1.5">All Payables</h2>
            {summary.all_payables.length === 0 ? (
              <div className="rounded-sm border border-gray-200 bg-gray-50 p-4 text-center text-xs text-gray-500">
                No payables in this period.
              </div>
            ) : (
              <ul className="space-y-1.5">
                {summary.all_payables.map((pay) => (
                  <li key={pay.collection_id} className="rounded-sm border border-gray-200 bg-white p-2.5">
                    <div className="flex flex-wrap items-center justify-between gap-2">
                      <div className="min-w-0">
                        <p className="font-medium text-sm text-gray-900">{pay.supplier.name}</p>
                        <p className="text-xs text-gray-500">{formatDate(pay.collection_date)} · Total: {formatAmount(pay.total_amount)} · Paid: {formatAmount(pay.amount_paid)}</p>
                      </div>
                      <div className="flex items-center gap-2 flex-shrink-0">
                        <span className="rounded bg-gray-100 px-1.5 py-0.5 text-xs text-gray-600">
                          {pay.aging_bucket === 'current' ? 'Current' : `${pay.days_outstanding}d`}
                        </span>
                        <span className="font-semibold text-sm text-red-600">{formatAmount(pay.outstanding)}</span>
                        {pay.outstanding > 0 && (
                          <button
                            type="button"
                            onClick={() => openPaymentModal(pay)}
                            className="rounded bg-red-600 px-2 py-1 text-xs font-medium text-white hover:bg-red-700"
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
        title="Record Payment (Payable)"
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
              <p className="text-gray-500">Supplier</p>
              <p className="font-medium text-gray-900">{paymentModal.pay.supplier.name}</p>
              <p className="text-gray-500 mt-1">Outstanding: <span className="font-semibold text-red-600">{formatAmount(paymentModal.pay.outstanding)}</span></p>
            </div>
            <div>
              <label className="block text-sm font-medium text-gray-700">Amount (RWF)</label>
              <input
                type="number"
                min="1"
                max={paymentModal.pay.outstanding}
                value={payAmount}
                onChange={(e) => setPayAmount(e.target.value)}
                className="mt-1 w-full rounded border border-gray-300 px-3 py-2"
              />
              <button
                type="button"
                onClick={() => setPayAmount(String(Math.round(paymentModal.pay.outstanding)))}
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
                placeholder="e.g. Bank transfer"
              />
            </div>
          </div>
        )}
      </Modal>
    </div>
  );
}
