'use client';

import { useState, useEffect, Suspense } from 'react';
import Link from 'next/link';
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
        <section className="relative overflow-hidden bg-gradient-to-br from-primary-500 via-primary-600 to-primary-800 dark:from-primary-900 dark:via-primary-800 dark:to-gray-900">
          <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 py-16 md:py-24">
            <div className="grid grid-cols-1 md:grid-cols-2 gap-8 items-center">
              <div className="text-white">
                <h1 className="text-4xl md:text-5xl lg:text-6xl font-bold leading-tight">
                  Uganda&apos;s Fashion{' '}
                  <span className="block text-primary-200">Marketplace</span>
                </h1>
                <p className="mt-4 text-lg text-primary-100 max-w-lg">
                  Buy and sell pre-loved fashion with confidence. Join thousands of fashion lovers across Uganda.
                </p>
                <div className="mt-8 flex flex-col sm:flex-row gap-4">
                  <Link
                    href="/explore"
                    className="inline-flex items-center justify-center px-8 py-3.5 bg-white text-primary-600 font-semibold rounded-full hover:bg-primary-50 transition-colors shadow-lg"
                  >
                    Start Shopping
                  </Link>
                  <Link
                    href="/sell"
                    className="inline-flex items-center justify-center px-8 py-3.5 border-2 border-white/30 text-white font-semibold rounded-full hover:bg-white/10 transition-colors"
                  >
                    Sell Your Fashion
                  </Link>
                </div>
              </div>
              <div className="hidden md:flex justify-center">
                <div className="grid grid-cols-2 gap-4 opacity-20">
                  {[...Array(6)].map((_, i) => (
                    <div
                      key={i}
                      className={`rounded-2xl bg-white/20 ${
                        i % 3 === 0 ? 'h-32 w-32' : i % 3 === 1 ? 'h-40 w-32' : 'h-28 w-32'
                      }`}
                    />
                  ))}
                </div>
              </div>
            </div>
          </div>
          {/* Wave bottom edge */}
          <div className="absolute bottom-0 left-0 right-0">
            <svg viewBox="0 0 1440 60" fill="none" xmlns="http://www.w3.org/2000/svg" className="w-full">
              <path
                d="M0 60V30C240 0 480 0 720 30C960 60 1200 60 1440 30V60H0Z"
                className="fill-gray-50 dark:fill-gray-900"
              />
            </svg>
          </div>
        </section>

        {/* Listings Section */}
        <section id="listings" className="py-12 bg-gray-50 dark:bg-gray-900">
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

        {/* CTA Section */}
        <section className="py-12 bg-gradient-to-r from-primary-500 to-primary-600 text-white">
          <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 text-center">
            <h2 className="text-2xl md:text-3xl font-bold mb-3">Ready to Start Selling?</h2>
            <p className="text-primary-100 mb-6 max-w-xl mx-auto text-sm md:text-base">
              Turn your closet into cash. List your first item today.
            </p>
            <Link
              href="/sell"
              className="inline-flex items-center justify-center px-6 py-3 bg-white text-primary-500 font-semibold rounded-full hover:bg-primary-50 transition-colors"
            >
              Start Selling Now
            </Link>
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
