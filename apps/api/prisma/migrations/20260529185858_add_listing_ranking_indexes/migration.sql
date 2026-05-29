-- Indexes supporting the new relevance ranking path (LISTING_RANK_SCORE_SQL
-- in listings.service.ts). Both are CREATE INDEX IF NOT EXISTS so re-runs
-- and partial deploys are safe.

-- Composite index for the dominant "active listings, newest first" filter.
-- Covers the common path where Postgres has to seek into the status='ACTIVE'
-- slice and then walk in created_at order — both for the legacy createdAt
-- sort and for the relevance tie-breaker (ORDER BY score DESC, created_at DESC).
CREATE INDEX IF NOT EXISTS "listings_status_created_at_idx"
  ON "listings" ("status", "created_at" DESC);

-- Partial index covering the engagement signals used in the relevance score.
-- Only active listings participate in ranking, so a partial index keeps the
-- structure small. Includes both counters so Postgres can satisfy the score's
-- ln(view_count) + ln(save_count) lookups from the index when filtering.
CREATE INDEX IF NOT EXISTS "listings_active_engagement_idx"
  ON "listings" ("view_count" DESC, "save_count" DESC)
  WHERE "status" = 'ACTIVE';
