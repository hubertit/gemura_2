'use client';

import { useState, useEffect } from 'react';
import { useRouter, useParams } from 'next/navigation';
import Link from 'next/link';
import { usePermission } from '@/hooks/usePermission';
import { salesApi, UpdateSaleData, Sale } from '@/lib/api/sales';
import { customersApi, Customer } from '@/lib/api/customers';
import { useAuthStore } from '@/store/auth';
import { useToastStore } from '@/store/toast';
import Icon, { faReceipt, faUser, faDollarSign, faCalendar, faFileAlt, faCheckCircle, faTimes, faSpinner } from '@/app/components/Icon';

const STATUS_OPTIONS = [
  { value: 'pending', label: 'Pending' },
  { value: 'accepted', label: 'Accepted' },
  { value: 'rejected', label: 'Rejected' },
  { value: 'cancelled', label: 'Cancelled' },
];

export default function EditSalePage() {
  const router = useRouter();
  const params = useParams();
  const saleId = params.id as string;
  const { currentAccount } = useAuthStore();
  const { hasPermission, isAdmin } = usePermission();
  const [loading, setLoading] = useState(true);
  const [saving, setSaving] = useState(false);
  const [loadingCustomers, setLoadingCustomers] = useState(true);
  const [error, setError] = useState('');
  const [sale, setSale] = useState<Sale | null>(null);
  const [customers, setCustomers] = useState<Customer[]>([]);
  const [formData, setFormData] = useState<UpdateSaleData & { customer_account_code: string }>({
    sale_id: saleId,
    customer_account_id: '',
    customer_account_code: '',
    quantity: 0,
    unit_price: 0,
    status: 'accepted',
    sale_at: '',
    notes: '',
  });

  useEffect(() => {
    if (!hasPermission('update_sales') && !isAdmin()) {
      router.push('/sales');
      return;
    }
    Promise.all([loadSale(), loadCustomers()]);
    // Only re-run when sale or account context changes; hasPermission/isAdmin are stable in behavior
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [saleId, currentAccount?.account_id]);

  const loadSale = async () => {
    try {
      setLoading(true);
      setError('');
      const response = await salesApi.getSaleById(saleId, currentAccount?.account_id);
      if (response.code === 200 && response.data) {
        const saleData = response.data;
        setSale(saleData);
        setFormData({
          sale_id: saleId,
          customer_account_id: saleData.customer_account.id,
          customer_account_code: saleData.customer_account.code,
          quantity: Number(saleData.quantity),
          unit_price: Number(saleData.unit_price),
          status: saleData.status,
          sale_at: saleData.sale_at ? new Date(saleData.sale_at).toISOString().slice(0, 16) : '',
          notes: saleData.notes || '',
        });
      } else {
        setError('Failed to load sale data');
      }
    } catch (err: any) {
      setError(err?.response?.data?.message || err?.message || 'Failed to load sale. Please try again.');
    } finally {
      setLoading(false);
    }
  };

  const loadCustomers = async () => {
    try {
      setLoadingCustomers(true);
      const response = await customersApi.getAllCustomers();
      if (response.code === 200) {
        setCustomers(response.data || []);
      }
    } catch (err: any) {
      console.error('Failed to load customers:', err);
    } finally {
      setLoadingCustomers(false);
    }
  };

  const handleChange = (e: React.ChangeEvent<HTMLInputElement | HTMLSelectElement | HTMLTextAreaElement>) => {
    const { name, value } = e.target;
    setFormData(prev => ({
      ...prev,
      [name]: value,
    }));
    setError('');
  };

  const validateForm = (): boolean => {
    if (!formData.customer_account_code && !formData.customer_account_id) {
      setError('Please select a customer');
      return false;
    }

    if (!formData.quantity || formData.quantity <= 0) {
      setError('Quantity must be greater than 0');
      return false;
    }

    if (formData.unit_price && formData.unit_price < 0) {
      setError('Unit price cannot be negative');
      return false;
    }

    return true;
  };

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    setError('');

    if (!validateForm()) {
      return;
    }

    setSaving(true);

    try {
      const { customer_account_code, ...saleData } = formData;
      const finalData: UpdateSaleData = {
        ...saleData,
        customer_account_code: customer_account_code || undefined,
      };

      const response = await salesApi.updateSale(finalData);

      if (response.code === 200) {
        useToastStore.getState().success('Sale updated successfully!');
        router.push(`/sales/${saleId}`);
      } else {
        setError(response.message || 'Failed to update sale');
      }
    } catch (err: any) {
      setError(err?.response?.data?.message || err?.message || 'Failed to update sale. Please try again.');
    } finally {
      setSaving(false);
    }
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

  return (
    <div className="space-y-4">
      {/* Page Header */}
      <div className="flex items-center justify-between">
        <div>
          <h1 className="text-2xl font-bold text-gray-900">Edit Sale</h1>
        </div>
        <Link href={`/sales/${saleId}`} className="btn btn-secondary">
          <Icon icon={faTimes} size="sm" className="mr-2" />
          Cancel
        </Link>
      </div>

      {/* Error Message */}
      {error && (
        <div className="bg-red-50 border border-red-200 rounded-sm p-4">
          <p className="text-sm text-red-600">{error}</p>
        </div>
      )}

      {/* Form */}
      <form onSubmit={handleSubmit} className="bg-white border border-gray-200 rounded-sm p-6 space-y-6">
        {/* Customer Selection */}
        <div>
          <h2 className="text-lg font-semibold text-gray-900 mb-4">Customer Information</h2>
          <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
            <div>
              <label htmlFor="customer_account_code" className="block text-sm font-medium text-gray-700 mb-2">
                <Icon icon={faUser} size="sm" className="inline mr-2" />
                Customer <span className="text-red-500">*</span>
              </label>
              {loadingCustomers ? (
                <div className="input w-full flex items-center">
                  <Icon icon={faSpinner} size="sm" spin className="mr-2" />
                  Loading customers...
                </div>
              ) : (
                <select
                  id="customer_account_code"
                  name="customer_account_code"
                  required
                  value={formData.customer_account_code}
                  onChange={handleChange}
                  className="input w-full"
                  disabled={saving}
                >
                  <option value="">Select a customer</option>
                  {customers.map(customer => (
                    <option key={customer.relationship_id} value={customer.account.code}>
                      {customer.name} ({customer.account.code})
                    </option>
                  ))}
                </select>
              )}
            </div>
          </div>
        </div>

        {/* Sale Details */}
        <div>
          <h2 className="text-lg font-semibold text-gray-900 mb-4">Sale Details</h2>
          <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
            <div>
              <label htmlFor="quantity" className="block text-sm font-medium text-gray-700 mb-2">
                Quantity (Liters) <span className="text-red-500">*</span>
              </label>
              <input
                id="quantity"
                name="quantity"
                type="number"
                step="0.01"
                min="0"
                required
                value={formData.quantity}
                onChange={handleChange}
                className="input w-full"
                placeholder="0.00"
                disabled={saving}
              />
            </div>

            <div>
              <label htmlFor="unit_price" className="block text-sm font-medium text-gray-700 mb-2">
                <Icon icon={faDollarSign} size="sm" className="inline mr-2" />
                Unit Price (RWF/L)
              </label>
              <input
                id="unit_price"
                name="unit_price"
                type="number"
                step="0.01"
                min="0"
                value={formData.unit_price || ''}
                onChange={handleChange}
                className="input w-full"
                placeholder="0.00"
                disabled={saving}
              />
            </div>

            <div>
              <label htmlFor="status" className="block text-sm font-medium text-gray-700 mb-2">
                Status
              </label>
              <select
                id="status"
                name="status"
                value={formData.status}
                onChange={handleChange}
                className="input w-full"
                disabled={saving}
              >
                {STATUS_OPTIONS.map(status => (
                  <option key={status.value} value={status.value}>
                    {status.label}
                  </option>
                ))}
              </select>
            </div>

            <div>
              <label htmlFor="sale_at" className="block text-sm font-medium text-gray-700 mb-2">
                <Icon icon={faCalendar} size="sm" className="inline mr-2" />
                Sale Date & Time
              </label>
              <input
                id="sale_at"
                name="sale_at"
                type="datetime-local"
                value={formData.sale_at}
                onChange={handleChange}
                className="input w-full"
                disabled={saving}
              />
            </div>
          </div>

          {/* Total Calculation */}
          {formData.quantity && formData.unit_price && (
            <div className="mt-4 p-4 bg-blue-50 border border-blue-200 rounded-sm">
              <div className="flex items-center justify-between">
                <span className="text-sm font-medium text-gray-700">Total Amount:</span>
                <span className="text-lg font-bold text-[var(--primary)]">
                  {new Intl.NumberFormat('en-RW', {
                    style: 'currency',
                    currency: 'RWF',
                    minimumFractionDigits: 0,
                  }).format(Number(formData.quantity) * Number(formData.unit_price))}
                </span>
              </div>
            </div>
          )}

          {/* Notes */}
          <div className="mt-4">
            <label htmlFor="notes" className="block text-sm font-medium text-gray-700 mb-2">
              <Icon icon={faFileAlt} size="sm" className="inline mr-2" />
              Notes
            </label>
            <textarea
              id="notes"
              name="notes"
              rows={3}
              value={formData.notes}
              onChange={handleChange}
              className="input w-full"
              placeholder="Additional notes about this sale..."
              disabled={saving}
            />
          </div>
        </div>

        {/* Form Actions */}
        <div className="flex items-center justify-end gap-3 pt-4 border-t border-gray-200">
          <Link href={`/sales/${saleId}`} className="btn btn-secondary" tabIndex={-1}>
            Cancel
          </Link>
          <button type="submit" className="btn btn-primary" disabled={saving}>
            {saving ? (
              <>
                <Icon icon={faSpinner} size="sm" spin className="mr-2" />
                Saving...
              </>
            ) : (
              <>
                <Icon icon={faCheckCircle} size="sm" className="mr-2" />
                Update Sale
              </>
            )}
          </button>
        </div>
      </form>
    </div>
  );
}
