'use client';

import { useEffect, useState, useCallback } from 'react';
import { useRouter, useSearchParams } from 'next/navigation';
import Link from 'next/link';
import { usePermission } from '@/hooks/usePermission';
import { suppliersApi, Supplier } from '@/lib/api/suppliers';
import DataTable, { TableColumn } from '@/app/components/DataTable';
import Icon, { faPlus, faEdit, faEye, faCheckCircle, faBuilding, faPhone, faEnvelope, faDollarSign } from '@/app/components/Icon';

export default function SuppliersPage() {
  const router = useRouter();
  const searchParams = useSearchParams();
  const { hasPermission, isAdmin } = usePermission();
  const [loading, setLoading] = useState(true);
  const [suppliers, setSuppliers] = useState<Supplier[]>([]);
  const [error, setError] = useState('');

  const loadSuppliers = useCallback(async () => {
    try {
      setLoading(true);
      setError('');
      const response = await suppliersApi.getAllSuppliers();
      if (response.code === 200) {
        setSuppliers(response.data || []);
      } else {
        setError(response.message || 'Failed to load suppliers');
      }
    } catch (err: any) {
      setError(err?.response?.data?.message || err?.message || 'Failed to load suppliers');
    } finally {
      setLoading(false);
    }
  }, []);

  useEffect(() => {
    // Check permission
    if (!hasPermission('view_suppliers') && !isAdmin()) {
      router.push('/dashboard');
      return;
    }
    loadSuppliers();
  }, [hasPermission, isAdmin, router, loadSuppliers]);

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
          <p className="text-sm text-gray-600 mt-1">Manage your milk suppliers</p>
        </div>
        <Link href="/suppliers/new" className="btn btn-primary">
          <Icon icon={faPlus} size="sm" className="mr-2" />
          Add Supplier
        </Link>
      </div>


      {/* Error Message */}
      {error && (
        <div className="bg-red-50 border border-red-200 rounded-sm p-4">
          <p className="text-sm text-red-600">{error}</p>
        </div>
      )}

      {/* Suppliers Table */}
      <DataTable
        data={suppliers}
        columns={columns}
        loading={loading}
        emptyMessage="No suppliers found"
      />

      {/* Summary */}
      {suppliers.length > 0 && (
        <div className="bg-white border border-gray-200 rounded-sm p-4">
          <div className="grid grid-cols-1 md:grid-cols-3 gap-4">
            <div>
              <p className="text-sm text-gray-600">Total Suppliers</p>
              <p className="text-lg font-semibold text-gray-900">{suppliers.length}</p>
            </div>
            <div>
              <p className="text-sm text-gray-600">Active Suppliers</p>
              <p className="text-lg font-semibold text-gray-900">
                {suppliers.filter(s => s.relationship_status === 'active').length}
              </p>
            </div>
            <div>
              <p className="text-sm text-gray-600">Average Price/Liter</p>
              <p className="text-lg font-semibold text-gray-900">
                {suppliers.filter(s => s.price_per_liter).length > 0
                  ? formatCurrency(
                      suppliers
                        .filter(s => s.price_per_liter)
                        .reduce((sum, s) => sum + (s.price_per_liter || 0), 0) /
                      suppliers.filter(s => s.price_per_liter).length
                    )
                  : 'N/A'}
              </p>
            </div>
          </div>
        </div>
      )}
    </div>
  );
}
