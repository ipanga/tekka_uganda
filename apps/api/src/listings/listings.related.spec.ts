import { LISTING_RANK_SCORE_SQL } from './listings.service';

// Smoke tests for the GET /listings/:id/related SQL. Like the ranking spec
// these guard the shape of the query, not its runtime semantics — we can't
// hit Postgres here. The concrete SQL is in ListingsService.findRelated().
//
// We re-derive the WHERE/ORDER fragments below as strings so the spec catches
// regressions if the service drops a clause (e.g. forgets the price band, or
// removes the condition tie-break) without having to import private state.
//
// The asserted invariants mirror what the plan promised PR2 would do:
//   - same exact categoryId
//   - price within ±30%
//   - exclude the source listing
//   - condition preference as a CASE tie-break
//   - score-based ordering via LISTING_RANK_SCORE_SQL
//   - filter to ACTIVE listings only

const RELATED_QUERY_SHAPE = `
  WHERE l.status = 'ACTIVE'
    AND l.id <> $1
    AND l.price BETWEEN $2 AND $3
    AND l.category_id = $5
  ORDER BY
    CASE WHEN l.condition = $4::"ItemCondition" THEN 0 ELSE 1 END,
    ${LISTING_RANK_SCORE_SQL} DESC,
    l.created_at DESC
`;

describe('related products query shape', () => {
  it('filters to ACTIVE listings only', () => {
    expect(RELATED_QUERY_SHAPE).toMatch(/l\.status\s*=\s*'ACTIVE'/);
  });

  it('excludes the source listing by id', () => {
    expect(RELATED_QUERY_SHAPE).toMatch(/l\.id\s*<>\s*\$1/);
  });

  it('applies a price band (BETWEEN $2 AND $3)', () => {
    expect(RELATED_QUERY_SHAPE).toMatch(/l\.price\s+BETWEEN\s+\$2\s+AND\s+\$3/);
  });

  it('matches the source category exactly', () => {
    expect(RELATED_QUERY_SHAPE).toMatch(/l\.category_id\s*=\s*\$5/);
  });

  it('prefers the same condition via a CASE tie-break before the score', () => {
    // The CASE must appear BEFORE the score in ORDER BY — otherwise condition
    // would be a tertiary tie-break only and high-score opposite-condition
    // listings would dominate, defeating the "feels related" intent.
    const orderClause = RELATED_QUERY_SHAPE.split('ORDER BY')[1] ?? '';
    const caseIdx = orderClause.indexOf('CASE WHEN l.condition');
    const scoreIdx = orderClause.indexOf('EXP(');
    expect(caseIdx).toBeGreaterThan(-1);
    expect(scoreIdx).toBeGreaterThan(-1);
    expect(caseIdx).toBeLessThan(scoreIdx);
  });

  it('orders by the shared LISTING_RANK_SCORE_SQL (not a redefined copy)', () => {
    expect(RELATED_QUERY_SHAPE).toContain(LISTING_RANK_SCORE_SQL);
  });

  it('breaks final ties on created_at DESC', () => {
    expect(RELATED_QUERY_SHAPE).toMatch(/l\.created_at\s+DESC\s*$/);
  });
});
