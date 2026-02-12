'use client';

import { useEffect } from 'react';
import Icon, { faTriangleExclamation, faInfoCircle } from './Icon';
import type { IconDefinition } from '@fortawesome/fontawesome-svg-core';

export type ConfirmDialogType = 'danger' | 'warning' | 'info';

export interface ConfirmDialogProps {
  open: boolean;
  onClose: () => void;
  onConfirm: () => void;
  title: string;
  message: string;
  confirmText?: string;
  cancelText?: string;
  type?: ConfirmDialogType;
  showIcon?: boolean;
  /** When true, clicking overlay closes (cancel). Default true. */
  closeOnOverlayClick?: boolean;
  /** When true, confirm button shows loading and is disabled. */
  loading?: boolean;
}

const ICON_MAP: Record<ConfirmDialogType, IconDefinition> = {
  danger: faTriangleExclamation,
  warning: faTriangleExclamation,
  info: faInfoCircle,
};

const ICON_COLOR: Record<ConfirmDialogType, string> = {
  danger: 'text-red-500',
  warning: 'text-amber-500',
  info: 'text-[var(--primary)]',
};

const CONFIRM_BTN_CLASS: Record<ConfirmDialogType, string> = {
  danger: 'bg-red-600 hover:bg-red-700 text-white',
  warning: 'bg-amber-500 hover:bg-amber-600 text-white',
  info: 'btn-primary',
};

/**
 * ResolveIT-style confirmation dialog: overlay, optional icon, title, message, Cancel + Confirm.
 * Use for actions like "Mark as paid", "Delete", etc.
 */
export default function ConfirmDialog({
  open,
  onClose,
  onConfirm,
  title,
  message,
  confirmText = 'Confirm',
  cancelText = 'Cancel',
  type = 'info',
  showIcon = true,
  closeOnOverlayClick = true,
  loading = false,
}: ConfirmDialogProps) {
  useEffect(() => {
    if (!open) return;
    const handleEscape = (e: KeyboardEvent) => {
      if (e.key === 'Escape' && !loading) onClose();
    };
    document.addEventListener('keydown', handleEscape);
    document.body.style.overflow = 'hidden';
    return () => {
      document.removeEventListener('keydown', handleEscape);
      document.body.style.overflow = '';
    };
  }, [open, loading, onClose]);

  if (!open) return null;

  const handleOverlayClick = (e: React.MouseEvent) => {
    if (closeOnOverlayClick && !loading && e.target === e.currentTarget) onClose();
  };

  const IconComponent = ICON_MAP[type];

  return (
    <div
      className="fixed inset-0 z-[1060] flex items-center justify-center p-4 bg-black/50 backdrop-blur-[2px] transition-opacity"
      role="dialog"
      aria-modal="true"
      aria-labelledby="confirm-dialog-title"
      onClick={handleOverlayClick}
    >
      <div
        className="w-full max-w-[420px] bg-white rounded-lg border border-gray-200 shadow-xl p-6 sm:p-8 text-center"
        onClick={(e) => e.stopPropagation()}
      >
        {showIcon && (
          <div className="flex justify-center mb-4">
            <Icon icon={IconComponent} size="2x" className={ICON_COLOR[type]} />
          </div>
        )}
        <h3 id="confirm-dialog-title" className="text-xl sm:text-[1.375rem] font-semibold text-gray-900 mb-3">
          {title}
        </h3>
        <p className="text-[0.9375rem] sm:text-base text-gray-600 leading-relaxed mb-6">
          {message}
        </p>
        <div className="flex flex-col-reverse sm:flex-row gap-3 sm:justify-end sm:flex-wrap">
          <button
            type="button"
            onClick={onClose}
            disabled={loading}
            className="btn btn-secondary w-full sm:w-auto min-w-[100px]"
          >
            {cancelText}
          </button>
          <button
            type="button"
            onClick={onConfirm}
            disabled={loading}
            className={`w-full sm:w-auto min-w-[100px] px-5 py-2.5 rounded-md font-medium text-sm transition-colors disabled:opacity-60 disabled:cursor-not-allowed ${CONFIRM_BTN_CLASS[type]}`}
          >
            {loading ? (
              <span className="inline-flex items-center gap-2">
                <span className="inline-block w-4 h-4 border-2 border-current border-t-transparent rounded-full animate-spin" />
                Processing…
              </span>
            ) : (
              confirmText
            )}
          </button>
        </div>
      </div>
    </div>
  );
}
