'use client';

import { useState, useEffect } from 'react';
import { useRouter, useParams } from 'next/navigation';
import Link from 'next/link';
import { usePermission } from '@/hooks/usePermission';
import { salesApi, UpdateSaleData, Sale } from '@/lib/api/sales';
import { customersApi, Customer } from '@/lib/api/customers';
import { useAuthStore } from '@/store/auth';
import { useToastStore } from '@/store/toast';
import Icon, { faReceipt, faUser, faDollarSign, faCalendar, faFileAlt, faCheckCircle, faTimes, faSpinner, faPaw } from '@/app/components/Icon';
import { DetailPageSkeleton } from '@/app/components/SkeletonLoader';
import SearchableSelect from '@/app/components/SearchableSelect';
import Select from '@/app/components/Select';
import DateTimePicker from '@/app/components/DateTimePicker';
import { animalsApi, Animal } from '@/lib/api/animals';

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
  const [loadingAnimals, setLoadingAnimals] = useState(false);
  const [error, setError] = useState('');
  const [sale, setSale] = useState<Sale | null>(null);
  const [customers, setCustomers] = useState<Customer[]>([]);
  const [animals, setAnimals] = useState<Animal[]>([]);
  const [formData, setFormData] = useState<UpdateSaleData & { customer_account_code: string }>({
    sale_id: saleId,
    customer_account_id: '',
    customer_account_code: '',
    quantity: 0,
    unit_price: 0,
    status: 'accepted',
    sale_at: '',
    notes: '',
    animal_id: undefined,
  });

  useEffect(() => {
    if (!hasPermission('update_sales') && !isAdmin()) {
      router.push('/sales');
      return;
    }
    loadSale();
    loadCustomers();
    // Only re-run when sale or account context changes; hasPermission/isAdmin are stable in behavior
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [saleId, currentAccount?.account_id]);

  useEffect(() => {
    if (!currentAccount?.account_id) {
      setAnimals([]);
      return;
    }
    let cancelled = false;
    setLoadingAnimals(true);
    animalsApi.getList(currentAccount.account_id).then((res) => {
      if (!cancelled && res.data) setAnimals(res.data);
      else if (!cancelled) setAnimals([]);
    }).catch(() => { if (!cancelled) setAnimals([]); }).finally(() => { if (!cancelled) setLoadingAnimals(false); });
    return () => { cancelled = true; };
  }, [currentAccount?.account_id]);

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
          animal_id: saleData.animal?.id ?? undefined,
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
        animal_id: formData.animal_id || undefined,
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
    return <DetailPageSkeleton />;
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
            <div className="input-group">
              <label htmlFor="customer_account_code" className="input-group-label">
                <Icon icon={faUser} size="sm" className="inline mr-1" />
                Customer <span className="text-red-500">*</span>
              </label>
              {loadingCustomers ? (
                <div className="input w-full flex items-center">
                  <Icon icon={faSpinner} size="sm" spin className="mr-2" />
                  Loading customers...
                </div>
              ) : (
                <SearchableSelect
                  id="customer_account_code"
                  name="customer_account_code"
                  options={customers.map(c => ({ value: c.account.code, label: `${c.name} (${c.account.code})` }))}
                  value={formData.customer_account_code}
                  onChange={(value) => setFormData(prev => ({ ...prev, customer_account_code: value }))}
                  placeholder="Search or select a customer..."
                  disabled={saving}
                  required
                  className="w-full"
                />
              )}
            </div>
            <div>
              <label htmlFor="sale-animal" className="block text-sm font-medium text-gray-700 mb-2">
                <Icon icon={faPaw} size="sm" className="inline mr-2 text-gray-500" />
                Animal (optional)
              </label>
              {loadingAnimals ? (
                <div className="input w-full flex items-center text-gray-500 text-sm">
                  <Icon icon={faSpinner} size="sm" spin className="mr-2" />
                  Loading animals...
                </div>
              ) : (
                <Select
                  id="sale-animal"
                  name="animal_id"
                  value={formData.animal_id ?? ''}
                  onChange={(v) => setFormData((prev) => ({ ...prev, animal_id: v || undefined }))}
                  options={animals.map((a) => ({
                    value: a.id,
                    label: `${a.tag_number} ${a.name ? `(${a.name})` : ''} · ${a.breed?.name ?? '—'}`,
                  }))}
                  placeholder="— None —"
                  allowEmpty
                  disabled={saving}
                  className="w-full"
                />
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
              <Select
                id="status"
                name="status"
                value={formData.status ?? ''}
                onChange={(v) => setFormData((prev) => ({ ...prev, status: v }))}
                options={STATUS_OPTIONS}
                placeholder="Select status"
                disabled={saving}
                className="w-full"
              />
            </div>

            <div>
              <label htmlFor="sale_at" className="block text-sm font-medium text-gray-700 mb-2">
                <Icon icon={faCalendar} size="sm" className="inline mr-2" />
                Sale Date & Time
              </label>
              <DateTimePicker
                id="sale_at"
                name="sale_at"
                value={formData.sale_at}
                onChange={(v) => setFormData((p) => ({ ...p, sale_at: v }))}
                max={new Date().toISOString().slice(0, 16)}
                className="w-full"
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
