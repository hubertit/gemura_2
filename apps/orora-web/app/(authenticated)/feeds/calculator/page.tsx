'use client';

import { useEffect } from 'react';
import { useRouter } from 'next/navigation';

/** Redirect to Feeds page with calculator modal open. */
export default function FeedCalculatorRedirectPage() {
  const router = useRouter();
  useEffect(() => {
    router.replace('/feeds?open=calculator');
  }, [router]);
  return null;
}
