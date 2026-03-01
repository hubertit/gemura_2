'use client';

import { useState } from 'react';
import Link from 'next/link';
import Icon, { faWeightScale, faChartBar, faChartPie, faCalendar, faCalculator } from '@/app/components/Icon';

type FeedType = 'green_fodder' | 'silage' | 'both';

/** Simplified dairy feed requirement: maintenance (DM) + production (DM). Returns total DM kg/day. */
function estimateDryMatterKg(weightKg: number, milkLPerDay: number, fatPct: number, lactationDays: number): number {
  const maintenance = 0.02 * weightKg;
  const productionFactor = 0.2 + 0.015 * Math.min(fatPct, 6);
  const production = productionFactor * milkLPerDay;
  const earlyLactationBonus = lactationDays > 0 && lactationDays <= 120 ? 0.5 : 0;
  return Math.max(0, maintenance + production + earlyLactationBonus);
}

/** As-fed kg from DM kg using typical DM% (e.g. 35% = 0.35 for green fodder). */
function dmToAsFed(dmKg: number, dmFraction: number): number {
  if (dmFraction <= 0 || dmFraction >= 1) return dmKg;
  return dmKg / dmFraction;
}

interface FeedCalculatorModalProps {
  open: boolean;
  onClose: () => void;
}

export default function FeedCalculatorModal({ open, onClose }: FeedCalculatorModalProps) {
  const [weight, setWeight] = useState('');
  const [milkYield, setMilkYield] = useState('');
  const [fat, setFat] = useState('');
  const [lactationDays, setLactationDays] = useState('');
  const [feedType, setFeedType] = useState<FeedType>('green_fodder');
  const [result, setResult] = useState<{ greenFodderKg: number; silageKg: number } | null>(null);

  const handleCalculate = () => {
    const w = parseFloat(weight);
    const milk = parseFloat(milkYield);
    const f = parseFloat(fat);
    const lact = parseInt(lactationDays, 10) || 0;
    if (Number.isNaN(w) || w <= 0) {
      setResult(null);
      return;
    }
    const dmKg = estimateDryMatterKg(w, Number.isNaN(milk) ? 0 : milk, Number.isNaN(f) ? 0 : f, lact);
    const greenDm = 0.35;
    const silageDm = 0.3;
    if (feedType === 'green_fodder') {
      setResult({ greenFodderKg: dmToAsFed(dmKg, greenDm), silageKg: 0 });
    } else if (feedType === 'silage') {
      setResult({ greenFodderKg: 0, silageKg: dmToAsFed(dmKg, silageDm) });
    } else {
      const halfDm = dmKg / 2;
      setResult({
        greenFodderKg: dmToAsFed(halfDm, greenDm),
        silageKg: dmToAsFed(halfDm, silageDm),
      });
    }
  };

  if (!open) return null;

  return (
    <div className="space-y-4">
      <p className="text-sm text-gray-500">
        Estimate daily feed (as-fed) for lactating cattle based on weight, milk yield, and feed type.
      </p>

      <div className="grid grid-cols-1 sm:grid-cols-2 gap-4">
        <div className="input-group">
          <label htmlFor="modal-weight" className="input-group-label">Weight (kg)</label>
          <div className="relative">
            <div className="absolute left-3 top-1/2 -translate-y-1/2 text-gray-400 pointer-events-none">
              <Icon icon={faWeightScale} size="sm" />
            </div>
            <input
              id="modal-weight"
              type="number"
              step="0.1"
              min="0"
              placeholder="Weight (kg)"
              value={weight}
              onChange={(e) => setWeight(e.target.value)}
              className="input w-full !pl-10 text-sm placeholder:text-gray-500 rounded-sm"
            />
          </div>
        </div>
        <div className="input-group">
          <label htmlFor="modal-milk" className="input-group-label">Milk yield (L/day)</label>
          <div className="relative">
            <div className="absolute left-3 top-1/2 -translate-y-1/2 text-gray-400 pointer-events-none">
              <Icon icon={faChartBar} size="sm" />
            </div>
            <input
              id="modal-milk"
              type="number"
              step="0.1"
              min="0"
              placeholder="Milk yield (L/day)"
              value={milkYield}
              onChange={(e) => setMilkYield(e.target.value)}
              className="input w-full !pl-10 text-sm placeholder:text-gray-500 rounded-sm"
            />
          </div>
        </div>
      </div>
      <div className="grid grid-cols-2 gap-4">
        <div className="input-group">
          <label htmlFor="modal-fat" className="input-group-label">Fat (%)</label>
          <div className="relative">
            <div className="absolute left-3 top-1/2 -translate-y-1/2 text-gray-400 pointer-events-none">
              <Icon icon={faChartPie} size="sm" />
            </div>
            <input
              id="modal-fat"
              type="number"
              step="0.1"
              min="0"
              max="10"
              placeholder="Fat (%)"
              value={fat}
              onChange={(e) => setFat(e.target.value)}
              className="input w-full !pl-10 text-sm placeholder:text-gray-500 rounded-sm"
            />
          </div>
        </div>
        <div className="input-group">
          <label htmlFor="modal-lactation" className="input-group-label">Lactation (days)</label>
          <div className="relative">
            <div className="absolute left-3 top-1/2 -translate-y-1/2 text-gray-400 pointer-events-none">
              <Icon icon={faCalendar} size="sm" />
            </div>
            <input
              id="modal-lactation"
              type="number"
              min="0"
              placeholder="Lactation (days)"
              value={lactationDays}
              onChange={(e) => setLactationDays(e.target.value)}
              className="input w-full !pl-10 text-sm placeholder:text-gray-500 rounded-sm"
            />
          </div>
        </div>
      </div>

      <div className="input-group">
        <span className="input-group-label font-medium text-gray-900">Feed type</span>
        <div className="p-1 rounded-sm bg-gray-100 border border-gray-200 flex gap-0.5">
          {(
            [
              { value: 'green_fodder' as const, label: 'Green Fodder' },
              { value: 'silage' as const, label: 'Silage' },
              { value: 'both' as const, label: 'Both' },
            ] as const
          ).map(({ value, label }) => (
            <button
              key={value}
              type="button"
              onClick={() => setFeedType(value)}
              className={`flex-1 py-2.5 px-3 rounded text-sm font-medium transition-colors ${
                feedType === value
                  ? 'bg-[var(--primary)] text-white'
                  : 'text-gray-600 hover:bg-gray-200/80'
              }`}
            >
              {label}
            </button>
          ))}
        </div>
      </div>

      <button
        type="button"
        onClick={handleCalculate}
        className="btn btn-primary w-full flex items-center justify-center gap-2 py-2.5"
      >
        <Icon icon={faCalculator} size="sm" />
        Calculate
      </button>

      {result !== null && (
        <div className="pt-4 border-t border-gray-200">
          <h3 className="text-sm font-semibold text-gray-900 mb-3">Recommended daily feed (as-fed)</h3>
          <div className="grid grid-cols-1 sm:grid-cols-2 gap-3">
            {result.greenFodderKg > 0 && (
              <div className="bg-gray-50 border border-gray-200 rounded-sm p-3">
                <p className="text-xs text-gray-500 uppercase tracking-wide">Green fodder</p>
                <p className="text-xl font-bold text-gray-900">{result.greenFodderKg.toFixed(1)} kg/day</p>
              </div>
            )}
            {result.silageKg > 0 && (
              <div className="bg-gray-50 border border-gray-200 rounded-sm p-3">
                <p className="text-xs text-gray-500 uppercase tracking-wide">Silage</p>
                <p className="text-xl font-bold text-gray-900">{result.silageKg.toFixed(1)} kg/day</p>
              </div>
            )}
          </div>
          <p className="text-xs text-gray-500 mt-3">
            Use these amounts with your feed products in{' '}
            <Link href="/inventory/items" className="text-[var(--primary)] hover:underline" onClick={onClose}>
              Inventory
            </Link>
            .
          </p>
        </div>
      )}
    </div>
  );
}
