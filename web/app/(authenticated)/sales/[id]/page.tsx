'use client';

import { useState, useEffect } from 'react';
import { useRouter, useParams, useSearchParams } from 'next/navigation';
import Link from 'next/link';
import { usePermission } from '@/hooks/usePermission';
import { salesApi, Sale } from '@/lib/api/sales';
import Icon, { faReceipt, faUser, faDollarSign, faCalendar, faFileAlt, faEdit, faArrowLeft, faSpinner, faCheckCircle, faBuilding } from '@/app/components/Icon';

export default function SaleDetailsPage() {
  const router = useRouter();
  const params = useParams();
  const searchParams = useSearchParams();
  const saleId = params.id as string;
  const { hasPermission, isAdmin } = usePermission();
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState('');
  const [sale, setSale] = useState<Sale | null>(null);

  useEffect(() => {
    if (!hasPermission('view_sales') && !isAdmin()) {
      router.push('/sales');
      return;
    }
    loadSale();
  }, [saleId, hasPermission, isAdmin, router]);

  const loadSale = async () => {
    try {
      setLoading(true);
      setError('');
      const response = await salesApi.getSaleById(saleId);
      if (response.code === 200 && response.data) {
        setSale(response.data);
      } else {
        setError('Failed to load sale data');
      }
    } catch (err: any) {
      setError(err?.response?.data?.message || err?.message || 'Failed to load sale. Please try again.');
    } finally {
      setLoading(false);
    }
  };

  const formatCurrency = (amount: number) => {
    return new Intl.NumberFormat('en-RW', {
      style: 'currency',
      currency: 'RWF',
      minimumFractionDigits: 0,
    }).format(amount);
  };

  if (loading) {
    return (
      <div className="flex items-center justify-center min-h-[400px]">
        <div className="text-center">
          <Icon icon={faSpinner} size="lg" spin className="text-[var(--primary)] mb-4" />
          <p className="text-gray-600">Loading sale data...</p>
        </div>
      </div>
    );
  }

  if (error && !sale) {
    return (
      <div className="space-y-4">
        <div className="bg-red-50 border border-red-200 rounded-sm p-4">
          <p className="text-sm text-red-600">{error}</p>
        </div>
        <Link href="/sales" className="btn btn-secondary">
          <Icon icon={faArrowLeft} size="sm" className="mr-2" />
          Back to Sales
        </Link>
      </div>
    );
  }

  const statusColors: Record<string, string> = {
    pending: 'bg-yellow-100 text-yellow-700',
    accepted: 'bg-green-100 text-green-700',
    rejected: 'bg-red-100 text-red-700',
    cancelled: 'bg-gray-100 text-gray-700',
    deleted: 'bg-red-100 text-red-700',
  };

  return (
    <div className="space-y-4">

      {/* Page Header */}
      <div className="flex items-center justify-between">
        <div>
          <Link href="/sales" className="text-sm text-gray-600 hover:text-[var(--primary)] mb-2 inline-flex items-center">
            <Icon icon={faArrowLeft} size="sm" className="mr-2" />
            Back to Sales
          </Link>
          <h1 className="text-2xl font-bold text-gray-900">Sale Details</h1>
        </div>
        {sale && sale.status !== 'cancelled' && sale.status !== 'deleted' && (
          <Link href={`/sales/${saleId}/edit`} className="btn btn-primary">
            <Icon icon={faEdit} size="sm" className="mr-2" />
            Edit Sale
          </Link>
        )}
      </div>

      {/* Error Message */}
      {error && (
        <div className="bg-red-50 border border-red-200 rounded-sm p-4">
          <p className="text-sm text-red-600">{error}</p>
        </div>
      )}

      {sale && (
        <div className="grid grid-cols-1 lg:grid-cols-3 gap-4">
          {/* Main Information */}
          <div className="lg:col-span-2 space-y-4">
            {/* Sale Information */}
            <div className="bg-white border border-gray-200 rounded-sm p-6">
              <h2 className="text-lg font-semibold text-gray-900 mb-4">Sale Information</h2>
              <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
                <div>
                  <label className="block text-sm font-medium text-gray-500 mb-1">Sale ID</label>
                  <p className="text-sm text-gray-900 font-mono">{sale.id}</p>
                </div>

                <div>
                  <label className="block text-sm font-medium text-gray-500 mb-1">Status</label>
                  <span className={`inline-flex px-2 py-1 text-xs font-medium rounded-full ${statusColors[sale.status] || 'bg-gray-100 text-gray-700'}`}>
                    {sale.status.charAt(0).toUpperCase() + sale.status.slice(1)}
                  </span>
                </div>

                <div>
                  <label className="block text-sm font-medium text-gray-500 mb-1">Sale Date</label>
                  <div className="flex items-center text-gray-900">
                    <Icon icon={faCalendar} size="sm" className="mr-2 text-gray-400" />
                    <span>{new Date(sale.sale_at).toLocaleString()}</span>
                  </div>
                </div>

                <div>
                  <label className="block text-sm font-medium text-gray-500 mb-1">Created At</label>
                  <div className="flex items-center text-gray-900">
                    <Icon icon={faCalendar} size="sm" className="mr-2 text-gray-400" />
                    <span>{new Date(sale.created_at).toLocaleString()}</span>
                  </div>
                </div>
              </div>
            </div>

            {/* Customer & Supplier Information */}
            <div className="bg-white border border-gray-200 rounded-sm p-6">
              <h2 className="text-lg font-semibold text-gray-900 mb-4">Parties</h2>
              <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
                <div>
                  <label className="block text-sm font-medium text-gray-500 mb-1">Customer</label>
                  <div className="flex items-center text-gray-900">
                    <Icon icon={faUser} size="sm" className="mr-2 text-gray-400" />
                    <div>
                      <div className="font-medium">{sale.customer_account.name}</div>
                      <div className="text-xs text-gray-500">{sale.customer_account.code}</div>
                    </div>
                  </div>
                </div>

                <div>
                  <label className="block text-sm font-medium text-gray-500 mb-1">Supplier</label>
                  <div className="flex items-center text-gray-900">
                    <Icon icon={faBuilding} size="sm" className="mr-2 text-gray-400" />
                    <div>
                      <div className="font-medium">{sale.supplier_account.name}</div>
                      <div className="text-xs text-gray-500">{sale.supplier_account.code}</div>
                    </div>
                  </div>
                </div>
              </div>
            </div>

            {/* Financial Details */}
            <div className="bg-white border border-gray-200 rounded-sm p-6">
              <h2 className="text-lg font-semibold text-gray-900 mb-4">Financial Details</h2>
              <div className="space-y-3">
                <div className="flex items-center justify-between py-2 border-b border-gray-100">
                  <span className="text-sm text-gray-600">Quantity</span>
                  <span className="text-sm font-medium text-gray-900">{Number(sale.quantity).toFixed(2)}L</span>
                </div>
                <div className="flex items-center justify-between py-2 border-b border-gray-100">
                  <span className="text-sm text-gray-600">Unit Price</span>
                  <span className="text-sm font-medium text-gray-900">{formatCurrency(Number(sale.unit_price))}</span>
                </div>
                <div className="flex items-center justify-between py-3 border-t-2 border-gray-200">
                  <span className="text-base font-semibold text-gray-900">Total Amount</span>
                  <span className="text-lg font-bold text-[var(--primary)]">{formatCurrency(Number(sale.total_amount))}</span>
                </div>
              </div>
            </div>

            {/* Notes */}
            {sale.notes && (
              <div className="bg-white border border-gray-200 rounded-sm p-6">
                <h2 className="text-lg font-semibold text-gray-900 mb-4">Notes</h2>
                <div className="flex items-start">
                  <Icon icon={faFileAlt} size="sm" className="mr-2 text-gray-400 mt-1" />
                  <p className="text-sm text-gray-700 whitespace-pre-wrap">{sale.notes}</p>
                </div>
              </div>
            )}
          </div>

          {/* Sidebar */}
          <div className="space-y-4">
            {/* Quick Actions */}
            <div className="bg-white border border-gray-200 rounded-sm p-6">
              <h2 className="text-lg font-semibold text-gray-900 mb-4">Quick Actions</h2>
              <div className="space-y-2">
                {sale.status !== 'cancelled' && sale.status !== 'deleted' && (
                  <Link href={`/sales/${saleId}/edit`} className="btn btn-primary w-full justify-center">
                    <Icon icon={faEdit} size="sm" className="mr-2" />
                    Edit Sale
                  </Link>
                )}
                <Link href="/sales" className="btn btn-secondary w-full justify-center">
                  <Icon icon={faArrowLeft} size="sm" className="mr-2" />
                  Back to List
                </Link>
              </div>
            </div>
          </div>
        </div>
      )}
    </div>
  );
}
