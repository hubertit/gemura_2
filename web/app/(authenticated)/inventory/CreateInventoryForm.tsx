'use client';

import { useState, useEffect } from 'react';
import { inventoryApi, CreateInventoryData } from '@/lib/api/inventory';
import { categoriesApi, Category } from '@/lib/api/categories';
import { useToastStore } from '@/store/toast';
import Icon, { faCheckCircle, faSpinner } from '@/app/components/Icon';

interface CreateInventoryFormProps {
  onSuccess: () => void;
  onCancel: () => void;
}

export default function CreateInventoryForm({ onSuccess, onCancel }: CreateInventoryFormProps) {
  const [loading, setLoading] = useState(false);
  const [loadingCategories, setLoadingCategories] = useState(true);
  const [error, setError] = useState('');
  const [categories, setCategories] = useState<Category[]>([]);
  const [formData, setFormData] = useState<CreateInventoryData & { selectedCategories: string[] }>({
    name: '',
    description: '',
    price: 0,
    stock_quantity: 0,
    min_stock_level: 0,
    category_ids: [],
    selectedCategories: [],
    is_listed_in_marketplace: false,
  });

  useEffect(() => {
    let cancelled = false;
    categoriesApi.getCategories().then((res) => {
      if (!cancelled && res.code === 200) setCategories(res.data || []);
    }).finally(() => { if (!cancelled) setLoadingCategories(false); });
    return () => { cancelled = true; };
  }, []);

  const handleChange = (e: React.ChangeEvent<HTMLInputElement | HTMLTextAreaElement>) => {
    const { name, value, type } = e.target;
    const checked = (e.target as HTMLInputElement).checked;
    setFormData(prev => ({
      ...prev,
      [name]: type === 'checkbox' ? checked : (type === 'number' ? parseFloat(value) || 0 : value),
    }));
    setError('');
  };

  const handleCategoryToggle = (categoryId: string) => {
    setFormData(prev => {
      const isSelected = prev.selectedCategories.includes(categoryId);
      const newCategories = isSelected ? prev.selectedCategories.filter(id => id !== categoryId) : [...prev.selectedCategories, categoryId];
      return { ...prev, selectedCategories: newCategories, category_ids: newCategories };
    });
  };

  const validateForm = (): boolean => {
    if (!formData.name.trim()) { setError('Product name is required'); return false; }
    if (formData.price < 0) { setError('Price must be >= 0'); return false; }
    if (formData.stock_quantity != null && formData.stock_quantity < 0) { setError('Stock quantity cannot be negative'); return false; }
    if (formData.min_stock_level != null && formData.min_stock_level < 0) { setError('Minimum stock level cannot be negative'); return false; }
    return true;
  };

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    setError('');
    if (!validateForm()) return;
    setLoading(true);
    try {
      const { selectedCategories, ...finalData } = formData;
      const response = await inventoryApi.createInventoryItem(finalData);
      if (response.code === 200 || response.code === 201) {
        useToastStore.getState().success('Inventory item created successfully!');
        onSuccess();
      } else {
        setError(response.message || 'Failed to create item');
      }
    } catch (err: unknown) {
      setError((err as { response?: { data?: { message?: string } }; message?: string })?.response?.data?.message || (err as { message?: string })?.message || 'Failed to create item.');
    } finally {
      setLoading(false);
    }
  };

  return (
    <form onSubmit={handleSubmit} className="space-y-4">
      {error && <div className="bg-red-50 border border-red-200 rounded p-3 text-sm text-red-600">{error}</div>}
      <div className="grid grid-cols-1 sm:grid-cols-2 gap-4">
        <div className="sm:col-span-2">
          <label htmlFor="inv-name" className="block text-sm font-medium text-gray-700 mb-1">Product name <span className="text-red-500">*</span></label>
          <input id="inv-name" name="name" type="text" required value={formData.name} onChange={handleChange} className="input w-full" placeholder="Product name" disabled={loading} />
        </div>
        <div className="sm:col-span-2">
          <label htmlFor="inv-description" className="block text-sm font-medium text-gray-700 mb-1">Description</label>
          <textarea id="inv-description" name="description" rows={2} value={formData.description} onChange={handleChange} className="input w-full" placeholder="Optional" disabled={loading} />
        </div>
        <div>
          <label htmlFor="inv-price" className="block text-sm font-medium text-gray-700 mb-1">Price (RWF) <span className="text-red-500">*</span></label>
          <input id="inv-price" name="price" type="number" step="0.01" min="0" required value={formData.price} onChange={handleChange} className="input w-full" disabled={loading} />
        </div>
        <div>
          <label htmlFor="inv-stock" className="block text-sm font-medium text-gray-700 mb-1">Initial stock</label>
          <input id="inv-stock" name="stock_quantity" type="number" min="0" value={formData.stock_quantity} onChange={handleChange} className="input w-full" disabled={loading} />
        </div>
        <div>
          <label htmlFor="inv-min" className="block text-sm font-medium text-gray-700 mb-1">Min stock level</label>
          <input id="inv-min" name="min_stock_level" type="number" min="0" value={formData.min_stock_level} onChange={handleChange} className="input w-full" disabled={loading} />
        </div>
      </div>
      {categories.length > 0 && (
        <div>
          <p className="text-sm font-medium text-gray-700 mb-2">Categories</p>
          <div className="flex flex-wrap gap-2">
            {categories.map(cat => (
              <label key={cat.id} className="flex items-center gap-2 px-3 py-1.5 border border-gray-200 rounded text-sm cursor-pointer hover:bg-gray-50">
                <input type="checkbox" checked={formData.selectedCategories.includes(cat.id)} onChange={() => handleCategoryToggle(cat.id)} className="rounded border-gray-300 text-[var(--primary)]" disabled={loading} />
                <span>{cat.name}</span>
              </label>
            ))}
          </div>
        </div>
      )}
      <label className="flex items-center gap-2 cursor-pointer">
        <input type="checkbox" name="is_listed_in_marketplace" checked={formData.is_listed_in_marketplace} onChange={handleChange} className="rounded border-gray-300 text-[var(--primary)]" disabled={loading} />
        <span className="text-sm text-gray-700">List in marketplace</span>
      </label>
      <div className="flex justify-end gap-2 pt-2 border-t border-gray-200">
        <button type="button" onClick={onCancel} className="btn btn-secondary">Cancel</button>
        <button type="submit" className="btn btn-primary" disabled={loading}>
          {loading ? <><Icon icon={faSpinner} size="sm" spin className="mr-2" />Creating...</> : <><Icon icon={faCheckCircle} size="sm" className="mr-2" />Create Item</>}
        </button>
      </div>
    </form>
  );
}
