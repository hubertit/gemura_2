'use client';

import { useState, useEffect } from 'react';
import { useRouter } from 'next/navigation';
import Link from 'next/link';
import { usePermission } from '@/hooks/usePermission';
import { salesApi, CreateSaleData } from '@/lib/api/sales';
import { customersApi, Customer } from '@/lib/api/customers';
import { useToastStore } from '@/store/toast';
import Icon, { faReceipt, faUser, faDollarSign, faCalendar, faFileAlt, faCheckCircle, faTimes, faSpinner } from '@/app/components/Icon';

const STATUS_OPTIONS = [
  { value: 'pending', label: 'Pending' },
  { value: 'accepted', label: 'Accepted' },
  { value: 'rejected', label: 'Rejected' },
];

export default function CreateSalePage() {
  const router = useRouter();
  const { hasPermission, isAdmin } = usePermission();
  const [loading, setLoading] = useState(false);
  const [loadingCustomers, setLoadingCustomers] = useState(true);
  const [error, setError] = useState('');
  const [customers, setCustomers] = useState<Customer[]>([]);
  const [formData, setFormData] = useState<CreateSaleData & { customer_account_code: string }>({
    customer_account_id: '',
    customer_account_code: '',
    quantity: 0,
    unit_price: 0,
    status: 'accepted',
    sale_at: new Date().toISOString().slice(0, 16),
    notes: '',
    payment_status: 'unpaid',
  });

  useEffect(() => {
    if (!hasPermission('create_sales') && !isAdmin()) {
      router.push('/sales');
      return;
    }
    loadCustomers();
  }, [hasPermission, isAdmin, router]);

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

    // Auto-fill unit price if customer is selected and has price_per_liter
    if (name === 'customer_account_code') {
      const customer = customers.find(c => c.account.code === value);
      if (customer && customer.price_per_liter) {
        setFormData(prev => ({
          ...prev,
          unit_price: customer.price_per_liter,
        }));
      }
    }
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

    setLoading(true);

    try {
      const { customer_account_code, ...saleData } = formData;
      const finalData: CreateSaleData = {
        ...saleData,
        customer_account_code: customer_account_code || undefined,
      };

      const response = await salesApi.createSale(finalData);

      if (response.code === 200 || response.code === 201) {
        useToastStore.getState().success('Sale created successfully!');
        router.push('/sales');
      } else {
        setError(response.message || 'Failed to create sale');
      }
    } catch (err: any) {
      const errorMessage = err?.response?.data?.message || err?.message || 'Failed to create sale. Please try again.';
      setError(errorMessage);
      useToastStore.getState().error(errorMessage);
    } finally {
      setLoading(false);
    }
  };

  return (
    <div className="space-y-4">
      {/* Page Header */}
      <div className="flex items-center justify-between">
        <div>
          <h1 className="text-2xl font-bold text-gray-900">Create Sale</h1>
        </div>
        <Link href="/sales" className="btn btn-secondary">
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
                  disabled={loading}
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
                disabled={loading}
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
                disabled={loading}
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
                disabled={loading}
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
                disabled={loading}
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
              disabled={loading}
            />
          </div>
        </div>

        {/* Form Actions */}
        <div className="flex items-center justify-end gap-3 pt-4 border-t border-gray-200">
          <Link href="/sales" className="btn btn-secondary" tabIndex={-1}>
            Cancel
          </Link>
          <button type="submit" className="btn btn-primary" disabled={loading}>
            {loading ? (
              <>
                <Icon icon={faSpinner} size="sm" spin className="mr-2" />
                Creating...
              </>
            ) : (
              <>
                <Icon icon={faCheckCircle} size="sm" className="mr-2" />
                Create Sale
              </>
            )}
          </button>
        </div>
      </form>
    </div>
  );
}
