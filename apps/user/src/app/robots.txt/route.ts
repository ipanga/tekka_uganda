// Hand-rolled robots.txt route. The Next.js `robots.ts` metadata convention
// strips empty `Disallow:` values, but Facebook's crawler follows the 1994
// robots.txt spec (no `Allow:` directive) and needs an explicit empty
// `Disallow:` line to recognise a User-agent group as "crawl everything".
// See https://developers.facebook.com/docs/sharing/webmasters/web-crawlers

const SOCIAL_CRAWLERS = [
  'facebookexternalhit',
  'Facebot',
  'Twitterbot',
  'LinkedInBot',
  'WhatsApp',
  'TelegramBot',
  'Discordbot',
  'Slackbot',
  'Slackbot-LinkExpanding',
  'Applebot',
  'Pinterestbot',
];

const PRIVATE_PATHS = [
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
];

export function GET() {
  const siteUrl = process.env.NEXT_PUBLIC_SITE_URL || 'https://tekka.ug';

  // Emit one record per UA (rather than stacking many `User-agent` lines under
  // a single `Disallow:`). Same intent per the 1994 spec, but FB's parser has
  // been observed to mishandle the stacked syntax — a sister site's identical
  // 403 cleared the day we split it into per-UA blocks.
  const socialBlock = SOCIAL_CRAWLERS.map((ua) =>
    [`User-agent: ${ua}`, 'Disallow:'].join('\n'),
  ).join('\n\n');

  const defaultBlock = [
    'User-agent: *',
    ...PRIVATE_PATHS.map((path) => `Disallow: ${path}`),
  ].join('\n');

  const body = [socialBlock, defaultBlock, `Sitemap: ${siteUrl}/sitemap.xml`].join('\n\n') + '\n';

  return new Response(body, {
    headers: {
      'Content-Type': 'text/plain; charset=utf-8',
      'Cache-Control': 'public, max-age=3600, s-maxage=3600',
    },
  });
}
