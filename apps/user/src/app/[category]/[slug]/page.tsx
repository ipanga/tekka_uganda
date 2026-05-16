import type { Metadata } from 'next';
import { notFound } from 'next/navigation';
import { getListingBySlug } from '@/lib/api-server';
import {
  getListingUrl,
  buildMetadata,
  buildProductJsonLd,
  buildBreadcrumbJsonLd,
  buildProductOgTags,
} from '@/lib/seo';
import ListingDetailClient from '@/components/listings/ListingDetailClient';

// ISR: emit a cacheable `s-maxage` header so social-card crawlers (Facebook in
// particular) can cache the parsed OG metadata. Without this, Next.js 16 marks
// the route dynamic and sends `Cache-Control: private, no-cache, no-store`,
// which makes FB's scraper refuse to persist og_object even on a 200 response.
// `generateStaticParams` returning `[]` is required alongside `revalidate` —
// without it Next.js classifies the route as `ƒ` (Dynamic SSR) and ignores the
// revalidate hint entirely.
export const revalidate = 300;
export const dynamicParams = true;
export function generateStaticParams() {
  return [];
}

interface PageProps {
  params: Promise<{ category: string; slug: string }>;
}

export async function generateMetadata({ params }: PageProps): Promise<Metadata> {
  const { slug } = await params;
  const listing = await getListingBySlug(slug);

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
  const indexable = listing.status === 'ACTIVE' || listing.status === 'SOLD';

  // openGraph + product:* tags are rendered as JSX in the page component (not
  // here) because Next.js 16 rejects og:type=product. See buildProductOgTags.
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
  const { slug } = await params;
  const listing = await getListingBySlug(slug);

  if (!listing) {
    notFound();
  }

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
      {/*
        og:type=website is required for Facebook. FB silently rejects og:type
        values it does not register (it dropped first-class `product` support
        years ago) and falls back to `type=website` with every other OG field
        nulled out — so a `product` value broke FB previews entirely while
        looking fine in curl. The `product:*` tags below are kept because
        Pinterest, Slack, and some other crawlers still consume them.
      */}
      <meta property="og:type" content="website" />
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
