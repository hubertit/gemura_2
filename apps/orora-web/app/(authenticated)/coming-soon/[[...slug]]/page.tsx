'use client';

import Link from 'next/link';
import { useParams } from 'next/navigation';
import Icon, { faArrowLeft, faRocket, faLeaf } from '@/app/components/Icon';

const COMING_SOON_LABELS: Record<string, { title: string; description: string }> = {
  'chart-of-accounts': {
    title: 'Chart of Accounts',
    description: 'Manage your account structure and categories for the general ledger. Coming in the next release.',
  },
  'accounting-reports': {
    title: 'Accounting Reports',
    description: 'Balance sheet, trial balance, and detailed financial reports. Coming soon.',
  },
  'asset-register': {
    title: 'Asset Register',
    description: 'Track equipment, vehicles, and fixed assets with depreciation and ledger posting.',
  },
  'analytics': {
    title: 'Analytics & Insights',
    description: 'Dashboards, trends, and custom reports across livestock, production, and finance.',
  },
  'production-runs': {
    title: 'Production Runs',
    description: 'Group and report milk collections by batch or production run.',
  },
  'health-records': {
    title: 'Health Records',
    description: 'Vaccinations, treatments, and vet visits for your animals.',
  },
  'breeding': {
    title: 'Breeding Management',
    description: 'Track breeding, pregnancies, and calving.',
  },
  default: {
    title: 'Coming Soon',
    description: 'We’re building this feature. Check back later or go to the dashboard to explore what’s already available.',
  },
};

export default function ComingSoonPage() {
  const params = useParams();
  const slug = (params?.slug as string[] | undefined)?.[0] ?? 'default';
  const { title, description } = COMING_SOON_LABELS[slug] ?? COMING_SOON_LABELS.default;

  return (
    <div className="min-h-[70vh] flex flex-col items-center justify-center px-4 py-12">
      <div className="max-w-lg w-full text-center">
        {/* Decorative background */}
        <div className="relative mb-8">
          <div className="absolute inset-0 flex items-center justify-center">
            <div className="w-48 h-48 rounded-full bg-[#84BD22]/10 blur-2xl" aria-hidden />
          </div>
          <div className="relative flex justify-center">
            <div className="flex items-center justify-center w-24 h-24 rounded-2xl bg-gradient-to-br from-[#1a2e1a] to-[#2d4a2d] border border-[#84BD22]/30 shadow-xl">
              <Icon icon={faRocket} className="text-[#84BD22]" size="2x" />
            </div>
          </div>
        </div>

        <h1 className="text-2xl sm:text-3xl font-bold text-gray-900 mb-2">{title}</h1>
        <p className="text-gray-600 mb-8 leading-relaxed">{description}</p>

        <div className="flex flex-col sm:flex-row gap-3 justify-center items-center">
          <Link
            href="/dashboard"
            className="inline-flex items-center gap-2 rounded-lg bg-[#84BD22] px-5 py-2.5 text-sm font-medium text-white shadow-sm hover:bg-[#6fa01b] transition focus:outline-none focus:ring-2 focus:ring-[#84BD22] focus:ring-offset-2"
          >
            <Icon icon={faArrowLeft} size="sm" />
            Back to Dashboard
          </Link>
          <Link
            href="/finance"
            className="inline-flex items-center gap-2 rounded-lg border border-gray-300 bg-white px-5 py-2.5 text-sm font-medium text-gray-700 hover:bg-gray-50 transition focus:outline-none focus:ring-2 focus:ring-gray-200"
          >
            <Icon icon={faLeaf} size="sm" />
            Finance
          </Link>
        </div>

        <p className="mt-10 text-xs text-gray-400">
          Orora · Cattle Farming Platform
        </p>
      </div>
    </div>
  );
}
