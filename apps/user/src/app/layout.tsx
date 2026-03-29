import type { Metadata, Viewport } from 'next';
import { Inter } from 'next/font/google';
import './globals.css';
import { AuthProvider } from '@/components/auth/AuthProvider';
import { buildWebsiteJsonLd, SITE_URL } from '@/lib/seo';

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
    default: 'Tekka - Buy & Sell Second-Hand Clothes in Uganda',
    template: '%s | Tekka',
  },
  description:
    'Tekka is Uganda\'s leading marketplace for buying and selling second-hand and new clothes. Find affordable fashion, sell your pre-loved items, and shop locally in Kampala and across Uganda.',
  keywords: [
    'buy used clothes Uganda',
    'sell clothes online Uganda',
    'second-hand clothes Uganda',
    'thrift shopping Uganda',
    'Kampala fashion marketplace',
    'C2C ecommerce Uganda',
    'pre-loved fashion Uganda',
    'affordable clothes Uganda',
    'buy sell fashion Kampala',
    'secondhand marketplace Africa',
  ],
  authors: [{ name: 'Tekka', url: SITE_URL }],
  creator: 'Tekka',
  publisher: 'Tekka',
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
    siteName: 'Tekka',
    title: 'Tekka - Buy & Sell Second-Hand Clothes in Uganda',
    description:
      'Uganda\'s leading marketplace for buying and selling second-hand and new clothes. Shop affordable fashion locally.',
    images: [
      {
        url: '/og-image.png',
        width: 1200,
        height: 630,
        alt: 'Tekka - Uganda\'s Fashion Marketplace',
      },
    ],
  },
  twitter: {
    card: 'summary_large_image',
    title: 'Tekka - Buy & Sell Second-Hand Clothes in Uganda',
    description:
      'Uganda\'s leading marketplace for buying and selling second-hand and new clothes.',
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
  const jsonLd = buildWebsiteJsonLd();

  return (
    <html lang="en">
      <head>
        <script
          type="application/ld+json"
          dangerouslySetInnerHTML={{ __html: JSON.stringify(jsonLd) }}
        />
      </head>
      <body className={`${inter.variable} font-sans antialiased`}>
        <AuthProvider>{children}</AuthProvider>
      </body>
    </html>
  );
}
