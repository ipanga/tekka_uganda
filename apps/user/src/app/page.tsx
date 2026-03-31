import type { Metadata } from 'next';
import Link from 'next/link';
import HomeClient from '@/components/home/HomeClient';

export const metadata: Metadata = {
  title: 'Tekka Uganda - Buy & Sell Second-Hand Clothes Online',
  description:
    'Buy and sell second-hand clothes in Uganda on Tekka. Affordable fashion in Kampala and across Uganda. List items in minutes, find great deals on pre-loved clothing.',
  alternates: {
    canonical: 'https://tekka.ug',
  },
};

export default function HomePage() {
  return (
    <>
      <HomeClient />
      {/*
        Server-rendered SEO section — always in the DOM for crawlers.
        Visually appears below the fold but provides crawlable text
        that reinforces the meta description and internal links.
      */}
      <section className="bg-gray-50 border-t border-gray-100">
        <div className="max-w-5xl mx-auto px-4 py-16 sm:px-6 lg:px-8">
          <h2 className="text-2xl font-bold text-gray-900 text-center">
            Buy &amp; Sell Second-Hand Clothes in Uganda
          </h2>
          <p className="mt-4 text-gray-600 text-center max-w-2xl mx-auto">
            Tekka is Uganda&apos;s leading online marketplace for second-hand and new
            clothes. Whether you&apos;re looking to refresh your wardrobe affordably or
            earn from items you no longer wear, Tekka makes it simple. Browse thousands
            of listings in Kampala and across Uganda, or list your own items in minutes.
          </p>
          <div className="mt-10 grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-4 gap-6 text-center">
            <Link href="/explore" className="block p-6 bg-white rounded-xl shadow-sm hover:shadow-md transition">
              <h3 className="font-semibold text-gray-900">Browse Clothes</h3>
              <p className="mt-1 text-sm text-gray-500">Discover affordable fashion deals</p>
            </Link>
            <Link href="/sell" className="block p-6 bg-white rounded-xl shadow-sm hover:shadow-md transition">
              <h3 className="font-semibold text-gray-900">Sell Your Clothes</h3>
              <p className="mt-1 text-sm text-gray-500">List items and start earning</p>
            </Link>
            <Link href="/how-to-sell" className="block p-6 bg-white rounded-xl shadow-sm hover:shadow-md transition">
              <h3 className="font-semibold text-gray-900">How It Works</h3>
              <p className="mt-1 text-sm text-gray-500">Step-by-step selling guide</p>
            </Link>
            <Link href="/about" className="block p-6 bg-white rounded-xl shadow-sm hover:shadow-md transition">
              <h3 className="font-semibold text-gray-900">About Tekka</h3>
              <p className="mt-1 text-sm text-gray-500">Our mission for Uganda</p>
            </Link>
          </div>
        </div>
      </section>
    </>
  );
}
