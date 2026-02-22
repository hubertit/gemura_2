'use client';

import { useRouter } from 'next/navigation';
import Link from 'next/link';
import Icon, { faTimes } from '@/app/components/Icon';
import CreateSaleForm from '../CreateSaleForm';

export default function CreateSalePage() {
  const router = useRouter();

  return (
    <div className="space-y-4">
      <div className="flex items-center justify-between">
        <h1 className="text-2xl font-bold text-gray-900">Create Sale</h1>
        <Link href="/sales" className="btn btn-secondary">
          <Icon icon={faTimes} size="sm" className="mr-2" />
          Cancel
        </Link>
      </div>
      <div className="bg-white border border-gray-200 rounded-sm p-6">
        <CreateSaleForm onSuccess={() => router.push('/sales')} onCancel={() => router.back()} />
      </div>
    </div>
  );
}
