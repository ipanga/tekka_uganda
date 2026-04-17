export const APP_STORE_URL = 'https://apps.apple.com/ug/app/tekka/id6759387476';
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
