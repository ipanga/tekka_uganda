// Next.js runtime hook (App Router). Called once per server-process start.
// Branches on NEXT_RUNTIME so the same file initialises both the Node.js
// server and the Edge runtime — they're independent processes with their
// own Sentry SDKs.
//
// `register()` is awaited by Next before any request handling begins, so
// it's safe to do async work here (we don't currently need any).

import * as Sentry from '@sentry/nextjs';
import { scrubEvent } from './src/lib/sentry-scrubber';

const COMMON_OPTIONS = {
  dsn: process.env.NEXT_PUBLIC_SENTRY_DSN_USER,
  environment:
    process.env.SENTRY_ENVIRONMENT ??
    process.env.NODE_ENV ??
    'development',
  release: process.env.SENTRY_RELEASE,
  tracesSampleRate: process.env.NODE_ENV === 'production' ? 0.1 : 1.0,
  sendDefaultPii: false,
  beforeSend: scrubEvent,
  beforeSendTransaction: scrubEvent,
  ignoreErrors: [
    // Next.js internal route signals — not bugs.
    'NEXT_REDIRECT',
    'NEXT_NOT_FOUND',
    // Network errors during navigation cancels.
    'AbortError',
    'ResizeObserver loop limit exceeded',
  ],
};

export async function register() {
  if (!process.env.NEXT_PUBLIC_SENTRY_DSN_USER) return;

  if (process.env.NEXT_RUNTIME === 'nodejs') {
    Sentry.init(COMMON_OPTIONS);
  } else if (process.env.NEXT_RUNTIME === 'edge') {
    Sentry.init(COMMON_OPTIONS);
  }
}

// Forwards server-side rendering / route-handler errors to Sentry. Picked
// up automatically by Next.js when exported from instrumentation.ts.
export const onRequestError = Sentry.captureRequestError;
