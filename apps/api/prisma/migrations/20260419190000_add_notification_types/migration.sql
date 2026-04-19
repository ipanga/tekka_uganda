-- Add dedicated NotificationType enum values for listing suspensions and
-- meetup lifecycle transitions. Previously:
--   * sendListingSuspended reused LISTING_REJECTED, muddying analytics and
--     in-app history.
--   * Meetup decline/cancel/no-show fired SYSTEM, so buildDeepLink routed
--     users to /notifications instead of /meetups/:id.
--
-- Additive only — existing rows stay as-is. `ALTER TYPE ... ADD VALUE` on
-- Postgres cannot run inside a transaction with other statements, so each
-- value gets its own statement.
ALTER TYPE "NotificationType" ADD VALUE IF NOT EXISTS 'LISTING_SUSPENDED';
ALTER TYPE "NotificationType" ADD VALUE IF NOT EXISTS 'MEETUP_DECLINED';
ALTER TYPE "NotificationType" ADD VALUE IF NOT EXISTS 'MEETUP_CANCELLED';
ALTER TYPE "NotificationType" ADD VALUE IF NOT EXISTS 'MEETUP_NO_SHOW';
