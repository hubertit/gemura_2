'use client';

import { useState, useRef, useEffect, useMemo } from 'react';
import Icon, { faChevronDown, faSearch } from '@/app/components/Icon';

export interface SearchableSelectOption {
  value: string;
  label: string;
}

interface SearchableSelectProps {
  options: SearchableSelectOption[];
  value: string;
  onChange: (value: string) => void;
  placeholder?: string;
  disabled?: boolean;
  id?: string;
  name?: string;
  required?: boolean;
  /** Optional: class for the trigger/input container */
  className?: string;
  /** Max height of dropdown list (default 240px) */
  maxListHeight?: number;
}

/**
 * Searchable select (combobox) – type or click to search and pick an option.
 * Similar to ResolveIT Pro ticket assignment user picker.
 */
export default function SearchableSelect({
  options,
  value,
  onChange,
  placeholder = 'Search or select...',
  disabled = false,
  id,
  name,
  required = false,
  className = '',
  maxListHeight = 240,
}: SearchableSelectProps) {
  const [open, setOpen] = useState(false);
  const [query, setQuery] = useState('');
  const [highlightIndex, setHighlightIndex] = useState(0);
  const containerRef = useRef<HTMLDivElement>(null);
  const listRef = useRef<HTMLUListElement>(null);
  const searchInputRef = useRef<HTMLInputElement>(null);

  const selectedOption = useMemo(() => options.find((o) => o.value === value), [options, value]);

  const filteredOptions = useMemo(() => {
    if (!query.trim()) return options;
    const q = query.trim().toLowerCase();
    return options.filter(
      (o) => o.label.toLowerCase().includes(q) || o.value.toLowerCase().includes(q)
    );
  }, [options, query]);

  // Reset highlight when filtered list changes
  useEffect(() => {
    setHighlightIndex(0);
  }, [filteredOptions.length, query]);

  // Close on outside click
  useEffect(() => {
    if (!open) return;
    const handleClickOutside = (e: MouseEvent) => {
      if (containerRef.current && !containerRef.current.contains(e.target as Node)) {
        setOpen(false);
      }
    };
    document.addEventListener('mousedown', handleClickOutside);
    return () => document.removeEventListener('mousedown', handleClickOutside);
  }, [open]);

  // Focus search when opening
  useEffect(() => {
    if (open) {
      setQuery('');
      setTimeout(() => searchInputRef.current?.focus(), 0);
    }
  }, [open]);

  // Scroll highlighted item into view
  useEffect(() => {
    if (!open || !listRef.current) return;
    const el = listRef.current.children[highlightIndex] as HTMLElement;
    el?.scrollIntoView({ block: 'nearest' });
  }, [highlightIndex, open]);

  const handleKeyDown = (e: React.KeyboardEvent) => {
    if (!open) {
      if (e.key === 'Enter' || e.key === ' ' || e.key === 'ArrowDown') {
        e.preventDefault();
        setOpen(true);
      }
      return;
    }
    if (e.key === 'Escape') {
      e.preventDefault();
      setOpen(false);
      return;
    }
    if (e.key === 'ArrowDown') {
      e.preventDefault();
      setHighlightIndex((i) => (i < filteredOptions.length - 1 ? i + 1 : i));
      return;
    }
    if (e.key === 'ArrowUp') {
      e.preventDefault();
      setHighlightIndex((i) => (i > 0 ? i - 1 : 0));
      return;
    }
    if (e.key === 'Enter' && filteredOptions[highlightIndex]) {
      e.preventDefault();
      onChange(filteredOptions[highlightIndex].value);
      setOpen(false);
    }
  };

  const handleSelect = (option: SearchableSelectOption) => {
    onChange(option.value);
    setOpen(false);
  };

  const displayLabel = selectedOption?.label ?? '';

  return (
    <div ref={containerRef} className={`relative ${className}`}>
      {name && <input type="hidden" name={name} value={value} readOnly required={required} />}
      <div
        role="combobox"
        aria-expanded={open}
        aria-haspopup="listbox"
        aria-controls={id ? `${id}-listbox` : undefined}
        aria-activedescendant={open && filteredOptions[highlightIndex] ? `${id || 'sel'}-opt-${highlightIndex}` : undefined}
        id={id}
        tabIndex={disabled ? -1 : 0}
        onClick={() => !disabled && setOpen((o) => !o)}
        onKeyDown={handleKeyDown}
        className={`input w-full flex items-center justify-between cursor-pointer bg-white border border-gray-200 rounded-sm px-3 py-2 text-sm text-gray-900 focus:outline-none focus:border-[var(--primary)] focus:ring-1 focus:ring-[var(--primary)] ${disabled ? 'bg-gray-50 cursor-not-allowed' : ''}`}
        style={{ caretColor: 'transparent' }}
        aria-disabled={disabled}
        aria-required={required}
        aria-label={placeholder}
      >
        <span className={!displayLabel ? 'text-gray-400' : ''}>
          {displayLabel || placeholder}
        </span>
      </div>
      <div className="absolute right-3 top-1/2 -translate-y-1/2 pointer-events-none text-gray-400">
        <Icon icon={faChevronDown} size="sm" className={open ? 'rotate-180' : ''} />
      </div>

      {open && (
        <div
          id={id ? `${id}-listbox` : undefined}
          role="listbox"
          className="absolute z-50 left-0 right-0 mt-1 bg-white border border-gray-200 rounded-lg shadow-lg overflow-hidden"
        >
          <div className="p-2 border-b border-gray-100 bg-gray-50/80">
            <div className="relative">
              <Icon icon={faSearch} size="sm" className="absolute left-3 top-1/2 -translate-y-1/2 text-gray-400 pointer-events-none" />
              <input
                ref={searchInputRef}
                type="text"
                value={query}
                onChange={(e) => setQuery(e.target.value)}
                onKeyDown={handleKeyDown}
                placeholder="Type to search..."
                className="w-full rounded border border-gray-200 bg-white py-2 pr-3 pl-9 text-sm text-gray-900 placeholder:text-gray-400 focus:outline-none focus:border-[var(--primary)] focus:ring-1 focus:ring-[var(--primary)]"
                aria-label="Filter options"
              />
            </div>
          </div>
          <ul
            ref={listRef}
            className="overflow-y-auto py-1"
            style={{ maxHeight: maxListHeight }}
          >
            {filteredOptions.length === 0 ? (
              <li className="px-3 py-2 text-sm text-gray-500">No matches</li>
            ) : (
              filteredOptions.map((option, i) => (
                <li
                  key={option.value}
                  id={id ? `${id}-opt-${i}` : undefined}
                  role="option"
                  aria-selected={option.value === value}
                  onClick={() => handleSelect(option)}
                  onMouseEnter={() => setHighlightIndex(i)}
                  className={`px-3 py-2 text-sm cursor-pointer ${
                    option.value === value
                      ? 'bg-[var(--primary)]/10 text-[var(--primary)] font-medium'
                      : highlightIndex === i
                        ? 'bg-gray-100'
                        : 'hover:bg-gray-50'
                  }`}
                >
                  {option.label}
                </li>
              ))
            )}
          </ul>
        </div>
      )}
    </div>
  );
}
