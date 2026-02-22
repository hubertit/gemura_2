/**
 * Split a full name into first and last name (frontend only; backend still receives single `name`).
 */
export function splitFullName(full: string): { firstName: string; lastName: string } {
  const trimmed = (full || '').trim();
  if (!trimmed) return { firstName: '', lastName: '' };
  const parts = trimmed.split(/\s+/);
  const firstName = parts[0] ?? '';
  const lastName = parts.slice(1).join(' ') ?? '';
  return { firstName, lastName };
}

/**
 * Build full name from first and last name for API payloads.
 */
export function fullNameFromParts(firstName: string, lastName: string): string {
  return [firstName.trim(), lastName.trim()].filter(Boolean).join(' ').trim();
}
