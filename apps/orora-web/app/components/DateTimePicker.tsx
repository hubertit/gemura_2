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
import Icon, { faCalendar, faClock, faChevronLeft, faChevronRight } from './Icon';

const WEEKDAYS = ['Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat'];
const HOURS = Array.from({ length: 24 }, (_, i) => i);
const MINUTES = [0, 15, 30, 45];

function pad(n: number) {
  return n.toString().padStart(2, '0');
}

export interface DateTimePickerProps {
  /** Value as YYYY-MM-DDTHH:mm (local) */
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

export default function DateTimePicker({
  value,
  onChange,
  min,
  max,
  placeholder = 'Select date and time',
  disabled = false,
  id,
  name,
  className = '',
  required = false,
}: DateTimePickerProps) {
  const [open, setOpen] = useState(false);
  const [position, setPosition] = useState({ top: 0, left: 0 });
  const [activeTab, setActiveTab] = useState<'date' | 'time'>('date');
  const [viewMonth, setViewMonth] = useState<Date>(() => {
    if (value) {
      const d = parseISO(value.replace('T', ' '));
      return isValid(d) ? d : new Date();
    }
    return new Date();
  });
  const containerRef = useRef<HTMLDivElement>(null);
  const dropdownRef = useRef<HTMLDivElement>(null);

  const valueDate = value && value.length >= 10 ? parseISO(value.slice(0, 10)) : null;
  const valueTime = value && value.length >= 16 ? value.slice(11, 16) : ''; // HH:mm
  const minDateObj = min ? parseISO(min.slice(0, 10)) : null;
  const maxDateObj = max ? parseISO(max.slice(0, 10)) : null;

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
      const d = parseISO(value.slice(0, 10));
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
    const dateStr = format(d, 'yyyy-MM-dd');
    const timePart = valueTime || '00:00';
    onChange(`${dateStr}T${timePart}`);
    setActiveTab('time');
  };

  const selectTime = (h: number, m: number) => {
    const datePart = valueDate ? format(valueDate, 'yyyy-MM-dd') : format(new Date(), 'yyyy-MM-dd');
    onChange(`${datePart}T${pad(h)}:${pad(m)}`);
    setOpen(false);
  };

  const displayValue = value
    ? valueDate
      ? `${format(valueDate, 'MMM d, yyyy')} ${valueTime || '00:00'}`
      : value
    : '';

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
        aria-label={value ? `Date and time: ${displayValue}` : placeholder}
      >
        <span className={value ? 'text-gray-900' : 'text-gray-500'}>{displayValue || placeholder}</span>
        <span className="flex items-center gap-2 shrink-0 text-gray-400">
          <Icon icon={faCalendar} size="sm" />
          <Icon icon={faClock} size="sm" />
        </span>
      </button>
      <input type="hidden" name={name} value={value ?? ''} required={required} readOnly aria-hidden />

      {open && typeof document !== 'undefined' && createPortal(
        <div
          ref={dropdownRef}
          className="fixed w-[280px] max-w-[280px] rounded-xl border border-gray-200 bg-white shadow-xl shadow-gray-200/50 overflow-hidden z-[9999]"
          style={{ top: position.top, left: position.left }}
          role="dialog"
          aria-label="Date and time picker"
        >
          <div className="flex border-b border-gray-100">
            <button
              type="button"
              onClick={() => setActiveTab('date')}
              className={`flex-1 py-2.5 text-sm font-medium transition-colors ${
                activeTab === 'date'
                  ? 'bg-[var(--primary)] text-white'
                  : 'text-gray-600 hover:bg-gray-50'
              }`}
            >
              Date
            </button>
            <button
              type="button"
              onClick={() => setActiveTab('time')}
              className={`flex-1 py-2.5 text-sm font-medium transition-colors ${
                activeTab === 'time'
                  ? 'bg-[var(--primary)] text-white'
                  : 'text-gray-600 hover:bg-gray-50'
              }`}
            >
              Time
            </button>
          </div>

          <div className="p-3">
            {activeTab === 'date' && (
              <>
                <div className="flex items-center justify-between mb-3 px-1">
                  <button
                    type="button"
                    onClick={() => setViewMonth((m) => subMonths(m, 1))}
                    className="p-2 rounded-lg text-gray-500 hover:bg-gray-100 hover:text-gray-700 transition-colors"
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
                    className="p-2 rounded-lg text-gray-500 hover:bg-gray-100 hover:text-gray-700 transition-colors"
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
                        (minDateObj && isBefore(d, minDateObj)) ||
                        (maxDateObj && isAfter(d, maxDateObj));
                      return (
                        <button
                          key={d.toISOString()}
                          type="button"
                          onClick={() => !disabledDay && selectDay(d)}
                          disabled={!!disabledDay}
                          className={`
                            h-9 w-9 rounded-lg text-sm transition-colors
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
              </>
            )}

            {activeTab === 'time' && (
              <div className="py-2">
                <p className="text-xs text-gray-500 mb-3">
                  {valueDate ? format(valueDate, 'EEE, MMM d') : 'Select date first'}
                </p>
                <div className="grid grid-cols-2 gap-4">
                  <div>
                    <label className="block text-xs font-medium text-gray-500 mb-1.5">Hour</label>
                    <div className="max-h-40 overflow-y-auto rounded-lg border border-gray-200 p-1 space-y-0.5">
                      {HOURS.map((h) => {
                        const [curH] = valueTime ? valueTime.split(':').map(Number) : [0, 0];
                        const selected = valueTime ? curH === h : false;
                        return (
                          <button
                            key={h}
                            type="button"
                            onClick={() => {
                              const [, m] = valueTime ? valueTime.split(':').map(Number) : [0, 0];
                              selectTime(h, Number.isNaN(m) ? 0 : m);
                            }}
                            className={`w-full py-1.5 px-2 rounded-md text-sm text-center transition-colors ${
                              selected
                                ? 'bg-[var(--primary)] text-white'
                                : 'hover:bg-gray-100 text-gray-700'
                            }`}
                          >
                            {pad(h)}
                          </button>
                        );
                      })}
                    </div>
                  </div>
                  <div>
                    <label className="block text-xs font-medium text-gray-500 mb-1.5">Minute</label>
                    <div className="max-h-40 overflow-y-auto rounded-lg border border-gray-200 p-1 space-y-0.5">
                      {MINUTES.map((m) => {
                        const [, curM] = valueTime ? valueTime.split(':').map(Number) : [0, 0];
                        const selected = valueTime ? curM === m : false;
                        return (
                          <button
                            key={m}
                            type="button"
                            onClick={() => {
                              const [h] = valueTime ? valueTime.split(':').map(Number) : [0, 0];
                              selectTime(Number.isNaN(h) ? 0 : h, m);
                            }}
                            className={`w-full py-1.5 px-2 rounded-md text-sm text-center transition-colors ${
                              selected
                                ? 'bg-[var(--primary)] text-white'
                                : 'hover:bg-gray-100 text-gray-700'
                            }`}
                          >
                            {pad(m)}
                          </button>
                        );
                      })}
                    </div>
                  </div>
                </div>
              </div>
            )}
          </div>
        </div>,
        document.body
      )}
    </div>
  );
}
