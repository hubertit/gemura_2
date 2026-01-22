'use client';

import { useEffect, useState, useCallback } from 'react';
import { useRouter } from 'next/navigation';
import { usePermission } from '@/hooks/usePermission';
import { adminApi, DashboardStats } from '@/lib/api/admin';
import { useAuthStore } from '@/store/auth';
import Icon, { 
  faUsers, 
  faBuilding, 
  faReceipt, 
  faBox, 
  faStore,
  faChartBar,
  faDollarSign,
} from '@/app/components/Icon';
import dynamic from 'next/dynamic';

// Dynamically import ApexCharts to avoid SSR issues
const Chart = dynamic(() => import('react-apexcharts'), { ssr: false });

type DashboardTab = 'overview' | 'financial' | 'sales' | 'collections';

const COLORS = ['#004AAD', '#10b981', '#f59e0b', '#ef4444', '#8b5cf6', '#06b6d4'];

export default function AdminDashboard() {
  const router = useRouter();
  const { canViewDashboard, isAdmin } = usePermission();
  const { currentAccount } = useAuthStore();
  const [loading, setLoading] = useState(true);
  const [stats, setStats] = useState<DashboardStats | null>(null);
  const [error, setError] = useState('');
  const [activeTab, setActiveTab] = useState<DashboardTab>('overview');

  useEffect(() => {
    // Check permission once on mount
    const hasPermission = canViewDashboard() || isAdmin();
    if (!hasPermission) {
      router.push('/dashboard');
      return;
    }
    
    // Load mock data only once
    if (!stats) {
      loadMockStats();
    }
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, []);

  const loadMockStats = useCallback(() => {
    // Generate mock data for dashboard
    const now = new Date();
    const dailyTrend = [];
    for (let i = 29; i >= 0; i--) {
      const date = new Date(now);
      date.setDate(date.getDate() - i);
      dailyTrend.push({
        date: date.toISOString().split('T')[0],
        label: date.toLocaleDateString('en-US', { month: 'short', day: 'numeric' }),
        revenue: Math.floor(Math.random() * 500000) + 200000,
        sales: Math.floor(Math.random() * 500) + 100,
      });
    }

    const mockStats: DashboardStats = {
      users: {
        total: 145,
        active: 132,
        inactive: 13,
      },
      accounts: {
        total: 89,
      },
      sales: {
        total: 1245,
        last30Days: 342,
        last7Days: 87,
        today: 12,
      },
      collections: {
        total: 892,
      },
      suppliers: {
        total: 45,
      },
      customers: {
        total: 32,
      },
      revenue: {
        total: 12500000,
        last30Days: 3450000,
        last7Days: 890000,
        today: 125000,
      },
      trends: {
        daily: dailyTrend,
      },
      salesByStatus: [
        { status: 'accepted', count: 892 },
        { status: 'pending', count: 234 },
        { status: 'rejected', count: 119 },
      ],
      recentSales: [
        {
          id: '1',
          quantity: 50,
          unitPrice: 2500,
          total: 125000,
          status: 'accepted',
          date: new Date().toISOString(),
          supplier: 'Farm A',
          customer: 'Customer B',
        },
        {
          id: '2',
          quantity: 75,
          unitPrice: 2400,
          total: 180000,
          status: 'accepted',
          date: new Date(Date.now() - 86400000).toISOString(),
          supplier: 'Farm B',
          customer: 'Customer C',
        },
        {
          id: '3',
          quantity: 30,
          unitPrice: 2600,
          total: 78000,
          status: 'pending',
          date: new Date(Date.now() - 172800000).toISOString(),
          supplier: 'Farm C',
          customer: 'Customer A',
        },
        {
          id: '4',
          quantity: 100,
          unitPrice: 2550,
          total: 255000,
          status: 'accepted',
          date: new Date(Date.now() - 259200000).toISOString(),
          supplier: 'Farm A',
          customer: 'Customer D',
        },
        {
          id: '5',
          quantity: 45,
          unitPrice: 2450,
          total: 110250,
          status: 'accepted',
          date: new Date(Date.now() - 345600000).toISOString(),
          supplier: 'Farm D',
          customer: 'Customer B',
        },
      ],
    };

    setStats(mockStats);
    setLoading(false);
  }, []);

  // Keep API function for later integration
  const loadStats = async () => {
    try {
      setLoading(true);
      const response = await adminApi.getDashboardStats(currentAccount?.account_id);
      if (response.code === 200) {
        setStats(response.data);
      } else {
        setError('Failed to load dashboard statistics');
      }
    } catch (err: any) {
      setError(err?.response?.data?.message || 'Failed to load dashboard statistics');
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

  if (loading) {
    return (
      <div className="flex items-center justify-center py-12">
        <div className="text-center">
          <div className="w-8 h-8 border-4 border-[var(--primary)] border-t-transparent rounded-full animate-spin mx-auto mb-4"></div>
          <p className="text-sm text-gray-600">Loading dashboard...</p>
        </div>
      </div>
    );
  }

  if (error) {
    return (
      <div className="bg-red-50 border border-red-200 rounded-sm p-4">
        <p className="text-sm text-red-600">{error}</p>
      </div>
    );
  }

  if (!stats) {
    return null;
  }

  return (
    <div className="space-y-4">
      {/* Page Header */}
      <div>
        <h1 className="text-2xl font-bold text-gray-900">Admin Dashboard</h1>
        <p className="text-sm text-gray-600 mt-1">System overview and analytics</p>
      </div>

      {/* Dashboard Tabs */}
      <div className="border-b border-gray-200">
        <nav className="flex space-x-8">
          {[
            { id: 'overview' as DashboardTab, label: 'Overview', icon: faChartBar },
            { id: 'financial' as DashboardTab, label: 'Financial', icon: faDollarSign },
            { id: 'sales' as DashboardTab, label: 'Sales', icon: faReceipt },
            { id: 'collections' as DashboardTab, label: 'Collections', icon: faBox },
          ].map((tab) => (
            <button
              key={tab.id}
              onClick={() => setActiveTab(tab.id)}
              className={`flex items-center gap-2 py-4 px-1 border-b-2 font-medium text-sm transition-colors ${
                activeTab === tab.id
                  ? 'border-[var(--primary)] text-[var(--primary)]'
                  : 'border-transparent text-gray-500 hover:text-gray-700 hover:border-gray-300'
              }`}
            >
              <Icon icon={tab.icon} size="sm" />
              {tab.label}
            </button>
          ))}
        </nav>
      </div>

      {/* Tab Content */}
      {activeTab === 'overview' && <OverviewTab stats={stats} formatCurrency={formatCurrency} router={router} />}
      {activeTab === 'financial' && <FinancialTab stats={stats} formatCurrency={formatCurrency} />}
      {activeTab === 'sales' && <SalesTab stats={stats} formatCurrency={formatCurrency} />}
      {activeTab === 'collections' && <CollectionsTab stats={stats} formatCurrency={formatCurrency} />}
    </div>
  );
}

// Overview Tab Component
function OverviewTab({ stats, formatCurrency, router }: { stats: DashboardStats; formatCurrency: (n: number) => string; router: any }) {
  return (
    <div className="space-y-4">
      {/* Metrics Grid */}
      <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-4 gap-4">
        <MetricCard
          title="Total Users"
          value={stats.users.total}
          subtitle={`${stats.users.active} active, ${stats.users.inactive} inactive`}
          icon={faUsers}
          color="blue"
        />
        <MetricCard
          title="Total Accounts"
          value={stats.accounts.total}
          icon={faBuilding}
          color="indigo"
        />
        <MetricCard
          title="Total Sales"
          value={stats.sales.total}
          subtitle={stats.sales.today ? `${stats.sales.today} today` : undefined}
          icon={faReceipt}
          color="green"
        />
        <MetricCard
          title="Total Revenue"
          value={stats.revenue ? formatCurrency(stats.revenue.total) : '0'}
          subtitle={stats.revenue ? formatCurrency(stats.revenue.today) + ' today' : undefined}
          icon={faDollarSign}
          color="emerald"
        />
      </div>

      {/* Charts Grid */}
      <div className="grid grid-cols-1 lg:grid-cols-2 gap-4">
        {/* Revenue Trend Chart */}
        {stats.trends && stats.trends.daily.length > 0 && (
          <div className="bg-white border border-gray-200 rounded-sm p-4">
            <h3 className="text-base font-semibold text-gray-900 mb-4">Revenue Trend (Last 30 Days)</h3>
            <Chart
              type="line"
              height={300}
              options={{
                chart: {
                  type: 'line',
                  toolbar: { show: false },
                  zoom: { enabled: false },
                },
                stroke: {
                  curve: 'smooth',
                  width: 2,
                },
                colors: ['#004AAD'],
                xaxis: {
                  categories: stats.trends.daily.map(d => d.label),
                },
                yaxis: {
                  labels: {
                    formatter: (value: number) => formatCurrency(value),
                  },
                },
                tooltip: {
                  y: {
                    formatter: (value: number) => formatCurrency(value),
                  },
                },
                grid: {
                  strokeDashArray: 3,
                },
              }}
              series={[
                {
                  name: 'Revenue',
                  data: stats.trends.daily.map(d => d.revenue),
                },
              ]}
            />
          </div>
        )}

        {/* Sales by Status */}
        {stats.salesByStatus && stats.salesByStatus.length > 0 && (
          <div className="bg-white border border-gray-200 rounded-sm p-4">
            <h3 className="text-base font-semibold text-gray-900 mb-4">Sales by Status</h3>
            <Chart
              type="donut"
              height={300}
              options={{
                chart: {
                  type: 'donut',
                },
                labels: stats.salesByStatus.map(s => s.status),
                colors: COLORS,
                legend: {
                  position: 'bottom',
                },
                dataLabels: {
                  enabled: true,
                  formatter: (val: number, opts: any) => {
                    const label = stats.salesByStatus![opts.seriesIndex].status;
                    const count = stats.salesByStatus![opts.seriesIndex].count;
                    return `${label}: ${count}`;
                  },
                },
                tooltip: {
                  y: {
                    formatter: (val: number) => val.toString(),
                  },
                },
              }}
              series={stats.salesByStatus.map(s => s.count)}
            />
          </div>
        )}
      </div>

      {/* Recent Sales Table */}
      {stats.recentSales && stats.recentSales.length > 0 && (
        <div className="bg-white border border-gray-200 rounded-sm p-4">
          <h3 className="text-base font-semibold text-gray-900 mb-4">Recent Sales</h3>
          <div className="overflow-x-auto">
            <table className="w-full text-sm">
              <thead>
                <tr className="border-b border-gray-200">
                  <th className="text-left py-2 px-3 font-medium text-gray-700">Date</th>
                  <th className="text-left py-2 px-3 font-medium text-gray-700">Supplier</th>
                  <th className="text-left py-2 px-3 font-medium text-gray-700">Customer</th>
                  <th className="text-right py-2 px-3 font-medium text-gray-700">Quantity</th>
                  <th className="text-right py-2 px-3 font-medium text-gray-700">Total</th>
                  <th className="text-left py-2 px-3 font-medium text-gray-700">Status</th>
                </tr>
              </thead>
              <tbody>
                {stats.recentSales.map((sale) => (
                  <tr key={sale.id} className="border-b border-gray-100 hover:bg-gray-50">
                    <td className="py-2 px-3 text-gray-600">{new Date(sale.date).toLocaleDateString()}</td>
                    <td className="py-2 px-3 text-gray-900">{sale.supplier}</td>
                    <td className="py-2 px-3 text-gray-900">{sale.customer}</td>
                    <td className="py-2 px-3 text-right text-gray-600">{sale.quantity}L</td>
                    <td className="py-2 px-3 text-right font-medium text-gray-900">{formatCurrency(sale.total)}</td>
                    <td className="py-2 px-3">
                      <span className={`inline-flex px-2 py-1 text-xs font-medium rounded-full ${
                        sale.status === 'accepted' ? 'bg-green-100 text-green-800' :
                        sale.status === 'pending' ? 'bg-yellow-100 text-yellow-800' :
                        'bg-gray-100 text-gray-800'
                      }`}>
                        {sale.status}
                      </span>
                    </td>
                  </tr>
                ))}
              </tbody>
            </table>
          </div>
        </div>
      )}

      {/* Quick Actions */}
      <div className="bg-white border border-gray-200 rounded-sm p-4">
        <h3 className="text-base font-semibold text-gray-900 mb-4">Quick Actions</h3>
        <div className="grid grid-cols-2 md:grid-cols-4 gap-3">
          <button
            onClick={() => router.push('/admin/users')}
            className="btn btn-primary text-sm"
          >
            <Icon icon={faUsers} size="sm" className="mr-2" />
            Manage Users
          </button>
          <button
            onClick={() => router.push('/admin/users/new')}
            className="btn btn-outline text-sm"
          >
            <Icon icon={faUsers} size="sm" className="mr-2" />
            Add User
          </button>
        </div>
      </div>
    </div>
  );
}

// Financial Tab Component
function FinancialTab({ stats, formatCurrency }: { stats: DashboardStats; formatCurrency: (n: number) => string }) {
  return (
    <div className="space-y-4">
      {/* Financial Metrics */}
      <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-4 gap-4">
        <MetricCard
          title="Total Revenue"
          value={stats.revenue ? formatCurrency(stats.revenue.total) : '0'}
          icon={faDollarSign}
          color="green"
        />
        <MetricCard
          title="Last 30 Days"
          value={stats.revenue ? formatCurrency(stats.revenue.last30Days) : '0'}
          icon={faChartBar}
          color="blue"
        />
        <MetricCard
          title="Last 7 Days"
          value={stats.revenue ? formatCurrency(stats.revenue.last7Days) : '0'}
          icon={faChartBar}
          color="indigo"
        />
        <MetricCard
          title="Today"
          value={stats.revenue ? formatCurrency(stats.revenue.today) : '0'}
          icon={faDollarSign}
          color="emerald"
        />
      </div>

      {/* Revenue Chart */}
      {stats.trends && stats.trends.daily.length > 0 && (
        <div className="bg-white border border-gray-200 rounded-sm p-4">
          <h3 className="text-base font-semibold text-gray-900 mb-4">Revenue Trend</h3>
          <Chart
            type="area"
            height={400}
            options={{
              chart: {
                type: 'area',
                toolbar: { show: true },
                zoom: { enabled: true },
              },
              stroke: {
                curve: 'smooth',
                width: 2,
              },
              fill: {
                type: 'gradient',
                gradient: {
                  shadeIntensity: 1,
                  opacityFrom: 0.7,
                  opacityTo: 0.3,
                  stops: [0, 90, 100],
                },
              },
              colors: ['#004AAD'],
              xaxis: {
                categories: stats.trends.daily.map(d => d.label),
              },
              yaxis: {
                labels: {
                  formatter: (value: number) => formatCurrency(value),
                },
              },
              tooltip: {
                y: {
                  formatter: (value: number) => formatCurrency(value),
                },
              },
              grid: {
                strokeDashArray: 3,
              },
            }}
            series={[
              {
                name: 'Revenue (RWF)',
                data: stats.trends.daily.map(d => d.revenue),
              },
            ]}
          />
        </div>
      )}
    </div>
  );
}

// Sales Tab Component
function SalesTab({ stats, formatCurrency }: { stats: DashboardStats; formatCurrency: (n: number) => string }) {
  return (
    <div className="space-y-4">
      {/* Sales Metrics */}
      <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-4 gap-4">
        <MetricCard
          title="Total Sales"
          value={stats.sales.total}
          icon={faReceipt}
          color="green"
        />
        <MetricCard
          title="Last 30 Days"
          value={stats.sales.last30Days || 0}
          icon={faChartBar}
          color="blue"
        />
        <MetricCard
          title="Last 7 Days"
          value={stats.sales.last7Days || 0}
          icon={faChartBar}
          color="indigo"
        />
        <MetricCard
          title="Today"
          value={stats.sales.today || 0}
          icon={faReceipt}
          color="emerald"
        />
      </div>

      {/* Sales Charts */}
      <div className="grid grid-cols-1 lg:grid-cols-2 gap-4">
        {stats.trends && stats.trends.daily.length > 0 && (
          <div className="bg-white border border-gray-200 rounded-sm p-4">
            <h3 className="text-base font-semibold text-gray-900 mb-4">Sales Volume Trend</h3>
            <Chart
              type="bar"
              height={300}
              options={{
                chart: {
                  type: 'bar',
                  toolbar: { show: false },
                },
                colors: ['#004AAD'],
                xaxis: {
                  categories: stats.trends.daily.map(d => d.label),
                },
                yaxis: {
                  title: {
                    text: 'Liters',
                  },
                },
                grid: {
                  strokeDashArray: 3,
                },
                dataLabels: {
                  enabled: false,
                },
              }}
              series={[
                {
                  name: 'Sales (Liters)',
                  data: stats.trends.daily.map(d => d.sales),
                },
              ]}
            />
          </div>
        )}

        {stats.salesByStatus && stats.salesByStatus.length > 0 && (
          <div className="bg-white border border-gray-200 rounded-sm p-4">
            <h3 className="text-base font-semibold text-gray-900 mb-4">Sales by Status</h3>
            <Chart
              type="bar"
              height={300}
              options={{
                chart: {
                  type: 'bar',
                  toolbar: { show: false },
                },
                colors: ['#10b981'],
                xaxis: {
                  categories: stats.salesByStatus.map(s => s.status),
                },
                yaxis: {
                  title: {
                    text: 'Count',
                  },
                },
                grid: {
                  strokeDashArray: 3,
                },
                dataLabels: {
                  enabled: true,
                },
              }}
              series={[
                {
                  name: 'Count',
                  data: stats.salesByStatus.map(s => s.count),
                },
              ]}
            />
          </div>
        )}
      </div>
    </div>
  );
}

// Collections Tab Component
function CollectionsTab({ stats, formatCurrency }: { stats: DashboardStats; formatCurrency: (n: number) => string }) {
  return (
    <div className="space-y-4">
      <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-3 gap-4">
        <MetricCard
          title="Total Collections"
          value={stats.collections.total}
          icon={faBox}
          color="purple"
        />
        <MetricCard
          title="Total Suppliers"
          value={stats.suppliers.total}
          icon={faStore}
          color="amber"
        />
        <MetricCard
          title="Total Customers"
          value={stats.customers.total}
          icon={faUsers}
          color="indigo"
        />
      </div>
    </div>
  );
}

// Metric Card Component
function MetricCard({ 
  title, 
  value, 
  subtitle, 
  icon, 
  color 
}: { 
  title: string; 
  value: string | number; 
  subtitle?: string; 
  icon: any; 
  color: string;
}) {
  const colorClasses: Record<string, string> = {
    blue: 'bg-blue-100 text-blue-600',
    green: 'bg-green-100 text-green-600',
    indigo: 'bg-indigo-100 text-indigo-600',
    purple: 'bg-purple-100 text-purple-600',
    amber: 'bg-amber-100 text-amber-600',
    emerald: 'bg-emerald-100 text-emerald-600',
  };

  return (
    <div className="bg-white border border-gray-200 rounded-sm p-4">
      <div className="flex items-center justify-between mb-2">
        <div className={`w-12 h-12 ${colorClasses[color] || 'bg-gray-100 text-gray-600'} rounded flex items-center justify-center`}>
          <Icon icon={icon} size="lg" />
        </div>
      </div>
      <div className="text-2xl font-bold text-gray-900">{value}</div>
      <div className="text-sm text-gray-600">{title}</div>
      {subtitle && (
        <div className="text-xs text-gray-500 mt-1">{subtitle}</div>
      )}
    </div>
  );
}
