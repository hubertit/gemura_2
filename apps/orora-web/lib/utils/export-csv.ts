/**
 * Export an array of objects to CSV and trigger download.
 * @param data Array of row objects
 * @param columns Column config: key (field name), label (header), optional getValue(row) for custom export value
 * @param filename Download filename (without .csv)
 */
export function exportToCsv<T extends object>(
  data: T[],
  columns: { key: string; label: string; getValue?: (row: T) => string }[],
  filename: string
): void {
  const escape = (val: string) => {
    const s = String(val);
    if (/[",\n\r]/.test(s)) return `"${s.replace(/"/g, '""')}"`;
    return s;
  };
  const header = columns.map((c) => escape(c.label)).join(',');
  const rows = data.map((row) =>
    columns.map((col) => escape(col.getValue ? col.getValue(row) : String((row as Record<string, unknown>)[col.key] ?? ''))).join(',')
  );
  const csv = [header, ...rows].join('\r\n');
  const blob = new Blob([csv], { type: 'text/csv;charset=utf-8;' });
  const link = document.createElement('a');
  link.href = URL.createObjectURL(blob);
  link.download = `${filename}.csv`;
  link.click();
  URL.revokeObjectURL(link.href);
}
