'use client';

const HOURS = Array.from({ length: 24 }, (_, i) => i);
const MINUTES = Array.from({ length: 60 }, (_, i) => i);

export interface TimePickerProps {
  /** Value as HH:mm (24h) */
  value: string;
  onChange: (value: string) => void;
  disabled?: boolean;
  className?: string;
}

function pad(n: number) {
  return n.toString().padStart(2, '0');
}

export default function TimePicker({ value, onChange, disabled = false, className = '' }: TimePickerProps) {
  const [hourStr, minuteStr] = value ? value.split(':') : ['', ''];
  const hour = hourStr !== '' ? parseInt(hourStr, 10) : null;
  const minute = minuteStr !== '' ? parseInt(minuteStr, 10) : null;

  const handleHourChange = (h: number) => {
    onChange(`${pad(h)}:${minute !== null ? pad(minute) : '00'}`);
  };
  const handleMinuteChange = (m: number) => {
    onChange(`${hour !== null ? pad(hour) : '00'}:${pad(m)}`);
  };

  return (
    <div className={`flex items-center gap-2 ${className}`}>
      <select
        value={hour !== null ? pad(hour) : ''}
        onChange={(e) => handleHourChange(parseInt(e.target.value, 10))}
        disabled={disabled}
        className="input flex-1 min-w-0 py-2 text-center"
        aria-label="Hour"
      >
        <option value="">—</option>
        {HOURS.map((h) => (
          <option key={h} value={pad(h)}>
            {pad(h)}
          </option>
        ))}
      </select>
      <span className="text-gray-400 font-medium">:</span>
      <select
        value={minute !== null ? pad(minute) : ''}
        onChange={(e) => handleMinuteChange(parseInt(e.target.value, 10))}
        disabled={disabled}
        className="input flex-1 min-w-0 py-2 text-center"
        aria-label="Minute"
      >
        <option value="">—</option>
        {MINUTES.map((m) => (
          <option key={m} value={pad(m)}>
            {pad(m)}
          </option>
        ))}
      </select>
    </div>
  );
}
