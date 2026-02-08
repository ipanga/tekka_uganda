'use client';

import Image from 'next/image';
import Link from 'next/link';
import { useRouter } from 'next/navigation';
import { HeartIcon } from '@heroicons/react/24/outline';
import { HeartIcon as HeartSolidIcon } from '@heroicons/react/24/solid';
import { useState } from 'react';
import type { Listing } from '@/types';
import { api } from '@/lib/api';
import { authManager } from '@/lib/auth';

interface ListingCardProps {
  listing: Listing;
  onSaveChange?: (listingId: string, isSaved: boolean) => void;
  showStatus?: boolean;
}

export function ListingCard({ listing, onSaveChange, showStatus }: ListingCardProps) {
  const router = useRouter();
  // Initialize from listing.isSaved if available
  const [isSaved, setIsSaved] = useState(listing.isSaved ?? false);
  const [isSaving, setIsSaving] = useState(false);

  const handleSaveToggle = async (e: React.MouseEvent) => {
    e.preventDefault();
    e.stopPropagation();

    // Check authentication
    if (!authManager.isAuthenticated()) {
      router.push('/login');
      return;
    }

    setIsSaving(true);
    try {
      if (isSaved) {
        await api.unsaveListing(listing.id);
        setIsSaved(false);
        onSaveChange?.(listing.id, false);
      } else {
        await api.saveListing(listing.id);
        setIsSaved(true);
        onSaveChange?.(listing.id, true);
      }
    } catch (err) {
      console.error('Failed to save/unsave listing:', err);
    } finally {
      setIsSaving(false);
    }
  };

  const formatPrice = (price: number) => {
    return new Intl.NumberFormat('en-UG', {
      style: 'currency',
      currency: 'UGX',
      minimumFractionDigits: 0,
    }).format(price);
  };

  const conditionLabels: Record<string, string> = {
    NEW: 'New',
    LIKE_NEW: 'Like New',
    GOOD: 'Good',
    FAIR: 'Fair',
  };

  const statusLabels: Record<string, { label: string; className: string }> = {
    PENDING: { label: 'Pending Review', className: 'bg-yellow-100 text-yellow-800' },
    REJECTED: { label: 'Rejected', className: 'bg-red-100 text-red-800' },
    DRAFT: { label: 'Draft', className: 'bg-gray-100 text-gray-800' },
    SOLD: { label: 'Sold', className: 'bg-green-100 text-green-800' },
    ARCHIVED: { label: 'Archived', className: 'bg-gray-100 text-gray-600' },
  };

  return (
    <div className="group relative bg-white rounded-xl overflow-hidden shadow-sm hover:shadow-md transition-shadow">
      {/* Image Container */}
      <Link href={`/listing/${listing.id}`} className="block aspect-[3/4] relative overflow-hidden">
        {listing.imageUrls.length > 0 ? (
          <Image
            src={listing.imageUrls[0]}
            alt={listing.title}
            fill
            className="object-cover group-hover:scale-105 transition-transform duration-300"
          />
        ) : (
          <div className="w-full h-full bg-gray-200 flex items-center justify-center">
            <span className="text-gray-400">No image</span>
          </div>
        )}

        {/* Condition Badge */}
        <span className="absolute top-2 left-2 bg-white/90 backdrop-blur-sm text-xs font-medium px-2 py-1 rounded-full">
          {conditionLabels[listing.condition] || listing.condition}
        </span>

        {/* Status Badge (for pending/suspended items) */}
        {showStatus && listing.status && statusLabels[listing.status] && (
          <span className={`absolute bottom-2 left-2 text-xs font-medium px-2 py-1 rounded-full ${statusLabels[listing.status].className}`}>
            {statusLabels[listing.status].label}
          </span>
        )}
      </Link>

      {/* Save Button */}
      <button
        onClick={handleSaveToggle}
        disabled={isSaving}
        className="absolute top-2 right-2 p-2 bg-white/90 backdrop-blur-sm rounded-full hover:bg-white transition-colors disabled:opacity-50"
      >
        {isSaved ? (
          <HeartSolidIcon className="h-5 w-5 text-pink-600" />
        ) : (
          <HeartIcon className="h-5 w-5 text-gray-600" />
        )}
      </button>

      {/* Details */}
      <div className="p-3">
        <Link href={`/listing/${listing.id}`}>
          <h3 className="font-medium text-gray-900 truncate hover:text-pink-600 transition-colors">
            {listing.title}
          </h3>
        </Link>

        <div className="mt-1 flex items-center justify-between">
          <span className="text-lg font-bold text-pink-600">
            {formatPrice(listing.price)}
          </span>
          {listing.originalPrice && listing.originalPrice > listing.price && (
            <span className="text-sm text-gray-400 line-through">
              {formatPrice(listing.originalPrice)}
            </span>
          )}
        </div>

        {listing.size && (
          <p className="mt-1 text-sm text-gray-500">Size: {listing.size}</p>
        )}

        {listing.location && (
          <p className="mt-1 text-xs text-gray-400">{listing.location}</p>
        )}
      </div>
    </div>
  );
}
