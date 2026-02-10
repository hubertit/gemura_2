'use client';

import { useState } from 'react';
import { suppliersApi, CreateSupplierData } from '@/lib/api/suppliers';
import { useToastStore } from '@/store/toast';
import Icon, { faCheckCircle, faSpinner } from '@/app/components/Icon';

interface CreateSupplierFormProps {
  onSuccess: () => void;
  onCancel: () => void;
}

export default function CreateSupplierForm({ onSuccess, onCancel }: CreateSupplierFormProps) {
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
      setError('Phone must be Rwandan format (250XXXXXXXXX)');
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
    if (!validateForm()) return;
    setLoading(true);
    try {
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
        useToastStore.getState().success('Supplier created successfully!');
        onSuccess();
      } else {
        setError(response.message || 'Failed to create supplier');
      }
    } catch (err: unknown) {
      setError((err as { response?: { data?: { message?: string } }; message?: string })?.response?.data?.message || (err as { message?: string })?.message || 'Failed to create supplier.');
    } finally {
      setLoading(false);
    }
  };

  return (
    <form onSubmit={handleSubmit} className="space-y-4">
      {error && (
        <div className="bg-red-50 border border-red-200 rounded p-3 text-sm text-red-600">
          {error}
        </div>
      )}
      <div className="grid grid-cols-1 sm:grid-cols-2 gap-4">
        <div>
          <label htmlFor="supplier-name" className="block text-sm font-medium text-gray-700 mb-1">Full Name <span className="text-red-500">*</span></label>
          <input id="supplier-name" name="name" type="text" required value={formData.name} onChange={handleChange} className="input w-full" placeholder="Supplier name" disabled={loading} />
        </div>
        <div>
          <label htmlFor="supplier-phone" className="block text-sm font-medium text-gray-700 mb-1">Phone <span className="text-red-500">*</span></label>
          <input id="supplier-phone" name="phone" type="tel" required value={formData.phone} onChange={handleChange} className="input w-full" placeholder="250788123456" disabled={loading} />
        </div>
        <div>
          <label htmlFor="supplier-email" className="block text-sm font-medium text-gray-700 mb-1">Email</label>
          <input id="supplier-email" name="email" type="email" value={formData.email} onChange={handleChange} className="input w-full" placeholder="email@example.com" disabled={loading} />
        </div>
        <div>
          <label htmlFor="supplier-price" className="block text-sm font-medium text-gray-700 mb-1">Price per liter (RWF) <span className="text-red-500">*</span></label>
          <input id="supplier-price" name="price_per_liter" type="number" step="0.01" min="0" required value={formData.price_per_liter} onChange={handleChange} className="input w-full" disabled={loading} />
        </div>
        <div className="sm:col-span-2">
          <label htmlFor="supplier-nid" className="block text-sm font-medium text-gray-700 mb-1">National ID</label>
          <input id="supplier-nid" name="nid" type="text" value={formData.nid} onChange={handleChange} className="input w-full" placeholder="Optional" disabled={loading} />
        </div>
        <div className="sm:col-span-2">
          <label htmlFor="supplier-address" className="block text-sm font-medium text-gray-700 mb-1">Address</label>
          <input id="supplier-address" name="address" type="text" value={formData.address} onChange={handleChange} className="input w-full" placeholder="Optional" disabled={loading} />
        </div>
      </div>
      <div className="flex justify-end gap-2 pt-2 border-t border-gray-200">
        <button type="button" onClick={onCancel} className="btn btn-secondary">
          Cancel
        </button>
        <button type="submit" className="btn btn-primary" disabled={loading}>
          {loading ? <><Icon icon={faSpinner} size="sm" spin className="mr-2" />Creating...</> : <><Icon icon={faCheckCircle} size="sm" className="mr-2" />Create Supplier</>}
        </button>
      </div>
    </form>
  );
}
