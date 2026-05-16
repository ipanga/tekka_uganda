import type { Metadata } from 'next';
import { getListingHref } from './utils';

const SITE_URL = process.env.NEXT_PUBLIC_SITE_URL || 'https://tekka.ug';
const SITE_NAME = 'Tekka Uganda';

/**
 * Generate a listing URL from its data.
 * Delegates to the shared getListingHref in utils.ts.
 */
export const getListingUrl = getListingHref;

/**
 * Generate full absolute URL for a path.
 */
export function absoluteUrl(path: string): string {
  return `${SITE_URL}${path.startsWith('/') ? path : `/${path}`}`;
}

/**
 * For og:image / twitter:image. WhatsApp/FB/X cards want a landscape image
 * (1.91:1) and WhatsApp specifically rejects portrait images even when small.
 * Raw listing uploads are usually portrait (e.g. 800×1000 phone photos).
 * Insert a Cloudinary transformation that:
 *   - c_fill,g_auto: center-fill, content-aware gravity (keeps the garment in frame)
 *   - w_1200,h_630: canonical OG dimensions
 *   - q_auto: Cloudinary picks optimal quality for the dimensions
 *   - f_jpg: force JPEG so scrapers without webp/avif support work
 *
 * Non-Cloudinary URLs pass through unchanged.
 */
export function ogImage(url: string): string {
  if (!url || !url.includes('res.cloudinary.com/') || !url.includes('/upload/')) {
    return url;
  }
  // Avoid double-transform if already present.
  if (/\/upload\/[^/]*c_fill/.test(url)) return url;
  return url.replace('/upload/', '/upload/c_fill,g_auto,w_1200,h_630,q_auto,f_jpg/');
}

function shouldProxySocialImage(url: string): boolean {
  try {
    const parsed = new URL(url);
    return parsed.protocol === 'https:' && parsed.hostname === 'res.cloudinary.com';
  } catch {
    return false;
  }
}

/**
 * WhatsApp is more reliable when the preview image is served from the same
 * origin as the shared URL. Keep Cloudinary transformations, then expose them
 * through a guarded same-domain proxy.
 */
export function socialImageUrl(url: string): string {
  const transformed = ogImage(url);

  if (!transformed) return transformed;
  if (transformed.startsWith('/')) return absoluteUrl(transformed);
  if (shouldProxySocialImage(transformed)) {
    return absoluteUrl(`/api/og-image?src=${encodeURIComponent(transformed)}`);
  }

  return transformed;
}

/**
 * Build page metadata with sensible defaults and OG/Twitter tags.
 */
export function buildMetadata({
  title,
  description,
  path = '/',
  image,
  type = 'website',
  noIndex = false,
}: {
  title: string;
  description: string;
  path?: string;
  image?: string;
  type?: 'website' | 'article';
  noIndex?: boolean;
}): Metadata {
  const url = absoluteUrl(path);
  // Let the root layout template append "| Tekka Uganda" — don't duplicate it here
  const ogTitle = title.includes('Tekka') ? title : `${title} | Tekka Uganda`;
  const previewImage = image ? socialImageUrl(image) : undefined;

  return {
    title,
    description,
    alternates: {
      canonical: url,
    },
    openGraph: {
      title: ogTitle,
      description,
      url,
      siteName: SITE_NAME,
      type,
      locale: 'en_UG',
      ...(previewImage && {
        images: [
          {
            url: previewImage,
            width: 1200,
            height: 630,
            alt: title,
          },
        ],
      }),
    },
    twitter: {
      card: previewImage ? 'summary_large_image' : 'summary',
      title: ogTitle,
      description,
      ...(previewImage && { images: [previewImage] }),
    },
    ...(noIndex && { robots: { index: false, follow: false } }),
  };
}

/**
 * JSON-LD structured data for a product listing.
 */
export function buildProductJsonLd(listing: {
  title: string;
  description: string;
  price: number;
  imageUrls: string[];
  condition: string;
  status: string;
  slug?: string;
  seller?: { displayName?: string } | null;
  categoryData?: { name?: string; slug?: string; parent?: { slug?: string; parent?: { slug?: string } } } | null;
}) {
  const conditionMap: Record<string, string> = {
    NEW: 'https://schema.org/NewCondition',
    USED: 'https://schema.org/UsedCondition',
  };

  const url = absoluteUrl(getListingUrl(listing as any));

  return {
    '@context': 'https://schema.org',
    '@type': 'Product',
    name: listing.title,
    description: listing.description,
    image: listing.imageUrls,
    url,
    brand: listing.seller?.displayName
      ? { '@type': 'Person', name: listing.seller.displayName }
      : undefined,
    category: listing.categoryData?.name,
    offers: {
      '@type': 'Offer',
      price: listing.price,
      priceCurrency: 'UGX',
      availability:
        listing.status === 'ACTIVE'
          ? 'https://schema.org/InStock'
          : listing.status === 'SOLD'
            ? 'https://schema.org/SoldOut'
            : 'https://schema.org/OutOfStock',
      itemCondition: conditionMap[listing.condition] || 'https://schema.org/UsedCondition',
      seller: listing.seller?.displayName
        ? { '@type': 'Person', name: listing.seller.displayName }
        : undefined,
    },
  };
}

/**
 * JSON-LD for BreadcrumbList structured data.
 */
export function buildBreadcrumbJsonLd(
  items: { name: string; url: string }[],
) {
  return {
    '@context': 'https://schema.org',
    '@type': 'BreadcrumbList',
    itemListElement: items.map((item, index) => ({
      '@type': 'ListItem',
      position: index + 1,
      name: item.name,
      item: absoluteUrl(item.url),
    })),
  };
}

/**
 * JSON-LD for the Tekka website (WebSite schema for sitelinks search).
 */
export function buildWebsiteJsonLd() {
  return {
    '@context': 'https://schema.org',
    '@type': 'WebSite',
    name: SITE_NAME,
    alternateName: 'Tekka',
    url: SITE_URL,
    description: 'Buy and sell second-hand clothes in Uganda. Tekka is Uganda\'s leading C2C fashion marketplace.',
    potentialAction: {
      '@type': 'SearchAction',
      target: {
        '@type': 'EntryPoint',
        urlTemplate: `${SITE_URL}/explore?search={search_term_string}`,
      },
      'query-input': 'required name=search_term_string',
    },
  };
}

/**
 * JSON-LD Organization schema for Google Knowledge Panel and rich results.
 */
export function buildOrganizationJsonLd() {
  return {
    '@context': 'https://schema.org',
    '@type': 'Organization',
    name: SITE_NAME,
    alternateName: 'Tekka',
    url: SITE_URL,
    logo: `${SITE_URL}/icon-512.png`,
    description: 'Uganda\'s leading marketplace for buying and selling second-hand and new clothes. Affordable fashion in Kampala and across Uganda.',
    foundingDate: '2025',
    areaServed: {
      '@type': 'Country',
      name: 'Uganda',
    },
    sameAs: [],
    contactPoint: {
      '@type': 'ContactPoint',
      contactType: 'customer service',
      url: `${SITE_URL}/contact`,
      availableLanguage: 'English',
    },
  };
}

export { SITE_URL, SITE_NAME };
