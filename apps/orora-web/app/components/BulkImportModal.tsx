'use client';

import { useState, useRef, useEffect } from 'react';
import { createPortal } from 'react-dom';
import Icon, { faTimes, faDownload, faUpload, faSpinner, faCheckCircle, faCircleXmark } from '@/app/components/Icon';

export interface BulkImportRow {
  [key: string]: string | number | undefined;
}

interface BulkImportModalProps {
  open: boolean;
  onClose: () => void;
  title: string;
  /** Column headers expected in CSV (order matters for mapping). */
  columns: { key: string; label: string; required?: boolean }[];
  /** Download template file. */
  onDownloadTemplate: () => Promise<void>;
  /** Submit parsed rows; returns { success, failed, errors }. */
  onBulkCreate: (rows: BulkImportRow[]) => Promise<{ success: number; failed: number; errors: { row: number; phone: string; message: string }[] }>;
  /** Transform parsed string row to API row (e.g. parse numbers). */
  mapRow: (row: Record<string, string>) => BulkImportRow;
  onSuccess?: () => void;
}

function parseCSV(text: string): Record<string, string>[] {
  const lines = text.trim().split(/\r?\n/).filter((l) => l.trim());
  if (lines.length < 2) return [];
  const headers = lines[0].split(',').map((h) => h.trim().toLowerCase().replace(/\s+/g, '_'));
  const rows: Record<string, string>[] = [];
  for (let i = 1; i < lines.length; i++) {
    const values = lines[i].split(',').map((v) => v.trim());
    const row: Record<string, string> = {};
    headers.forEach((h, j) => {
      row[h] = values[j] ?? '';
    });
    rows.push(row);
  }
  return rows;
}

