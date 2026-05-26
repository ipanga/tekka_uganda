'use client';

// Top-level React error boundary. Catches errors that escape every nested
// boundary — at this point Next.js has already torn down the layout, so we
// render a minimal HTML shell (no app chrome, no client state assumed).

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
