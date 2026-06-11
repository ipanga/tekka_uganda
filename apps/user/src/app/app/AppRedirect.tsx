'use client';

import { useEffect } from 'react';
import { detectMobilePlatform, getStoreUrl } from '@/lib/app-links';

/**
 * Mobile-only smart redirect for the /app landing page.
 *
 * The page itself is rendered statically (identical HTML for every device, so
 * it stays CDN/edge-cacheable and crawlable — no User-Agent Vary, no cloaking).
 * Device detection and the store redirect happen here, in the browser:
 *   - iOS  -> App Store
 *   - Android -> Google Play
 *   - Desktop / crawlers -> platform is null, no redirect, the page content stays.
 *
 * `location.replace` (not `href`) keeps the store visit out of history so the
 * back button returns the user to where they came from, not to a redirect loop.
 */
export function AppRedirect() {
  useEffect(() => {
    const url = getStoreUrl(detectMobilePlatform());
    if (url) window.location.replace(url);
  }, []);

  return null;
}
