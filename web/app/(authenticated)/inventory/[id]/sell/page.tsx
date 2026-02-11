'use client';

import { useState, useEffect } from 'react';
import { useRouter, useParams } from 'next/navigation';
import Link from 'next/link';
import { usePermission } from '@/hooks/usePermission';
import { inventoryApi, InventoryItem, CreateInventorySaleData } from '@/lib/api/inventory';
import { customersApi, Customer } from '@/lib/api/customers';
import { suppliersApi, Supplier } from '@/lib/api/suppliers';
import { useAuthStore } from '@/store/auth';
import { useToastStore } from '@/store/toast';
import Icon, { faDollarSign, faUser, faBox, faCalendar, faFileAlt, faCheckCircle, faTimes, faSpinner } from '@/app/components/Icon';
import SearchableSelect from '@/app/components/SearchableSelect';

const BUYER_TYPES = [
  { value: 'supplier', label: 'Supplier' },
  { value: 'customer', label: 'Customer' },
  { value: 'other', label: 'Other' },
];

const PAYMENT_STATUS_OPTIONS = [
  { value: 'paid', label: 'Paid' },
  { value: 'partial', label: 'Partial' },
  { value: 'unpaid', label: 'Unpaid' },
];

export default function SellInventoryPage() {
  const router = useRouter();
  const params = useParams();
  const itemId = params.id as string;
  const { currentAccount } = useAuthStore();
  const { hasPermission, isAdmin } = usePermission();
  const [loading, setLoading] = useState(true);
  const [saving, setSaving] = useState(false);
  const [loadingBuyers, setLoadingBuyers] = useState(true);
  const [error, setError] = useState('');
  const [item, setItem] = useState<InventoryItem | null>(null);
  const [customers, setCustomers] = useState<Customer[]>([]);
  const [suppliers, setSuppliers] = useState<Supplier[]>([]);
  const [formData, setFormData] = useState<CreateInventorySaleData & { buyer_account_code: string }>({
    buyer_type: 'customer',
    buyer_account_id: '',
    buyer_account_code: '',
    buyer_name: '',
    buyer_phone: '',
    quantity: 1,
    unit_price: 0,
    amount_paid: 0,
    sale_date: new Date().toISOString().slice(0, 16),
    notes: '',
  });

  useEffect(() => {
    if (!hasPermission('manage_inventory') && !isAdmin()) {
      router.push('/inventory');
      return;
    }
    Promise.all([loadItem(), loadBuyers()]);
    // Only re-run when item or account changes
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [itemId, currentAccount?.account_id]);

  const loadItem = async () => {
    try {
      setLoading(true);
      setError('');
      const response = await inventoryApi.getInventoryItem(itemId, currentAccount?.account_id);
      if (response.code === 200 && response.data) {
        const itemData = response.data;
        setItem(itemData);
        setFormData(prev => ({
          ...prev,
          unit_price: Number(itemData.price),
        }));
      } else {
        setError('Failed to load inventory item data');
      }
    } catch (err: any) {
      setError(err?.response?.data?.message || err?.message || 'Failed to load inventory item. Please try again.');
    } finally {
      setLoading(false);
    }
  };

  const loadBuyers = async () => {
    try {
      setLoadingBuyers(true);
      const [customersRes, suppliersRes] = await Promise.all([
        customersApi.getAllCustomers(currentAccount?.account_id).catch(() => ({ code: 200, data: [] })),
        suppliersApi.getAllSuppliers(currentAccount?.account_id).catch(() => ({ code: 200, data: [] })),
      ]);
      if (customersRes.code === 200) {
        setCustomers(customersRes.data || []);
      }
      if (suppliersRes.code === 200) {
        setSuppliers(suppliersRes.data || []);
      }
    } catch (err: any) {
      console.error('Failed to load buyers:', err);
    } finally {
      setLoadingBuyers(false);
    }
  };

  const handleChange = (e: React.ChangeEvent<HTMLInputElement | HTMLSelectElement | HTMLTextAreaElement>) => {
    const { name, value } = e.target;
    setFormData(prev => {
      const newData = {
        ...prev,
        [name]: name === 'quantity' || name === 'unit_price' || name === 'amount_paid'
          ? parseFloat(value) || 0
          : value,
      };

      // Auto-calculate total amount
      if (name === 'quantity' || name === 'unit_price') {
        const total = (newData.quantity || 0) * (newData.unit_price || 0);
        newData.amount_paid = total;
      }

      return newData;
    });
    setError('');
  };

  const handleBuyerTypeChange = (buyerType: string) => {
    setFormData(prev => ({
      ...prev,
      buyer_type: buyerType as 'supplier' | 'customer' | 'other',
      buyer_account_id: '',
      buyer_account_code: '',
      buyer_name: '',
      buyer_phone: '',
    }));
  };

  const validateForm = (): boolean => {
    if (!formData.quantity || formData.quantity <= 0) {
      setError('Quantity must be greater than 0');
      return false;
    }

    if (formData.quantity > Number(item?.stock_quantity || 0)) {
      setError(`Insufficient stock. Available: ${item?.stock_quantity || 0}`);
      return false;
    }

    if (!formData.unit_price || formData.unit_price < 0) {
      setError('Unit price must be greater than or equal to 0');
      return false;
    }

    if (formData.buyer_type !== 'other') {
      if (!formData.buyer_account_code && !formData.buyer_account_id) {
        setError(`Please select a ${formData.buyer_type}`);
        return false;
      }
    } else {
      if (!formData.buyer_name) {
        setError('Buyer name is required for other buyers');
        return false;
      }
    }

    if (formData.amount_paid < 0) {
      setError('Amount paid cannot be negative');
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
      const { buyer_account_code, ...finalData } = formData;
      // Backend accepts either account id or account code in buyer_account_id
      const saleData: CreateInventorySaleData = {
        ...finalData,
        buyer_account_id: finalData.buyer_account_id || buyer_account_code || undefined,
        sale_date: finalData.sale_date ? new Date(finalData.sale_date).toISOString() : undefined,
      };

      const response = await inventoryApi.sellInventoryItem(itemId, saleData);

      if (response.code === 200 || response.code === 201) {
        useToastStore.getState().success('Inventory item sold successfully!');
        router.push(`/inventory/${itemId}`);
      } else {
        setError(response.message || 'Failed to sell inventory item');
      }
    } catch (err: any) {
      setError(err?.response?.data?.message || err?.message || 'Failed to sell inventory item. Please try again.');
    } finally {
      setSaving(false);
    }
  };

  if (loading) {
    return (
      <div className="flex items-center justify-center min-h-[400px]">
        <div className="text-center">
          <Icon icon={faSpinner} size="lg" spin className="text-[var(--primary)] mb-4" />
          <p className="text-gray-600">Loading inventory item data...</p>
        </div>
      </div>
    );
  }

  const totalAmount = (formData.quantity || 0) * (formData.unit_price || 0);
  const availableStock = Number(item?.stock_quantity || 0);

  return (
    <div className="space-y-4">
      {/* Page Header */}
      <div className="flex items-center justify-between">
        <div>
          <h1 className="text-2xl font-bold text-gray-900">Sell Inventory Item</h1>
        </div>
        <Link href={`/inventory/${itemId}`} className="btn btn-secondary">
          <Icon icon={faTimes} size="sm" className="mr-2" />
          Cancel
        </Link>
      </div>

      {/* Stock Alert */}
      {item && (
        <div className={`border rounded-sm p-4 ${
          availableStock <= (item.min_stock_level || 0)
            ? 'bg-red-50 border-red-200'
            : 'bg-blue-50 border-blue-200'
        }`}>
          <div className="flex items-center justify-between">
            <span className="text-sm font-medium">
              Available Stock: <span className={availableStock <= (item.min_stock_level || 0) ? 'text-red-600' : 'text-blue-600'}>{availableStock}</span>
            </span>
            {item.min_stock_level !== null && (
              <span className="text-xs text-gray-600">Min Level: {item.min_stock_level}</span>
            )}
          </div>
        </div>
      )}

      {/* Error Message */}
      {error && (
        <div className="bg-red-50 border border-red-200 rounded-sm p-4">
          <p className="text-sm text-red-600">{error}</p>
        </div>
      )}

      {/* Form */}
      <form onSubmit={handleSubmit} className="bg-white border border-gray-200 rounded-sm p-6 space-y-6">
        {/* Buyer Information */}
        <div>
          <h2 className="text-lg font-semibold text-gray-900 mb-4">Buyer Information</h2>
          <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
            <div>
              <label htmlFor="buyer_type" className="block text-sm font-medium text-gray-700 mb-2">
                Buyer Type <span className="text-red-500">*</span>
              </label>
              <select
                id="buyer_type"
                name="buyer_type"
                required
                value={formData.buyer_type}
                onChange={(e) => handleBuyerTypeChange(e.target.value)}
                className="input w-full"
                disabled={saving}
              >
                {BUYER_TYPES.map(type => (
                  <option key={type.value} value={type.value}>
                    {type.label}
                  </option>
                ))}
              </select>
            </div>

            {formData.buyer_type !== 'other' && (
              <div>
                <label htmlFor="buyer_account_code" className="block text-sm font-medium text-gray-700 mb-2">
                  <Icon icon={faUser} size="sm" className="inline mr-2" />
                  {formData.buyer_type === 'customer' ? 'Customer' : 'Supplier'} <span className="text-red-500">*</span>
                </label>
                {loadingBuyers ? (
                  <div className="input w-full flex items-center">
                    <Icon icon={faSpinner} size="sm" spin className="mr-2" />
                    Loading...
                  </div>
                ) : (
                  <SearchableSelect
                    id="buyer_account_code"
                    name="buyer_account_code"
                    options={(formData.buyer_type === 'customer' ? customers : suppliers).map(b => ({ value: b.account.code, label: `${b.name} (${b.account.code})` }))}
                    value={formData.buyer_account_code}
                    onChange={(value) => setFormData(prev => ({ ...prev, buyer_account_code: value }))}
                    placeholder={`Search or select a ${formData.buyer_type}...`}
                    disabled={saving}
                    required
                  />
                )}
              </div>
            )}

            {formData.buyer_type === 'other' && (
              <>
                <div>
                  <label htmlFor="buyer_name" className="block text-sm font-medium text-gray-700 mb-2">
                    Buyer Name <span className="text-red-500">*</span>
                  </label>
                  <input
                    id="buyer_name"
                    name="buyer_name"
                    type="text"
                    required
                    value={formData.buyer_name}
                    onChange={handleChange}
                    className="input w-full"
                    placeholder="Enter buyer name"
                    disabled={saving}
                  />
                </div>
                <div>
                  <label htmlFor="buyer_phone" className="block text-sm font-medium text-gray-700 mb-2">
                    Buyer Phone
                  </label>
                  <input
                    id="buyer_phone"
                    name="buyer_phone"
                    type="tel"
                    value={formData.buyer_phone}
                    onChange={handleChange}
                    className="input w-full"
                    placeholder="250788123456"
                    disabled={saving}
                  />
                </div>
              </>
            )}
          </div>
        </div>

        {/* Sale Details */}
        <div>
          <h2 className="text-lg font-semibold text-gray-900 mb-4">Sale Details</h2>
          <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
            <div>
              <label htmlFor="quantity" className="block text-sm font-medium text-gray-700 mb-2">
                Quantity <span className="text-red-500">*</span>
              </label>
              <input
                id="quantity"
                name="quantity"
                type="number"
                step="0.01"
                min="0.01"
                max={availableStock}
                required
                value={formData.quantity}
                onChange={handleChange}
                className="input w-full"
                placeholder="1"
                disabled={saving}
              />
              <p className="text-xs text-gray-500 mt-1">Max: {availableStock}</p>
            </div>

            <div>
              <label htmlFor="unit_price" className="block text-sm font-medium text-gray-700 mb-2">
                <Icon icon={faDollarSign} size="sm" className="inline mr-2" />
                Unit Price (RWF) <span className="text-red-500">*</span>
              </label>
              <input
                id="unit_price"
                name="unit_price"
                type="number"
                step="0.01"
                min="0"
                required
                value={formData.unit_price}
                onChange={handleChange}
                className="input w-full"
                placeholder="0.00"
                disabled={saving}
              />
            </div>

            <div>
              <label htmlFor="amount_paid" className="block text-sm font-medium text-gray-700 mb-2">
                Amount Paid (RWF) <span className="text-red-500">*</span>
              </label>
              <input
                id="amount_paid"
                name="amount_paid"
                type="number"
                step="0.01"
                min="0"
                required
                value={formData.amount_paid}
                onChange={handleChange}
                className="input w-full"
                placeholder="0.00"
                disabled={saving}
              />
            </div>

            <div>
              <label htmlFor="sale_date" className="block text-sm font-medium text-gray-700 mb-2">
                <Icon icon={faCalendar} size="sm" className="inline mr-2" />
                Sale Date
              </label>
              <input
                id="sale_date"
                name="sale_date"
                type="datetime-local"
                value={formData.sale_date}
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
                  }).format(totalAmount)}
                </span>
              </div>
              {formData.amount_paid < totalAmount && (
                <div className="mt-2 text-xs text-yellow-600">
                  Outstanding: {new Intl.NumberFormat('en-RW', {
                    style: 'currency',
                    currency: 'RWF',
                    minimumFractionDigits: 0,
                  }).format(totalAmount - formData.amount_paid)}
                </div>
              )}
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
          <Link href={`/inventory/${itemId}`} className="btn btn-secondary" tabIndex={-1}>
            Cancel
          </Link>
          <button type="submit" className="btn btn-primary" disabled={saving || !item}>
            {saving ? (
              <>
                <Icon icon={faSpinner} size="sm" spin className="mr-2" />
                Processing...
              </>
            ) : (
              <>
                <Icon icon={faCheckCircle} size="sm" className="mr-2" />
                Record Sale
              </>
            )}
          </button>
        </div>
      </form>
    </div>
  );
}
