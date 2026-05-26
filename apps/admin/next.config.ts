import type { NextConfig } from 'next';
import { withSentryConfig } from '@sentry/nextjs';

const nextConfig: NextConfig = {
  output: 'standalone',
  reactCompiler: true,
  images: {
    remotePatterns: [
      {
        protocol: 'https',
        hostname: 'firebasestorage.googleapis.com',
      },
      {
        protocol: 'https',
        hostname: '*.cloudinary.com',
      },
    ],
  },
};

// `withSentryConfig` wraps the Next build to upload source maps, tunnel
// client-side Sentry traffic through /monitoring (bypasses ad-blockers),
// and inject release tags. Source-map upload is gated by SENTRY_AUTH_TOKEN
// being present — CI passes it in, local dev silently skips.
export default withSentryConfig(nextConfig, {
  org: process.env.SENTRY_ORG ?? 'tekka-uganda',
  project: process.env.SENTRY_PROJECT_ADMIN ?? 'tekka-admin',
  silent: !process.env.CI,
  widenClientFileUpload: true,
  tunnelRoute: '/monitoring',
  disableLogger: true,
  authToken: process.env.SENTRY_AUTH_TOKEN,
  sourcemaps: {
    deleteSourcemapsAfterUpload: true,
  },
});
