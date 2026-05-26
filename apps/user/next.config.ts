import type { NextConfig } from 'next';
import { withSentryConfig } from '@sentry/nextjs';

const nextConfig: NextConfig = {
  output: 'standalone',
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
      {
        protocol: 'https',
        hostname: 'images.unsplash.com',
      },
      {
        protocol: 'https',
        hostname: 'picsum.photos',
      },
    ],
  },
};

// `withSentryConfig` wraps the Next build to:
//   - Upload source maps to Sentry (only when SENTRY_AUTH_TOKEN is set;
//     CI passes this in, local dev silently skips).
//   - Tunnel client-side Sentry traffic through /monitoring (bypasses
//     ad-blockers that block sentry.io domain).
//   - Inject a Sentry release tag into the build so events group per
//     deploy.
//
// Org + project slugs come from .env.production / .env.development. The
// hard-coded fallbacks keep a misconfigured env from uploading to the
// wrong project.
export default withSentryConfig(nextConfig, {
  org: process.env.SENTRY_ORG ?? 'tekka-uganda',
  project: process.env.SENTRY_PROJECT_USER ?? 'tekka-user',
  silent: !process.env.CI,
  widenClientFileUpload: true,
  tunnelRoute: '/monitoring',
  disableLogger: true,
  authToken: process.env.SENTRY_AUTH_TOKEN,
  sourcemaps: {
    deleteSourcemapsAfterUpload: true,
  },
});
