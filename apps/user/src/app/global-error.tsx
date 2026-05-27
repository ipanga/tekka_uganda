'use client';

// Top-level React error boundary. Catches errors that escape every nested
// boundary — at this point Next.js has already torn down the layout, so we
// render a minimal HTML shell (no app chrome, no client state assumed).
//
// Sentry's `captureUnderscoreErrorException` reports the React error to the
// same project that `instrumentation-client.ts` is wired to. Without this
// file, React errors that bubble past `error.tsx` would only show up as
// console errors and `window.onerror`-derived events, which are noisier and
// often miss the React component stack.

import * as Sentry from '@sentry/nextjs';
import NextError from 'next/error';
import { useEffect } from 'react';

export default function GlobalError({
  error,
}: {
  error: Error & { digest?: string };
}) {
  useEffect(() => {
    Sentry.captureException(error);
  }, [error]);

  return (
    <html lang="en">
      <body>
        <NextError statusCode={0} />
      </body>
    </html>
  );
}
