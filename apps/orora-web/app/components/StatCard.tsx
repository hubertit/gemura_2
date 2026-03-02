'use client';

import { IconDefinition } from '@fortawesome/fontawesome-svg-core';
import Icon from './Icon';
import Link from 'next/link';

interface StatCardProps {
  label: string;
  value: string | number;
  icon: IconDefinition;
  href?: string;
  subtitle?: string;
  iconBgColor?: string;
  iconColor?: string;
}

/**
 * ResolveIT-style stat card: label, value, optional subtitle, icon in colored box (right).
 */
export default function StatCard({
  label,
  value,
  icon,
  href,
  subtitle,
  iconBgColor = '#eff6ff',
  iconColor = 'var(--primary)',
}: StatCardProps) {
  const content = (
    <div className="bg-white rounded-sm border border-gray-200 p-3 sm:p-4 h-full min-h-[88px] flex flex-col hover:border-gray-300 transition-colors">
      <div className="flex items-start justify-between gap-2 flex-1 min-h-0">
        <div className="min-w-0 flex-1">
          <div className="text-[10px] sm:text-xs font-medium text-gray-500 uppercase tracking-wide mb-0.5">
            {label}
          </div>
          <div className="text-lg sm:text-xl font-bold text-gray-900 leading-tight truncate">
            {value}
          </div>
          {subtitle && (
            <div className="text-[10px] sm:text-xs text-gray-600 mt-0.5 line-clamp-2">{subtitle}</div>
          )}
        </div>
        <div
          className="flex-shrink-0 w-9 h-9 sm:w-10 sm:h-10 rounded-md flex items-center justify-center"
          style={{ backgroundColor: iconBgColor, color: iconColor }}
        >
          <Icon icon={icon} size="sm" />
        </div>
      </div>
    </div>
  );

  if (href) {
    return <Link href={href} className="block h-full">{content}</Link>;
  }
  return content;
}
