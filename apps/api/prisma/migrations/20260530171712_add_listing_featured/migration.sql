-- Admin-curated "Featured" surface on the home page (PR4 of the ranking
-- rollout). is_featured marks a listing as currently promoted; featured_at
-- records when it was promoted so admins can sort by recency.

ALTER TABLE "listings"
  ADD COLUMN IF NOT EXISTS "is_featured" BOOLEAN NOT NULL DEFAULT false,
  ADD COLUMN IF NOT EXISTS "featured_at" TIMESTAMP(3);

-- Partial index supporting the dominant Featured query: list current
-- featured listings ordered by promotion time. Only featured rows
-- participate, keeping the index small.
CREATE INDEX IF NOT EXISTS "listings_featured_at_idx"
  ON "listings" ("featured_at" DESC)
  WHERE "is_featured" = true;
