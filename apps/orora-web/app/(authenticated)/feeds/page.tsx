'use client';

import { useEffect, useState } from 'react';
import { useSearchParams } from 'next/navigation';
import Link from 'next/link';
import { useAuthStore } from '@/store/auth';
import { inventoryApi, type InventoryItem } from '@/lib/api/inventory';
import Icon, { faLeaf, faCalculator, faWarehouse, faBox } from '@/app/components/Icon';
import Modal from '@/app/components/Modal';
import FeedCalculatorModal from './FeedCalculatorModal';

const FEED_CATEGORY_NAMES = ['feed', 'feeds', 'animal feed', 'fodder', 'silage', 'concentrate'];

function isFeedCategory(categories: InventoryItem['categories']): boolean {
  if (!categories?.length) return false;
  return categories.some((c) => FEED_CATEGORY_NAMES.some((name) => (c.name || '').toLowerCase().includes(name)));
}

export default function FeedsPage() {
  const searchParams = useSearchParams();
  const { currentAccount } = useAuthStore();
  const [inventory, setInventory] = useState<InventoryItem[]>([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState('');
  const [calculatorOpen, setCalculatorOpen] = useState(false);

  useEffect(() => {
    if (!currentAccount?.account_id) {
      setLoading(false);
      return;
    }
    inventoryApi
      .getInventory(currentAccount.account_id)
      .then((res) => {
        if (res.code === 200 && res.data) setInventory(res.data);
      })
      .catch(() => setError('Failed to load inventory'))
      .finally(() => setLoading(false));
  }, [currentAccount?.account_id]);

  useEffect(() => {
    if (searchParams.get('open') === 'calculator') setCalculatorOpen(true);
  }, [searchParams]);

  const feedItems = inventory.filter((item) => isFeedCategory(item.categories));

  return (
    <div className="space-y-6">
      <div>
        <h1 className="text-2xl font-bold text-gray-900">Feeds</h1>
        <p className="text-sm text-gray-500 mt-1">
          Manage feed and use the calculator to estimate daily rations for your animals.
        </p>
      </div>

      <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
        <button
          type="button"
          onClick={() => setCalculatorOpen(true)}
          className="flex items-center gap-4 p-6 bg-white border border-gray-200 rounded-sm hover:border-gray-300 transition-colors text-left w-full"
        >
          <div className="w-12 h-12 rounded-sm bg-[var(--primary)]/10 flex items-center justify-center flex-shrink-0">
            <Icon icon={faCalculator} className="text-[var(--primary)]" size="lg" />
          </div>
          <div>
            <h2 className="font-semibold text-gray-900">Feed calculator</h2>
            <p className="text-sm text-gray-500 mt-0.5">
              Estimate daily feed (green fodder, silage, or both) from weight and milk yield.
            </p>
          </div>
        </button>

        <Link
          href="/inventory/items"
          className="flex items-center gap-4 p-6 bg-white border border-gray-200 rounded-sm hover:border-gray-300 transition-colors"
        >
          <div className="w-12 h-12 rounded-sm bg-[var(--primary)]/10 flex items-center justify-center flex-shrink-0">
            <Icon icon={faWarehouse} className="text-[var(--primary)]" size="lg" />
          </div>
          <div>
            <h2 className="font-semibold text-gray-900">Inventory</h2>
            <p className="text-sm text-gray-500 mt-0.5">
              Add and manage feed products (fodder, silage, concentrates) in your inventory.
            </p>
          </div>
        </Link>
      </div>

      <div className="bg-white border border-gray-200 rounded-sm overflow-hidden">
        <div className="px-4 py-3 border-b border-gray-200 flex items-center gap-2">
          <Icon icon={faLeaf} className="text-[var(--primary)]" size="sm" />
          <h2 className="font-semibold text-gray-900">Feed in your inventory</h2>
        </div>
        <div className="p-4">
          {loading && (
            <p className="text-sm text-gray-500">Loading…</p>
          )}
          {error && (
            <p className="text-sm text-red-600">{error}</p>
          )}
          {!loading && !error && feedItems.length === 0 && (
            <p className="text-sm text-gray-500">
              No feed items found. Add products in{' '}
              <Link href="/inventory/items" className="text-[var(--primary)] hover:underline">Inventory</Link> and
              assign them to a category like &quot;Feed&quot; or &quot;Fodder&quot; to see them here.
            </p>
          )}
          {!loading && !error && feedItems.length > 0 && (
            <ul className="divide-y divide-gray-100">
              {feedItems.map((item) => (
                <li key={item.id} className="py-3 flex items-center justify-between gap-4">
                  <div className="flex items-center gap-3 min-w-0">
                    <div className="w-10 h-10 rounded-sm bg-gray-100 flex items-center justify-center flex-shrink-0">
                      <Icon icon={faBox} className="text-gray-400" size="sm" />
                    </div>
                    <div className="min-w-0">
                      <p className="font-medium text-gray-900 truncate">{item.name}</p>
                      <p className="text-xs text-gray-500">
                        Stock: {item.stock_quantity} · {item.categories?.map((c) => c.name).join(', ')}
                      </p>
                    </div>
                  </div>
                  <Link
                    href={`/inventory/${item.id}`}
                    className="text-sm text-[var(--primary)] hover:underline flex-shrink-0"
                  >
                    View
                  </Link>
                </li>
              ))}
            </ul>
          )}
        </div>
      </div>

      <Modal
        open={calculatorOpen}
        onClose={() => setCalculatorOpen(false)}
        title="Feed calculator"
        maxWidth="max-w-xl"
      >
        <FeedCalculatorModal open={calculatorOpen} onClose={() => setCalculatorOpen(false)} />
      </Modal>
    </div>
  );
}
