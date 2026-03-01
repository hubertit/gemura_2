'use client';

import { useState, useRef, useEffect, useLayoutEffect } from 'react';
import { createPortal } from 'react-dom';
import {
  format,
  startOfMonth,
  endOfMonth,
  startOfWeek,
  addDays,
  isSameMonth,
  isSameDay,
  isToday,
  isBefore,
  isAfter,
  addMonths,
  subMonths,
  parseISO,
  isValid,
} from 'date-fns';
import Icon, { faCalendar, faChevronLeft, faChevronRight } from './Icon';

const WEEKDAYS = ['Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat'];

export interface DatePickerProps {
  /** Value as YYYY-MM-DD */
  value?: string;
  onChange: (value: string) => void;
  min?: string;
  max?: string;
  placeholder?: string;
  disabled?: boolean;
  id?: string;
  name?: string;
  className?: string;
  required?: boolean;
}

export default function DatePicker({
  value,
  onChange,
  min,
  max,
  placeholder = 'Select date',
  disabled = false,
  id,
  name,
  className = '',
  required = false,
}: DatePickerProps) {
  const [open, setOpen] = useState(false);
  const [position, setPosition] = useState({ top: 0, left: 0 });
  const [viewMonth, setViewMonth] = useState<Date>(() => {
    if (value) {
      const d = parseISO(value);
      return isValid(d) ? d : new Date();
    }
    return new Date();
  });
  const containerRef = useRef<HTMLDivElement>(null);
  const dropdownRef = useRef<HTMLDivElement>(null);

  const valueDate = value && value.trim() ? parseISO(value) : null;
  const minDateObj = min ? parseISO(min) : null;
  const maxDateObj = max ? parseISO(max) : null;

  useLayoutEffect(() => {
    if (open && containerRef.current) {
      const rect = containerRef.current.getBoundingClientRect();
      setPosition({ top: rect.bottom + 4, left: rect.left });
    }
  }, [open]);

  useEffect(() => {
    if (!open) return;
    const handleClickOutside = (e: MouseEvent) => {
      const target = e.target as Node;
      if (
        containerRef.current?.contains(target) ||
        dropdownRef.current?.contains(target)
      ) return;
      setOpen(false);
    };
    document.addEventListener('mousedown', handleClickOutside);
    return () => document.removeEventListener('mousedown', handleClickOutside);
  }, [open]);

  useEffect(() => {
    if (value && open) {
      const d = parseISO(value);
      if (isValid(d)) setViewMonth(d);
    }
  }, [value, open]);

  const monthStart = startOfMonth(viewMonth);
  const monthEnd = endOfMonth(viewMonth);
  const calStart = startOfWeek(monthStart, { weekStartsOn: 0 });
  const weeks: Date[][] = [];
  let day = calStart;
  while (day <= monthEnd || weeks.length < 6) {
    const week: Date[] = [];
    for (let i = 0; i < 7; i++) {
      week.push(day);
      day = addDays(day, 1);
    }
    weeks.push(week);
    if (day > monthEnd && day.getDay() === 0) break;
  }

  const selectDay = (d: Date) => {
    if (minDateObj && isBefore(d, minDateObj)) return;
    if (maxDateObj && isAfter(d, maxDateObj)) return;
    onChange(format(d, 'yyyy-MM-dd'));
    setOpen(false);
  };

  const displayValue = valueDate ? format(valueDate, 'MMM d, yyyy') : (value ?? '');

  return (
    <div ref={containerRef} className={`relative ${className}`}>
      <button
        type="button"
        id={id}
        onClick={() => !disabled && setOpen((o) => !o)}
        disabled={disabled}
        className="input w-full flex items-center justify-between gap-2 text-left cursor-pointer"
        aria-haspopup="dialog"
        aria-expanded={open}
        aria-label={value ? `Date: ${displayValue}` : placeholder}
      >
        <span className={value ? 'text-gray-900' : 'text-gray-500'}>{displayValue || placeholder}</span>
        <Icon icon={faCalendar} className="text-gray-400 shrink-0" size="sm" />
      </button>
      <input type="hidden" name={name} value={value ?? ''} required={required} readOnly aria-hidden />

      {open && typeof document !== 'undefined' && createPortal(
        <div
          ref={dropdownRef}
          className="fixed min-w-[280px] rounded-lg border border-gray-200 bg-white shadow-xl shadow-gray-200/50 py-3 px-3 z-[9999]"
          style={{ top: position.top, left: position.left }}
          role="dialog"
          aria-label="Calendar"
        >
          <div className="flex items-center justify-between mb-3 px-1">
            <button
              type="button"
              onClick={() => setViewMonth((m) => subMonths(m, 1))}
              className="p-2 rounded-md text-gray-500 hover:bg-gray-100 hover:text-gray-700 transition-colors"
              aria-label="Previous month"
            >
              <Icon icon={faChevronLeft} size="sm" />
            </button>
            <span className="text-sm font-semibold text-gray-900">
              {format(viewMonth, 'MMMM yyyy')}
            </span>
            <button
              type="button"
              onClick={() => setViewMonth((m) => addMonths(m, 1))}
              className="p-2 rounded-md text-gray-500 hover:bg-gray-100 hover:text-gray-700 transition-colors"
              aria-label="Next month"
            >
              <Icon icon={faChevronRight} size="sm" />
            </button>
          </div>

          <div className="grid grid-cols-7 gap-0.5 mb-2">
            {WEEKDAYS.map((wd) => (
              <div
                key={wd}
                className="h-8 flex items-center justify-center text-xs font-medium text-gray-500"
              >
                {wd}
              </div>
            ))}
          </div>
          <div className="grid grid-cols-7 gap-0.5">
            {weeks.flatMap((week) =>
              week.map((d) => {
                const inMonth = isSameMonth(d, viewMonth);
                const selected = valueDate && isSameDay(d, valueDate);
                const today = isToday(d);
                const disabledDay =
                  (minDateObj && isBefore(d, minDateObj)) || (maxDateObj && isAfter(d, maxDateObj));
                return (
                  <button
                    key={d.toISOString()}
                    type="button"
                    onClick={() => !disabledDay && selectDay(d)}
                    disabled={!!disabledDay}
                    className={`
                      h-9 w-9 rounded-md text-sm transition-colors
                      ${!inMonth ? 'text-gray-300' : 'text-gray-900'}
                      ${disabledDay ? 'cursor-not-allowed opacity-40' : 'cursor-pointer hover:bg-gray-100'}
                      ${selected ? 'bg-[var(--primary)] text-white hover:bg-[var(--primary-hover)]' : ''}
                      ${today && !selected ? 'ring-1 ring-[var(--primary)] ring-inset' : ''}
                    `}
                  >
                    {format(d, 'd')}
                  </button>
                );
              })
            )}
          </div>
        </div>,
        document.body
      )}
    </div>
  );
}
