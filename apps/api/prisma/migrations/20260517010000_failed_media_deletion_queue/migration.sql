-- Retry queue for Cloudinary deletes. Populated by the upload service when
-- a destroy() call fails; drained by an hourly cron. After 5 failed
-- attempts the row is left for manual review.

CREATE TABLE "failed_media_deletions" (
    "id" TEXT NOT NULL,
    "public_id" TEXT,
    "url" TEXT,
    "attempt_count" INTEGER NOT NULL DEFAULT 0,
    "last_error" TEXT,
    "created_at" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "last_attempt_at" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "failed_media_deletions_pkey" PRIMARY KEY ("id")
);

CREATE INDEX "failed_media_deletions_attempt_count_idx" ON "failed_media_deletions"("attempt_count");
CREATE INDEX "failed_media_deletions_last_attempt_at_idx" ON "failed_media_deletions"("last_attempt_at");
