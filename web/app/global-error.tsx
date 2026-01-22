'use client';

export default function GlobalError({
  error,
  reset,
}: {
  error: Error & { digest?: string };
  reset: () => void;
}) {
  return (
    <html>
      <body>
        <div className="min-h-screen flex items-center justify-center bg-gray-50 p-4">
          <div className="max-w-md w-full bg-white border border-red-200 rounded-sm p-6">
            <h1 className="text-xl font-bold text-gray-900 mb-4">Something went wrong</h1>
            <p className="text-sm text-gray-600 mb-4">A critical error occurred. Please refresh the page.</p>
            <button
              onClick={reset}
              className="btn btn-primary w-full"
            >
              Try Again
            </button>
          </div>
        </div>
      </body>
    </html>
  );
}
