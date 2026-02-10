'use client';

import { useEffect, useState, useCallback, useMemo } from 'react';
import { useSearchParams } from 'next/navigation';
import Link from 'next/link';
import { suppliersApi, Supplier } from '@/lib/api/suppliers';
import { useAuthStore } from '@/store/auth';
import DataTableWithPagination from '@/app/components/DataTableWithPagination';
import FilterBar, { FilterBarGroup, FilterBarSearch, FilterBarActions, FilterBarExport } from '@/app/components/FilterBar';
import type { TableColumn } from '@/app/components/DataTable';
import Modal from '@/app/components/Modal';
import CreateSupplierForm from './CreateSupplierForm';
import Icon, { faPlus, faEdit, faEye, faCheckCircle, faBuilding, faPhone, faEnvelope, faDollarSign } from '@/app/components/Icon';

const STATUS_OPTIONS = [
  { value: '', label: 'All Statuses' },
  { value: 'active', label: 'Active' },
  { value: 'inactive', label: 'Inactive' },
];

export default function SuppliersPage() {
  const searchParams = useSearchParams();
  const { currentAccount } = useAuthStore();
  const [loading, setLoading] = useState(true);
  const [suppliers, setSuppliers] = useState<Supplier[]>([]);
  const [error, setError] = useState('');
  const [createModalOpen, setCreateModalOpen] = useState(false);
  const [search, setSearch] = useState('');
  const [statusFilter, setStatusFilter] = useState('');

  const loadSuppliers = useCallback(async () => {
    try {
      setLoading(true);
      setError('');
      const response = await suppliersApi.getAllSuppliers(currentAccount?.account_id);
      if (response.code === 200) {
        setSuppliers(response.data || []);
      } else {
        setError(response.message || 'Failed to load suppliers');
      }
    } catch (err: unknown) {
      setError((err as { response?: { data?: { message?: string } }; message?: string })?.response?.data?.message || (err as { message?: string })?.message || 'Failed to load suppliers');
    } finally {
      setLoading(false);
    }
  }, [currentAccount?.account_id]);

  useEffect(() => {
    loadSuppliers();
  }, [loadSuppliers]);

  const filteredSuppliers = useMemo(() => {
    let list = suppliers;
    const q = search.trim().toLowerCase();
    if (q) {
      list = list.filter(
        (s) =>
          (s.name && s.name.toLowerCase().includes(q)) ||
          (s.code && s.code.toLowerCase().includes(q)) ||
          (s.phone && s.phone.includes(q)) ||
          (s.email && s.email.toLowerCase().includes(q)) ||
          (s.account?.code && s.account.code.toLowerCase().includes(q)) ||
          (s.account?.name && s.account.name.toLowerCase().includes(q))
      );
    }
    if (statusFilter) {
      list = list.filter((s) => s.relationship_status === statusFilter);
    }
    return list;
  }, [suppliers, search, statusFilter]);

  const clearFilters = () => {
    setSearch('');
    setStatusFilter('');
  };

  const formatCurrency = (amount: number) => {
    return new Intl.NumberFormat('en-RW', {
      style: 'currency',
      currency: 'RWF',
      minimumFractionDigits: 0,
    }).format(amount);
  };

  const columns: TableColumn<Supplier>[] = [
    {
      key: 'name',
      label: 'Name',
      sortable: true,
      render: (value, row) => (
        <div>
          <div className="font-medium text-gray-900">{value}</div>
          <div className="text-xs text-gray-500">{row.account.code}</div>
        </div>
      ),
    },
    {
      key: 'phone',
      label: 'Phone',
      sortable: true,
      render: (value) => (
        <div className="flex items-center text-gray-900">
          <Icon icon={faPhone} size="sm" className="mr-2 text-gray-400" />
          <span>{value}</span>
        </div>
      ),
    },
    {
      key: 'email',
      label: 'Email',
      sortable: true,
      render: (value) => value ? (
        <div className="flex items-center text-gray-900">
          <Icon icon={faEnvelope} size="sm" className="mr-2 text-gray-400" />
          <span>{value}</span>
        </div>
      ) : (
        <span className="text-gray-400">N/A</span>
      ),
    },
    {
      key: 'price_per_liter',
      label: 'Price/Liter',
      sortable: true,
      render: (value) => value ? (
        <div className="flex items-center text-gray-900">
          <Icon icon={faDollarSign} size="sm" className="mr-2 text-gray-400" />
          <span>{formatCurrency(Number(value))}</span>
        </div>
      ) : (
        <span className="text-gray-400">N/A</span>
      ),
    },
    {
      key: 'average_supply_quantity',
      label: 'Avg Quantity',
      sortable: true,
      render: (value) => value ? `${Number(value).toFixed(2)}L` : <span className="text-gray-400">N/A</span>,
    },
    {
      key: 'relationship_status',
      label: 'Status',
      sortable: true,
      render: (value) => (
        <span className={`px-2 py-1 rounded text-xs font-medium ${
          value === 'active' 
            ? 'bg-green-100 text-green-700' 
            : 'bg-gray-100 text-gray-700'
        }`}>
          {String(value).charAt(0).toUpperCase() + String(value).slice(1)}
        </span>
      ),
    },
    {
      key: 'actions',
      label: 'Actions',
      render: (_, row) => (
        <div className="flex items-center gap-2">
          <Link
            href={`/suppliers/${row.account.code}`}
            className="p-1.5 text-gray-600 hover:text-[var(--primary)] transition-colors"
            title="View"
          >
            <Icon icon={faEye} size="sm" />
          </Link>
          <Link
            href={`/suppliers/${row.account.code}/edit`}
            className="p-1.5 text-gray-600 hover:text-[var(--primary)] transition-colors"
            title="Edit"
          >
            <Icon icon={faEdit} size="sm" />
          </Link>
        </div>
      ),
    },
  ];

  return (
    <div className="space-y-4">
      {/* Page Header */}
      <div className="flex items-center justify-between">
        <div>
          <h1 className="text-2xl font-bold text-gray-900">Suppliers</h1>
        </div>
        <button type="button" onClick={() => setCreateModalOpen(true)} className="btn btn-primary">
          <Icon icon={faPlus} size="sm" className="mr-2" />
          Add Supplier
        </button>
      </div>

      <Modal open={createModalOpen} onClose={() => setCreateModalOpen(false)} title="Add Supplier" maxWidth="max-w-lg">
        <CreateSupplierForm
          onSuccess={() => {
            setCreateModalOpen(false);
            loadSuppliers();
          }}
          onCancel={() => setCreateModalOpen(false)}
        />
      </Modal>

      <FilterBar>
        <FilterBarSearch
          value={search}
          onChange={setSearch}
          placeholder="Search by name, code, phone, email..."
        />
        <FilterBarGroup label="Status">
          <select
            value={statusFilter}
            onChange={(e) => setStatusFilter(e.target.value)}
            className="input h-9 min-h-[2.25rem] !py-1.5 !px-3 text-sm w-full text-gray-900"
          >
            {STATUS_OPTIONS.map((o) => (
              <option key={o.value || 'all'} value={o.value}>
                {o.label}
              </option>
            ))}
          </select>
        </FilterBarGroup>
        <FilterBarActions onClear={clearFilters} />
        <FilterBarExport<Supplier>
          data={filteredSuppliers}
          exportFilename="suppliers"
          exportColumns={[
            { key: 'name', label: 'Name' },
            { key: 'code', label: 'Code' },
            { key: 'phone', label: 'Phone' },
            { key: 'email', label: 'Email', getValue: (r) => r.email ?? '' },
            { key: 'price_per_liter', label: 'Price/Liter', getValue: (r) => r.price_per_liter != null ? String(r.price_per_liter) : '' },
            { key: 'relationship_status', label: 'Status' },
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

      {/* Suppliers Table */}
      <DataTableWithPagination<Supplier>
        data={filteredSuppliers}
        columns={columns}
        loading={loading}
        emptyMessage={currentAccount ? (filteredSuppliers.length === 0 && suppliers.length > 0 ? 'No suppliers match the filters' : 'No suppliers for this account') : 'Select an account to view suppliers'}
        itemLabel="suppliers"
      />
    </div>
  );
}
