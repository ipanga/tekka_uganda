-- AlterTable
ALTER TABLE "users" ADD COLUMN     "is_phone_verified" BOOLEAN NOT NULL DEFAULT false,
ADD COLUMN     "last_login_at" TIMESTAMP(3),
ALTER COLUMN "firebase_uid" DROP NOT NULL;
