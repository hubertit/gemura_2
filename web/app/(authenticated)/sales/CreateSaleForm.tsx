'use client';

import { useState, useEffect } from 'react';
import { salesApi, CreateSaleData } from '@/lib/api/sales';
import { customersApi, Customer } from '@/lib/api/customers';
import { useToastStore } from '@/store/toast';
import Icon, { faCheckCircle, faSpinner } from '@/app/components/Icon';

const STATUS_OPTIONS = [
  { value: 'pending', label: 'Pending' },
  { value: 'accepted', label: 'Accepted' },
  { value: 'rejected', label: 'Rejected' },
];

interface CreateSaleFormProps {
  onSuccess: () => void;
  onCancel: () => void;
}

export default function CreateSaleForm({ onSuccess, onCancel }: CreateSaleFormProps) {
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
    let cancelled = false;
    customersApi.getAllCustomers().then((res) => {
      if (!cancelled && res.code === 200) setCustomers(res.data || []);
    }).finally(() => { if (!cancelled) setLoadingCustomers(false); });
    return () => { cancelled = true; };
  }, []);

  const handleChange = (e: React.ChangeEvent<HTMLInputElement | HTMLSelectElement | HTMLTextAreaElement>) => {
    const { name, value } = e.target;
    setFormData(prev => ({
      ...prev,
      [name]: value,
    }));
    setError('');
    if (name === 'customer_account_code') {
      const customer = customers.find(c => c.account.code === value);
      if (customer?.price_per_liter) {
        setFormData(prev => ({ ...prev, unit_price: customer.price_per_liter }));
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
    if (formData.unit_price != null && formData.unit_price < 0) {
      setError('Unit price cannot be negative');
      return false;
    }
    return true;
  };

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    setError('');
    if (!validateForm()) return;
    setLoading(true);
    try {
      const { customer_account_code, ...rest } = formData;
      const finalData: CreateSaleData = { ...rest, customer_account_code: customer_account_code || undefined };
      const response = await salesApi.createSale(finalData);
      if (response.code === 200 || response.code === 201) {
        useToastStore.getState().success('Sale created successfully!');
        onSuccess();
      } else {
        setError(response.message || 'Failed to create sale');
      }
    } catch (err: unknown) {
      const msg = (err as { response?: { data?: { message?: string } }; message?: string })?.response?.data?.message || (err as { message?: string })?.message || 'Failed to create sale.';
      setError(msg);
      useToastStore.getState().error(msg);
    } finally {
      setLoading(false);
    }
  };

  return (
    <form onSubmit={handleSubmit} className="space-y-4">
      {error && <div className="bg-red-50 border border-red-200 rounded p-3 text-sm text-red-600">{error}</div>}
      <div className="grid grid-cols-1 sm:grid-cols-2 gap-4">
        <div className="sm:col-span-2">
          <label htmlFor="sale-customer" className="block text-sm font-medium text-gray-700 mb-1">Customer <span className="text-red-500">*</span></label>
          {loadingCustomers ? (
            <div className="input w-full flex items-center text-gray-500 text-sm"><Icon icon={faSpinner} size="sm" spin className="mr-2" />Loading customers...</div>
          ) : (
            <select id="sale-customer" name="customer_account_code" required value={formData.customer_account_code} onChange={handleChange} className="input w-full" disabled={loading}>
              <option value="">Select a customer</option>
              {customers.map(c => <option key={c.relationship_id} value={c.account.code}>{c.name} ({c.account.code})</option>)}
            </select>
          )}
        </div>
        <div>
          <label htmlFor="sale-quantity" className="block text-sm font-medium text-gray-700 mb-1">Quantity (L) <span className="text-red-500">*</span></label>
          <input id="sale-quantity" name="quantity" type="number" step="0.01" min="0" required value={formData.quantity} onChange={handleChange} className="input w-full" disabled={loading} />
        </div>
        <div>
          <label htmlFor="sale-unit_price" className="block text-sm font-medium text-gray-700 mb-1">Unit price (RWF/L)</label>
          <input id="sale-unit_price" name="unit_price" type="number" step="0.01" min="0" value={formData.unit_price || ''} onChange={handleChange} className="input w-full" disabled={loading} />
        </div>
        <div>
          <label htmlFor="sale-status" className="block text-sm font-medium text-gray-700 mb-1">Status</label>
          <select id="sale-status" name="status" value={formData.status} onChange={handleChange} className="input w-full" disabled={loading}>
            {STATUS_OPTIONS.map(s => <option key={s.value} value={s.value}>{s.label}</option>)}
          </select>
        </div>
        <div>
          <label htmlFor="sale_at" className="block text-sm font-medium text-gray-700 mb-1">Date & time</label>
          <input id="sale_at" name="sale_at" type="datetime-local" value={formData.sale_at} onChange={handleChange} className="input w-full" disabled={loading} />
        </div>
        <div className="sm:col-span-2">
          <label htmlFor="sale-notes" className="block text-sm font-medium text-gray-700 mb-1">Notes</label>
          <textarea id="sale-notes" name="notes" rows={2} value={formData.notes} onChange={handleChange} className="input w-full" disabled={loading} placeholder="Optional" />
        </div>
      </div>
      {formData.quantity && formData.unit_price && (
        <p className="text-sm text-gray-600">
          Total: {new Intl.NumberFormat('en-RW', { style: 'currency', currency: 'RWF', minimumFractionDigits: 0 }).format(Number(formData.quantity) * Number(formData.unit_price))}
        </p>
      )}
      <div className="flex justify-end gap-2 pt-2 border-t border-gray-200">
        <button type="button" onClick={onCancel} className="btn btn-secondary">Cancel</button>
        <button type="submit" className="btn btn-primary" disabled={loading}>
          {loading ? <><Icon icon={faSpinner} size="sm" spin className="mr-2" />Creating...</> : <><Icon icon={faCheckCircle} size="sm" className="mr-2" />Create Sale</>}
        </button>
      </div>
    </form>
  );
}
