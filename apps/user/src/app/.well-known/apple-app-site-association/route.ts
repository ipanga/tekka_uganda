import { NextResponse } from 'next/server';

const APPLE_APP_ID_PREFIX = 'YK6Z393A4D';
const BUNDLE_ID = 'com.tootiyesolutions.tekka';

const aasa = {
  applinks: {
    details: [
      {
        appIDs: [`${APPLE_APP_ID_PREFIX}.${BUNDLE_ID}`],
        components: [
          { '/': '/listing/*' },
          { '/': '/chat/*' },
          { '/': '/user/*' },
          { '/': '/reviews/*' },
          { '/': '/notifications' },
          { '/': '/notifications/*' },
          { '/': '/profile' },
          { '/': '/profile/*' },
          { '/': '/meetups' },
          { '/': '/meetups/*' },
        ],
      },
    ],
  },
};

export function GET() {
  return NextResponse.json(aasa, {
    headers: {
      'Content-Type': 'application/json',
      'Cache-Control': 'public, max-age=3600',
    },
  });
}
