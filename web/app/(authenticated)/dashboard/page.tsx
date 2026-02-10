'use client';

import { useEffect, useState, useMemo } from 'react';
import { useRouter } from 'next/navigation';
import Link from 'next/link';
import { useAuthStore } from '@/store/auth';
import { isAdminAccount } from '@/lib/config/nav.config';
import { statsApi, OverviewResponse } from '@/lib/api/stats';
import Icon, {
  faBuilding,
  faStore,
  faBox,
  faReceipt,
  faPlus,
  faArrowRight,
} from '@/app/components/Icon';
import StatCard from '@/app/components/StatCard';
import dynamic from 'next/dynamic';

const Chart = dynamic(() => import('react-apexcharts'), { ssr: false });

const BLUE_ICON = { iconBgColor: '#eff6ff', iconColor: 'var(--primary)' };
const GREEN_ICON = { iconBgColor: '#dcfce7', iconColor: '#059669' };
const PURPLE_ICON = { iconBgColor: '#f3e8ff', iconColor: '#7c3aed' };

type PeriodKey = 'day' | 'month' | 'quarter' | 'year' | 'custom';

function toYYYYMMDD(d: Date): string {
  const y = d.getFullYear();
  const m = String(d.getMonth() + 1).padStart(2, '0');
  const day = String(d.getDate()).padStart(2, '0');
  return `${y}-${m}-${day}`;
}

function getPeriodRange(period: PeriodKey, customFrom?: string, customTo?: string): { date_from: string; date_to: string } {
  const now = new Date();
  if (period === 'custom' && customFrom && customTo) {
    return { date_from: customFrom, date_to: customTo };
  }
  let start: Date;
  let end: Date;
  switch (period) {
    case 'day':
      start = new Date(now.getFullYear(), now.getMonth(), now.getDate());
      end = new Date(now.getFullYear(), now.getMonth(), now.getDate());
      break;
    case 'month':
      start = new Date(now.getFullYear(), now.getMonth(), 1);
      end = new Date(now.getFullYear(), now.getMonth() + 1, 0);
      break;
    case 'quarter': {
      const q = Math.ceil((now.getMonth() + 1) / 3);
      start = new Date(now.getFullYear(), (q - 1) * 3, 1);
      end = new Date(now.getFullYear(), q * 3, 0);
      break;
    }
    case 'year':
      start = new Date(now.getFullYear(), 0, 1);
      end = new Date(now.getFullYear(), 11, 31);
      break;
    default:
      start = new Date(now.getFullYear(), now.getMonth(), 1);
      end = new Date();
  }
  return { date_from: toYYYYMMDD(start), date_to: toYYYYMMDD(end) };
}

