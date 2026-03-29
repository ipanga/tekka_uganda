import type { Metadata } from 'next';
import { redirect, notFound } from 'next/navigation';
import { getListingById, getListingBySlug } from '@/lib/api-server';
import { getListingUrl, buildMetadata, buildProductJsonLd, buildBreadcrumbJsonLd, absoluteUrl } from '@/lib/seo';
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
  const description = listing.description
    ? `${listing.description.slice(0, 155)}...`
    : `Buy ${listing.title} on Tekka - Uganda's fashion marketplace. ${listing.condition === 'NEW' ? 'Brand new' : 'Pre-loved'} item available in Uganda.`;

  const categoryName = listing.categoryData?.name || 'Fashion';

  return buildMetadata({
    title: `${listing.title} - ${categoryName} for Sale`,
    description,
    path: listingPath,
    image: listing.imageUrls?.[0],
  });
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

  const categoryName = listing.categoryData?.name || 'Fashion';
  const breadcrumbItems = [
    { name: 'Home', url: '/' },
    { name: categoryName, url: listing.categoryId ? `/explore?categoryId=${listing.categoryId}` : '/explore' },
    { name: listing.title, url: getListingUrl(listing as any) },
  ];
  const breadcrumbJsonLd = buildBreadcrumbJsonLd(breadcrumbItems);

  return (
    <>
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
