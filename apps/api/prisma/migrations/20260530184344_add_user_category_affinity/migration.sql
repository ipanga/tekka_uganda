-- Per-(user, category) affinity counter for PR5a tracking. PR5b's "For You"
-- ranking reads from this table. All operations are CREATE on a brand-new
-- table — no ALTER on hot tables, fully online, no row-level locks on
-- existing data.

CREATE TABLE "user_category_affinities" (
    "id" TEXT NOT NULL,
    "user_id" TEXT NOT NULL,
    "category_id" TEXT NOT NULL,
    "weight" DOUBLE PRECISION NOT NULL DEFAULT 0,
    "event_count" INTEGER NOT NULL DEFAULT 0,
    "last_seen_at" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "created_at" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updated_at" TIMESTAMP(3) NOT NULL,

    CONSTRAINT "user_category_affinities_pkey" PRIMARY KEY ("id")
);

-- Unique index that the service's upsert keys on.
CREATE UNIQUE INDEX "user_category_affinities_user_id_category_id_key"
    ON "user_category_affinities"("user_id", "category_id");

-- Read-path index for PR5b: "get this user's top categories by weight".
CREATE INDEX "user_category_affinities_user_id_weight_idx"
    ON "user_category_affinities"("user_id", "weight" DESC);

-- Foreign keys cascade on user/category delete so the affinity rows go
-- away with their parents (account deletion, category removal).
ALTER TABLE "user_category_affinities"
    ADD CONSTRAINT "user_category_affinities_user_id_fkey"
    FOREIGN KEY ("user_id") REFERENCES "users"("id")
    ON DELETE CASCADE ON UPDATE CASCADE;

ALTER TABLE "user_category_affinities"
    ADD CONSTRAINT "user_category_affinities_category_id_fkey"
    FOREIGN KEY ("category_id") REFERENCES "categories"("id")
    ON DELETE CASCADE ON UPDATE CASCADE;
