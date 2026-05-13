import type { Metadata } from 'next';
import { getListingHref } from './utils';

const SITE_URL = process.env.NEXT_PUBLIC_SITE_URL || 'https://tekka.ug';
const SITE_NAME = 'Tekka Uganda';
const TWITTER_HANDLE = '@tekkauganda';

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
 * Build page metadata with sensible defaults and OG/Twitter tags.
 *
 * Next.js 16 validates `openGraph.type` against a preset list (website, article,
 * book, profile, music.*, video.*) and rejects others — including 'product'.
 * For product pages, pass `type: 'product'` here to SUPPRESS Next.js's
 * openGraph emission, then render the og:* and product:* tags from the page
 * component as JSX <meta property="..."> (see buildProductOgTags below).
 */
export function buildMetadata({
  title,
  description,
  path = '/',
  image,
  images,
  type = 'website',
  noIndex = false,
}: {
  title: string;
  description: string;
  path?: string;
  image?: string;
  images?: string[];
  type?: 'website' | 'article' | 'product';
  noIndex?: boolean;
}): Metadata {
  const url = absoluteUrl(path);
  // Let the root layout template append "| Tekka Uganda" — don't duplicate it here
  const ogTitle = title.includes('Tekka') ? title : `${title} | Tekka Uganda`;

  const allImages = (images && images.length > 0 ? images : image ? [image] : []).filter(Boolean);

  // For product pages, openGraph is rendered as JSX by the page component
  // because Next.js's openGraph API rejects og:type=product. Setting it to
  // null here opts out of inheriting the root layout's site-wide openGraph
  // (Next.js's metadata-interface.d.ts: `openGraph?: null | OpenGraph`).
  const openGraph: Metadata['openGraph'] =
    type === 'product'
      ? null
      : {
          title: ogTitle,
          description,
          url,
          siteName: SITE_NAME,
          type,
          locale: 'en_UG',
          ...(allImages.length && {
            images: allImages.map((url) => ({
              url,
              width: 1200,
              height: 630,
              alt: title,
            })),
          }),
        };

  return {
    title,
    description,
    alternates: {
      canonical: url,
    },
    openGraph,
    twitter: {
      card: allImages.length ? 'summary_large_image' : 'summary',
      site: TWITTER_HANDLE,
      creator: TWITTER_HANDLE,
      title: ogTitle,
      description,
      ...(allImages.length && { images: allImages }),
    },
    ...(noIndex && { robots: { index: false, follow: false } }),
  };
}

/**
 * Open Graph tags for a product page, rendered as JSX <meta property="...">.
 * Used in place of Next.js's openGraph config because Next.js rejects
 * og:type=product. Render at the top of the page component's returned tree
 * so the tags land in <head>.
 */
export function buildProductOgTags(opts: {
  title: string;
  description: string;
  path: string;
  images: string[];
  price: number | string;
  currency: string;
  availability: 'instock' | 'oos' | 'pending';
  condition: 'new' | 'used' | 'refurbished';
}) {
  const url = absoluteUrl(opts.path);
  const ogTitle = opts.title.includes('Tekka') ? opts.title : `${opts.title} | Tekka Uganda`;
  return {
    url,
    ogTitle,
    description: opts.description,
    siteName: SITE_NAME,
    images: opts.images.filter(Boolean),
    price: String(opts.price),
    currency: opts.currency,
    availability: opts.availability,
    condition: opts.condition,
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
    sameAs: [
      'https://www.facebook.com/tekkauganda',
      'https://www.instagram.com/tekkauganda',
      'https://x.com/tekkauganda',
      'https://www.threads.net/@tekkauganda',
      'https://www.tiktok.com/@tekkauganda',
    ],
    contactPoint: {
      '@type': 'ContactPoint',
      contactType: 'customer service',
      url: `${SITE_URL}/contact`,
      availableLanguage: 'English',
    },
  };
}

export { SITE_URL, SITE_NAME };
