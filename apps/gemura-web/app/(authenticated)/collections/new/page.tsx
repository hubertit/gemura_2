'use client';

import { useRouter } from 'next/navigation';
import Link from 'next/link';
import Icon, { faTimes } from '@/app/components/Icon';
import CreateCollectionForm from '../CreateCollectionForm';

export default function CreateCollectionPage() {
  const router = useRouter();

  return (
    <div className="space-y-4">
      <div className="flex items-center justify-between">
        <h1 className="text-2xl font-bold text-gray-900">Create Collection</h1>
        <Link href="/collections" className="btn btn-secondary">
          <Icon icon={faTimes} size="sm" className="mr-2" />
          Cancel
        </Link>
      </div>
      <div className="bg-white border border-gray-200 rounded-sm p-6">
        <CreateCollectionForm onSuccess={() => router.push('/collections')} onCancel={() => router.back()} />
      </div>
    </div>
  );
}
