import { LISTING_RANK_SCORE_SQL } from './listings.service';

// Smoke tests for the listing relevance score SQL fragment. We can't run
// real Postgres in this unit test, but we can guard against the most common
// regressions: someone accidentally drops a component, introduces a
// placeholder, or breaks the parenthesization that lets the expression
// drop into an ORDER BY.
describe('LISTING_RANK_SCORE_SQL', () => {
  it('is wrapped in parens so it can be inlined into ORDER BY / arithmetic', () => {
    expect(LISTING_RANK_SCORE_SQL.trim().startsWith('(')).toBe(true);
    expect(LISTING_RANK_SCORE_SQL.trim().endsWith(')')).toBe(true);
  });

  it('contains the freshness component (exp decay on created_at)', () => {
    expect(LISTING_RANK_SCORE_SQL).toMatch(/EXP\(/);
    expect(LISTING_RANK_SCORE_SQL).toMatch(/l\.created_at/);
    // 604800 = 60*60*24*7 seconds — the 1-week decay constant
    expect(LISTING_RANK_SCORE_SQL).toMatch(/604800/);
  });

  it('contains the engagement component (log of view + save counters)', () => {
    expect(LISTING_RANK_SCORE_SQL).toMatch(/LN\(GREATEST\(l\.view_count/);
    expect(LISTING_RANK_SCORE_SQL).toMatch(/LN\(GREATEST\(l\.save_count/);
  });

  it('weights saves more heavily than views', () => {
    // Engagement weights are tuned in the file; if the relationship inverts
    // it's almost certainly a typo. Saves are higher-intent than views.
    const viewMatch = LISTING_RANK_SCORE_SQL.match(
      /([\d.]+)\s*\*\s*LN\(GREATEST\(l\.view_count/,
    );
    const saveMatch = LISTING_RANK_SCORE_SQL.match(
      /([\d.]+)\s*\*\s*LN\(GREATEST\(l\.save_count/,
    );
    expect(viewMatch).not.toBeNull();
    expect(saveMatch).not.toBeNull();
    const viewWeight = Number(viewMatch![1]);
    const saveWeight = Number(saveMatch![1]);
    expect(saveWeight).toBeGreaterThan(viewWeight);
  });

  it('contains the listing-quality component (photos, description, attributes)', () => {
    expect(LISTING_RANK_SCORE_SQL).toMatch(/array_length\(l\.image_urls/);
    expect(LISTING_RANK_SCORE_SQL).toMatch(/LENGTH\(COALESCE\(l\.description/);
    expect(LISTING_RANK_SCORE_SQL).toMatch(/l\.attributes/);
    expect(LISTING_RANK_SCORE_SQL).toMatch(/jsonb_typeof/);
  });

  it('contains no parameter placeholders ($1, $2, ...)', () => {
    // The score is meant to be inlined into a query alongside other params;
    // a stray placeholder here would shift the param index of the host
    // query and silently corrupt searches.
    expect(LISTING_RANK_SCORE_SQL).not.toMatch(/\$\d+/);
  });

  it('contains no semicolons (must be safely embeddable)', () => {
    expect(LISTING_RANK_SCORE_SQL).not.toContain(';');
  });
});
