'use client';

import { useState, ReactNode } from 'react';
import Icon, { faFilter, faChevronUp, faChevronDown, faTimes, faCheck } from './Icon';

interface FiltersProps {
  children: ReactNode;
  activeFilterCount?: number;
  onApply?: () => void;
  onClear?: () => void;
  showActions?: boolean;
}

export default function Filters({
  children,
  activeFilterCount = 0,
  onApply,
  onClear,
  showActions = true,
}: FiltersProps) {
  const [expanded, setExpanded] = useState(false);

  const toggleFilters = () => {
    setExpanded(!expanded);
  };

  return (
    <div className="bg-white border border-gray-200 rounded-sm mb-4">
      <div className="flex items-center justify-between px-3.5 py-2 border-b border-gray-200">
        <h3 className="flex items-center gap-1.5 m-0 text-sm font-semibold text-gray-700">
          <Icon icon={faFilter} size="sm" />
          Filters
          {activeFilterCount > 0 && (
            <span className="inline-flex items-center justify-center min-w-[18px] h-[18px] px-1.5 bg-[var(--primary)] text-white rounded-full text-[0.6875rem] font-semibold ml-1.5">
              {activeFilterCount}
            </span>
          )}
        </h3>
        <button
          onClick={toggleFilters}
          className="bg-transparent border-0 text-gray-500 cursor-pointer p-1 flex items-center justify-center hover:text-[var(--primary)] transition-colors"
          aria-label={expanded ? 'Collapse filters' : 'Expand filters'}
        >
          <Icon icon={expanded ? faChevronUp : faChevronDown} size="sm" />
        </button>
      </div>

      {expanded && (
        <div className="px-3.5 py-2.5">
          <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-3 xl:grid-cols-4 gap-3 mb-3">
            {children}
          </div>

          {showActions && (onApply || onClear) && (
            <div className="flex gap-2.5 justify-end pt-2.5 border-t border-gray-200">
              {onClear && (
                <button
                  onClick={onClear}
                  className="flex items-center gap-1.5 px-4 py-2 text-sm font-medium bg-gray-100 text-gray-700 border-0 rounded transition-all h-8 hover:bg-gray-200"
                >
                  <Icon icon={faTimes} size="sm" />
                  Clear Filters
                </button>
              )}
              {onApply && (
                <button
                  onClick={onApply}
                  className="flex items-center gap-1.5 px-4 py-2 text-sm font-medium bg-[var(--primary)] text-white border-0 rounded transition-all h-8 hover:opacity-90"
                >
                  <Icon icon={faCheck} size="sm" />
                  Apply Filters
                </button>
              )}
            </div>
          )}
        </div>
      )}
    </div>
  );
}

export function FilterGroup({ children, fullWidth = false }: { children: ReactNode; fullWidth?: boolean }) {
  return (
    <div className={`flex flex-col gap-1.5 ${fullWidth ? 'col-span-full' : ''}`}>
      {children}
    </div>
  );
}

export function FilterLabel({ children }: { children: ReactNode }) {
  return (
    <label className="text-[0.8125rem] font-medium text-gray-700 leading-tight">
      {children}
    </label>
  );
}
