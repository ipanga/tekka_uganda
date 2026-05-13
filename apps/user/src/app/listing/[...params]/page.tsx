import type { Metadata } from 'next';
import { redirect, notFound } from 'next/navigation';
import { getListingById, getListingBySlug } from '@/lib/api-server';
import {
  getListingUrl,
  buildMetadata,
  buildProductJsonLd,
  buildBreadcrumbJsonLd,
  buildProductOgTags,
} from '@/lib/seo';
import ListingDetailClient from '@/components/listings/ListingDetailClient';

interface PageProps {
  params: Promise<{ params: string[] }>;
}

/**
 * Determine how to fetch the listing based on URL structure:
 * - /listing/{id}                → Legacy ID route (redirect to SEO URL)
 * - /listing/{categorySlug}/{slug} → SEO-friendly route (render)
 */
async function resolveListing(segments: string[]) {
  if (segments.length === 2) {
    // SEO-friendly: /listing/{categorySlug}/{slug}
    const [, slug] = segments;
    const listing = await getListingBySlug(slug);
    return { listing, isLegacy: false };
  }

  if (segments.length === 1) {
    // Legacy: /listing/{id}
    const [idOrSlug] = segments;
    // Try as ID first
    const listing = await getListingById(idOrSlug);
    if (listing) return { listing, isLegacy: true };
    // Try as slug fallback
    const bySlug = await getListingBySlug(idOrSlug);
    return { listing: bySlug, isLegacy: !!bySlug };
  }

  return { listing: null, isLegacy: false };
}

export async function generateMetadata({ params }: PageProps): Promise<Metadata> {
  const { params: segments } = await params;
  const { listing } = await resolveListing(segments);

  if (!listing) {
    return buildMetadata({
      title: 'Listing Not Found',
      description: 'This listing may have been removed or is no longer available on Tekka.',
      noIndex: true,
    });
  }

  const listingPath = getListingUrl(listing as any);
  const title = (listing.title || '').trim() || 'Listing';
  const rawDesc = (listing.description || '').trim();
  const description = rawDesc
    ? rawDesc.length > 155
      ? `${rawDesc.slice(0, 155)}…`
      : rawDesc
    : `Buy ${title} on Tekka — Uganda's fashion marketplace. ${listing.condition === 'NEW' ? 'Brand new' : 'Pre-loved'} item available in Uganda.`;

  const categoryName = listing.categoryData?.name || 'Fashion';

  // Only public-facing statuses should be indexed by search engines
  const indexable = listing.status === 'ACTIVE' || listing.status === 'SOLD';

  // openGraph + product:* tags are rendered as JSX in the page component (not
  // here) because Next.js 16 rejects og:type=product. See buildProductOgTags.
  // We still pass `images` so the Twitter card picks up the product photo.
  return buildMetadata({
    title: `${title} - ${categoryName} for Sale`,
    description,
    path: listingPath,
    images: listing.imageUrls,
    type: 'product',
    noIndex: !indexable,
  });
}

function availabilityFor(status: string): 'instock' | 'oos' | 'pending' {
  switch (status) {
    case 'ACTIVE':
      return 'instock';
    case 'PENDING':
    case 'DRAFT':
      return 'pending';
    default:
      return 'oos';
  }
}

export default async function ListingPage({ params }: PageProps) {
  const { params: segments } = await params;
  const { listing, isLegacy } = await resolveListing(segments);

  if (!listing) {
    notFound();
  }

  // Redirect legacy ID URLs to SEO-friendly URLs
  if (isLegacy && listing.slug) {
    const seoUrl = getListingUrl(listing as any);
    redirect(seoUrl);
  }

  // Build JSON-LD structured data
  const productJsonLd = buildProductJsonLd(listing as any);

  const cat = listing.categoryData as any;
  const L1 = cat?.parent?.parent || cat?.parent;
  const L2 = cat?.parent?.parent ? cat?.parent : null;
  const breadcrumbItems: { name: string; url: string }[] = [
    { name: 'Home', url: '/' },
  ];
  if (L1) breadcrumbItems.push({ name: L1.name, url: `/explore?categoryId=${L1.id}` });
  if (L2) breadcrumbItems.push({ name: L2.name, url: `/explore?categoryId=${L2.id}` });
  if (!L1 && cat) breadcrumbItems.push({ name: cat.name, url: `/explore?categoryId=${cat.id}` });
  breadcrumbItems.push({ name: listing.title, url: getListingUrl(listing as any) });
  const breadcrumbJsonLd = buildBreadcrumbJsonLd(breadcrumbItems);

  // Build OG tags for this product. Rendered as JSX below so we can emit
  // og:type=product, which Next.js's openGraph config doesn't allow.
  const title = (listing.title || '').trim() || 'Listing';
  const categoryName = listing.categoryData?.name || 'Fashion';
  const rawDesc = (listing.description || '').trim();
  const ogDescription = rawDesc
    ? rawDesc.length > 155
      ? `${rawDesc.slice(0, 155)}…`
      : rawDesc
    : `Buy ${title} on Tekka — Uganda's fashion marketplace. ${listing.condition === 'NEW' ? 'Brand new' : 'Pre-loved'} item available in Uganda.`;

  const og = buildProductOgTags({
    title: `${title} - ${categoryName} for Sale`,
    description: ogDescription,
    path: getListingUrl(listing as any),
    images: listing.imageUrls || [],
    price: listing.price,
    currency: 'UGX',
    availability: availabilityFor(listing.status),
    condition: listing.condition === 'NEW' ? 'new' : 'used',
  });

  return (
    <>
      {/* Open Graph (product type — rendered here instead of via Next.js
          openGraph config, which rejects og:type=product) */}
      <meta property="og:type" content="product" />
      <meta property="og:title" content={og.ogTitle} />
      <meta property="og:description" content={og.description} />
      <meta property="og:url" content={og.url} />
      <meta property="og:site_name" content={og.siteName} />
      <meta property="og:locale" content="en_UG" />
      {og.images.map((img) => (
        <meta key={img} property="og:image" content={img} />
      ))}
      {og.images.length > 0 && (
        <>
          <meta property="og:image:width" content="1200" />
          <meta property="og:image:height" content="630" />
          <meta property="og:image:alt" content={`${title} - ${categoryName} for Sale`} />
        </>
      )}
      <meta property="product:price:amount" content={og.price} />
      <meta property="product:price:currency" content={og.currency} />
      <meta property="product:availability" content={og.availability} />
      <meta property="product:condition" content={og.condition} />

      <script
        type="application/ld+json"
        dangerouslySetInnerHTML={{ __html: JSON.stringify(productJsonLd) }}
      />
      <script
        type="application/ld+json"
        dangerouslySetInnerHTML={{ __html: JSON.stringify(breadcrumbJsonLd) }}
      />
      <ListingDetailClient listingId={listing.id} />
    </>
  );
}
