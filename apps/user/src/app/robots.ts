import type { MetadataRoute } from 'next';

export default function robots(): MetadataRoute.Robots {
  const siteUrl = process.env.NEXT_PUBLIC_SITE_URL || 'https://tekka.ug';

  return {
    rules: [
      {
        userAgent: '*',
        allow: '/',
        disallow: [
          '/api/',
          '/messages/',
          '/profile/edit',
          '/profile/verify-email',
          '/settings/',
          '/my-listings/',
          '/sell/',
          '/saved/',
          '/saved-searches/',
          '/price-alerts/',
          '/notifications/',
        ],
      },
    ],
    sitemap: `${siteUrl}/sitemap.xml`,
  };
}
