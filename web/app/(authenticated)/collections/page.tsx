'use client';

import { useEffect, useState, useCallback } from 'react';
import { useRouter, useSearchParams } from 'next/navigation';
import Link from 'next/link';
import { usePermission } from '@/hooks/usePermission';
import { collectionsApi, Collection, CollectionsFilters } from '@/lib/api/collections';
import { useToastStore } from '@/store/toast';
import DataTable, { TableColumn } from '@/app/components/DataTable';
import Filters, { FilterGroup, FilterLabel } from '@/app/components/Filters';
import Icon, { faPlus, faEdit, faTrash, faEye, faCheckCircle, faFilter, faTimes } from '@/app/components/Icon';

const STATUS_OPTIONS = [
  { value: '', label: 'All Statuses' },
  { value: 'pending', label: 'Pending' },
  { value: 'accepted', label: 'Accepted' },
  { value: 'rejected', label: 'Rejected' },
  { value: 'cancelled', label: 'Cancelled' },
];

export default function CollectionsPage() {
  const router = useRouter();
  const searchParams = useSearchParams();
  const { hasPermission, isAdmin } = usePermission();
  const [loading, setLoading] = useState(true);
  const [collections, setCollections] = useState<Collection[]>([]);
  const [error, setError] = useState('');
  const [filters, setFilters] = useState<CollectionsFilters>({
    status: searchParams.get('status') || undefined,
    date_from: searchParams.get('date_from') || undefined,
    date_to: searchParams.get('date_to') || undefined,
    supplier_account_code: searchParams.get('supplier') || undefined,
  });

  const loadCollections = useCallback(async () => {
    try {
      setLoading(true);
      setError('');
      const response = await collectionsApi.getCollections(filters);
      if (response.code === 200) {
        setCollections(response.data || []);
      } else {
        setError(response.message || 'Failed to load collections');
      }
    } catch (err: any) {
      setError(err?.response?.data?.message || err?.message || 'Failed to load collections');
    } finally {
      setLoading(false);
    }
  }, [filters]);

  useEffect(() => {
    // Check permission
    if (!hasPermission('view_collections') && !isAdmin()) {
      router.push('/dashboard');
      return;
    }
    loadCollections();
  }, [hasPermission, isAdmin, router, loadCollections]);

  const handleFilterChange = (key: keyof CollectionsFilters, value: string | number | undefined) => {
    setFilters(prev => ({
      ...prev,
      [key]: value || undefined,
    }));
  };

  const handleApplyFilters = () => {
    loadCollections();
  };

  const handleClearFilters = () => {
    setFilters({});
    loadCollections();
  };

  const getActiveFilterCount = () => {
    let count = 0;
    if (filters.status) count++;
    if (filters.date_from) count++;
    if (filters.date_to) count++;
    if (filters.supplier_account_code) count++;
    return count;
  };

  const handleCancelCollection = async (collectionId: string) => {
    if (!confirm('Are you sure you want to cancel this collection?')) {
      return;
    }

    try {
      await collectionsApi.cancelCollection(collectionId);
      loadCollections();
    } catch (err: any) {
      useToastStore.getState().error(err?.response?.data?.message || 'Failed to cancel collection');
    }
  };

  const formatCurrency = (amount: number) => {
    return new Intl.NumberFormat('en-RW', {
      style: 'currency',
      currency: 'RWF',
      minimumFractionDigits: 0,
    }).format(amount);
  };

  const columns: TableColumn<Collection>[] = [
    {
      key: 'collection_at',
      label: 'Date',
      sortable: true,
      render: (value) => new Date(value).toLocaleDateString(),
    },
    {
      key: 'supplier_account',
      label: 'Supplier',
      sortable: false,
      render: (_, row) => (
        <div>
          <div className="font-medium text-gray-900">{row.supplier_account.name}</div>
          <div className="text-xs text-gray-500">{row.supplier_account.code}</div>
        </div>
      ),
    },
    {
      key: 'quantity',
      label: 'Quantity (L)',
      sortable: true,
      render: (value) => `${Number(value).toFixed(2)}L`,
    },
    {
      key: 'unit_price',
      label: 'Unit Price',
      sortable: true,
      render: (value) => formatCurrency(Number(value)),
    },
    {
      key: 'total_amount',
      label: 'Total',
      sortable: true,
      render: (value) => (
        <span className="font-semibold text-gray-900">{formatCurrency(Number(value))}</span>
      ),
    },
    {
      key: 'status',
      label: 'Status',
      sortable: true,
      render: (value) => {
        const statusColors: Record<string, string> = {
          pending: 'bg-yellow-100 text-yellow-700',
          accepted: 'bg-green-100 text-green-700',
          rejected: 'bg-red-100 text-red-700',
          cancelled: 'bg-gray-100 text-gray-700',
          deleted: 'bg-red-100 text-red-700',
        };
        return (
          <span className={`px-2 py-1 rounded text-xs font-medium ${statusColors[value as string] || 'bg-gray-100 text-gray-700'}`}>
            {String(value).charAt(0).toUpperCase() + String(value).slice(1)}
          </span>
        );
      },
    },
    {
      key: 'actions',
      label: 'Actions',
      render: (_, row) => (
        <div className="flex items-center gap-2">
          <Link
            href={`/collections/${row.id}`}
            className="p-1.5 text-gray-600 hover:text-[var(--primary)] transition-colors"
            title="View"
          >
            <Icon icon={faEye} size="sm" />
          </Link>
          {row.status !== 'cancelled' && row.status !== 'deleted' && (
            <>
              <Link
                href={`/collections/${row.id}/edit`}
                className="p-1.5 text-gray-600 hover:text-[var(--primary)] transition-colors"
                title="Edit"
              >
                <Icon icon={faEdit} size="sm" />
              </Link>
              <button
                onClick={() => handleCancelCollection(row.id)}
                className="p-1.5 text-gray-600 hover:text-red-600 transition-colors"
                title="Cancel"
              >
                <Icon icon={faTrash} size="sm" />
              </button>
            </>
          )}
        </div>
      ),
    },
  ];

  return (
    <div className="space-y-4">
      {/* Page Header */}
      <div className="flex items-center justify-between">
        <div>
          <h1 className="text-2xl font-bold text-gray-900">Collections</h1>
        </div>
        <Link href="/collections/new" className="btn btn-primary">
          <Icon icon={faPlus} size="sm" className="mr-2" />
          New Collection
        </Link>
      </div>

      {/* Filters */}
      <Filters
        activeFilterCount={getActiveFilterCount()}
        onApply={handleApplyFilters}
        onClear={handleClearFilters}
      >
        <FilterGroup>
          <FilterLabel>Status</FilterLabel>
          <select
            value={filters.status || ''}
            onChange={(e) => handleFilterChange('status', e.target.value)}
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
          <FilterLabel>Date From</FilterLabel>
          <input
            type="date"
            value={filters.date_from || ''}
            onChange={(e) => handleFilterChange('date_from', e.target.value)}
            className="px-2.5 py-[0.4375rem] border border-gray-300 rounded text-[0.8125rem] text-gray-700 bg-white h-9 w-full focus:outline-none focus:border-[var(--primary)] focus:ring-1 focus:ring-[var(--primary)]"
          />
        </FilterGroup>
        <FilterGroup>
          <FilterLabel>Date To</FilterLabel>
          <input
            type="date"
            value={filters.date_to || ''}
            onChange={(e) => handleFilterChange('date_to', e.target.value)}
            className="px-2.5 py-[0.4375rem] border border-gray-300 rounded text-[0.8125rem] text-gray-700 bg-white h-9 w-full focus:outline-none focus:border-[var(--primary)] focus:ring-1 focus:ring-[var(--primary)]"
          />
        </FilterGroup>
        <FilterGroup>
          <FilterLabel>Supplier Code</FilterLabel>
          <input
            type="text"
            value={filters.supplier_account_code || ''}
            onChange={(e) => handleFilterChange('supplier_account_code', e.target.value)}
            className="px-2.5 py-[0.4375rem] border border-gray-300 rounded text-[0.8125rem] text-gray-700 bg-white h-9 w-full focus:outline-none focus:border-[var(--primary)] focus:ring-1 focus:ring-[var(--primary)]"
            placeholder="A_ABC123"
          />
        </FilterGroup>
      </Filters>

      {/* Error Message */}
      {error && (
        <div className="bg-red-50 border border-red-200 rounded-sm p-4">
          <p className="text-sm text-red-600">{error}</p>
        </div>
      )}

      {/* Collections Table */}
      <DataTable
        data={collections}
        columns={columns}
        loading={loading}
        emptyMessage="No collections found"
      />

      {/* Summary */}
      {collections.length > 0 && (
        <div className="bg-white border border-gray-200 rounded-sm p-4">
          <div className="grid grid-cols-1 md:grid-cols-3 gap-4">
            <div>
              <p className="text-sm text-gray-600">Total Collections</p>
              <p className="text-lg font-semibold text-gray-900">{collections.length}</p>
            </div>
            <div>
              <p className="text-sm text-gray-600">Total Quantity</p>
              <p className="text-lg font-semibold text-gray-900">
                {collections.reduce((sum, collection) => sum + Number(collection.quantity), 0).toFixed(2)}L
              </p>
            </div>
            <div>
              <p className="text-sm text-gray-600">Total Amount</p>
              <p className="text-lg font-semibold text-gray-900">
                {formatCurrency(collections.reduce((sum, collection) => sum + Number(collection.total_amount), 0))}
              </p>
            </div>
          </div>
        </div>
      )}
    </div>
  );
}
