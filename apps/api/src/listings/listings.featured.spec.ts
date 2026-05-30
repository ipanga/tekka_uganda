import { readFileSync } from 'node:fs';
import { join } from 'node:path';

// Smoke tests for the Featured surface SQL and the admin toggle service
// method. Mirrors the pattern of listings.ranking.spec.ts /
// listings.trending.spec.ts: we can't hit Postgres in unit tests, so we
// scan the service source for the invariants we care about.

const SOURCE = readFileSync(
  join(__dirname, 'listings.service.ts'),
  'utf8',
);

describe('Featured surface', () => {
  it('filters by is_featured = true when featured=true', () => {
    expect(SOURCE).toMatch(/l\.is_featured\s*=\s*true/);
  });

  it('orders featured listings by featured_at DESC NULLS LAST', () => {
    expect(SOURCE).toMatch(
      /l\.featured_at\s+DESC\s+NULLS\s+LAST/i,
    );
  });

  it('routes featured=true through the raw-SQL ranking path', () => {
    // The `search()` router must include query.featured in the condition
    // that dispatches to fullTextSearch — otherwise featured listings would
    // skip the raw-SQL filter/order and silently fall back to Prisma.
    const routerSlice =
      SOURCE.split('async search(')[1]?.split('async ')[0] ?? '';
    expect(routerSlice).toMatch(/query\.featured/);
  });
});

describe('setListingFeatured', () => {
  const fn =
    SOURCE.match(
      /async setListingFeatured\([^)]*\)\s*:\s*Promise<Listing>\s*\{([\s\S]*?)\n  \}/,
    )?.[1] ?? '';

  it('requires the listing to be ACTIVE when promoting', () => {
    expect(fn).toMatch(/listing\.status\s*!==?\s*ListingStatus\.ACTIVE/);
    expect(fn).toMatch(/Only active listings can be featured/);
  });

  it('stamps featuredAt when featured=true and clears it otherwise', () => {
    expect(fn).toMatch(/isFeatured:\s*featured/);
    expect(fn).toMatch(/featuredAt:\s*featured\s*\?\s*new Date\(\)\s*:\s*null/);
  });

  it('logs an admin action with FEATURE_LISTING / UNFEATURE_LISTING', () => {
    expect(fn).toMatch(/FEATURE_LISTING/);
    expect(fn).toMatch(/UNFEATURE_LISTING/);
  });
});
