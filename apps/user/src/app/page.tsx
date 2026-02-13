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
        <section className="border-b border-[var(--border)] bg-[var(--surface)]">
          <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 py-10 md:py-14">
            <div className="grid grid-cols-1 lg:grid-cols-[1fr_1.15fr] gap-8 items-center">
              <div>
                <p className="text-xs font-semibold uppercase tracking-[0.14em] text-primary-600 dark:text-primary-300">
                  Tekka Pre-Loved Fashion
                </p>
                <h1 className="mt-3 text-4xl md:text-5xl lg:text-[3.35rem] font-bold leading-[1.08] text-gray-900 dark:text-gray-100">
                  Fashion Finds That Feel New, Priced for Real Life
                </h1>
                <p className="mt-4 max-w-lg text-base md:text-lg text-gray-600 dark:text-gray-300">
                  Buy and sell quality second-hand pieces in minutes, with a trusted marketplace built for everyday style.
                </p>
                <div className="mt-7">
                  <Link
                    href="/sell"
                    className="inline-flex items-center justify-center rounded-full bg-primary-500 px-7 py-3 text-sm font-semibold text-white transition hover:bg-primary-600"
                  >
                    Start Selling
                  </Link>
                </div>
              </div>

              <div className="relative">
                <div className="relative overflow-hidden rounded-[1.75rem] border border-[var(--border)] bg-[var(--surface-elevated)]">
                  <Image
                    src="/images/hero-fashion.svg"
                    alt="Second-hand fashion clothing pieces on display"
                    width={960}
                    height={720}
                    priority
                    className="h-auto w-full"
                  />
                </div>
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
