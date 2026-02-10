'use client';

import { useEffect } from 'react';
import { useRouter } from 'next/navigation';
import { usePermission } from '@/hooks/usePermission';
import Link from 'next/link';
import Icon, { 
  faDollarSign, 
  faBox, 
  faBuilding, 
  faStore, 
  faWarehouse,
  faChartBar,
  faPlus,
  faList,
  faArrowRight,
  faReceipt,
} from '@/app/components/Icon';

export default function Dashboard() {
  const router = useRouter();
  const { isAdmin, canViewDashboard } = usePermission();

  useEffect(() => {
    // Redirect admin users to admin dashboard
    if (isAdmin() || canViewDashboard()) {
      router.push('/admin/dashboard');
    }
  }, [isAdmin, canViewDashboard, router]);
  // Mock data - will be replaced with API calls
  const stats = {
    totalSales: 1250000,
    totalCollections: 980000,
    totalSuppliers: 45,
    totalCustomers: 32,
    totalInventory: 156,
  };

  const formatCurrency = (amount: number) => {
    return new Intl.NumberFormat('en-RW', {
      style: 'currency',
      currency: 'RWF',
      minimumFractionDigits: 0,
    }).format(amount);
  };

  const recentSales = [
    { id: '1', customer: 'Customer A', amount: 50000, date: '2025-01-20' },
    { id: '2', customer: 'Customer B', amount: 75000, date: '2025-01-19' },
    { id: '3', customer: 'Customer C', amount: 30000, date: '2025-01-19' },
  ];

  return (
    <div className="space-y-4">
      {/* Page Header */}
      <div>
        <h1 className="text-2xl font-bold text-gray-900">Dashboard</h1>
      </div>

      {/* Metrics Grid */}
      <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-5 gap-4">
        {/* Total Sales */}
        <div className="bg-white border border-gray-200 rounded-sm p-4 flex items-center gap-4 transition-all hover:shadow-md hover:-translate-y-0.5 cursor-pointer">
          <div className="w-12 h-12 bg-[var(--primary)]/10 rounded flex items-center justify-center flex-shrink-0">
            <Icon icon={faReceipt} className="text-[var(--primary)]" size="lg" />
          </div>
          <div className="flex-1 min-w-0">
            <div className="text-2xl font-bold text-gray-900">{formatCurrency(stats.totalSales)}</div>
            <div className="text-sm text-gray-600">Total Sales</div>
          </div>
        </div>

        {/* Total Collections */}
        <div className="bg-white border border-gray-200 rounded-sm p-4 flex items-center gap-4 transition-all hover:shadow-md hover:-translate-y-0.5 cursor-pointer">
          <div className="w-12 h-12 bg-green-100 rounded flex items-center justify-center flex-shrink-0">
            <Icon icon={faBox} className="text-green-600" size="lg" />
          </div>
          <div className="flex-1 min-w-0">
            <div className="text-2xl font-bold text-gray-900">{formatCurrency(stats.totalCollections)}</div>
            <div className="text-sm text-gray-600">Total Collections</div>
          </div>
        </div>

        {/* Total Suppliers */}
        <div className="bg-white border border-gray-200 rounded-sm p-4 flex items-center gap-4 transition-all hover:shadow-md hover:-translate-y-0.5 cursor-pointer">
          <div className="w-12 h-12 bg-blue-100 rounded flex items-center justify-center flex-shrink-0">
            <Icon icon={faBuilding} className="text-blue-600" size="lg" />
          </div>
          <div className="flex-1 min-w-0">
            <div className="text-2xl font-bold text-gray-900">{stats.totalSuppliers}</div>
            <div className="text-sm text-gray-600">Total Suppliers</div>
          </div>
        </div>

        {/* Total Customers */}
        <div className="bg-white border border-gray-200 rounded-sm p-4 flex items-center gap-4 transition-all hover:shadow-md hover:-translate-y-0.5 cursor-pointer">
          <div className="w-12 h-12 bg-purple-100 rounded flex items-center justify-center flex-shrink-0">
            <Icon icon={faStore} className="text-purple-600" size="lg" />
          </div>
          <div className="flex-1 min-w-0">
            <div className="text-2xl font-bold text-gray-900">{stats.totalCustomers}</div>
            <div className="text-sm text-gray-600">Total Customers</div>
          </div>
        </div>

        {/* Total Inventory */}
        <div className="bg-white border border-gray-200 rounded-sm p-4 flex items-center gap-4 transition-all hover:shadow-md hover:-translate-y-0.5 cursor-pointer">
          <div className="w-12 h-12 bg-amber-100 rounded flex items-center justify-center flex-shrink-0">
            <Icon icon={faWarehouse} className="text-amber-600" size="lg" />
          </div>
          <div className="flex-1 min-w-0">
            <div className="text-2xl font-bold text-gray-900">{stats.totalInventory}</div>
            <div className="text-sm text-gray-600">Inventory Items</div>
          </div>
        </div>
      </div>

      {/* Main Content Grid */}
      <div className="grid grid-cols-1 lg:grid-cols-3 gap-4">
        {/* Recent Sales */}
        <div className="lg:col-span-2 bg-white border border-gray-200 rounded-sm">
          <div className="p-4 border-b border-gray-200 flex items-center justify-between">
            <h3 className="text-base font-semibold text-gray-900 flex items-center gap-2">
              <Icon icon={faReceipt} className="text-[var(--primary)]" size="sm" />
              Recent Sales
            </h3>
            <Link href="/sales" className="text-xs text-[var(--primary)] hover:text-[#003d8f] flex items-center gap-1">
              View All
              <Icon icon={faArrowRight} size="xs" />
            </Link>
          </div>
          <div className="p-4">
            <div className="space-y-3">
              {recentSales.map((sale) => (
                <div key={sale.id} className="flex items-center justify-between p-3 border border-gray-200 rounded-sm hover:bg-gray-50 transition-colors">
                  <div>
                    <div className="text-sm font-medium text-gray-900">{sale.customer}</div>
                    <div className="text-xs text-gray-500">{sale.date}</div>
                  </div>
                  <div className="text-sm font-semibold text-gray-900">{formatCurrency(sale.amount)}</div>
                </div>
              ))}
            </div>
          </div>
        </div>

        {/* Quick Actions */}
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
