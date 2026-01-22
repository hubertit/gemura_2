'use client';

import { useState, useEffect } from 'react';
import { useRouter, useParams } from 'next/navigation';
import Link from 'next/link';
import { usePermission } from '@/hooks/usePermission';
import { customersApi, UpdateCustomerData, CustomerDetails } from '@/lib/api/customers';
import Icon, { faUser, faPhone, faEnvelope, faIdCard, faMapPin, faDollarSign, faCheckCircle, faTimes, faSpinner } from '@/app/components/Icon';

const STATUS_OPTIONS = [
  { value: 'active', label: 'Active' },
  { value: 'inactive', label: 'Inactive' },
];

export default function EditCustomerPage() {
  const router = useRouter();
  const params = useParams();
  const customerCode = params.code as string;
  const { hasPermission, isAdmin } = usePermission();
  const [loading, setLoading] = useState(true);
  const [saving, setSaving] = useState(false);
  const [error, setError] = useState('');
  const [customer, setCustomer] = useState<CustomerDetails | null>(null);
  const [formData, setFormData] = useState<UpdateCustomerData>({
    customer_account_code: customerCode,
    name: '',
    phone: '',
    email: '',
    nid: '',
    address: '',
    price_per_liter: 0,
    relationship_status: 'active',
  });

  useEffect(() => {
    if (!hasPermission('create_customers') && !isAdmin()) {
      router.push('/customers');
      return;
    }
    loadCustomer();
  }, [customerCode, hasPermission, isAdmin, router]);

  const loadCustomer = async () => {
    try {
      setLoading(true);
      setError('');
      const response = await customersApi.getCustomerByCode(customerCode);
      if (response.code === 200 && response.data) {
        const customerData = response.data.customer;
        setCustomer(customerData);
        setFormData({
          customer_account_code: customerCode,
          name: customerData.user.name,
          phone: customerData.user.phone,
          email: customerData.user.email || '',
          nid: customerData.user.nid || '',
          address: customerData.user.address || '',
          price_per_liter: customerData.relationship.price_per_liter,
          relationship_status: customerData.relationship.relationship_status as 'active' | 'inactive',
        });
      } else {
        setError('Failed to load customer data');
      }
    } catch (err: any) {
      setError(err?.response?.data?.message || err?.message || 'Failed to load customer. Please try again.');
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
    if (!formData.name?.trim()) {
      setError('Customer name is required');
      return false;
    }

    if (!formData.phone?.trim()) {
      setError('Phone number is required');
      return false;
    }

    if (formData.email && !/^[^\s@]+@[^\s@]+\.[^\s@]+$/.test(formData.email)) {
      setError('Invalid email format');
      return false;
    }

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
      const finalData: UpdateCustomerData = {
        ...formData,
        email: formData.email || undefined,
        nid: formData.nid || undefined,
        address: formData.address || undefined,
        price_per_liter: formData.price_per_liter || undefined,
      };

      const response = await customersApi.updateCustomer(finalData);

      if (response.code === 200) {
        router.push(`/customers/${customerCode}?updated=true`);
      } else {
        setError(response.message || 'Failed to update customer');
      }
    } catch (err: any) {
      setError(err?.response?.data?.message || err?.message || 'Failed to update customer. Please try again.');
    } finally {
      setSaving(false);
    }
  };

  if (loading) {
    return (
      <div className="flex items-center justify-center min-h-[400px]">
        <div className="text-center">
          <Icon icon={faSpinner} size="lg" spin className="text-[var(--primary)] mb-4" />
          <p className="text-gray-600">Loading customer data...</p>
        </div>
      </div>
    );
  }

  return (
    <div className="space-y-4">
      {/* Page Header */}
      <div className="flex items-center justify-between">
        <div>
          <h1 className="text-2xl font-bold text-gray-900">Edit Customer</h1>
          <p className="text-sm text-gray-600 mt-1">Update customer information</p>
        </div>
        <Link href={`/customers/${customerCode}`} className="btn btn-secondary">
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
        {/* Basic Information */}
        <div>
          <h2 className="text-lg font-semibold text-gray-900 mb-4">Basic Information</h2>
          <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
            <div>
              <label htmlFor="name" className="block text-sm font-medium text-gray-700 mb-2">
                <Icon icon={faUser} size="sm" className="inline mr-2" />
                Full Name <span className="text-red-500">*</span>
              </label>
              <input
                id="name"
                name="name"
                type="text"
                required
                value={formData.name}
                onChange={handleChange}
                className="input w-full"
                placeholder="Enter customer name"
                disabled={saving}
              />
            </div>

            <div>
              <label htmlFor="phone" className="block text-sm font-medium text-gray-700 mb-2">
                <Icon icon={faPhone} size="sm" className="inline mr-2" />
                Phone Number <span className="text-red-500">*</span>
              </label>
              <input
                id="phone"
                name="phone"
                type="tel"
                required
                value={formData.phone}
                onChange={handleChange}
                className="input w-full"
                placeholder="250788123456"
                disabled={saving}
              />
            </div>

            <div>
              <label htmlFor="email" className="block text-sm font-medium text-gray-700 mb-2">
                <Icon icon={faEnvelope} size="sm" className="inline mr-2" />
                Email Address
              </label>
              <input
                id="email"
                name="email"
                type="email"
                value={formData.email}
                onChange={handleChange}
                className="input w-full"
                placeholder="customer@example.com"
                disabled={saving}
              />
            </div>

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
              <label htmlFor="nid" className="block text-sm font-medium text-gray-700 mb-2">
                <Icon icon={faIdCard} size="sm" className="inline mr-2" />
                National ID
              </label>
              <input
                id="nid"
                name="nid"
                type="text"
                value={formData.nid}
                onChange={handleChange}
                className="input w-full"
                placeholder="1199887766554433"
                disabled={saving}
              />
            </div>

            <div>
              <label htmlFor="address" className="block text-sm font-medium text-gray-700 mb-2">
                <Icon icon={faMapPin} size="sm" className="inline mr-2" />
                Address
              </label>
              <input
                id="address"
                name="address"
                type="text"
                value={formData.address}
                onChange={handleChange}
                className="input w-full"
                placeholder="Kigali, Rwanda"
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
          <Link href={`/customers/${customerCode}`} className="btn btn-secondary" tabIndex={-1}>
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
                Update Customer
              </>
            )}
          </button>
        </div>
      </form>
    </div>
  );
}
