-- Add public_id storage alongside existing URL columns so Cloudinary deletes
-- don't depend on URL regex parsing. Also wires the missing CASCADE FK on
-- identity_verifications so user deletes propagate.

-- AlterTable: users
ALTER TABLE "users" ADD COLUMN "photo_public_id" TEXT;

-- AlterTable: listings
ALTER TABLE "listings" ADD COLUMN "image_public_ids" TEXT[] DEFAULT ARRAY[]::TEXT[];

-- AlterTable: messages
ALTER TABLE "messages" ADD COLUMN "image_public_id" TEXT;

-- AlterTable: identity_verifications
ALTER TABLE "identity_verifications" ADD COLUMN "front_image_public_id" TEXT;
ALTER TABLE "identity_verifications" ADD COLUMN "back_image_public_id" TEXT;
ALTER TABLE "identity_verifications" ADD COLUMN "selfie_public_id" TEXT;

-- Remove orphaned identity_verifications rows so the new FK can be added cleanly.
DELETE FROM "identity_verifications"
WHERE "user_id" NOT IN (SELECT "id" FROM "users");

-- AddForeignKey: identity_verifications.user_id -> users.id (CASCADE)
ALTER TABLE "identity_verifications"
ADD CONSTRAINT "identity_verifications_user_id_fkey"
FOREIGN KEY ("user_id") REFERENCES "users"("id")
ON DELETE CASCADE ON UPDATE CASCADE;
