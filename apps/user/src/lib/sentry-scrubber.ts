/**
 * PII scrubber for Sentry events. Walks every event recursively and
 * replaces values for known-sensitive keys with `'[Filtered]'`. Same
 * key list as the backend (`apps/api/src/instrument.ts`) — keep them
 * in lockstep when new sensitive fields are added.
 */

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
  ].map((k) => k.toLowerCase()),
);

export function scrubEvent<T extends object>(event: T): T {
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
