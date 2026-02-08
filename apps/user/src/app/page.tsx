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
        {/* Listings Section */}
        <section id="listings" className="py-12 bg-gray-50">
          <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8">
            <div className="flex items-center justify-between mb-6">
              <h2 className="text-xl font-bold text-gray-900">Just Dropped</h2>
              <Link
                href="/explore"
                className="text-sm font-medium text-pink-600 hover:text-pink-700"
              >
                View all
              </Link>
            </div>

            {loading ? (
              <div className="flex items-center justify-center py-12">
                <div className="h-8 w-8 animate-spin rounded-full border-4 border-pink-600 border-t-transparent" />
              </div>
            ) : listings.length === 0 ? (
              <div className="text-center py-12">
                <p className="text-gray-500">No listings found</p>
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
        <section className="py-12 bg-gradient-to-r from-pink-500 to-rose-500 text-white">
          <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 text-center">
            <h2 className="text-2xl md:text-3xl font-bold mb-3">Ready to Start Selling?</h2>
            <p className="text-pink-100 mb-6 max-w-xl mx-auto text-sm md:text-base">
              Turn your closet into cash. List your first item today.
            </p>
            <Link
              href="/sell"
              className="inline-flex items-center justify-center px-6 py-3 bg-white text-pink-600 font-semibold rounded-full hover:bg-pink-50 transition-colors"
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
          <div className="h-8 w-8 animate-spin rounded-full border-4 border-pink-600 border-t-transparent" />
        </div>
      }
    >
      <HomeContent />
    </Suspense>
  );
}
