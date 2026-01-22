'use client';

import { useState, useEffect } from 'react';
import { useRouter } from 'next/navigation';
import Link from 'next/link';
import { usePermission } from '@/hooks/usePermission';
import { suppliersApi, CreateSupplierData } from '@/lib/api/suppliers';
import Icon, { faBuilding, faUser, faPhone, faEnvelope, faIdCard, faMapPin, faDollarSign, faCheckCircle, faTimes, faSpinner } from '@/app/components/Icon';

export default function CreateSupplierPage() {
  const router = useRouter();
  const { hasPermission, isAdmin } = usePermission();
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState('');
  const [formData, setFormData] = useState<CreateSupplierData>({
    name: '',
    phone: '',
    price_per_liter: 0,
    email: '',
    nid: '',
    address: '',
  });

  useEffect(() => {
    if (!hasPermission('create_suppliers') && !isAdmin()) {
      router.push('/suppliers');
      return;
    }
  }, [hasPermission, isAdmin, router]);

  const handleChange = (e: React.ChangeEvent<HTMLInputElement>) => {
    const { name, value } = e.target;
    setFormData(prev => ({
      ...prev,
      [name]: name === 'price_per_liter' ? parseFloat(value) || 0 : value,
    }));
    setError('');
  };

  const validateForm = (): boolean => {
    if (!formData.name.trim()) {
      setError('Supplier name is required');
      return false;
    }

    if (!formData.phone.trim()) {
      setError('Phone number is required');
      return false;
    }

    if (!/^250[0-9]{9}$/.test(formData.phone.replace(/\D/g, ''))) {
      setError('Phone number must be in Rwandan format (250XXXXXXXXX)');
      return false;
    }

    if (!formData.price_per_liter || formData.price_per_liter <= 0) {
      setError('Price per liter must be greater than 0');
      return false;
    }

    if (formData.email && !/^[^\s@]+@[^\s@]+\.[^\s@]+$/.test(formData.email)) {
      setError('Invalid email format');
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
      // Normalize phone number
      const normalizedPhone = formData.phone.replace(/\D/g, '');
      
      const finalData: CreateSupplierData = {
        ...formData,
        phone: normalizedPhone,
        email: formData.email || undefined,
        nid: formData.nid || undefined,
        address: formData.address || undefined,
      };

      const response = await suppliersApi.createSupplier(finalData);

      if (response.code === 200 || response.code === 201) {
        router.push('/suppliers?created=true');
      } else {
        setError(response.message || 'Failed to create supplier');
      }
    } catch (err: any) {
      setError(err?.response?.data?.message || err?.message || 'Failed to create supplier. Please try again.');
    } finally {
      setLoading(false);
    }
  };

  return (
    <div className="space-y-4">
      {/* Page Header */}
      <div className="flex items-center justify-between">
        <div>
          <h1 className="text-2xl font-bold text-gray-900">Add Supplier</h1>
          <p className="text-sm text-gray-600 mt-1">Register a new milk supplier</p>
        </div>
        <Link href="/suppliers" className="btn btn-secondary">
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
                placeholder="Enter supplier name"
                disabled={loading}
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
                disabled={loading}
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
                placeholder="supplier@example.com"
                disabled={loading}
              />
            </div>

            <div>
              <label htmlFor="price_per_liter" className="block text-sm font-medium text-gray-700 mb-2">
                <Icon icon={faDollarSign} size="sm" className="inline mr-2" />
                Price per Liter (RWF) <span className="text-red-500">*</span>
              </label>
              <input
                id="price_per_liter"
                name="price_per_liter"
                type="number"
                step="0.01"
                min="0"
                required
                value={formData.price_per_liter}
                onChange={handleChange}
                className="input w-full"
                placeholder="0.00"
                disabled={loading}
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
                disabled={loading}
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
                disabled={loading}
              />
            </div>
          </div>
        </div>

        {/* Form Actions */}
        <div className="flex items-center justify-end gap-3 pt-4 border-t border-gray-200">
          <Link href="/suppliers" className="btn btn-secondary" tabIndex={-1}>
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
                Create Supplier
              </>
            )}
          </button>
        </div>
      </form>
    </div>
  );
}
