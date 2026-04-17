'use client';

import { useEffect, useState } from 'react';
import Image from 'next/image';
import { XMarkIcon } from '@heroicons/react/24/outline';
import {
  detectMobilePlatform,
  getStoreUrl,
  type MobilePlatform,
} from '@/lib/app-links';

const DISMISS_KEY = 'tekka.smartBanner.dismissedAt';
const DISMISS_TTL_MS = 7 * 24 * 60 * 60 * 1000;

export default function SmartAppBanner() {
  const [platform, setPlatform] = useState<MobilePlatform>(null);

  useEffect(() => {
    const nav = window.navigator as Navigator & { standalone?: boolean };
    const isStandalone =
      window.matchMedia?.('(display-mode: standalone)').matches ||
      nav.standalone === true;
    if (isStandalone) return;

    const detected = detectMobilePlatform();
    if (!detected) return;

    try {
      const raw = window.localStorage.getItem(DISMISS_KEY);
      if (raw && Date.now() - Number(raw) < DISMISS_TTL_MS) return;
    } catch {
      // localStorage unavailable (private mode, etc.) — still show banner
    }

    // Hydration-safe client-only detection: state must initialize after mount
    // to avoid SSR mismatch on UA-dependent rendering.
    // eslint-disable-next-line react-hooks/set-state-in-effect
    setPlatform(detected);
  }, []);

  if (!platform) return null;

  const storeUrl = getStoreUrl(platform);
  if (!storeUrl) return null;

  const handleDismiss = () => {
    setPlatform(null);
    try {
      window.localStorage.setItem(DISMISS_KEY, String(Date.now()));
    } catch {
      // ignore
    }
  };

  return (
    <div
      role="complementary"
      aria-label="Get the Tekka Uganda app"
      className="md:hidden sticky top-0 z-40 flex items-center gap-3 bg-white border-b border-gray-200 px-3 py-2 shadow-sm"
    >
      <button
        type="button"
        onClick={handleDismiss}
        aria-label="Dismiss app banner"
        className="p-1 -ml-1 text-gray-400 hover:text-gray-600"
      >
        <XMarkIcon className="h-4 w-4" />
      </button>
      <Image
        src="/icon-192.png"
        alt=""
        width={36}
        height={36}
        className="rounded-lg shrink-0"
        unoptimized
      />
      <div className="flex-1 min-w-0">
        <p className="text-sm font-semibold text-gray-900 leading-tight truncate">
          Tekka Uganda
        </p>
        <p className="text-xs text-gray-500 leading-tight truncate">
          Faster browsing & chat in the app
        </p>
      </div>
      <a
        href={storeUrl}
        target="_blank"
        rel="noopener noreferrer"
        className="shrink-0 text-sm font-semibold text-primary-600 hover:text-primary-700 px-2 py-1"
      >
        Get
      </a>
    </div>
  );
}
