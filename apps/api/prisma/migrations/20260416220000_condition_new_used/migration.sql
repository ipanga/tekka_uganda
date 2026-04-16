-- Collapse ItemCondition from {NEW, LIKE_NEW, GOOD, FAIR} to {NEW, USED}.
-- Data mapping:
--   NEW, LIKE_NEW        -> NEW
--   GOOD, FAIR           -> USED

-- Step 1: create the target enum
CREATE TYPE "ItemCondition_new" AS ENUM ('NEW', 'USED');

-- Step 2: migrate the listings.condition column with a CASE map
ALTER TABLE "listings"
  ALTER COLUMN "condition" TYPE "ItemCondition_new"
  USING (
    CASE "condition"::text
      WHEN 'NEW'      THEN 'NEW'::"ItemCondition_new"
      WHEN 'LIKE_NEW' THEN 'NEW'::"ItemCondition_new"
      WHEN 'GOOD'     THEN 'USED'::"ItemCondition_new"
      WHEN 'FAIR'     THEN 'USED'::"ItemCondition_new"
    END
  );

-- Step 3: swap the type in place
DROP TYPE "ItemCondition";
ALTER TYPE "ItemCondition_new" RENAME TO "ItemCondition";

-- Step 4: normalize any legacy values in the free-text saved_searches.condition column
UPDATE "saved_searches" SET "condition" = 'NEW'  WHERE "condition" IN ('LIKE_NEW');
UPDATE "saved_searches" SET "condition" = 'USED' WHERE "condition" IN ('GOOD', 'FAIR');
