import type { MetadataRoute } from 'next';
import { getActiveListings, getCategories } from '@/lib/api-server';
import { getListingUrl } from '@/lib/seo';

const SITE_URL = process.env.NEXT_PUBLIC_SITE_URL || 'https://tekka.ug';

export default async function sitemap(): Promise<MetadataRoute.Sitemap> {
  const entries: MetadataRoute.Sitemap = [];

  // Static pages
  const staticPages = [
    { path: '/', priority: 1.0, changeFrequency: 'daily' as const },
    { path: '/explore', priority: 0.9, changeFrequency: 'daily' as const },
    { path: '/login', priority: 0.3, changeFrequency: 'yearly' as const },
    { path: '/register', priority: 0.3, changeFrequency: 'yearly' as const },
    { path: '/help', priority: 0.5, changeFrequency: 'monthly' as const },
    { path: '/faq', priority: 0.5, changeFrequency: 'monthly' as const },
    { path: '/safety', priority: 0.5, changeFrequency: 'monthly' as const },
    { path: '/terms', priority: 0.3, changeFrequency: 'yearly' as const },
    { path: '/privacy', priority: 0.3, changeFrequency: 'yearly' as const },
    { path: '/account-deletion', priority: 0.3, changeFrequency: 'yearly' as const },
    { path: '/cookies', priority: 0.2, changeFrequency: 'yearly' as const },
    { path: '/contact', priority: 0.4, changeFrequency: 'monthly' as const },
    { path: '/about', priority: 0.6, changeFrequency: 'monthly' as const },
    { path: '/how-to-sell', priority: 0.7, changeFrequency: 'monthly' as const },
    { path: '/buy-second-hand-clothes', priority: 0.7, changeFrequency: 'monthly' as const },
  ];

  for (const page of staticPages) {
    entries.push({
      url: `${SITE_URL}${page.path}`,
      lastModified: new Date(),
      changeFrequency: page.changeFrequency,
      priority: page.priority,
    });
  }

  // Category pages
  try {
    const categories = await getCategories();
    if (categories) {
      const flatCategories = flattenCategories(categories);
      for (const cat of flatCategories) {
        entries.push({
          url: `${SITE_URL}/explore?categoryId=${cat.id}`,
          lastModified: new Date(),
          changeFrequency: 'daily',
          priority: 0.7,
        });
      }
    }
  } catch {
    // Continue without categories
  }

  // Active listing pages (paginate through all)
  try {
    let page = 1;
    const limit = 500;
    let hasMore = true;

    while (hasMore && page <= 20) {
      const result = await getActiveListings(page, limit);
      if (!result || result.data.length === 0) break;

      for (const listing of result.data) {
        const listingPath = getListingUrl(listing as any);
        entries.push({
          url: `${SITE_URL}${listingPath}`,
          lastModified: new Date(listing.updatedAt || listing.createdAt),
          changeFrequency: 'weekly',
          priority: 0.8,
        });
      }

      hasMore = page < result.totalPages;
      page++;
    }
  } catch {
    // Continue without listings
  }

  return entries;
}

function flattenCategories(
  categories: { id: string; children?: { id: string; children?: { id: string }[] }[] }[],
): { id: string }[] {
  const result: { id: string }[] = [];
  for (const cat of categories) {
    result.push({ id: cat.id });
    if (cat.children) {
      for (const sub of cat.children) {
        result.push({ id: sub.id });
        if (sub.children) {
          for (const child of sub.children) {
            result.push({ id: child.id });
          }
        }
      }
    }
  }
  return result;
}
