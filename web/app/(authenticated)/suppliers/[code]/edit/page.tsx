'use client';

import { useState, useEffect } from 'react';
import { useRouter, useParams } from 'next/navigation';
import Link from 'next/link';
import { usePermission } from '@/hooks/usePermission';
import { suppliersApi, UpdateSupplierData, SupplierDetails } from '@/lib/api/suppliers';
import { useToastStore } from '@/store/toast';
import Icon, { faDollarSign, faCheckCircle, faTimes, faSpinner } from '@/app/components/Icon';

const STATUS_OPTIONS = [
  { value: 'active', label: 'Active' },
  { value: 'inactive', label: 'Inactive' },
];

export default function EditSupplierPage() {
  const router = useRouter();
  const params = useParams();
  const supplierCode = params.code as string;
  const { hasPermission, isAdmin } = usePermission();
  const [loading, setLoading] = useState(true);
  const [saving, setSaving] = useState(false);
  const [error, setError] = useState('');
  const [supplier, setSupplier] = useState<SupplierDetails | null>(null);
  const [formData, setFormData] = useState<UpdateSupplierData>({
    supplier_account_code: supplierCode,
    price_per_liter: 0,
    relationship_status: 'active',
  });

  useEffect(() => {
    if (!hasPermission('create_suppliers') && !isAdmin()) {
      router.push('/suppliers');
      return;
    }
    loadSupplier();
  }, [supplierCode, hasPermission, isAdmin, router]);

  const loadSupplier = async () => {
    try {
      setLoading(true);
      setError('');
      const response = await suppliersApi.getSupplierByCode(supplierCode);
      if (response.code === 200 && response.data) {
        const supplierData = response.data.supplier;
        setSupplier(supplierData);
        setFormData({
          supplier_account_code: supplierCode,
          price_per_liter: supplierData.relationship.price_per_liter,
          relationship_status: supplierData.relationship.relationship_status as 'active' | 'inactive',
        });
      } else {
        setError('Failed to load supplier data');
      }
    } catch (err: any) {
      setError(err?.response?.data?.message || err?.message || 'Failed to load supplier. Please try again.');
    } finally {
      setLoading(false);
    }
  };

  const handleChange = (e: React.ChangeEvent<HTMLInputElement | HTMLSelectElement>) => {
    const { name, value } = e.target;
    setFormData(prev => ({
      ...prev,
      [name]: name === 'price_per_liter' ? parseFloat(value) || 0 : value,
    }));
    setError('');
  };

  const validateForm = (): boolean => {
    if (formData.price_per_liter && formData.price_per_liter < 0) {
      setError('Price per liter cannot be negative');
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
      const response = await suppliersApi.updateSupplier(formData);

      if (response.code === 200) {
        useToastStore.getState().success('Supplier updated successfully!');
        router.push(`/suppliers/${supplierCode}`);
      } else {
        setError(response.message || 'Failed to update supplier');
      }
    } catch (err: any) {
      setError(err?.response?.data?.message || err?.message || 'Failed to update supplier. Please try again.');
    } finally {
      setSaving(false);
    }
  };

  if (loading) {
    return (
      <div className="flex items-center justify-center min-h-[400px]">
        <div className="text-center">
          <Icon icon={faSpinner} size="lg" spin className="text-[var(--primary)] mb-4" />
          <p className="text-gray-600">Loading supplier data...</p>
        </div>
      </div>
    );
  }

  return (
    <div className="space-y-4">
      {/* Page Header */}
      <div className="flex items-center justify-between">
        <div>
          <h1 className="text-2xl font-bold text-gray-900">Edit Supplier</h1>
          <p className="text-sm text-gray-600 mt-1">Update supplier information</p>
        </div>
        <Link href={`/suppliers/${supplierCode}`} className="btn btn-secondary">
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
        {/* Supplier Details */}
        <div>
          <h2 className="text-lg font-semibold text-gray-900 mb-4">Supplier Relationship</h2>
          <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
            <div>
              <label htmlFor="price_per_liter" className="block text-sm font-medium text-gray-700 mb-2">
                <Icon icon={faDollarSign} size="sm" className="inline mr-2" />
                Price per Liter (RWF)
              </label>
              <input
                id="price_per_liter"
                name="price_per_liter"
                type="number"
                step="0.01"
                min="0"
                value={formData.price_per_liter || ''}
                onChange={handleChange}
                className="input w-full"
                placeholder="0.00"
                disabled={saving}
              />
            </div>

            <div>
              <label htmlFor="relationship_status" className="block text-sm font-medium text-gray-700 mb-2">
                Relationship Status
              </label>
              <select
                id="relationship_status"
                name="relationship_status"
                value={formData.relationship_status}
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
          </div>
        </div>

        {/* Form Actions */}
        <div className="flex items-center justify-end gap-3 pt-4 border-t border-gray-200">
          <Link href={`/suppliers/${supplierCode}`} className="btn btn-secondary" tabIndex={-1}>
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
                Update Supplier
              </>
            )}
          </button>
        </div>
      </form>
    </div>
  );
}
