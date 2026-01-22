'use client';

import { useState, useEffect } from 'react';
import { useRouter } from 'next/navigation';
import Link from 'next/link';
import { usePermission } from '@/hooks/usePermission';
import { collectionsApi, CreateCollectionData } from '@/lib/api/collections';
import { suppliersApi, Supplier } from '@/lib/api/suppliers';
import { useToastStore } from '@/store/toast';
import Icon, { faBox, faUser, faDollarSign, faCalendar, faFileAlt, faCheckCircle, faTimes, faSpinner } from '@/app/components/Icon';

const STATUS_OPTIONS = [
  { value: 'pending', label: 'Pending' },
  { value: 'accepted', label: 'Accepted' },
  { value: 'rejected', label: 'Rejected' },
];

export default function CreateCollectionPage() {
  const router = useRouter();
  const { hasPermission, isAdmin } = usePermission();
  const [loading, setLoading] = useState(false);
  const [loadingSuppliers, setLoadingSuppliers] = useState(true);
  const [error, setError] = useState('');
  const [suppliers, setSuppliers] = useState<Supplier[]>([]);
  const [formData, setFormData] = useState<CreateCollectionData & { unit_price: number }>({
    supplier_account_code: '',
    quantity: 0,
    unit_price: 0,
    status: 'accepted',
    collection_at: new Date().toISOString().slice(0, 16).replace('T', ' ').slice(0, 16),
    notes: '',
    payment_status: 'unpaid',
  });

  useEffect(() => {
    if (!hasPermission('create_collections') && !isAdmin()) {
      router.push('/collections');
      return;
    }
    loadSuppliers();
  }, [hasPermission, isAdmin, router]);

  const loadSuppliers = async () => {
    try {
      setLoadingSuppliers(true);
      const response = await suppliersApi.getAllSuppliers();
      if (response.code === 200) {
        setSuppliers(response.data || []);
      }
    } catch (err: any) {
      console.error('Failed to load suppliers:', err);
    } finally {
      setLoadingSuppliers(false);
    }
  };

  const handleChange = (e: React.ChangeEvent<HTMLInputElement | HTMLSelectElement | HTMLTextAreaElement>) => {
    const { name, value } = e.target;
    setFormData(prev => ({
      ...prev,
      [name]: value,
    }));
    setError('');

    // Auto-fill unit price if supplier is selected and has price_per_liter
    if (name === 'supplier_account_code') {
      const supplier = suppliers.find(s => s.account.code === value);
      if (supplier && supplier.price_per_liter) {
        setFormData(prev => ({
          ...prev,
          unit_price: supplier.price_per_liter || 0,
        }));
      }
    }
  };

  const validateForm = (): boolean => {
    if (!formData.supplier_account_code) {
      setError('Please select a supplier');
      return false;
    }

    if (!formData.quantity || formData.quantity <= 0) {
      setError('Quantity must be greater than 0');
      return false;
    }

    if (!formData.collection_at) {
      setError('Collection date and time is required');
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
      // Format collection_at as YYYY-MM-DD HH:mm:ss
      const collectionDate = formData.collection_at.replace('T', ' ').slice(0, 19);
      
      const finalData: CreateCollectionData = {
        supplier_account_code: formData.supplier_account_code,
        quantity: formData.quantity,
        status: formData.status,
        collection_at: collectionDate,
        notes: formData.notes,
        payment_status: formData.payment_status,
      };

      const response = await collectionsApi.createCollection(finalData);

      if (response.code === 200 || response.code === 201) {
        useToastStore.getState().success('Collection created successfully!');
        router.push('/collections');
      } else {
        setError(response.message || 'Failed to create collection');
      }
    } catch (err: any) {
      setError(err?.response?.data?.message || err?.message || 'Failed to create collection. Please try again.');
    } finally {
      setLoading(false);
    }
  };

  return (
    <div className="space-y-4">
      {/* Page Header */}
      <div className="flex items-center justify-between">
        <div>
          <h1 className="text-2xl font-bold text-gray-900">Create Collection</h1>
          <p className="text-sm text-gray-600 mt-1">Record a new milk collection from supplier</p>
        </div>
        <Link href="/collections" className="btn btn-secondary">
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
        {/* Supplier Selection */}
        <div>
          <h2 className="text-lg font-semibold text-gray-900 mb-4">Supplier Information</h2>
          <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
            <div>
              <label htmlFor="supplier_account_code" className="block text-sm font-medium text-gray-700 mb-2">
                <Icon icon={faUser} size="sm" className="inline mr-2" />
                Supplier <span className="text-red-500">*</span>
              </label>
              {loadingSuppliers ? (
                <div className="input w-full flex items-center">
                  <Icon icon={faSpinner} size="sm" spin className="mr-2" />
                  Loading suppliers...
                </div>
              ) : (
                <select
                  id="supplier_account_code"
                  name="supplier_account_code"
                  required
                  value={formData.supplier_account_code}
                  onChange={handleChange}
                  className="input w-full"
                  disabled={loading}
                >
                  <option value="">Select a supplier</option>
                  {suppliers.map(supplier => (
                    <option key={supplier.relationship_id} value={supplier.account.code}>
                      {supplier.name} ({supplier.account.code})
                    </option>
                  ))}
                </select>
              )}
            </div>
          </div>
        </div>

        {/* Collection Details */}
        <div>
          <h2 className="text-lg font-semibold text-gray-900 mb-4">Collection Details</h2>
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
                min="0.01"
                required
                value={formData.quantity}
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
              <label htmlFor="collection_at" className="block text-sm font-medium text-gray-700 mb-2">
                <Icon icon={faCalendar} size="sm" className="inline mr-2" />
                Collection Date & Time <span className="text-red-500">*</span>
              </label>
              <input
                id="collection_at"
                name="collection_at"
                type="datetime-local"
                required
                value={formData.collection_at}
                onChange={handleChange}
                className="input w-full"
                disabled={loading}
              />
            </div>
          </div>

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
              placeholder="Additional notes about this collection..."
              disabled={loading}
            />
          </div>
        </div>

        {/* Form Actions */}
        <div className="flex items-center justify-end gap-3 pt-4 border-t border-gray-200">
          <Link href="/collections" className="btn btn-secondary" tabIndex={-1}>
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
                Create Collection
              </>
            )}
          </button>
        </div>
      </form>
    </div>
  );
}
