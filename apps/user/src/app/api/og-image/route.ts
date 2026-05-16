const ALLOWED_IMAGE_HOSTS = new Set([
  'res.cloudinary.com',
  'firebasestorage.googleapis.com',
]);

const MAX_IMAGE_BYTES = 8 * 1024 * 1024;
const CACHE_CONTROL = 'public, max-age=86400, s-maxage=86400, stale-while-revalidate=604800';

function parseAllowedImageUrl(rawSrc: string | null): URL | null {
  if (!rawSrc) return null;

  try {
    const url = new URL(rawSrc);
    if (url.protocol !== 'https:') return null;
    if (!ALLOWED_IMAGE_HOSTS.has(url.hostname)) return null;
    return url;
  } catch {
    return null;
  }
}

export async function GET(request: Request) {
  const requestUrl = new URL(request.url);
  const imageUrl = parseAllowedImageUrl(requestUrl.searchParams.get('src'));

  if (!imageUrl) {
    return new Response('Invalid image source', { status: 400 });
  }

  const upstream = await fetch(imageUrl, {
    headers: {
      Accept: 'image/jpeg,image/png,image/webp,image/*;q=0.8',
      'User-Agent': 'TekkaSocialImageProxy/1.0',
    },
    next: { revalidate: 86400 },
  });

  if (!upstream.ok) {
    return new Response('Image unavailable', { status: 502 });
  }

  const contentType = upstream.headers.get('content-type') || 'image/jpeg';
  if (!contentType.toLowerCase().startsWith('image/')) {
    return new Response('Unsupported image response', { status: 502 });
  }

  const contentLength = Number(upstream.headers.get('content-length') || 0);
  if (contentLength > MAX_IMAGE_BYTES) {
    return new Response('Image too large', { status: 413 });
  }

  const body = await upstream.arrayBuffer();
  if (body.byteLength > MAX_IMAGE_BYTES) {
    return new Response('Image too large', { status: 413 });
  }

  return new Response(body, {
    headers: {
      'Cache-Control': CACHE_CONTROL,
      'Content-Type': contentType,
      'Content-Length': String(body.byteLength),
      'X-Content-Type-Options': 'nosniff',
    },
  });
}
