import {
  LISTING_RANK_SCORE_SQL,
  LISTING_TRENDING_SCORE_SQL,
} from './listings.service';

// Smoke tests for the trending score SQL. Same approach as
// listings.ranking.spec.ts — we cannot run real Postgres in unit tests, so
// we guard the most regression-prone properties of the SQL expression.
//
// The trending score must:
//   - keep the same shape (parenthesized, no semicolons, no placeholders)
//     so it can drop into ORDER BY and multiply with ts_rank,
//   - have a *shorter* time-decay window than the relevance score (so newer
//     items dominate within the 7-day filter),
//   - have *heavier* engagement weights than relevance (so saves drive
//     trending), with saves still weighted more than views,
//   - keep the same listing-quality terms so a polished listing isn't
//     penalized on the trending surface.

function weight(sql: string, column: string): number {
  const m = sql.match(
    new RegExp(`([\\d.]+)\\s*\\*\\s*LN\\(GREATEST\\(l\\.${column}`),
  );
  if (!m) throw new Error(`weight for ${column} not found`);
  return Number(m[1]);
}

function decayDivisor(sql: string): number {
  // EXP(-... / DIVISOR) — pull the divisor out so we can compare windows.
  const m = sql.match(/EXP\(-[^)]+\)\s*\/\s*([\d.]+)\)/);
  if (!m) {
    // Fallback for the format used in the file (divisor directly inside the
    // EXP argument with the - already applied).
    const m2 = sql.match(/EXP\(-[^/]+\/\s*([\d.]+)\)/);
    if (!m2) throw new Error('decay divisor not found');
    return Number(m2[1]);
  }
  return Number(m[1]);
}

describe('LISTING_TRENDING_SCORE_SQL', () => {
  it('is wrapped in parens (embeddable in ORDER BY / arithmetic)', () => {
    expect(LISTING_TRENDING_SCORE_SQL.trim().startsWith('(')).toBe(true);
    expect(LISTING_TRENDING_SCORE_SQL.trim().endsWith(')')).toBe(true);
  });

  it('contains the freshness, engagement, and quality components', () => {
    expect(LISTING_TRENDING_SCORE_SQL).toMatch(/EXP\(/);
    expect(LISTING_TRENDING_SCORE_SQL).toMatch(/l\.created_at/);
    expect(LISTING_TRENDING_SCORE_SQL).toMatch(/LN\(GREATEST\(l\.view_count/);
    expect(LISTING_TRENDING_SCORE_SQL).toMatch(/LN\(GREATEST\(l\.save_count/);
    expect(LISTING_TRENDING_SCORE_SQL).toMatch(/array_length\(l\.image_urls/);
    expect(LISTING_TRENDING_SCORE_SQL).toMatch(
      /LENGTH\(COALESCE\(l\.description/,
    );
    expect(LISTING_TRENDING_SCORE_SQL).toMatch(/jsonb_typeof/);
  });

  it('weights saves more heavily than views', () => {
    expect(weight(LISTING_TRENDING_SCORE_SQL, 'save_count')).toBeGreaterThan(
      weight(LISTING_TRENDING_SCORE_SQL, 'view_count'),
    );
  });

  it('has heavier engagement weights than the relevance score', () => {
    // The whole point of the trending surface: saves and views matter much
    // more than in the default browse ranking.
    expect(weight(LISTING_TRENDING_SCORE_SQL, 'view_count')).toBeGreaterThan(
      weight(LISTING_RANK_SCORE_SQL, 'view_count'),
    );
    expect(weight(LISTING_TRENDING_SCORE_SQL, 'save_count')).toBeGreaterThan(
      weight(LISTING_RANK_SCORE_SQL, 'save_count'),
    );
  });

  it('uses a shorter time-decay window than the relevance score', () => {
    // Smaller divisor = faster decay = newer items pull further ahead.
    expect(decayDivisor(LISTING_TRENDING_SCORE_SQL)).toBeLessThan(
      decayDivisor(LISTING_RANK_SCORE_SQL),
    );
  });

  it('contains no parameter placeholders or semicolons', () => {
    expect(LISTING_TRENDING_SCORE_SQL).not.toMatch(/\$\d+/);
    expect(LISTING_TRENDING_SCORE_SQL).not.toContain(';');
  });
});
