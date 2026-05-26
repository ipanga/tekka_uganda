// Client-side Sentry init. Runs once per browser page load (before any
// React render), wired through Next.js's `instrumentation-client.ts`
// convention (Next 15.3+).
//
// Replay is intentionally NOT enabled here: it would add ~50 KB to the
// initial JS bundle and start recording before the user opts in. We may
// add error-only replay later — keep the page-load light for SEO and
// Lighthouse scores.

import * as Sentry from '@sentry/nextjs';
import { scrubEvent } from './src/lib/sentry-scrubber';

if (process.env.NEXT_PUBLIC_SENTRY_DSN_USER) {
  Sentry.init({
    dsn: process.env.NEXT_PUBLIC_SENTRY_DSN_USER,
    environment:
      process.env.NEXT_PUBLIC_SENTRY_ENVIRONMENT ??
      process.env.NODE_ENV ??
      'development',
    release: process.env.NEXT_PUBLIC_SENTRY_RELEASE,
    tracesSampleRate: process.env.NODE_ENV === 'production' ? 0.1 : 1.0,
    sendDefaultPii: false,
    beforeSend: scrubEvent,
    beforeSendTransaction: scrubEvent,
    ignoreErrors: [
      'NEXT_REDIRECT',
      'NEXT_NOT_FOUND',
      'AbortError',
      'ResizeObserver loop limit exceeded',
      // Browser extension noise.
      "Can't find variable: gtag",
      "Can't find variable: fbq",
    ],
  });
}

// Wires client-side router transitions into Sentry traces.
export const onRouterTransitionStart = Sentry.captureRouterTransitionStart;
