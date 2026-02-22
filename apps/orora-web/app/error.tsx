'use client';

import { useEffect } from 'react';
import Link from 'next/link';
import Icon, { faCircleXmark, faHome } from './components/Icon';

export default function Error({
  error,
  reset,
}: {
  error: Error & { digest?: string };
  reset: () => void;
}) {
  useEffect(() => {
    // Log error to error reporting service
    console.error('Application error:', error);
  }, [error]);

  return (
    <div className="min-h-screen flex items-center justify-center bg-gray-50 p-4">
      <div className="max-w-md w-full bg-white border border-red-200 rounded-sm p-6">
        <div className="flex items-center mb-4">
          <div className="w-12 h-12 bg-red-100 rounded-full flex items-center justify-center mr-4">
            <Icon icon={faCircleXmark} size="lg" className="text-red-600" />
          </div>
          <div>
            <h1 className="text-xl font-bold text-gray-900">Something went wrong</h1>
            <p className="text-sm text-gray-600 mt-1">An unexpected error occurred</p>
          </div>
        </div>

        {process.env.NODE_ENV === 'development' && (
          <div className="mb-4 p-3 bg-gray-50 border border-gray-200 rounded-sm">
            <p className="text-xs font-mono text-red-600 break-all">
              {error.message}
            </p>
            {error.digest && (
              <p className="text-xs text-gray-500 mt-2">Error ID: {error.digest}</p>
            )}
          </div>
        )}

        <div className="flex items-center gap-3">
          <button
            onClick={reset}
            className="btn btn-primary flex-1"
          >
            Try Again
          </button>
          <Link href="/dashboard" className="btn btn-secondary flex-1">
            <Icon icon={faHome} size="sm" className="mr-2" />
            Go Home
          </Link>
        </div>
      </div>
    </div>
  );
}
