import type { Metadata } from 'next';
import Image from 'next/image';
import { Header } from '@/components/layout/Header';
import { Footer } from '@/components/layout/Footer';
import { buildMetadata } from '@/lib/seo';
import { STORE_BADGES } from '@/lib/app-links';
import { AppRedirect } from './AppRedirect';

export const metadata: Metadata = buildMetadata({
  title: 'Download the Tekka App',
  description:
    'Get the Tekka Uganda app for iPhone and Android. Buy and sell second-hand clothes faster with push notifications, in-app chat and a smoother browsing experience.',
  path: '/app',
});

const BENEFITS = [
  {
    title: 'Instant chat & push notifications',
    body: 'Message buyers and sellers in real time and never miss an offer.',
  },
  {
    title: 'Faster browsing',
    body: 'A smoother, app-native experience for discovering and saving items.',
  },
  {
    title: 'Sell in minutes',
    body: 'Snap photos and list items straight from your phone.',
  },
];

export default function AppDownloadPage() {
  return (
    <div className="min-h-screen flex flex-col">
      {/* Mobile visitors are redirected to their app store from here; desktop
          visitors and crawlers see the page below. */}
      <AppRedirect />
      <Header />
      <main className="flex-1">
        <section className="bg-gradient-to-b from-primary-50 to-white">
          <div className="max-w-5xl mx-auto px-4 py-16 sm:py-20">
            <div className="grid items-center gap-12 lg:grid-cols-2">
              {/* Left: copy + store buttons */}
              <div>
                <Image
                  src="/icon-192.png"
                  alt="Tekka Uganda app icon"
                  width={72}
                  height={72}
                  className="rounded-2xl shadow-sm"
                  unoptimized
                />
                <h1 className="mt-6 text-3xl sm:text-4xl font-extrabold tracking-tight text-gray-900">
                  Get the Tekka Uganda app
                </h1>
                <p className="mt-4 text-lg text-gray-600">
                  Buy and sell pre-loved fashion across Uganda. Download the app
                  for the fastest, most reliable Tekka experience.
                </p>

                <div className="mt-8 flex flex-wrap items-center gap-4">
                  {STORE_BADGES.map((b) => (
                    <a
                      key={b.name}
                      href={b.href}
                      target="_blank"
                      rel="noopener noreferrer"
                      aria-label={b.aria}
                      className="inline-flex transition-opacity hover:opacity-80 focus:outline-none focus-visible:ring-2 focus-visible:ring-primary-500 focus-visible:ring-offset-2 rounded"
                    >
                      {/* Plain <img>: tiny static brand assets — next/image's
                          pipeline adds a runtime fetch + LQIP for no gain. */}
                      {/* eslint-disable-next-line @next/next/no-img-element */}
                      <img
                        src={b.src}
                        alt={b.alt}
                        width={b.width}
                        height={b.height}
                        className="h-12 w-auto"
                      />
                    </a>
                  ))}
                </div>
              </div>

              {/* Right: scan-to-open QR (most useful on desktop) */}
              <div className="flex justify-center lg:justify-end">
                <div className="rounded-2xl border border-gray-200 bg-white p-6 text-center shadow-sm">
                  <Image
                    src="/images/app-qr.svg"
                    alt="QR code linking to the Tekka app download page"
                    width={200}
                    height={200}
                    className="mx-auto h-48 w-48"
                    unoptimized
                  />
                  <p className="mt-4 max-w-[12rem] text-sm text-gray-600">
                    On a computer? Scan with your phone&apos;s camera to open the
                    app store.
                  </p>
                </div>
              </div>
            </div>

            {/* Benefits */}
            <div className="mt-16 grid gap-6 sm:grid-cols-3">
              {BENEFITS.map((benefit) => (
                <div
                  key={benefit.title}
                  className="rounded-xl border border-gray-200 bg-white p-6 shadow-sm"
                >
                  <h2 className="font-semibold text-gray-900">{benefit.title}</h2>
                  <p className="mt-2 text-sm text-gray-600">{benefit.body}</p>
                </div>
              ))}
            </div>
          </div>
        </section>
      </main>
      <Footer />
    </div>
  );
}
