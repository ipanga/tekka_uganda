-- Add missing indexes for production query performance

-- FcmToken: Critical for push notification queries (find all tokens for a user)
CREATE INDEX "fcm_tokens_user_id_idx" ON "fcm_tokens"("user_id");

-- Listing: Division filtering
CREATE INDEX "listings_division_id_idx" ON "listings"("division_id");

-- Review: Lookup reviews given by a specific user
CREATE INDEX "reviews_reviewer_id_idx" ON "reviews"("reviewer_id");
