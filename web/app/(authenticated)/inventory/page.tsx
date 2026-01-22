'use client';

import { useEffect, useState, useCallback } from 'react';
import { useRouter, useSearchParams } from 'next/navigation';
import Link from 'next/link';
import { usePermission } from '@/hooks/usePermission';
import { inventoryApi, InventoryItem } from '@/lib/api/inventory';
import { useToastStore } from '@/store/toast';
import DataTable, { TableColumn } from '@/app/components/DataTable';
import Filters, { FilterGroup, FilterLabel } from '@/app/components/Filters';
import Icon, { faPlus, faEdit, faTrash, faEye, faCheckCircle, faWarehouse, faDollarSign, faBox } from '@/app/components/Icon';

const STATUS_OPTIONS = [
  { value: '', label: 'All Statuses' },
  { value: 'active', label: 'Active' },
  { value: 'inactive', label: 'Inactive' },
  { value: 'out_of_stock', label: 'Out of Stock' },
];

export default function InventoryPage() {
  const router = useRouter();
  const searchParams = useSearchParams();
  const { hasPermission, isAdmin } = usePermission();
  const [loading, setLoading] = useState(true);
  const [inventory, setInventory] = useState<InventoryItem[]>([]);
  const [error, setError] = useState('');
  const [statusFilter, setStatusFilter] = useState<string>(searchParams.get('status') || '');
  const [lowStockFilter, setLowStockFilter] = useState<boolean>(false);

  const loadInventory = useCallback(async () => {
    try {
      setLoading(true);
      setError('');
      const response = await inventoryApi.getInventory(statusFilter || undefined, lowStockFilter);
      if (response.code === 200) {
        setInventory(response.data || []);
      } else {
        setError(response.message || 'Failed to load inventory');
      }
    } catch (err: any) {
      setError(err?.response?.data?.message || err?.message || 'Failed to load inventory');
    } finally {
      setLoading(false);
    }
  }, [statusFilter, lowStockFilter]);

  useEffect(() => {
    // Check permission
    if (!hasPermission('view_inventory') && !isAdmin()) {
      router.push('/dashboard');
      return;
    }
    loadInventory();
  }, [hasPermission, isAdmin, router, loadInventory]);

  const handleDelete = async (itemId: string) => {
    if (!confirm('Are you sure you want to delete this inventory item?')) {
      return;
    }

    try {
      await inventoryApi.deleteInventoryItem(itemId);
      loadInventory();
    } catch (err: any) {
      useToastStore.getState().error(err?.response?.data?.message || 'Failed to delete inventory item');
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

  const columns: TableColumn<InventoryItem>[] = [
    {
      key: 'name',
      label: 'Product Name',
      sortable: true,
      render: (value, row) => (
        <div>
          <div className="font-medium text-gray-900">{value}</div>
          {row.description && (
            <div className="text-xs text-gray-500">{row.description}</div>
          )}
        </div>
      ),
    },
    {
      key: 'price',
      label: 'Price',
      sortable: true,
      render: (value) => (
        <div className="flex items-center text-gray-900">
          <Icon icon={faDollarSign} size="sm" className="mr-1 text-gray-400" />
          <span>{formatCurrency(Number(value))}</span>
        </div>
      ),
    },
    {
      key: 'stock_quantity',
      label: 'Stock',
      sortable: true,
      render: (value, row) => {
        const isLow = isLowStock(row);
        return (
          <div className="flex items-center">
            <Icon icon={faBox} size="sm" className={`mr-2 ${isLow ? 'text-red-500' : 'text-gray-400'}`} />
            <span className={isLow ? 'text-red-600 font-semibold' : 'text-gray-900'}>
              {Number(value)}
            </span>
            {isLow && (
              <span className="ml-2 text-red-500" title="Low Stock">⚠️</span>
            )}
          </div>
        );
      },
    },
    {
      key: 'status',
      label: 'Status',
      sortable: true,
      render: (value) => {
        const statusColors: Record<string, string> = {
          active: 'bg-green-100 text-green-700',
          inactive: 'bg-gray-100 text-gray-700',
          out_of_stock: 'bg-red-100 text-red-700',
        };
        return (
          <span className={`px-2 py-1 rounded text-xs font-medium ${statusColors[value as string] || 'bg-gray-100 text-gray-700'}`}>
            {String(value).replace(/_/g, ' ').replace(/\b\w/g, l => l.toUpperCase())}
          </span>
        );
      },
    },
    {
      key: 'is_listed_in_marketplace',
      label: 'Marketplace',
      sortable: true,
      render: (value) => (
        <span className={`px-2 py-1 rounded text-xs font-medium ${
          value ? 'bg-blue-100 text-blue-700' : 'bg-gray-100 text-gray-700'
        }`}>
          {value ? 'Listed' : 'Not Listed'}
        </span>
      ),
    },
    {
      key: 'actions',
      label: 'Actions',
      render: (_, row) => (
        <div className="flex items-center gap-2">
          <Link
            href={`/inventory/${row.id}`}
            className="p-1.5 text-gray-600 hover:text-[var(--primary)] transition-colors"
            title="View"
          >
            <Icon icon={faEye} size="sm" />
          </Link>
          <Link
            href={`/inventory/${row.id}/edit`}
            className="p-1.5 text-gray-600 hover:text-[var(--primary)] transition-colors"
            title="Edit"
          >
            <Icon icon={faEdit} size="sm" />
          </Link>
          <Link
            href={`/inventory/${row.id}/sell`}
            className="p-1.5 text-gray-600 hover:text-green-600 transition-colors"
            title="Sell"
          >
            <Icon icon={faDollarSign} size="sm" />
          </Link>
          <button
            onClick={() => handleDelete(row.id)}
            className="p-1.5 text-gray-600 hover:text-red-600 transition-colors"
            title="Delete"
          >
            <Icon icon={faTrash} size="sm" />
          </button>
        </div>
      ),
    },
  ];

  return (
    <div className="space-y-4">
      {/* Page Header */}
      <div className="flex items-center justify-between">
        <div>
          <h1 className="text-2xl font-bold text-gray-900">Inventory</h1>
          <p className="text-sm text-gray-600 mt-1">Manage your product inventory</p>
        </div>
        <Link href="/inventory/new" className="btn btn-primary">
          <Icon icon={faPlus} size="sm" className="mr-2" />
          Add Item
        </Link>
      </div>


      {/* Filters */}
      <Filters
        activeFilterCount={(statusFilter ? 1 : 0) + (lowStockFilter ? 1 : 0)}
        onApply={() => loadInventory()}
        onClear={() => {
          setStatusFilter('');
          setLowStockFilter(false);
          loadInventory();
        }}
      >
        <FilterGroup>
          <FilterLabel>Status</FilterLabel>
          <select
            value={statusFilter}
            onChange={(e) => setStatusFilter(e.target.value)}
            className="px-2.5 py-[0.4375rem] border border-gray-300 rounded text-[0.8125rem] text-gray-700 bg-white h-9 w-full focus:outline-none focus:border-[var(--primary)] focus:ring-1 focus:ring-[var(--primary)]"
          >
            {STATUS_OPTIONS.map(option => (
              <option key={option.value} value={option.value}>
                {option.label}
              </option>
            ))}
          </select>
        </FilterGroup>
        <FilterGroup>
          <FilterLabel>Stock Filter</FilterLabel>
          <label className="flex items-center h-9">
            <input
              type="checkbox"
              checked={lowStockFilter}
              onChange={(e) => setLowStockFilter(e.target.checked)}
              className="mr-2 h-4 w-4 text-[var(--primary)] focus:ring-[var(--primary)] border-gray-300 rounded"
            />
            <span className="text-sm text-gray-700">Show Low Stock Only</span>
          </label>
        </FilterGroup>
      </Filters>

      {/* Error Message */}
      {error && (
        <div className="bg-red-50 border border-red-200 rounded-sm p-4">
          <p className="text-sm text-red-600">{error}</p>
        </div>
      )}

      {/* Inventory Table */}
      <DataTable
        data={inventory}
        columns={columns}
        loading={loading}
        emptyMessage="No inventory items found"
      />

      {/* Summary */}
      {inventory.length > 0 && (
        <div className="bg-white border border-gray-200 rounded-sm p-4">
          <div className="grid grid-cols-1 md:grid-cols-4 gap-4">
            <div>
              <p className="text-sm text-gray-600">Total Items</p>
              <p className="text-lg font-semibold text-gray-900">{inventory.length}</p>
            </div>
            <div>
              <p className="text-sm text-gray-600">Total Stock</p>
              <p className="text-lg font-semibold text-gray-900">
                {inventory.reduce((sum, item) => sum + Number(item.stock_quantity), 0)}
              </p>
            </div>
            <div>
              <p className="text-sm text-gray-600">Low Stock Items</p>
              <p className="text-lg font-semibold text-red-600">
                {inventory.filter(item => isLowStock(item)).length}
              </p>
            </div>
            <div>
              <p className="text-sm text-gray-600">Total Value</p>
              <p className="text-lg font-semibold text-gray-900">
                {formatCurrency(
                  inventory.reduce((sum, item) => sum + (Number(item.price) * Number(item.stock_quantity)), 0)
                )}
              </p>
            </div>
          </div>
        </div>
      )}
    </div>
  );
}
