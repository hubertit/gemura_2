'use client';

import { useState, useEffect } from 'react';
import { useRouter, useParams, useSearchParams } from 'next/navigation';
import Link from 'next/link';
import { usePermission } from '@/hooks/usePermission';
import { inventoryApi, InventoryItem } from '@/lib/api/inventory';
import Icon, { faWarehouse, faBox, faDollarSign, faTag, faEdit, faArrowLeft, faSpinner, faCheckCircle, faCalendar } from '@/app/components/Icon';

export default function InventoryItemDetailsPage() {
  const router = useRouter();
  const params = useParams();
  const searchParams = useSearchParams();
  const itemId = params.id as string;
  const { hasPermission, isAdmin } = usePermission();
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState('');
  const [item, setItem] = useState<InventoryItem | null>(null);

  useEffect(() => {
    if (!hasPermission('view_inventory') && !isAdmin()) {
      router.push('/inventory');
      return;
    }
    loadItem();
  }, [itemId, hasPermission, isAdmin, router]);

  const loadItem = async () => {
    try {
      setLoading(true);
      setError('');
      const response = await inventoryApi.getInventoryItem(itemId);
      if (response.code === 200 && response.data) {
        setItem(response.data);
      } else {
        setError('Failed to load inventory item data');
      }
    } catch (err: any) {
      setError(err?.response?.data?.message || err?.message || 'Failed to load inventory item. Please try again.');
    } finally {
      setLoading(false);
    }
  };

  const formatCurrency = (amount: number) => {
    return new Intl.NumberFormat('en-RW', {
      style: 'currency',
      currency: 'RWF',
      minimumFractionDigits: 0,
    }).format(amount);
  };

  const isLowStock = (item: InventoryItem) => {
    if (item.min_stock_level !== null && item.min_stock_level !== undefined) {
      return item.stock_quantity <= item.min_stock_level;
    }
    return item.stock_quantity <= 0;
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

  if (error && !item) {
    return (
      <div className="space-y-4">
        <div className="bg-red-50 border border-red-200 rounded-sm p-4">
          <p className="text-sm text-red-600">{error}</p>
        </div>
        <Link href="/inventory" className="btn btn-secondary">
          <Icon icon={faArrowLeft} size="sm" className="mr-2" />
          Back to Inventory
        </Link>
      </div>
    );
  }

  const statusColors: Record<string, string> = {
    active: 'bg-green-100 text-green-700',
    inactive: 'bg-gray-100 text-gray-700',
    out_of_stock: 'bg-red-100 text-red-700',
  };

  return (
    <div className="space-y-4">

      {/* Page Header */}
      <div className="flex items-center justify-between">
        <div>
          <Link href="/inventory" className="text-sm text-gray-600 hover:text-[var(--primary)] mb-2 inline-flex items-center">
            <Icon icon={faArrowLeft} size="sm" className="mr-2" />
            Back to Inventory
          </Link>
          <h1 className="text-2xl font-bold text-gray-900">{item?.name || 'Inventory Item Details'}</h1>
        </div>
        <div className="flex items-center gap-2">
          <Link href={`/inventory/${itemId}/sell`} className="btn btn-primary">
            <Icon icon={faDollarSign} size="sm" className="mr-2" />
            Sell Item
          </Link>
          <Link href={`/inventory/${itemId}/edit`} className="btn btn-secondary">
            <Icon icon={faEdit} size="sm" className="mr-2" />
            Edit
          </Link>
        </div>
      </div>

      {/* Error Message */}
      {error && (
        <div className="bg-red-50 border border-red-200 rounded-sm p-4">
          <p className="text-sm text-red-600">{error}</p>
        </div>
      )}

      {item && (
        <div className="grid grid-cols-1 lg:grid-cols-3 gap-4">
          {/* Main Information */}
          <div className="lg:col-span-2 space-y-4">
            {/* Basic Information */}
            <div className="bg-white border border-gray-200 rounded-sm p-6">
              <h2 className="text-lg font-semibold text-gray-900 mb-4">Product Information</h2>
              <div className="space-y-4">
                <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
                  <div>
                    <label className="block text-sm font-medium text-gray-500 mb-1">Product Name</label>
                    <div className="flex items-center text-gray-900">
                      <Icon icon={faBox} size="sm" className="mr-2 text-gray-400" />
                      <span className="font-medium">{item.name}</span>
                    </div>
                  </div>

                  <div>
                    <label className="block text-sm font-medium text-gray-500 mb-1">Status</label>
                    <span className={`inline-flex px-2 py-1 text-xs font-medium rounded-full ${statusColors[item.status] || 'bg-gray-100 text-gray-700'}`}>
                      {item.status.replace(/_/g, ' ').replace(/\b\w/g, l => l.toUpperCase())}
                    </span>
                  </div>

                  {item.description && (
                    <div className="md:col-span-2">
                      <label className="block text-sm font-medium text-gray-500 mb-1">Description</label>
                      <p className="text-sm text-gray-700">{item.description}</p>
                    </div>
                  )}
                </div>
              </div>
            </div>

            {/* Stock Information */}
            <div className="bg-white border border-gray-200 rounded-sm p-6">
              <h2 className="text-lg font-semibold text-gray-900 mb-4">Stock Information</h2>
              <div className="space-y-3">
                <div className="flex items-center justify-between py-2 border-b border-gray-100">
                  <span className="text-sm text-gray-600 flex items-center">
                    <Icon icon={faWarehouse} size="sm" className="mr-2 text-gray-400" />
                    Current Stock
                  </span>
                  <div className="flex items-center">
                    <span className={`text-sm font-medium ${isLowStock(item) ? 'text-red-600' : 'text-gray-900'}`}>
                      {Number(item.stock_quantity)}
                    </span>
                    {isLowStock(item) && (
                      <span className="ml-2 text-red-500" title="Low Stock">⚠️</span>
                    )}
                  </div>
                </div>
                {item.min_stock_level !== null && item.min_stock_level !== undefined && (
                  <div className="flex items-center justify-between py-2 border-b border-gray-100">
                    <span className="text-sm text-gray-600">Minimum Stock Level</span>
                    <span className="text-sm font-medium text-gray-900">{item.min_stock_level}</span>
                  </div>
                )}
                <div className="flex items-center justify-between py-2">
                  <span className="text-sm text-gray-600">Total Value</span>
                  <span className="text-lg font-bold text-[var(--primary)]">
                    {formatCurrency(Number(item.price) * Number(item.stock_quantity))}
                  </span>
                </div>
              </div>
            </div>

            {/* Pricing */}
            <div className="bg-white border border-gray-200 rounded-sm p-6">
              <h2 className="text-lg font-semibold text-gray-900 mb-4">Pricing</h2>
              <div className="flex items-center justify-between">
                <span className="text-sm text-gray-600">Unit Price</span>
                <span className="text-lg font-semibold text-gray-900 flex items-center">
                  <Icon icon={faDollarSign} size="sm" className="mr-1 text-gray-400" />
                  {formatCurrency(Number(item.price))}
                </span>
              </div>
            </div>

            {/* Categories */}
            {item.categories && item.categories.length > 0 && (
              <div className="bg-white border border-gray-200 rounded-sm p-6">
                <h2 className="text-lg font-semibold text-gray-900 mb-4">Categories</h2>
                <div className="flex flex-wrap gap-2">
                  {item.categories.map(category => (
                    <span
                      key={category.id}
                      className="inline-flex px-3 py-1 text-xs font-medium bg-blue-100 text-blue-700 rounded-full"
                    >
                      <Icon icon={faTag} size="sm" className="mr-1" />
                      {category.name}
                    </span>
                  ))}
                </div>
              </div>
            )}
          </div>

          {/* Sidebar */}
          <div className="space-y-4">
            {/* Quick Information */}
            <div className="bg-white border border-gray-200 rounded-sm p-6">
              <h2 className="text-lg font-semibold text-gray-900 mb-4">Quick Information</h2>
              <div className="space-y-3">
                <div>
                  <label className="block text-sm font-medium text-gray-500 mb-1">Item ID</label>
                  <p className="text-sm text-gray-900 font-mono">{item.id}</p>
                </div>

                <div>
                  <label className="block text-sm font-medium text-gray-500 mb-1">Created At</label>
                  <div className="flex items-center text-sm text-gray-900">
                    <Icon icon={faCalendar} size="sm" className="mr-2 text-gray-400" />
                    <span>{new Date(item.created_at).toLocaleString()}</span>
                  </div>
                </div>

                <div>
                  <label className="block text-sm font-medium text-gray-500 mb-1">Updated At</label>
                  <div className="flex items-center text-sm text-gray-900">
                    <Icon icon={faCalendar} size="sm" className="mr-2 text-gray-400" />
                    <span>{new Date(item.updated_at).toLocaleString()}</span>
                  </div>
                </div>

                <div>
                  <label className="block text-sm font-medium text-gray-500 mb-1">Marketplace</label>
                  <span className={`px-2 py-1 rounded text-xs font-medium ${
                    item.is_listed_in_marketplace 
                      ? 'bg-blue-100 text-blue-700' 
                      : 'bg-gray-100 text-gray-700'
                  }`}>
                    {item.is_listed_in_marketplace ? 'Listed' : 'Not Listed'}
                  </span>
                </div>
              </div>
            </div>

            {/* Quick Actions */}
            <div className="bg-white border border-gray-200 rounded-sm p-6">
              <h2 className="text-lg font-semibold text-gray-900 mb-4">Quick Actions</h2>
              <div className="space-y-2">
                <Link href={`/inventory/${itemId}/sell`} className="btn btn-primary w-full justify-center">
                  <Icon icon={faDollarSign} size="sm" className="mr-2" />
                  Sell Item
                </Link>
                <Link href={`/inventory/${itemId}/edit`} className="btn btn-secondary w-full justify-center">
                  <Icon icon={faEdit} size="sm" className="mr-2" />
                  Edit Item
                </Link>
                <Link href="/inventory" className="btn btn-secondary w-full justify-center">
                  <Icon icon={faArrowLeft} size="sm" className="mr-2" />
                  Back to List
                </Link>
              </div>
            </div>
          </div>
        </div>
      )}
    </div>
  );
}