export default function BulkImportModal({
  open,
  onClose,
  title,
  columns,
  onDownloadTemplate,
  onBulkCreate,
  mapRow,
  onSuccess,
}: BulkImportModalProps) {
  const [downloading, setDownloading] = useState(false);
  const [file, setFile] = useState<File | null>(null);
  const [parsedRows, setParsedRows] = useState<BulkImportRow[]>([]);
  const [parseError, setParseError] = useState('');
  const [submitting, setSubmitting] = useState(false);
  const [result, setResult] = useState<{ success: number; failed: number; errors: { row: number; phone: string; message: string }[] } | null>(null);
  const inputRef = useRef<HTMLInputElement>(null);

  useEffect(() => {
    if (!open) return;
    document.body.style.overflow = 'hidden';
    return () => {
      document.body.style.overflow = '';
    };
  }, [open]);

  const handleDownload = async () => {
    setDownloading(true);
    setParseError('');
    setResult(null);
    try {
      await onDownloadTemplate();
    } catch (e) {
      setParseError((e as Error)?.message || 'Download failed');
    } finally {
      setDownloading(false);
    }
  };

  const handleFileChange = (e: React.ChangeEvent<HTMLInputElement>) => {
    const f = e.target.files?.[0];
    setResult(null);
    setFile(f || null);
    setParseError('');
    setParsedRows([]);
    if (!f) return;
    const reader = new FileReader();
    reader.onload = () => {
      try {
        const text = String(reader.result ?? '');
        const raw = parseCSV(text);
        const mapped = raw.map((r) => mapRow(r));
        setParsedRows(mapped);
      } catch (err) {
        setParseError((err as Error)?.message || 'Invalid CSV');
      }
    };
    reader.readAsText(f, 'UTF-8');
  };

  const handleSubmit = async () => {
    if (parsedRows.length === 0) {
      setParseError('Upload a CSV file first');
      return;
    }
    setSubmitting(true);
    setParseError('');
    setResult(null);
    try {
      const res = await onBulkCreate(parsedRows);
      setResult(res);
      if (res.failed === 0) {
        onSuccess?.();
        setTimeout(() => {
          onClose();
          setFile(null);
          setParsedRows([]);
          setResult(null);
          if (inputRef.current) inputRef.current.value = '';
        }, 1500);
      }
    } catch (err: unknown) {
      const msg = (err as { response?: { data?: { message?: string } }; message?: string })?.response?.data?.message ?? (err as Error)?.message ?? 'Import failed';
      setParseError(msg);
    } finally {
      setSubmitting(false);
    }
  };

  const handleClose = () => {
    setFile(null);
    setParsedRows([]);
    setParseError('');
    setResult(null);
    if (inputRef.current) inputRef.current.value = '';
    onClose();
  };

  if (!open) return null;

  const modalContent = (
    <div className="fixed inset-0 z-50 flex items-center justify-center p-4 sm:p-5 min-h-screen min-h-[100dvh]" role="dialog" aria-modal="true">
      <div
        className="absolute inset-0 bg-black/50"
        style={{ minHeight: '100dvh' }}
        onClick={handleClose}
        aria-hidden="true"
      />
      <div className="relative w-full max-w-lg max-h-[90vh] flex flex-col bg-white rounded-lg border border-gray-200 shadow-xl" onClick={(e) => e.stopPropagation()}>
        <div className="flex items-center justify-between shrink-0 border-b border-gray-200 px-6 py-4">
          <h2 className="text-lg font-semibold text-gray-900">{title} – Bulk import</h2>
          <button type="button" onClick={handleClose} className="p-2 -m-2 text-gray-400 hover:text-gray-600 hover:bg-gray-100 rounded-lg transition-colors" aria-label="Close">
            <Icon icon={faTimes} size="sm" />
          </button>
        </div>
        <div className="overflow-y-auto flex-1 px-6 py-5 space-y-4">
          <div className="flex flex-wrap items-center gap-2">
            <button type="button" onClick={handleDownload} disabled={downloading} className="inline-flex items-center justify-center gap-1.5 h-9 px-4 text-sm font-medium text-emerald-800 bg-emerald-50 border border-emerald-200 rounded hover:bg-emerald-100 disabled:opacity-50 disabled:cursor-not-allowed transition-colors">
              {downloading ? <Icon icon={faSpinner} size="sm" spin className="mr-2" /> : <Icon icon={faDownload} size="sm" className="mr-2" />}
              Download template
            </button>
          </div>
          <p className="text-sm text-gray-600">Upload a CSV with columns: {columns.map((c) => c.label).join(', ')}.</p>
          <div>
            <label className="block text-sm font-medium text-gray-700 mb-1">CSV file</label>
            <input
              ref={inputRef}
              type="file"
              accept=".csv,text/csv"
              onChange={handleFileChange}
              className="block w-full text-sm text-gray-500 file:mr-3 file:py-2 file:px-3 file:rounded-lg file:border-0 file:text-sm file:font-medium file:bg-[var(--primary)] file:text-white hover:file:opacity-90"
            />
            {file && <p className="mt-1 text-xs text-gray-500">{file.name} – {parsedRows.length} row(s)</p>}
          </div>
          {parseError && (
            <div className="rounded border border-red-200 bg-red-50 px-3 py-2 text-sm text-red-700 flex items-center gap-2">
              <Icon icon={faCircleXmark} size="sm" />
              {parseError}
            </div>
          )}
          {result && (
            <div className="rounded border border-gray-200 bg-gray-50 px-3 py-2 text-sm">
              <div className="flex items-center gap-2 text-green-700">
                <Icon icon={faCheckCircle} size="sm" />
                <span>{result.success} imported successfully.</span>
              </div>
              {result.failed > 0 && (
                <div className="mt-2 text-amber-700">
                  {result.failed} failed. {result.errors.slice(0, 5).map((e) => `Row ${e.row} (${e.phone}): ${e.message}`).join('; ')}
                  {result.errors.length > 5 && ` … and ${result.errors.length - 5} more.`}
                </div>
              )}
            </div>
          )}
        </div>
        <div className="shrink-0 border-t border-gray-200 px-6 py-4 flex items-center justify-end gap-3">
          <button type="button" onClick={handleClose} className="btn btn-secondary">
            Cancel
          </button>
          <button type="button" onClick={handleSubmit} disabled={submitting || parsedRows.length === 0} className="btn btn-primary">
            {submitting ? <Icon icon={faSpinner} size="sm" spin className="mr-2" /> : <Icon icon={faUpload} size="sm" className="mr-2" />}
            Import {parsedRows.length > 0 ? `(${parsedRows.length})` : ''}
          </button>
        </div>
      </div>
    </div>
  );

  return typeof document !== 'undefined' ? createPortal(modalContent, document.body) : null;
}
