-- AlterTable: Add slug column (nullable initially for backfill)
ALTER TABLE "listings" ADD COLUMN "slug" TEXT;

-- Backfill: Generate slugs for existing listings from title
-- Uses lower(title), replaces non-alphanumeric with hyphens, appends short id suffix
UPDATE "listings"
SET "slug" = CONCAT(
  LEFT(
    REGEXP_REPLACE(
      REGEXP_REPLACE(
        LOWER(TRIM(title)),
        '[^a-z0-9\s-]', '', 'g'
      ),
      '\s+', '-', 'g'
    ),
    80
  ),
  '-',
  LEFT(id, 8)
)
WHERE "slug" IS NULL;

-- Handle any potential duplicates by appending more of the id
UPDATE "listings" l1
SET "slug" = CONCAT(l1."slug", '-', RIGHT(l1.id, 4))
WHERE EXISTS (
  SELECT 1 FROM "listings" l2
  WHERE l2."slug" = l1."slug" AND l2.id != l1.id
);

-- Now make slug NOT NULL and UNIQUE
ALTER TABLE "listings" ALTER COLUMN "slug" SET NOT NULL;

-- CreateIndex
CREATE UNIQUE INDEX "listings_slug_key" ON "listings"("slug");

-- CreateIndex
CREATE INDEX "listings_slug_idx" ON "listings"("slug");
