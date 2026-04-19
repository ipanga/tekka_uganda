'use client';

import { useEffect, useRef, useState } from 'react';
import { useOnlineStatus } from '@/hooks/useOnlineStatus';

/**
 * Thin top-of-page banner that mirrors the Flutter app's offline UX:
 *   - Shows "No internet connection" while offline.
 *   - Briefly flashes "Back online" when connectivity returns.
 * Hidden by default so SSR output is clean for SEO.
 */
export default function OfflineBanner() {
  const isOnline = useOnlineStatus();
  const [showRestored, setShowRestored] = useState(false);
  const prevOnline = useRef(isOnline);

  useEffect(() => {
    if (!prevOnline.current && isOnline) {
      setShowRestored(true);
      const t = setTimeout(() => setShowRestored(false), 2000);
      return () => clearTimeout(t);
    }
    prevOnline.current = isOnline;
  }, [isOnline]);

  if (!isOnline) {
    return (
      <div
        role="status"
        className="sticky top-0 z-50 w-full bg-gray-900 px-4 py-2 text-center text-sm text-white"
      >
        No internet connection
      </div>
    );
  }
  if (showRestored) {
    return (
      <div
        role="status"
        className="sticky top-0 z-50 w-full bg-[#E53E3E] px-4 py-2 text-center text-sm text-white"
      >
        Back online
      </div>
    );
  }
  return null;
}
