// Client-side Sentry init. Runs once per browser page load (before any
// React render), wired through Next.js's `instrumentation-client.ts`
// convention (Next 15.3+).
//
// Replay is intentionally NOT enabled here to keep the admin bundle
// small; we can opt-in error-only replay later if needed.

import * as Sentry from '@sentry/nextjs';
import { scrubEvent } from './src/lib/sentry-scrubber';

if (process.env.NEXT_PUBLIC_SENTRY_DSN_ADMIN) {
  Sentry.init({
    dsn: process.env.NEXT_PUBLIC_SENTRY_DSN_ADMIN,
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
    ],
  });
}

export const onRouterTransitionStart = Sentry.captureRouterTransitionStart;
