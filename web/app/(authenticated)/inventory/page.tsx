'use client';

import { useEffect, useState, useCallback } from 'react';
import { useSearchParams } from 'next/navigation';
import Link from 'next/link';
import { inventoryApi, InventoryItem } from '@/lib/api/inventory';
import { useAuthStore } from '@/store/auth';
import { useToastStore } from '@/store/toast';
import DataTableWithPagination from '@/app/components/DataTableWithPagination';
import type { TableColumn } from '@/app/components/DataTable';
import FilterBar, { FilterBarGroup, FilterBarActions, FilterBarExport } from '@/app/components/FilterBar';
import Modal from '@/app/components/Modal';
import CreateInventoryForm from './CreateInventoryForm';
import Icon, { faPlus, faEye, faCheckCircle, faWarehouse, faDollarSign, faBox, faTriangleExclamation, faCircleXmark } from '@/app/components/Icon';

const STATUS_OPTIONS = [
  { value: '', label: 'All Statuses' },
  { value: 'active', label: 'Active' },
  { value: 'inactive', label: 'Inactive' },
  { value: 'out_of_stock', label: 'Out of Stock' },
];

export default function InventoryPage() {
  const searchParams = useSearchParams();
  const { currentAccount } = useAuthStore();
  const [loading, setLoading] = useState(true);
  const [inventory, setInventory] = useState<InventoryItem[]>([]);
  const [error, setError] = useState('');
  const [createModalOpen, setCreateModalOpen] = useState(false);
  const [statusFilter, setStatusFilter] = useState<string>(searchParams.get('status') || '');
  const [lowStockFilter, setLowStockFilter] = useState<boolean>(false);
  const [stats, setStats] = useState<{ total_items: number; active_items: number; out_of_stock_items: number; low_stock_items: number; listed_in_marketplace?: number } | null>(null);

  const loadInventory = useCallback(async () => {
    try {
      setLoading(true);
      setError('');
      const [listRes, statsRes] = await Promise.all([
        inventoryApi.getInventory(currentAccount?.account_id, statusFilter || undefined, lowStockFilter),
        currentAccount?.account_id ? inventoryApi.getInventoryStats(currentAccount.account_id).catch(() => null) : Promise.resolve(null),
      ]);
      if (listRes.code === 200) {
        setInventory(listRes.data || []);
      } else {
        setError(listRes.message || 'Failed to load inventory');
      }
      if (statsRes?.code === 200 && statsRes.data) {
        setStats(statsRes.data);
      } else {
        setStats(null);
      }
    } catch (err: unknown) {
      setError((err as { response?: { data?: { message?: string } }; message?: string })?.response?.data?.message || (err as { message?: string })?.message || 'Failed to load inventory');
    } finally {
      setLoading(false);
    }
  }, [currentAccount?.account_id, statusFilter, lowStockFilter]);

  useEffect(() => {
    loadInventory();
  }, [loadInventory]);

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
        <Link
          href={`/inventory/${row.id}`}
          className="p-1.5 text-gray-600 hover:text-[var(--primary)] transition-colors inline-flex"
          title="View details"
        >
          <Icon icon={faEye} size="sm" />
        </Link>
      ),
    },
  ];

  return (
    <div className="space-y-4">
      {/* Page Header */}
      <div className="flex items-center justify-between">
        <div>
          <h1 className="text-2xl font-bold text-gray-900">Inventory</h1>
        </div>
        <button type="button" onClick={() => setCreateModalOpen(true)} className="btn btn-primary">
          <Icon icon={faPlus} size="sm" className="mr-2" />
          Add Item
        </button>
      </div>

      <Modal open={createModalOpen} onClose={() => setCreateModalOpen(false)} title="Add inventory item" maxWidth="max-w-xl">
        <CreateInventoryForm
          onSuccess={() => { setCreateModalOpen(false); loadInventory(); }}
          onCancel={() => setCreateModalOpen(false)}
        />
      </Modal>

      {/* Stats cards */}
      {stats && currentAccount && (
        <div className="grid grid-cols-2 sm:grid-cols-4 gap-4">
          <div className="bg-white border border-gray-200 rounded-sm p-5 shadow-sm flex flex-col gap-3 border-l-4 border-l-gray-400">
            <div className="flex items-center justify-between">
              <span className="text-xs font-semibold text-gray-500 uppercase tracking-wider">Total Items</span>
              <Icon icon={faBox} className="text-gray-400" size="sm" />
            </div>
            <p className="text-3xl font-bold text-gray-900 tabular-nums">{stats.total_items}</p>
          </div>
          <div className="bg-white border border-gray-200 rounded-sm p-5 shadow-sm flex flex-col gap-3 border-l-4 border-l-green-500">
            <div className="flex items-center justify-between">
              <span className="text-xs font-semibold text-gray-500 uppercase tracking-wider">Active</span>
              <Icon icon={faCheckCircle} className="text-green-500" size="sm" />
            </div>
            <p className="text-3xl font-bold text-green-600 tabular-nums">{stats.active_items}</p>
          </div>
          <div className="bg-white border border-gray-200 rounded-sm p-5 shadow-sm flex flex-col gap-3 border-l-4 border-l-amber-500">
            <div className="flex items-center justify-between">
              <span className="text-xs font-semibold text-gray-500 uppercase tracking-wider">Low Stock</span>
              <Icon icon={faTriangleExclamation} className="text-amber-500" size="sm" />
            </div>
            <p className="text-3xl font-bold text-amber-600 tabular-nums">{stats.low_stock_items}</p>
          </div>
          <div className="bg-white border border-gray-200 rounded-sm p-5 shadow-sm flex flex-col gap-3 border-l-4 border-l-red-500">
            <div className="flex items-center justify-between">
              <span className="text-xs font-semibold text-gray-500 uppercase tracking-wider">Out of Stock</span>
              <Icon icon={faCircleXmark} className="text-red-500" size="sm" />
            </div>
            <p className="text-3xl font-bold text-red-600 tabular-nums">{stats.out_of_stock_items}</p>
          </div>
        </div>
      )}

      {/* Filters (admin/users style) */}
      <FilterBar alignItems="center">
        <FilterBarGroup label="Status">
          <select
            value={statusFilter}
            onChange={(e) => setStatusFilter(e.target.value)}
            className="input h-9 min-h-[2.25rem] !py-1.5 !px-3 text-sm w-full text-gray-900"
          >
            {STATUS_OPTIONS.map(option => (
              <option key={option.value} value={option.value}>
                {option.label}
              </option>
            ))}
          </select>
        </FilterBarGroup>
        <FilterBarGroup label="Stock">
          <label className="flex items-center h-9 min-h-[2.25rem] cursor-pointer">
            <input
              type="checkbox"
              checked={lowStockFilter}
              onChange={(e) => setLowStockFilter(e.target.checked)}
              className="mr-2 h-4 w-4 text-[var(--primary)] focus:ring-[var(--primary)] border-gray-300 rounded"
            />
            <span className="text-sm text-gray-700">Low stock only</span>
          </label>
        </FilterBarGroup>
        <FilterBarActions
          onClear={() => {
            setStatusFilter('');
            setLowStockFilter(false);
          }}
        />
        <FilterBarExport<InventoryItem>
          data={inventory}
          exportFilename="inventory"
          exportColumns={[
            { key: 'name', label: 'Name' },
            { key: 'description', label: 'Description', getValue: (r) => r.description ?? '' },
            { key: 'price', label: 'Price', getValue: (r) => String(r.price ?? '') },
            { key: 'stock_quantity', label: 'Stock', getValue: (r) => String(r.stock_quantity ?? '') },
            { key: 'status', label: 'Status' },
          ]}
          disabled={loading}
        />
      </FilterBar>

      {/* Error Message */}
      {error && (
        <div className="bg-red-50 border border-red-200 rounded-sm p-4">
          <p className="text-sm text-red-600">{error}</p>
        </div>
      )}

      {/* Inventory Table */}
      <DataTableWithPagination<InventoryItem>
        data={inventory}
        columns={columns}
        loading={loading}
        emptyMessage={currentAccount ? 'No inventory items for this account' : 'Select an account to view inventory'}
        itemLabel="items"
      />
    </div>
  );
}
