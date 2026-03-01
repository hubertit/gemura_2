'use client';

import { useEffect, useState, useCallback } from 'react';
import { useAuthStore } from '@/store/auth';
import { milkProductionApi, MilkProductionRecord } from '@/lib/api/milk-production';
import { ListPageSkeleton } from '@/app/components/SkeletonLoader';
import FilterBar, { FilterBarGroup, FilterBarActions } from '@/app/components/FilterBar';
import Icon, { faBox, faChartLine } from '@/app/components/Icon';
import DatePicker from '@/app/components/DatePicker';
import Link from 'next/link';

export default function MilkProductionPage() {
  const { currentAccount } = useAuthStore();
  const accountId = currentAccount?.account_id;
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState('');
  const [records, setRecords] = useState<MilkProductionRecord[]>([]);
  const [report, setReport] = useState<{ total_production_litres: number; total_sold_litres: number } | null>(null);
  const [dateFrom, setDateFrom] = useState('');
  const [dateTo, setDateTo] = useState('');

  const load = useCallback(async () => {
    if (!accountId) return;
    try {
      setLoading(true);
      setError('');
      const [listRes, reportRes] = await Promise.all([
        milkProductionApi.list(accountId, dateFrom || dateTo ? { from: dateFrom || undefined, to: dateTo || undefined } : undefined),
        milkProductionApi.report(accountId, dateFrom || undefined, dateTo || undefined),
      ]);
      if (listRes.code === 200 && listRes.data) setRecords(listRes.data);
      if (reportRes.code === 200 && reportRes.data) setReport(reportRes.data);
    } catch (err: unknown) {
      const e = err as { response?: { data?: { message?: string } }; message?: string };
      setError(e?.response?.data?.message || e?.message || 'Failed to load production');
      setRecords([]);
      setReport(null);
    } finally {
      setLoading(false);
    }
  }, [accountId, dateFrom, dateTo]);

  useEffect(() => {
    load();
  }, [load]);

  const clearFilters = () => {
    setDateFrom('');
    setDateTo('');
  };

  if (!accountId) {
    return (
      <div className="p-4">
        <p className="text-sm text-gray-500">Select an account to view milk production.</p>
      </div>
    );
  }

  return (
    <div className="space-y-4">
      <div className="flex items-center justify-between">
        <h1 className="text-2xl font-bold text-gray-900">Milk production</h1>
      </div>

      {error && (
        <div className="bg-red-50 border border-red-200 rounded-sm p-4">
          <p className="text-sm text-red-600">{error}</p>
        </div>
      )}

      {report != null && (
        <div className="grid grid-cols-1 sm:grid-cols-2 gap-4">
          <div className="bg-white border border-gray-200 rounded-lg p-4 flex items-center gap-4">
            <div className="w-12 h-12 rounded-lg bg-[var(--primary)]/10 flex items-center justify-center">
              <Icon icon={faBox} className="text-[var(--primary)]" size="lg" />
            </div>
            <div>
              <p className="text-sm font-medium text-gray-500">Total produced (L)</p>
              <p className="text-2xl font-bold text-gray-900">{Number(report.total_production_litres).toLocaleString(undefined, { minimumFractionDigits: 1, maximumFractionDigits: 1 })}</p>
              {(dateFrom || dateTo) && <p className="text-xs text-gray-400">In selected period</p>}
            </div>
          </div>
          <div className="bg-white border border-gray-200 rounded-lg p-4 flex items-center gap-4">
            <div className="w-12 h-12 rounded-lg bg-emerald-100 flex items-center justify-center">
              <Icon icon={faChartLine} className="text-emerald-600" size="lg" />
            </div>
            <div>
              <p className="text-sm font-medium text-gray-500">Total sold (L)</p>
              <p className="text-2xl font-bold text-gray-900">{Number(report.total_sold_litres).toLocaleString(undefined, { minimumFractionDigits: 1, maximumFractionDigits: 1 })}</p>
              {(dateFrom || dateTo) && <p className="text-xs text-gray-400">In selected period</p>}
            </div>
          </div>
        </div>
      )}

      <FilterBar>
        <FilterBarGroup label="From date">
          <DatePicker value={dateFrom} onChange={setDateFrom} max={new Date().toISOString().slice(0, 10)} placeholder="From" className="w-full" />
        </FilterBarGroup>
        <FilterBarGroup label="To date">
          <DatePicker value={dateTo} onChange={setDateTo} max={new Date().toISOString().slice(0, 10)} placeholder="To" className="w-full" />
        </FilterBarGroup>
        <FilterBarActions onClear={clearFilters} />
      </FilterBar>

      {loading ? (
        <ListPageSkeleton />
      ) : (
        <div className="bg-white border border-gray-200 rounded-sm overflow-hidden">
          <div className="px-4 py-3 border-b border-gray-200">
            <h2 className="text-lg font-semibold text-gray-900">Production records</h2>
            <p className="text-sm text-gray-500">Record production on each animal&apos;s detail page.</p>
          </div>
          {records.length === 0 ? (
            <div className="p-8 text-center text-gray-500">
              <Icon icon={faBox} size="2x" className="mx-auto mb-2 text-gray-300" />
              <p>No production records in this period.</p>
              <Link href="/animals" className="text-[var(--primary)] hover:underline text-sm mt-2 inline-block">
                Go to Animals to record production per animal
              </Link>
            </div>
          ) : (
            <div className="overflow-x-auto">
              <table className="w-full text-sm">
                <thead>
                  <tr className="border-b border-gray-200 bg-gray-50 text-left text-gray-600">
                    <th className="py-3 px-4 font-medium">Date</th>
                    <th className="py-3 px-4 font-medium">Quantity (L)</th>
                    <th className="py-3 px-4 font-medium">Animal</th>
                    <th className="py-3 px-4 font-medium">Farm</th>
                    <th className="py-3 px-4 font-medium">Notes</th>
                  </tr>
                </thead>
                <tbody>
                  {records.map((r) => (
                    <tr key={r.id} className="border-b border-gray-100 hover:bg-gray-50/50">
                      <td className="py-3 px-4 text-gray-900">{new Date(r.production_date).toLocaleDateString()}</td>
                      <td className="py-3 px-4 font-medium">{Number(r.quantity_litres)}</td>
                      <td className="py-3 px-4">
                        {r.animal ? (
                          <Link href={`/animals/${r.animal.id}`} className="text-[var(--primary)] hover:underline">
                            {r.animal.tag_number} {r.animal.name ? `(${r.animal.name})` : ''}
                          </Link>
                        ) : (
                          <span className="text-gray-400">—</span>
                        )}
                      </td>
                      <td className="py-3 px-4 text-gray-600">{r.farm?.name ?? '—'}</td>
                      <td className="py-3 px-4 text-gray-600">{r.notes || '—'}</td>
                    </tr>
                  ))}
                </tbody>
              </table>
            </div>
          )}
        </div>
      )}
    </div>
  );
}
