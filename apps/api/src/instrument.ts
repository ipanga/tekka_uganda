// Sentry bootstrap. MUST be imported as the very first thing in main.ts —
// `Sentry.init()` patches `require()` to instrument Node modules as they're
// loaded, so anything imported before this file runs cannot be traced.
//
// Disabled when SENTRY_DSN_API is not set (e.g. local dev without a project
// or staging env that intentionally opts out). The SDK becomes a no-op.

import * as Sentry from '@sentry/nestjs';
import { nodeProfilingIntegration } from '@sentry/profiling-node';

const dsn = process.env.SENTRY_DSN_API;

if (dsn) {
  const isProd = process.env.NODE_ENV === 'production';

  Sentry.init({
    dsn,
    environment:
      process.env.SENTRY_ENVIRONMENT ?? process.env.NODE_ENV ?? 'development',
    // Release is set by CI (Sentry CLI release create) using the git SHA so
    // events group across the same deploy. Falls back to package.json version.
    release: process.env.SENTRY_RELEASE,

    integrations: [nodeProfilingIntegration()],

    // Performance: 10% of transactions in prod, 100% in dev/staging.
    tracesSampleRate: isProd ? 0.1 : 1.0,
    profilesSampleRate: isProd ? 0.1 : 1.0,

    // PII safety. `sendDefaultPii: false` means Sentry's HTTP integration
    // won't auto-capture request headers, cookies, query strings, or bodies.
    // `beforeSend` is a belt-and-braces scrubber for anything that still
    // leaks via error messages / stack-trace local variables.
    sendDefaultPii: false,
    beforeSend(event) {
      return scrub(event);
    },
    beforeSendTransaction(transaction) {
      return scrub(transaction);
    },

    // Ignore client-cancelled requests and validation errors — these are not
    // bugs, they're normal API operation. Filtering at the SDK level keeps
    // the Sentry quota for real problems.
    ignoreErrors: [
      'BadRequestException', // class-validator 400s
      'UnauthorizedException', // expired tokens, anonymous browse
      'ForbiddenException', // RBAC denials
      'NotFoundException',
      'ECONNABORTED',
      'AbortError',
    ],
  });
}

// Keys that may contain PII or secrets and must be redacted from any field
// that survives into a Sentry event (extra, contexts, breadcrumbs, etc.).
// Matched case-insensitively. Add new ones here as the schema evolves.
const SENSITIVE_KEYS = new Set(
  [
    'password',
    'token',
    'accesstoken',
    'refreshtoken',
    'authorization',
    'cookie',
    'set-cookie',
    'code',
    'otp',
    'verificationid',
    'phonenumber',
    'phone',
    'email',
    'twofactorsecret',
    'twofactorpendingsecret',
    'twofactorbackupcodes',
    'backupcodes',
    'firebase_private_key',
    'jwt_secret',
    'cloudinary_api_secret',
    'thinkxcloud_api_key',
    'resend_api_key',
  ].map((k) => k.toLowerCase()),
);

// Recursively redact sensitive keys anywhere in the event payload. Mutates
// the object in place and returns it (matches Sentry's beforeSend contract).
function scrub<T extends object>(event: T): T {
  walk(event as unknown as Record<string, unknown>, new WeakSet());
  return event;
}

function walk(node: unknown, seen: WeakSet<object>): void {
  if (node === null || typeof node !== 'object') return;
  if (seen.has(node)) return;
  seen.add(node);

  if (Array.isArray(node)) {
    for (const v of node) walk(v, seen);
    return;
  }

  const obj = node as Record<string, unknown>;
  for (const key of Object.keys(obj)) {
    if (SENSITIVE_KEYS.has(key.toLowerCase())) {
      obj[key] = '[Filtered]';
      continue;
    }
    walk(obj[key], seen);
  }
}
