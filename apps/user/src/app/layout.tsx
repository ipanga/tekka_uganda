import type { Metadata, Viewport } from 'next';
import { Inter } from 'next/font/google';
import './globals.css';
import { AuthProvider } from '@/components/auth/AuthProvider';
import OfflineBanner from '@/components/layout/OfflineBanner';
import SmartAppBanner from '@/components/layout/SmartAppBanner';
import { buildWebsiteJsonLd, buildOrganizationJsonLd, SITE_URL } from '@/lib/seo';
import { IOS_APP_ID } from '@/lib/app-links';

const inter = Inter({
  variable: '--font-sans',
  subsets: ['latin'],
});

export const viewport: Viewport = {
  width: 'device-width',
  initialScale: 1,
  themeColor: '#E53E3E',
};

export const metadata: Metadata = {
  metadataBase: new URL(SITE_URL),
  title: {
    default: 'Tekka Uganda - Buy & Sell Second-Hand Clothes Online',
    template: '%s | Tekka Uganda',
  },
  description:
    'Buy and sell second-hand clothes in Uganda on Tekka. Affordable fashion in Kampala and across Uganda. List items in minutes, find great deals on pre-loved clothing.',
  keywords: [
    'buy used clothes Uganda',
    'sell clothes online Uganda',
    'second-hand clothes Uganda',
    'thrift shopping Uganda',
    'Kampala fashion marketplace',
    'pre-loved fashion Uganda',
    'affordable clothes Uganda',
    'buy sell fashion Kampala',
    'Uganda online marketplace',
    'secondhand marketplace Africa',
  ],
  authors: [{ name: 'Tekka Uganda', url: SITE_URL }],
  creator: 'Tekka Uganda',
  publisher: 'Tekka Uganda',
  icons: {
    icon: [
      { url: '/favicon.ico', sizes: '48x48' },
      { url: '/icon-192.png', sizes: '192x192', type: 'image/png' },
      { url: '/icon-512.png', sizes: '512x512', type: 'image/png' },
    ],
    apple: [{ url: '/apple-touch-icon.png', sizes: '180x180' }],
  },
  openGraph: {
    type: 'website',
    locale: 'en_UG',
    url: SITE_URL,
    siteName: 'Tekka Uganda',
    title: 'Tekka Uganda - Buy & Sell Second-Hand Clothes Online',
    description:
      'Buy and sell second-hand clothes in Uganda on Tekka. Affordable fashion in Kampala and across Uganda.',
    images: [
      {
        url: '/og-image.png',
        width: 1200,
        height: 630,
        alt: 'Tekka Uganda - Buy & Sell Second-Hand Clothes',
      },
    ],
  },
  twitter: {
    card: 'summary_large_image',
    title: 'Tekka Uganda - Buy & Sell Second-Hand Clothes Online',
    description:
      'Buy and sell second-hand clothes in Uganda on Tekka. Affordable fashion in Kampala and across Uganda.',
    images: ['/og-image.png'],
  },
  robots: {
    index: true,
    follow: true,
    googleBot: {
      index: true,
      follow: true,
      'max-video-preview': -1,
      'max-image-preview': 'large',
      'max-snippet': -1,
    },
  },
  alternates: {
    canonical: SITE_URL,
  },
};

export default function RootLayout({
  children,
}: Readonly<{
  children: React.ReactNode;
}>) {
  const websiteJsonLd = buildWebsiteJsonLd();
  const orgJsonLd = buildOrganizationJsonLd();

  return (
    <html lang="en">
      <head>
        <meta name="apple-itunes-app" content={`app-id=${IOS_APP_ID}`} />
        <script
          type="application/ld+json"
          dangerouslySetInnerHTML={{ __html: JSON.stringify(websiteJsonLd) }}
        />
        <script
          type="application/ld+json"
          dangerouslySetInnerHTML={{ __html: JSON.stringify(orgJsonLd) }}
        />
      </head>
      <body className={`${inter.variable} font-sans antialiased`}>
        <OfflineBanner />
        <SmartAppBanner />
        <AuthProvider>{children}</AuthProvider>
      </body>
    </html>
  );
}
