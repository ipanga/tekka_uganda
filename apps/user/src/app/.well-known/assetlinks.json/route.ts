import { NextResponse } from 'next/server';

// NOTE: If the SHA-256 below is the upload key, Play Store installs will not
// auto-verify App Links. Add the Play App Signing key fingerprint as a second
// entry in `sha256_cert_fingerprints` (Play Console → App integrity).
const ANDROID_PACKAGE = 'com.tootiye.tekka';
const SHA256_FINGERPRINTS = [
  '6A:F2:3F:C2:BF:91:CC:9E:80:AA:0F:EE:39:74:DA:50:56:14:81:25:F0:22:29:E1:5C:6A:A3:6D:E9:2A:26:0A',
];

const assetlinks = [
  {
    relation: ['delegate_permission/common.handle_all_urls'],
    target: {
      namespace: 'android_app',
      package_name: ANDROID_PACKAGE,
      sha256_cert_fingerprints: SHA256_FINGERPRINTS,
    },
  },
];

export function GET() {
  return NextResponse.json(assetlinks, {
    headers: {
      'Content-Type': 'application/json',
      'Cache-Control': 'public, max-age=3600',
    },
  });
}
