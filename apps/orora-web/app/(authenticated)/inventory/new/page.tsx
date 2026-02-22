'use client';

import { useRouter } from 'next/navigation';
import Link from 'next/link';
import Icon, { faTimes } from '@/app/components/Icon';
import CreateInventoryForm from '../CreateInventoryForm';

export default function CreateInventoryPage() {
  const router = useRouter();

  return (
    <div className="space-y-4">
      <div className="flex items-center justify-between">
        <h1 className="text-2xl font-bold text-gray-900">Add inventory item</h1>
        <Link href="/inventory" className="btn btn-secondary">
          <Icon icon={faTimes} size="sm" className="mr-2" />
          Cancel
        </Link>
      </div>
      <div className="bg-white border border-gray-200 rounded-sm p-6">
        <CreateInventoryForm onSuccess={() => router.push('/inventory')} onCancel={() => router.back()} />
      </div>
    </div>
  );
}
