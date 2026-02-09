'use client';

import { useState, useEffect } from 'react';
import { useParams, useRouter } from 'next/navigation';
import { api } from '@/lib/api';
import { Listing } from '@/types';
import Header from '@/components/layout/Header';
import Footer from '@/components/layout/Footer';
import { Button } from '@/components/ui/Button';
import { PageLoader } from '@/components/ui/Spinner';
import { useAuthStore } from '@/stores/authStore';
import { ListingForm } from '../../page';

export default function EditListingPage() {
  const params = useParams();
  const router = useRouter();
  const listingId = params.id as string;

  const { user, isAuthenticated, isLoading: authLoading } = useAuthStore();

  const [listing, setListing] = useState<Listing | null>(null);
  const [loadingListing, setLoadingListing] = useState(true);
  const [error, setError] = useState<string | null>(null);

  useEffect(() => {
    if (!authLoading && !isAuthenticated) {
      router.push('/login');
      return;
    }

    if (isAuthenticated && listingId) {
      loadListing();
    }
  }, [authLoading, isAuthenticated, listingId]);

  const loadListing = async () => {
    try {
      setLoadingListing(true);
      const data = await api.getListing(listingId);

      // Check if user owns this listing
      if (data.sellerId !== user?.id) {
        router.push('/my-listings');
        return;
      }

      setListing(data);
    } catch (err) {
      setError('Failed to load listing');
      console.error(err);
    } finally {
      setLoadingListing(false);
    }
  };

  if (authLoading || loadingListing) {
    return (
      <div className="min-h-screen flex flex-col">
        <Header />
        <PageLoader message="Loading listing..." />
        <Footer />
      </div>
    );
  }

  if (error || !listing) {
    return (
      <div className="min-h-screen flex flex-col">
        <Header />
        <main className="flex-1 flex items-center justify-center">
          <div className="text-center">
            <h1 className="text-xl font-bold text-gray-900 mb-2">
              {error || 'Listing not found'}
            </h1>
            <Button onClick={() => router.push('/my-listings')}>Back to My Listings</Button>
          </div>
        </main>
        <Footer />
      </div>
    );
  }

  return (
    <ListingForm
      mode="edit"
      existingListing={listing}
      listingId={listingId}
    />
  );
}
