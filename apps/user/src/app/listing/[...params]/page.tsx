import { permanentRedirect, notFound } from 'next/navigation';
import { getListingById, getListingBySlug } from '@/lib/api-server';
import { getListingUrl } from '@/lib/seo';

interface PageProps {
  params: Promise<{ params: string[] }>;
  searchParams: Promise<Record<string, string | string[] | undefined>>;
}

// All `/listing/*` URLs now 308-redirect to the canonical `/<category>/<slug>`
// route. Kept solely for backward compatibility with indexed pages, shared
// social links, FCM deep-link payloads, and existing universal/App Link
// patterns in the .well-known files.
//
// - /listing/<cat>/<slug>  → /<cat>/<slug>          (no DB hit)
// - /listing/<idOrSlug>    → look up, then redirect to canonical
export default async function LegacyListingRedirect({ params, searchParams }: PageProps) {
  const { params: segments } = await params;
  const sp = await searchParams;

  const qs = new URLSearchParams();
  for (const [k, v] of Object.entries(sp)) {
    if (Array.isArray(v)) v.forEach((item) => qs.append(k, item));
    else if (v !== undefined) qs.set(k, v);
  }
  const queryString = qs.toString() ? `?${qs.toString()}` : '';

  if (segments.length === 2) {
    const [category, slug] = segments;
    permanentRedirect(`/${encodeURIComponent(category)}/${encodeURIComponent(slug)}${queryString}`);
  }

  if (segments.length === 1) {
    const [idOrSlug] = segments;
    const listing =
      (await getListingById(idOrSlug)) ?? (await getListingBySlug(idOrSlug));
    if (listing?.slug) {
      permanentRedirect(`${getListingUrl(listing as any)}${queryString}`);
    }
  }

  notFound();
}
