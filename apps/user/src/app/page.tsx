'use client';

import { useState, useEffect, Suspense } from 'react';
import Link from 'next/link';
import Image from 'next/image';
import { Header } from '@/components/layout/Header';
import { CategoryNav } from '@/components/layout/CategoryNav';
import { Footer } from '@/components/layout/Footer';
import { ListingCard } from '@/components/listings/ListingCard';
import { api } from '@/lib/api';
import type { Listing, PaginatedResponse } from '@/types';

function HomeContent() {
  const [listings, setListings] = useState<Listing[]>([]);
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    async function loadListings() {
      try {
        const params = new URLSearchParams();
        params.append('status', 'ACTIVE');
        params.append('limit', '24');
        params.append('sortBy', 'createdAt');
        params.append('sortOrder', 'desc');

        const response = await api.get<PaginatedResponse<Listing> & { listings?: Listing[] }>(`/listings?${params}`);
        setListings(response?.data || response?.listings || []);
      } catch (error) {
        console.error('Failed to fetch listings:', error);
        setListings([]);
      } finally {
        setLoading(false);
      }
    }
    loadListings();
  }, []);

  return (
    <div className="min-h-screen flex flex-col">
      <Header />
      <CategoryNav />

      <main className="flex-1">
        {/* Hero Section */}
        <section className="relative h-[280px] sm:h-[340px] md:h-[400px] lg:h-[440px] overflow-hidden">
          <Image
            src="/images/hero-bg.jpg"
            alt="Woman browsing fashion clothing on a rack"
            fill
            priority
            sizes="100vw"
            className="object-cover object-[70%_30%] sm:object-center"
          />
          {/* Subtle gradient for depth on the left */}
          <div className="absolute inset-0 bg-gradient-to-r from-black/35 via-black/15 to-transparent" />

          {/* Left-aligned floating card */}
          <div className="absolute inset-0 flex items-end sm:items-center justify-start">
            <div className="px-4 sm:px-6 lg:px-10 xl:px-16 pb-5 sm:pb-0">
              <div className="bg-black/50 backdrop-blur-md rounded-2xl px-5 py-5 sm:px-7 sm:py-6 max-w-[22rem]">
                <h1 className="text-2xl sm:text-[1.7rem] font-extrabold leading-snug tracking-tight text-white">
                  Ready to refresh your wardrobe?
                </h1>
                <p className="mt-2.5 text-[0.835rem] leading-relaxed text-white/90">
                  Give your clothes a second life and earn from what you no longer wear.
                </p>
                <Link
                  href="/sell"
                  className="mt-5 flex items-center justify-center rounded-lg bg-primary-500 px-6 py-2.5 text-sm font-semibold text-white transition hover:bg-primary-600"
                >
                  Sell now
                </Link>
                <Link
                  href="/explore"
                  className="mt-2.5 block text-center text-[0.8rem] font-medium text-white/80 hover:text-white transition"
                >
                  Explore items
                </Link>
              </div>
            </div>
          </div>
        </section>

        {/* Listings Section */}
        <section id="listings" className="py-12 bg-[var(--background)]">
          <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8">
            <div className="flex items-center justify-between mb-6">
              <h2 className="text-xl font-bold text-gray-900 dark:text-gray-100">Just Dropped</h2>
              <Link
                href="/explore"
                className="text-sm font-medium text-primary-500 dark:text-primary-300 hover:text-primary-600 dark:hover:text-primary-200"
              >
                View all
              </Link>
            </div>

            {loading ? (
              <div className="flex items-center justify-center py-12">
                <div className="h-8 w-8 animate-spin rounded-full border-4 border-primary-500 dark:border-primary-400 border-t-transparent" />
              </div>
            ) : listings.length === 0 ? (
              <div className="text-center py-12">
                <p className="text-gray-500 dark:text-gray-400">No listings found</p>
              </div>
            ) : (
              <div className="grid grid-cols-2 md:grid-cols-3 lg:grid-cols-4 gap-4">
                {listings.map((listing) => (
                  <ListingCard key={listing.id} listing={listing} />
                ))}
              </div>
            )}
          </div>
        </section>

      </main>

      <Footer />
    </div>
  );
}

export default function HomePage() {
  return (
    <Suspense
      fallback={
        <div className="min-h-screen flex items-center justify-center">
          <div className="h-8 w-8 animate-spin rounded-full border-4 border-primary-500 dark:border-primary-400 border-t-transparent" />
        </div>
      }
    >
      <HomeContent />
    </Suspense>
  );
}
