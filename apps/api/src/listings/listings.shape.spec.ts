import { readFileSync } from 'node:fs';
import { join } from 'node:path';

// Regression guard for the raw-SQL response normalization blocks in
// ListingsService.
//
// Both `fullTextSearch()` (used for sortBy=relevance and keyword search) and
// `findRelated()` (used for /listings/:id/related) explicitly enumerate the
// fields they hand back to the client. The legacy Prisma-path response
// includes every Listing column by default; the raw-SQL paths only include
// what's listed. Any field omitted from those blocks silently disappears
// from the wire — that's how `slug` and `imagePublicIds` drift was first
// noticed in PR1, breaking slug-based card URLs on the user dashboard.
//
// Rather than mock Postgres, this spec scans the source for both blocks
// and asserts that every load-bearing field is mapped. If you add a field
// to the Prisma schema and serve it via these endpoints, add it here too.

const SERVICE_PATH = join(__dirname, 'listings.service.ts');
const SOURCE = readFileSync(SERVICE_PATH, 'utf8');

// Fields the client app depends on regardless of which sort path served
// the row. Anything in this list MUST appear in BOTH raw-SQL normalization
// blocks (the search/relevance one inside fullTextSearch, and the one
// inside findRelated).
const REQUIRED_FIELD_MAPPINGS: ReadonlyArray<readonly [string, string]> = [
  ['id', 'row.id'],
  ['sellerId', 'row.seller_id'],
  ['title', 'row.title'],
  ['slug', 'row.slug'],
  ['description', 'row.description'],
  ['price', 'row.price'],
  ['categoryId', 'row.category_id'],
  ['imageUrls', 'row.image_urls'],
  ['imagePublicIds', 'row.image_public_ids'],
  ['condition', 'row.condition'],
  ['status', 'row.status'],
  ['createdAt', 'row.created_at'],
  ['updatedAt', 'row.updated_at'],
  ['seller', 'row.seller'],
  ['categoryData', 'row.category_data'],
];

function extractBlock(after: string, until: string): string {
  const start = SOURCE.indexOf(after);
  if (start < 0) throw new Error(`anchor not found: ${after}`);
  const end = SOURCE.indexOf(until, start);
  if (end < 0) throw new Error(`terminator not found: ${until} after ${after}`);
  return SOURCE.slice(start, end);
}

describe('raw-SQL listing normalization', () => {
  const searchBlock = extractBlock(
    'const normalizedListings = listings.map((row) => ({',
    '}));',
  );
  const relatedBlock = extractBlock(
    'const normalized = rows.map((row) => ({',
    '}));',
  );

  describe.each([
    ['fullTextSearch normalization', searchBlock],
    ['findRelated normalization', relatedBlock],
  ])('%s', (_name, block) => {
    it.each(REQUIRED_FIELD_MAPPINGS)('maps %s -> %s', (key, source) => {
      // Looking for `key: source` with flexible whitespace.
      const re = new RegExp(
        `\\b${key}\\s*:\\s*${source.replace(/\./g, '\\.')}\\b`,
      );
      expect(block).toMatch(re);
    });
  });
});
