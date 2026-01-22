'use client';

import Icon, { faTimes, faCircleXmark } from './Icon';

interface ErrorMessageProps {
  message: string;
  onDismiss?: () => void;
  variant?: 'error' | 'warning' | 'info';
  className?: string;
}

export default function ErrorMessage({
  message,
  onDismiss,
  variant = 'error',
  className = '',
}: ErrorMessageProps) {
  const variantStyles = {
    error: 'bg-red-50 border-red-200 text-red-600',
    warning: 'bg-yellow-50 border-yellow-200 text-yellow-600',
    info: 'bg-blue-50 border-blue-200 text-blue-600',
  };

  return (
    <div className={`border rounded-sm p-4 ${variantStyles[variant]} ${className}`}>
      <div className="flex items-start">
        <Icon icon={faCircleXmark} size="sm" className="mr-2 mt-0.5 flex-shrink-0" />
        <div className="flex-1">
          <p className="text-sm font-medium">{message}</p>
        </div>
        {onDismiss && (
          <button
            onClick={onDismiss}
            className="ml-2 text-current opacity-70 hover:opacity-100 transition-opacity"
            aria-label="Dismiss"
          >
            <Icon icon={faTimes} size="sm" />
          </button>
        )}
      </div>
    </div>
  );
}
