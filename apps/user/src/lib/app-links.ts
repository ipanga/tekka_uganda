export const APP_STORE_URL =
  'https://apps.apple.com/ug/app/tekka-uganda/id6759387476';
export const PLAY_STORE_URL =
  'https://play.google.com/store/apps/details?id=com.tootiye.tekka';
export const IOS_APP_ID = '6759387476';
export const ANDROID_PACKAGE = 'com.tootiye.tekka';

export type MobilePlatform = 'ios' | 'android' | null;

export function detectMobilePlatform(userAgent?: string): MobilePlatform {
  const ua = userAgent ?? (typeof navigator !== 'undefined' ? navigator.userAgent : '');
  if (!ua) return null;
  if (/iPad|iPhone|iPod/.test(ua)) return 'ios';
  if (/Android/i.test(ua)) return 'android';
  return null;
}

export function getStoreUrl(platform: MobilePlatform): string | null {
  if (platform === 'ios') return APP_STORE_URL;
  if (platform === 'android') return PLAY_STORE_URL;
  return null;
}

// Official store badges (matched 3.375:1 SVGs so App Store and Google Play
// render at equal width for a given height — the official assets straight from
// Apple/Google have different proportions). Shared by the footer and the /app
// download page; hrefs reuse the canonical store URLs above so there is a
// single source of truth.
export const STORE_BADGES = [
  {
    name: 'App Store',
    href: APP_STORE_URL,
    src: '/images/store-badges/app-store.svg',
    alt: 'Download on the App Store',
    aria: 'Download Tekka Uganda on the App Store',
    width: 135,
    height: 40,
  },
  {
    name: 'Google Play',
    href: PLAY_STORE_URL,
    src: '/images/store-badges/google-play.svg',
    alt: 'Get it on Google Play',
    aria: 'Get Tekka Uganda on Google Play',
    width: 135,
    height: 40,
  },
] as const;
