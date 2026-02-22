'use client';

import { useState, useEffect, useCallback, useMemo } from 'react';
import Link from 'next/link';
import { accountingApi, AccountingTransaction } from '@/lib/api/accounting';
import DataTableWithPagination from '@/app/components/DataTableWithPagination';
import type { TableColumn } from '@/app/components/DataTable';
import FilterBar, { FilterBarGroup, FilterBarActions, FilterBarApply, FilterBarExport } from '@/app/components/FilterBar';
import Icon, { faArrowLeft, faArrowsRotate, faSpinner, faTriangleExclamation } from '@/app/components/Icon';

function formatDate(str: string): string {
  try {
    return new Date(str).toLocaleDateString('en-US', { month: 'short', day: 'numeric', year: 'numeric' });
  } catch {
    return str;
  }
}

function formatAmount(amount: number): string {
  return new Intl.NumberFormat('en-RW', { style: 'currency', currency: 'RWF', minimumFractionDigits: 0 }).format(amount);
}

export default function FinanceTransactionsPage() {
  const [typeFilter, setTypeFilter] = useState<'revenue' | 'expense' | ''>('');
  const [dateFrom, setDateFrom] = useState('');
  const [dateTo, setDateTo] = useState('');
  const [amountMin, setAmountMin] = useState('');
  const [amountMax, setAmountMax] = useState('');
  const [transactions, setTransactions] = useState<AccountingTransaction[]>([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);

  const load = useCallback(async () => {
    setLoading(true);
    setError(null);
    try {
      const list = await accountingApi.getTransactions({
        type: typeFilter || undefined,
        date_from: dateFrom || undefined,
        date_to: dateTo || undefined,
        limit: undefined,
      });
      setTransactions(list);
    } catch (e: unknown) {
      const msg =
        (e as { response?: { data?: { message?: string } }; message?: string })?.response?.data?.message ??
        (e as Error)?.message ??
        'Failed to load transactions';
      setError(msg);
      setTransactions([]);
    } finally {
      setLoading(false);
    }
  }, [typeFilter, dateFrom, dateTo]);

  useEffect(() => {
    load();
  }, [load]);

  const handleApplyFilters = () => {
    load();
  };

  const handleClearFilters = () => {
    setTypeFilter('');
    setDateFrom('');
    setDateTo('');
    setAmountMin('');
    setAmountMax('');
  };

  // Client-side amount range filter (API doesn't support it)
  const filteredData = useMemo(() => {
    const min = amountMin ? Number(amountMin) : -Infinity;
    const max = amountMax ? Number(amountMax) : Infinity;
    if (!amountMin && !amountMax) return transactions;
    return transactions.filter((t) => {
      const n = Number(t.amount);
      return !Number.isNaN(n) && n >= min && n <= max;
    });
  }, [transactions, amountMin, amountMax]);

  const columns: TableColumn<AccountingTransaction>[] = [
    {
      key: 'transaction_date',
      label: 'Date',
      sortable: true,
      render: (value) => formatDate(String(value)),
    },
    {
      key: 'type',
      label: 'Type',
      sortable: true,
      render: (value, row) => {
        const isRevenue = row.type === 'revenue';
        return (
          <span
            className={`inline-block rounded px-2 py-0.5 text-xs font-medium ${
              isRevenue ? 'bg-emerald-100 text-emerald-700' : 'bg-red-100 text-red-700'
            }`}
          >
            {isRevenue ? 'Revenue' : 'Expense'}
          </span>
        );
      },
    },
    {
      key: 'description',
      label: 'Description',
      sortable: true,
      render: (value) => <span className="font-medium text-gray-900">{String(value || '-')}</span>,
    },
    {
      key: 'amount',
      label: 'Amount',
      sortable: true,
      className: 'text-right',
      render: (value, row) => {
        const isRevenue = row.type === 'revenue';
        return (
          <span className={`font-semibold ${isRevenue ? 'text-emerald-600' : 'text-red-600'}`}>
            {formatAmount(Number(value))}
          </span>
        );
      },
    },
    {
      key: 'category_account',
      label: 'Category',
      sortable: false,
      render: (value) => <span className="text-gray-500">{String(value || '-')}</span>,
    },
  ];

  return (
    <div className="space-y-4">
      <div className="flex flex-wrap items-center justify-between gap-4">
        <div>
          <Link href="/finance" className="text-sm text-gray-600 hover:text-[var(--primary)] mb-2 inline-flex items-center">
            <Icon icon={faArrowLeft} size="sm" className="mr-2" />
            Back to Finance
          </Link>
          <h1 className="text-2xl font-bold text-gray-900">All Transactions</h1>
        </div>
        <button type="button" onClick={() => load()} className="btn btn-secondary" disabled={loading}>
          <Icon icon={loading ? faSpinner : faArrowsRotate} size="sm" className={`mr-2 ${loading ? 'animate-spin' : ''}`} />
          Refresh
        </button>
      </div>

      <FilterBar>
        <FilterBarGroup label="Type">
          <select
            value={typeFilter}
            onChange={(e) => setTypeFilter((e.target.value || '') as 'revenue' | 'expense' | '')}
            className="input h-9 min-h-[2.25rem] !py-1.5 !px-3 text-sm w-full text-gray-900"
          >
            <option value="">All</option>
            <option value="revenue">Revenue</option>
            <option value="expense">Expense</option>
          </select>
        </FilterBarGroup>
        <FilterBarGroup label="Date From">
          <input
            type="date"
            value={dateFrom}
            onChange={(e) => setDateFrom(e.target.value)}
            className="input h-9 min-h-[2.25rem] !py-1.5 !px-3 text-sm w-full text-gray-900"
          />
        </FilterBarGroup>
        <FilterBarGroup label="Date To">
          <input
            type="date"
            value={dateTo}
            onChange={(e) => setDateTo(e.target.value)}
            className="input h-9 min-h-[2.25rem] !py-1.5 !px-3 text-sm w-full text-gray-900"
          />
        </FilterBarGroup>
        <FilterBarGroup label="Amount Min (RWF)">
          <input
            type="number"
            min={0}
            value={amountMin}
            onChange={(e) => setAmountMin(e.target.value)}
            placeholder="Min"
            className="input h-9 min-h-[2.25rem] !py-1.5 !px-3 text-sm w-full text-gray-900"
          />
        </FilterBarGroup>
        <FilterBarGroup label="Amount Max (RWF)">
          <input
            type="number"
            min={0}
            value={amountMax}
            onChange={(e) => setAmountMax(e.target.value)}
            placeholder="Max"
            className="input h-9 min-h-[2.25rem] !py-1.5 !px-3 text-sm w-full text-gray-900"
          />
        </FilterBarGroup>
        <FilterBarActions onClear={handleClearFilters} />
        <FilterBarApply onApply={handleApplyFilters} />
        <FilterBarExport<AccountingTransaction>
          data={filteredData}
          exportFilename="finance-transactions"
          exportColumns={[
            { key: 'transaction_date', label: 'Date', getValue: (r) => formatDate(r.transaction_date) },
            { key: 'type', label: 'Type', getValue: (r) => r.type },
            { key: 'description', label: 'Description', getValue: (r) => r.description ?? '' },
            { key: 'amount', label: 'Amount', getValue: (r) => String(r.amount) },
            { key: 'category_account', label: 'Category', getValue: (r) => r.category_account ?? '' },
          ]}
          disabled={loading}
        />
      </FilterBar>

      {error && (
        <div className="flex items-center gap-2 rounded border border-red-200 bg-red-50 p-3 text-red-800">
          <Icon icon={faTriangleExclamation} size="sm" />
          <span>{error}</span>
          <button type="button" onClick={() => load()} className="ml-2 text-sm underline">
            Retry
          </button>
        </div>
      )}

      <DataTableWithPagination<AccountingTransaction>
        data={filteredData}
        columns={columns}
        loading={loading}
        emptyMessage={
          transactions.length === 0
            ? 'No transactions. Use filters and Apply, or record a transaction from Finance.'
            : 'No transactions match the amount range. Adjust filters.'
        }
        itemLabel="transactions"
      />
    </div>
  );
}
