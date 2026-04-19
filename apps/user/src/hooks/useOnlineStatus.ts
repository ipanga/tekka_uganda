'use client';

import { useEffect, useState } from 'react';

/**
 * Reports the browser's current online status. Initializes from
 * `navigator.onLine` on mount (SSR-safe: assumes online server-side) and
 * tracks `online`/`offline` events thereafter.
 *
 * This is a coarse signal — the browser can report "online" while a specific
 * endpoint is unreachable — but it's the right fit for a top-of-page banner
 * that says "no network at all". Per-request retry still happens in api.ts.
 */
export function useOnlineStatus(): boolean {
  const [isOnline, setIsOnline] = useState<boolean>(true);

  useEffect(() => {
    // Initial sync once the component mounts (client side).
    setIsOnline(navigator.onLine);

    const handleOnline = () => setIsOnline(true);
    const handleOffline = () => setIsOnline(false);
    window.addEventListener('online', handleOnline);
    window.addEventListener('offline', handleOffline);
    return () => {
      window.removeEventListener('online', handleOnline);
      window.removeEventListener('offline', handleOffline);
    };
  }, []);

  return isOnline;
}
