'use client';

import { useState, useEffect } from 'react';
import { useRouter } from 'next/navigation';
import Link from 'next/link';
import { usePermission } from '@/hooks/usePermission';
import { inventoryApi, CreateInventoryData } from '@/lib/api/inventory';
import { categoriesApi, Category } from '@/lib/api/categories';
import { useToastStore } from '@/store/toast';
import Icon, { faWarehouse, faBox, faDollarSign, faTag, faCheckCircle, faTimes, faSpinner } from '@/app/components/Icon';

export default function CreateInventoryPage() {
  const router = useRouter();
  const { hasPermission, isAdmin } = usePermission();
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
    if (!hasPermission('manage_inventory') && !isAdmin()) {
      router.push('/inventory');
      return;
    }
    loadCategories();
  }, [hasPermission, isAdmin, router]);

  const loadCategories = async () => {
    try {
      setLoadingCategories(true);
      const response = await categoriesApi.getCategories();
      if (response.code === 200) {
        setCategories(response.data || []);
      }
    } catch (err: any) {
      console.error('Failed to load categories:', err);
    } finally {
      setLoadingCategories(false);
    }
  };

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
      const newCategories = isSelected
        ? prev.selectedCategories.filter(id => id !== categoryId)
        : [...prev.selectedCategories, categoryId];
      
      return {
        ...prev,
        selectedCategories: newCategories,
        category_ids: newCategories,
      };
    });
  };

  const validateForm = (): boolean => {
    if (!formData.name.trim()) {
      setError('Product name is required');
      return false;
    }

    if (!formData.price || formData.price < 0) {
      setError('Price must be greater than or equal to 0');
      return false;
    }

    if (formData.stock_quantity && formData.stock_quantity < 0) {
      setError('Stock quantity cannot be negative');
      return false;
    }

    if (formData.min_stock_level && formData.min_stock_level < 0) {
      setError('Minimum stock level cannot be negative');
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
      const { selectedCategories, ...finalData } = formData;
      const response = await inventoryApi.createInventoryItem(finalData);

      if (response.code === 200 || response.code === 201) {
        useToastStore.getState().success('Inventory item created successfully!');
        router.push('/inventory');
      } else {
        setError(response.message || 'Failed to create inventory item');
      }
    } catch (err: any) {
      setError(err?.response?.data?.message || err?.message || 'Failed to create inventory item. Please try again.');
    } finally {
      setLoading(false);
    }
  };

  return (
    <div className="space-y-4">
      {/* Page Header */}
      <div className="flex items-center justify-between">
        <div>
          <h1 className="text-2xl font-bold text-gray-900">Add Inventory Item</h1>
          <p className="text-sm text-gray-600 mt-1">Create a new product in your inventory</p>
        </div>
        <Link href="/inventory" className="btn btn-secondary">
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
            <div className="md:col-span-2">
              <label htmlFor="name" className="block text-sm font-medium text-gray-700 mb-2">
                <Icon icon={faBox} size="sm" className="inline mr-2" />
                Product Name <span className="text-red-500">*</span>
              </label>
              <input
                id="name"
                name="name"
                type="text"
                required
                value={formData.name}
                onChange={handleChange}
                className="input w-full"
                placeholder="Enter product name"
                disabled={loading}
              />
            </div>

            <div className="md:col-span-2">
              <label htmlFor="description" className="block text-sm font-medium text-gray-700 mb-2">
                Description
              </label>
              <textarea
                id="description"
                name="description"
                rows={3}
                value={formData.description}
                onChange={handleChange}
                className="input w-full"
                placeholder="Enter product description"
                disabled={loading}
              />
            </div>

            <div>
              <label htmlFor="price" className="block text-sm font-medium text-gray-700 mb-2">
                <Icon icon={faDollarSign} size="sm" className="inline mr-2" />
                Price (RWF) <span className="text-red-500">*</span>
              </label>
              <input
                id="price"
                name="price"
                type="number"
                step="0.01"
                min="0"
                required
                value={formData.price}
                onChange={handleChange}
                className="input w-full"
                placeholder="0.00"
                disabled={loading}
              />
            </div>

            <div>
              <label htmlFor="stock_quantity" className="block text-sm font-medium text-gray-700 mb-2">
                <Icon icon={faWarehouse} size="sm" className="inline mr-2" />
                Initial Stock Quantity
              </label>
              <input
                id="stock_quantity"
                name="stock_quantity"
                type="number"
                min="0"
                value={formData.stock_quantity}
                onChange={handleChange}
                className="input w-full"
                placeholder="0"
                disabled={loading}
              />
            </div>

            <div>
              <label htmlFor="min_stock_level" className="block text-sm font-medium text-gray-700 mb-2">
                Minimum Stock Level
              </label>
              <input
                id="min_stock_level"
                name="min_stock_level"
                type="number"
                min="0"
                value={formData.min_stock_level}
                onChange={handleChange}
                className="input w-full"
                placeholder="0"
                disabled={loading}
              />
            </div>
          </div>
        </div>

        {/* Categories */}
        {categories.length > 0 && (
          <div>
            <h2 className="text-lg font-semibold text-gray-900 mb-4">Categories</h2>
            <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-3">
              {categories.map(category => (
                <label
                  key={category.id}
                  className="flex items-center p-3 border border-gray-200 rounded-sm hover:bg-gray-50 cursor-pointer"
                >
                  <input
                    type="checkbox"
                    checked={formData.selectedCategories.includes(category.id)}
                    onChange={() => handleCategoryToggle(category.id)}
                    className="mr-3 h-4 w-4 text-[var(--primary)] focus:ring-[var(--primary)] border-gray-300 rounded"
                    disabled={loading}
                  />
                  <div>
                    <span className="text-sm text-gray-900 font-medium">{category.name}</span>
                    {category.description && (
                      <p className="text-xs text-gray-500">{category.description}</p>
                    )}
                  </div>
                </label>
              ))}
            </div>
          </div>
        )}

        {/* Marketplace Listing */}
        <div>
          <label className="flex items-center cursor-pointer">
            <input
              type="checkbox"
              name="is_listed_in_marketplace"
              checked={formData.is_listed_in_marketplace}
              onChange={handleChange}
              className="mr-3 h-4 w-4 text-[var(--primary)] focus:ring-[var(--primary)] border-gray-300 rounded"
              disabled={loading}
            />
            <span className="text-sm text-gray-700">List in marketplace immediately</span>
          </label>
        </div>

        {/* Form Actions */}
        <div className="flex items-center justify-end gap-3 pt-4 border-t border-gray-200">
          <Link href="/inventory" className="btn btn-secondary" tabIndex={-1}>
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
                Create Item
              </>
            )}
          </button>
        </div>
      </form>
    </div>
  );
}
