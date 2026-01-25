-- Create a GIN index for full-text search on listings (title, description, brand)
CREATE INDEX IF NOT EXISTS listings_fulltext_search_idx
ON listings
USING GIN (
  to_tsvector('english', COALESCE(title, '') || ' ' || COALESCE(description, '') || ' ' || COALESCE(brand, ''))
);