export default function Dashboard() {
  const router = useRouter();
  const { currentAccount } = useAuthStore();
  const accountType = currentAccount?.account_type ?? '';
  const [loading, setLoading] = useState(true);
  const [overview, setOverview] = useState<OverviewResponse['data'] | null>(null);
  const [error, setError] = useState('');
  const [chartTab, setChartTab] = useState<'value' | 'volume'>('value');
  const [period, setPeriod] = useState<PeriodKey>('quarter');
  const [customFrom, setCustomFrom] = useState('');
  const [customTo, setCustomTo] = useState('');

  const dateRange = useMemo(
    () => getPeriodRange(period, customFrom || undefined, customTo || undefined),
    [period, customFrom, customTo],
  );

  // Redraw chart when tab becomes visible (charts in hidden container may render at 0 size)
  useEffect(() => {
    const t = setTimeout(() => window.dispatchEvent(new Event('resize')), 50);
    return () => clearTimeout(t);
  }, [chartTab]);

  useEffect(() => {
    if (isAdminAccount(accountType)) {
      router.replace('/admin/dashboard');
      return;
    }
    let cancelled = false;
    setLoading(true);
    setError('');
    statsApi
      .getOverview(currentAccount?.account_id, {
        date_from: dateRange.date_from,
        date_to: dateRange.date_to,
      })
      .then((res) => {
        if (cancelled) return;
        if (res.code === 200 && res.data) setOverview(res.data);
        else setError('Failed to load dashboard');
      })
      .catch((err: unknown) => {
        if (!cancelled) {
          const msg =
            (err as { response?: { data?: { message?: string } }; message?: string })?.response?.data?.message ||
            (err as { message?: string })?.message ||
            'Failed to load dashboard';
          setError(msg);
        }
      })
      .finally(() => {
        if (!cancelled) setLoading(false);
      });
    return () => {
      cancelled = true;
    };
  }, [accountType, currentAccount?.account_id, router, dateRange.date_from, dateRange.date_to]);

  const formatCurrency = (amount: number) => {
    return `RF ${new Intl.NumberFormat('en-RW', { minimumFractionDigits: 0, maximumFractionDigits: 0 }).format(amount)}`;
  };

  if (loading) {
    return (
      <div className="flex items-center justify-center py-12">
        <div className="text-center">
          <div className="w-8 h-8 border-4 border-[var(--primary)] border-t-transparent rounded-full animate-spin mx-auto mb-4" />
          <p className="text-sm text-gray-600">Loading dashboard...</p>
        </div>
      </div>
    );
  }

  if (error) {
    return (
      <div className="space-y-4">
        <h1 className="text-2xl font-bold text-gray-900">Dashboard</h1>
        <div className="bg-red-50 border border-red-200 rounded-sm p-4">
          <p className="text-sm text-red-600">{error}</p>
        </div>
      </div>
    );
  }

  if (!overview) return null;

  const { summary, breakdown, recent_transactions } = overview;
  const hasBreakdown = breakdown.length > 0;
  const lastN = 14;
  const breakdownSlice = breakdown.slice(-lastN);

  const periodLabel =
    period === 'custom'
      ? customFrom && customTo
        ? `${customFrom} – ${customTo}`
        : 'Custom range'
      : `${dateRange.date_from} – ${dateRange.date_to}`;

  return (
    <div className="-mt-1 space-y-4">
      <div className="flex items-center justify-between gap-2 py-0.5">
        <h1 className="text-2xl font-bold text-gray-900 leading-tight">Dashboard</h1>
        <div className="relative flex-shrink-0">
          <select
            value={period}
            onChange={(e) => {
              const v = e.target.value as PeriodKey;
              setPeriod(v);
              if (v === 'custom' && !customFrom && !customTo) {
                const n = new Date();
                setCustomFrom(toYYYYMMDD(new Date(n.getFullYear(), n.getMonth(), 1)));
                setCustomTo(toYYYYMMDD(n));
              }
            }}
            title={periodLabel}
            className="min-w-0 w-[120px] border border-gray-300 rounded py-0.5 pl-1.5 pr-6 text-xs text-gray-900 bg-white focus:ring-1 focus:ring-[var(--primary)] focus:border-[var(--primary)]"
          >
            <option value="day">Day</option>
            <option value="month">Month</option>
            <option value="quarter">Quarter</option>
            <option value="year">Year</option>
            <option value="custom">Custom</option>
          </select>
          {period === 'custom' && (
            <div className="absolute top-full right-0 z-10 mt-0.5 py-1.5 px-1.5 bg-white border border-gray-200 rounded shadow-lg flex items-center gap-1.5">
              <input
                type="date"
                value={customFrom}
                onChange={(e) => setCustomFrom(e.target.value)}
                className="border border-gray-300 rounded px-1.5 py-0.5 text-xs w-28"
              />
              <span className="text-gray-400 text-[10px]">–</span>
              <input
                type="date"
                value={customTo}
                onChange={(e) => setCustomTo(e.target.value)}
                className="border border-gray-300 rounded px-1.5 py-0.5 text-xs w-28"
              />
            </div>
          )}
        </div>
      </div>

      {/* Summary cards - same data as mobile */}
      <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-4 gap-4">
        <StatCard
          label="Total Sales"
          value={formatCurrency(summary.sales.value)}
          subtitle={`${summary.sales.transactions} transactions · ${summary.sales.liters.toFixed(1)} L`}
          icon={faReceipt}
          href="/sales"
          {...GREEN_ICON}
        />
        <StatCard
          label="Total Collections"
          value={formatCurrency(summary.collection.value)}
          subtitle={`${summary.collection.transactions} transactions · ${summary.collection.liters.toFixed(1)} L`}
          icon={faBox}
          href="/collections"
          {...BLUE_ICON}
        />
        <StatCard
          label="Suppliers"
          value={summary.suppliers.active + summary.suppliers.inactive}
          subtitle={`${summary.suppliers.active} active, ${summary.suppliers.inactive} inactive`}
          icon={faBuilding}
          href="/suppliers"
          {...BLUE_ICON}
        />
        <StatCard
          label="Customers"
          value={summary.customers.active + summary.customers.inactive}
          subtitle={`${summary.customers.active} active, ${summary.customers.inactive} inactive`}
          icon={faStore}
          href="/customers"
          {...PURPLE_ICON}
        />
      </div>

      {/* Charts row: tabbed Value/Volume + donut */}
      <div className="grid grid-cols-1 lg:grid-cols-3 gap-4">
        <div className="lg:col-span-2 bg-white border border-gray-200 rounded-sm p-6">
          <div className="flex items-center justify-between gap-4 mb-4">
            <h3 className="text-base font-semibold text-gray-900">Sales vs Collections</h3>
            <div className="flex rounded-lg border border-gray-200 p-0.5 bg-gray-50">
              <button
                type="button"
                onClick={() => setChartTab('value')}
                className={`px-3 py-1.5 text-sm font-medium rounded-md transition-colors ${
                  chartTab === 'value'
                    ? 'bg-white text-gray-900 shadow-sm'
                    : 'text-gray-600 hover:text-gray-900'
                }`}
              >
                Value
              </button>
              <button
                type="button"
                onClick={() => setChartTab('volume')}
                className={`px-3 py-1.5 text-sm font-medium rounded-md transition-colors ${
                  chartTab === 'volume'
                    ? 'bg-white text-gray-900 shadow-sm'
                    : 'text-gray-600 hover:text-gray-900'
                }`}
              >
                Volume (L)
              </button>
            </div>
          </div>
          {!hasBreakdown ? (
            <div className="h-[280px] flex items-center justify-center text-gray-500 text-sm">
              No time series data yet.
            </div>
          ) : (
            <>
              <div className={chartTab === 'value' ? 'block' : 'hidden'}>
                <Chart
                  type="area"
                  height={280}
                  options={{
                    chart: { type: 'area', toolbar: { show: false }, zoom: { enabled: false } },
                    stroke: { curve: 'smooth', width: 2 },
                    fill: { type: 'gradient', gradient: { shadeIntensity: 1, opacityFrom: 0.5, opacityTo: 0.2, stops: [0, 90, 100] } },
                    colors: ['#059669', '#004AAD'],
                    xaxis: { categories: breakdownSlice.map((d) => d.date) },
                    yaxis: { labels: { formatter: (v: number) => formatCurrency(v) } },
                    tooltip: { y: { formatter: (v: number) => formatCurrency(v) } },
                    dataLabels: { enabled: false },
                    grid: { strokeDashArray: 3 },
                    legend: { position: 'top' },
                  }}
                  series={[
                    { name: 'Sales', data: breakdownSlice.map((d) => d.sales.value) },
                    { name: 'Collections', data: breakdownSlice.map((d) => d.collection.value) },
                  ]}
                />
              </div>
              <div className={chartTab === 'volume' ? 'block' : 'hidden'}>
                <Chart
                  type="bar"
                  height={280}
                  options={{
                    chart: { type: 'bar', toolbar: { show: false } },
                    plotOptions: { bar: { borderRadius: 6, columnWidth: '70%', distributed: false } },
                    colors: ['#059669', '#004AAD'],
                    xaxis: { categories: breakdownSlice.map((d) => d.date), labels: { rotate: -45, rotateAlways: true } },
                    yaxis: { title: { text: 'Liters' }, labels: { formatter: (v: number) => String(Math.round(v)) } },
                    dataLabels: { enabled: false },
                    grid: { strokeDashArray: 3 },
                    tooltip: { y: { formatter: (v: number) => `${v} L` } },
                    legend: { position: 'top' },
                  }}
                  series={[
                    { name: 'Sales (L)', data: breakdownSlice.map((d) => d.sales.liters) },
                    { name: 'Collections (L)', data: breakdownSlice.map((d) => d.collection.liters) },
                  ]}
                />
              </div>
            </>
          )}
        </div>
        <div className="bg-white border border-gray-200 rounded-sm p-6">
          <h3 className="text-base font-semibold text-gray-900 mb-4">Split by value</h3>
          {summary.sales.value === 0 && summary.collection.value === 0 ? (
            <div className="h-[280px] flex items-center justify-center text-gray-500 text-sm">
              No data yet.
            </div>
          ) : (
            <Chart
              type="donut"
              height={280}
              options={{
                chart: { type: 'donut', fontFamily: 'inherit' },
                labels: ['Sales', 'Collections'],
                colors: ['#059669', '#004AAD'],
                legend: { position: 'bottom', fontSize: '12px' },
                dataLabels: { formatter: (val: number) => `${Math.round(val)}%` },
                plotOptions: {
                  pie: {
                    donut: {
                      size: '65%',
                      labels: {
                        show: true,
                        total: {
                          show: true,
                          label: 'Total',
                          formatter: () => formatCurrency(summary.sales.value + summary.collection.value),
                        },
                      },
                    },
                  },
                },
              }}
              series={[summary.sales.value, summary.collection.value]}
            />
          )}
        </div>
      </div>

      {/* Recent transactions + Quick actions */}
      <div className="grid grid-cols-1 lg:grid-cols-3 gap-4">
        <div className="lg:col-span-2 bg-white border border-gray-200 rounded-sm">
          <div className="p-4 border-b border-gray-200 flex items-center justify-between">
            <h3 className="text-base font-semibold text-gray-900 flex items-center gap-2">
              <Icon icon={faReceipt} className="text-[var(--primary)]" size="sm" />
              Recent Transactions
            </h3>
            <Link href="/sales" className="text-xs text-[var(--primary)] hover:text-[#003d8f] flex items-center gap-1">
              View All
              <Icon icon={faArrowRight} size="xs" />
            </Link>
          </div>
          <div className="p-4">
            {recent_transactions.length === 0 ? (
              <p className="text-sm text-gray-500 py-4">No recent transactions.</p>
            ) : (
              <div className="overflow-x-auto">
                <table className="w-full text-sm">
                  <thead>
                    <tr className="border-b border-gray-200">
                      <th className="text-left py-2 px-3 font-medium text-gray-700">Date</th>
                      <th className="text-left py-2 px-3 font-medium text-gray-700">Type</th>
                      <th className="text-left py-2 px-3 font-medium text-gray-700">Party</th>
                      <th className="text-right py-2 px-3 font-medium text-gray-700">Qty</th>
                      <th className="text-right py-2 px-3 font-medium text-gray-700">Total</th>
                    </tr>
                  </thead>
                  <tbody>
                    {recent_transactions.map((tx) => (
                      <tr key={tx.id} className="border-b border-gray-100 hover:bg-gray-50">
                        <td className="py-2 px-3 text-gray-600">
                          {new Date(tx.transaction_at).toLocaleDateString()}
                        </td>
                        <td className="py-2 px-3">
                          <span
                            className={
                              tx.type === 'sale'
                                ? 'text-green-700 font-medium'
                                : 'text-[var(--primary)] font-medium'
                            }
                          >
                            {tx.type === 'sale' ? 'Sale' : 'Collection'}
                          </span>
                        </td>
                        <td className="py-2 px-3 text-gray-900">
                          {tx.type === 'sale'
                            ? tx.customer_account?.name ?? tx.customer_account?.code ?? '—'
                            : tx.supplier_account?.name ?? tx.supplier_account?.code ?? '—'}
                        </td>
                        <td className="py-2 px-3 text-right text-gray-600">{tx.quantity} L</td>
                        <td className="py-2 px-3 text-right font-medium text-gray-900">
                          {formatCurrency(tx.total_amount)}
                        </td>
                      </tr>
                    ))}
                  </tbody>
                </table>
              </div>
            )}
          </div>
        </div>

        <div className="bg-white border border-gray-200 rounded-sm">
          <div className="p-4 border-b border-gray-200">
            <h3 className="text-base font-semibold text-gray-900 flex items-center gap-2">
              <Icon icon={faPlus} className="text-[var(--primary)]" size="sm" />
              Quick Actions
            </h3>
          </div>
          <div className="p-4">
            <div className="space-y-2">
              <Link
                href="/sales/new"
                className="flex items-center gap-2 px-4 py-2.5 bg-[var(--primary)] text-white rounded-sm hover:bg-[#003d8f] transition-colors text-sm font-medium"
              >
                <Icon icon={faReceipt} size="sm" />
                <span>New Sale</span>
              </Link>
              <Link
                href="/collections/new"
                className="flex items-center gap-2 px-4 py-2.5 bg-white border border-gray-200 text-gray-700 rounded-sm hover:bg-gray-50 transition-colors text-sm font-medium"
              >
                <Icon icon={faBox} size="sm" />
                <span>New Collection</span>
              </Link>
              <Link
                href="/suppliers/new"
                className="flex items-center gap-2 px-4 py-2.5 bg-white border border-gray-200 text-gray-700 rounded-sm hover:bg-gray-50 transition-colors text-sm font-medium"
              >
                <Icon icon={faBuilding} size="sm" />
                <span>Add Supplier</span>
              </Link>
              <Link
                href="/customers/new"
                className="flex items-center gap-2 px-4 py-2.5 bg-white border border-gray-200 text-gray-700 rounded-sm hover:bg-gray-50 transition-colors text-sm font-medium"
              >
                <Icon icon={faStore} size="sm" />
                <span>Add Customer</span>
              </Link>
            </div>
          </div>
        </div>
      </div>
    </div>
  );
}
