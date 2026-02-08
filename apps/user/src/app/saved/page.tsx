'use client';

import { useState, useEffect } from 'react';
import { useRouter } from 'next/navigation';
import { api } from '@/lib/api';
import { Listing } from '@/types';
import Header from '@/components/layout/Header';
import Footer from '@/components/layout/Footer';
import { PageLoader } from '@/components/ui/Spinner';
import { NoSavedItemsEmptyState } from '@/components/ui/EmptyState';
import { ListingCard } from '@/components/listings/ListingCard';
import { useAuthStore } from '@/stores/authStore';

export default function SavedItemsPage() {
  const router = useRouter();
  const { isAuthenticated, isLoading: authLoading } = useAuthStore();

  const [listings, setListings] = useState<Listing[]>([]);
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    if (!authLoading && !isAuthenticated) {
      router.push('/login');
      return;
    }

    if (isAuthenticated) {
      loadSavedItems();
    }
  }, [authLoading, isAuthenticated]);

  const loadSavedItems = async () => {
    try {
      setLoading(true);
      const data = await api.getSavedListings();
      setListings(data);
    } catch (error) {
      console.error('Error loading saved items:', error);
    } finally {
      setLoading(false);
    }
  };

  const handleUnsave = (listingId: string) => {
    setListings(listings.filter((l) => l.id !== listingId));
  };

  if (authLoading || loading) {
    return (
      <div className="min-h-screen flex flex-col">
        <Header />
        <PageLoader message="Loading saved items..." />
        <Footer />
      </div>
    );
  }

  return (
    <div className="min-h-screen flex flex-col bg-gray-50">
      <Header />

      <main className="flex-1 py-8">
        <div className="max-w-6xl mx-auto px-4">
          {/* Header */}
          <div className="mb-6">
            <h1 className="text-2xl font-bold text-gray-900">Saved Items</h1>
            <p className="text-gray-500 mt-1">
              {listings.length} {listings.length === 1 ? 'item' : 'items'} saved
            </p>
          </div>

          {/* Listings Grid */}
          {listings.length === 0 ? (
            <NoSavedItemsEmptyState onBrowse={() => router.push('/')} />
          ) : (
            <div className="grid grid-cols-2 sm:grid-cols-3 lg:grid-cols-4 xl:grid-cols-5 gap-4">
              {listings.map((listing) => (
                <ListingCard
                  key={listing.id}
                  listing={{ ...listing, isSaved: true }}
                />
              ))}
            </div>
          )}
        </div>
      </main>

      <Footer />
    </div>
  );
}
