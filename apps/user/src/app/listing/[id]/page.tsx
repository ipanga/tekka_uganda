'use client';

import { useState, useEffect } from 'react';
import { useParams, useRouter } from 'next/navigation';
import Image from 'next/image';
import Link from 'next/link';
import {
  HeartIcon,
  ShareIcon,
  ChatBubbleLeftRightIcon,
  MapPinIcon,
  EyeIcon,
  ShieldCheckIcon,
  FlagIcon,
  ChevronLeftIcon,
  ChevronRightIcon,
  StarIcon,
} from '@heroicons/react/24/outline';
import { StarIcon as StarSolidIcon } from '@heroicons/react/24/solid';
import { HeartIcon as HeartSolidIcon } from '@heroicons/react/24/solid';
import { api } from '@/lib/api';
import { authManager } from '@/lib/auth';
import { Listing, User, UserStats, CATEGORY_LABELS, CONDITION_LABELS, OCCASION_LABELS } from '@/types';
import { formatPrice, formatRelativeTime, cn } from '@/lib/utils';
import Header from '@/components/layout/Header';
import Footer from '@/components/layout/Footer';
import { Button } from '@/components/ui/Button';
import { Badge, getStatusVariant } from '@/components/ui/Badge';
import { Avatar } from '@/components/ui/Avatar';
import { PageLoader } from '@/components/ui/Spinner';
import { ReportModal } from '@/components/modals/ReportModal';
import { useAuthStore } from '@/stores/authStore';

export default function ListingDetailPage() {
  const params = useParams();
  const router = useRouter();
  const listingId = params.id as string;

  const { user, isAuthenticated } = useAuthStore();
  const [listing, setListing] = useState<Listing | null>(null);
  const [seller, setSeller] = useState<User | null>(null);
  const [sellerStats, setSellerStats] = useState<UserStats | null>(null);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);
  const [currentImageIndex, setCurrentImageIndex] = useState(0);
  const [isSaved, setIsSaved] = useState(false);
  const [savingItem, setSavingItem] = useState(false);
  const [showReportModal, setShowReportModal] = useState(false);

  useEffect(() => {
    loadListing();
  }, [listingId]);

  const loadListing = async () => {
    try {
      setLoading(true);
      const data = await api.getListing(listingId);
      setListing(data);

      if (data.seller) {
        setSeller(data.seller);
        // Fetch seller stats for rating
        try {
          const stats = await api.getUserStats(data.seller.id);
          setSellerStats(stats);
        } catch {
          // Ignore stats fetch error
        }
      } else if (data.sellerId) {
        const sellerData = await api.getUser(data.sellerId);
        setSeller(sellerData);
        // Fetch seller stats for rating
        try {
          const stats = await api.getUserStats(data.sellerId);
          setSellerStats(stats);
        } catch {
          // Ignore stats fetch error
        }
      }

      // Check if saved
      if (isAuthenticated) {
        try {
          const savedStatus = await api.isListingSaved(listingId);
          setIsSaved(savedStatus.saved);
        } catch {
          // Ignore error
        }
      }
    } catch (err) {
      setError('Failed to load listing');
      console.error(err);
    } finally {
      setLoading(false);
    }
  };

  const handleSaveToggle = async () => {
    // Use authManager as primary source - it ensures initialization and sets API token
    if (!authManager.isAuthenticated()) {
      router.push('/login');
      return;
    }

    setSavingItem(true);
    try {
      if (isSaved) {
        await api.unsaveListing(listingId);
        setIsSaved(false);
      } else {
        await api.saveListing(listingId);
        setIsSaved(true);
      }
    } catch (err) {
      console.error('Failed to save/unsave listing:', err);
    } finally {
      setSavingItem(false);
    }
  };

  const handleShare = async () => {
    if (navigator.share) {
      try {
        await navigator.share({
          title: listing?.title,
          text: `Check out this item on Tekka: ${listing?.title}`,
          url: window.location.href,
        });
      } catch {
        // User cancelled share
      }
    } else {
      // Fallback: copy to clipboard
      await navigator.clipboard.writeText(window.location.href);
      alert('Link copied to clipboard!');
    }
  };

  const handleContactSeller = async () => {
    // Use authManager as primary source - it ensures initialization and sets API token
    if (!authManager.isAuthenticated()) {
      router.push('/login');
      return;
    }

    if (!seller) return;

    try {
      const chat = await api.createChat({
        participantId: seller.id,
        listingId: listingId,
      });
      router.push(`/messages/${chat.id}`);
    } catch (err) {
      console.error('Failed to create chat:', err);
    }
  };

  const nextImage = () => {
    if (listing?.imageUrls) {
      setCurrentImageIndex((prev) =>
        prev === listing.imageUrls.length - 1 ? 0 : prev + 1
      );
    }
  };

  const prevImage = () => {
    if (listing?.imageUrls) {
      setCurrentImageIndex((prev) =>
        prev === 0 ? listing.imageUrls.length - 1 : prev - 1
      );
    }
  };

  if (loading) {
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
            <h1 className="text-2xl font-bold text-gray-900 mb-2">Listing not found</h1>
            <p className="text-gray-500 mb-6">This listing may have been removed or is no longer available.</p>
            <Button onClick={() => router.push('/')}>Browse Listings</Button>
          </div>
        </main>
        <Footer />
      </div>
    );
  }

  const isOwnListing = user?.id === listing.sellerId;
  const discount = listing.originalPrice
    ? Math.round(((listing.originalPrice - listing.price) / listing.originalPrice) * 100)
    : 0;

  return (
    <div className="min-h-screen flex flex-col bg-gray-50">
      <Header />

      <main className="flex-1 py-8">
        <div className="max-w-7xl mx-auto px-4">
          {/* Breadcrumb */}
          {/* Pending Review Notice - Only shown to listing owner */}
          {isOwnListing && listing.status === 'PENDING' && (
            <div className="mb-6 p-4 bg-yellow-50 border border-yellow-200 rounded-lg">
              <p className="text-yellow-800">
                <strong>Pending Review:</strong> Your listing is being reviewed and will be visible to others once approved. This usually takes less than 24 hours.
              </p>
            </div>
          )}

          {/* Draft Notice - Only shown to listing owner */}
          {isOwnListing && listing.status === 'DRAFT' && (
            <div className="mb-6 p-4 bg-gray-50 border border-gray-200 rounded-lg">
              <p className="text-gray-700">
                <strong>Draft:</strong> This listing is saved as a draft and is not visible to others. Publish it when you&apos;re ready.
              </p>
            </div>
          )}

          <nav className="flex items-center gap-2 text-sm text-gray-500 mb-6">
            <Link href="/" className="hover:text-gray-700">Home</Link>
            <span>/</span>
            <Link
              href={listing.categoryId ? `/?categoryId=${listing.categoryId}` : '/'}
              className="hover:text-gray-700"
            >
              {listing.categoryData?.name || (listing.category && CATEGORY_LABELS[listing.category as keyof typeof CATEGORY_LABELS]) || 'Category'}
            </Link>
            <span>/</span>
            <span className="text-gray-900 truncate max-w-xs">{listing.title}</span>
          </nav>

          <div className="grid grid-cols-1 lg:grid-cols-2 gap-8">
            {/* Image Gallery */}
            <div className="space-y-4">
              <div className="relative aspect-square bg-white rounded-2xl overflow-hidden shadow-sm">
                {listing.imageUrls.length > 0 ? (
                  <>
                    <Image
                      src={listing.imageUrls[currentImageIndex]}
                      alt={listing.title}
                      fill
                      className="object-cover"
                      priority
                    />
                    {listing.imageUrls.length > 1 && (
                      <>
                        <button
                          onClick={prevImage}
                          className="absolute left-4 top-1/2 -translate-y-1/2 p-2 bg-white/90 rounded-full shadow-lg hover:bg-white transition-colors"
                        >
                          <ChevronLeftIcon className="w-5 h-5" />
                        </button>
                        <button
                          onClick={nextImage}
                          className="absolute right-4 top-1/2 -translate-y-1/2 p-2 bg-white/90 rounded-full shadow-lg hover:bg-white transition-colors"
                        >
                          <ChevronRightIcon className="w-5 h-5" />
                        </button>
                        <div className="absolute bottom-4 left-1/2 -translate-x-1/2 flex gap-2">
                          {listing.imageUrls.map((_, index) => (
                            <button
                              key={index}
                              onClick={() => setCurrentImageIndex(index)}
                              className={cn(
                                'w-2 h-2 rounded-full transition-colors',
                                index === currentImageIndex ? 'bg-white' : 'bg-white/50'
                              )}
                            />
                          ))}
                        </div>
                      </>
                    )}
                  </>
                ) : (
                  <div className="w-full h-full flex items-center justify-center bg-gray-100">
                    <span className="text-gray-400">No image</span>
                  </div>
                )}

                {/* Badges */}
                <div className="absolute top-4 left-4 flex flex-col gap-2">
                  <Badge variant={getStatusVariant(listing.condition)}>
                    {CONDITION_LABELS[listing.condition]}
                  </Badge>
                  {listing.status === 'SOLD' && (
                    <Badge variant="danger">Sold</Badge>
                  )}
                </div>
              </div>

              {/* Thumbnail Gallery */}
              {listing.imageUrls.length > 1 && (
                <div className="flex gap-2 overflow-x-auto pb-2">
                  {listing.imageUrls.map((url, index) => (
                    <button
                      key={index}
                      onClick={() => setCurrentImageIndex(index)}
                      className={cn(
                        'relative w-20 h-20 rounded-lg overflow-hidden flex-shrink-0',
                        index === currentImageIndex && 'ring-2 ring-pink-600'
                      )}
                    >
                      <Image
                        src={url}
                        alt={`${listing.title} ${index + 1}`}
                        fill
                        className="object-cover"
                      />
                    </button>
                  ))}
                </div>
              )}
            </div>

            {/* Listing Details */}
            <div className="space-y-6">
              {/* Title & Price */}
              <div>
                <h1 className="text-2xl font-bold text-gray-900 mb-2">{listing.title}</h1>
                <div className="flex items-baseline gap-3">
                  <span className="text-3xl font-bold text-pink-600">
                    {formatPrice(listing.price)}
                  </span>
                  {listing.originalPrice && listing.originalPrice > listing.price && (
                    <>
                      <span className="text-lg text-gray-400 line-through">
                        {formatPrice(listing.originalPrice)}
                      </span>
                      <Badge variant="success">{discount}% off</Badge>
                    </>
                  )}
                </div>
              </div>

              {/* Quick Actions */}
              <div className="flex items-center gap-3">
                <button
                  onClick={handleSaveToggle}
                  disabled={savingItem}
                  className="flex items-center gap-2 px-4 py-2 rounded-lg border border-gray-200 hover:bg-gray-50 transition-colors"
                >
                  {isSaved ? (
                    <HeartSolidIcon className="w-5 h-5 text-pink-600" />
                  ) : (
                    <HeartIcon className="w-5 h-5 text-gray-500" />
                  )}
                  <span className="text-sm">{isSaved ? 'Saved' : 'Save'}</span>
                </button>
                <button
                  onClick={handleShare}
                  className="flex items-center gap-2 px-4 py-2 rounded-lg border border-gray-200 hover:bg-gray-50 transition-colors"
                >
                  <ShareIcon className="w-5 h-5 text-gray-500" />
                  <span className="text-sm">Share</span>
                </button>
              </div>

              {/* Seller Card */}
              {seller && (
                <div className="bg-white rounded-xl p-4 border border-gray-200">
                  <div className="flex items-center gap-4">
                    <Link href={`/profile/${seller.id}`}>
                      <Avatar
                        src={seller.photoUrl}
                        name={seller.displayName}
                        size="lg"
                        showBadge={seller.isVerified}
                        badgeColor="green"
                      />
                    </Link>
                    <div className="flex-1">
                      <Link
                        href={`/profile/${seller.id}`}
                        className="font-semibold text-gray-900 hover:text-pink-600 flex items-center gap-1"
                      >
                        {seller.displayName || 'Anonymous'}
                        {seller.isVerified && (
                          <ShieldCheckIcon className="w-4 h-4 text-green-500" />
                        )}
                      </Link>
                      {seller.location && (
                        <p className="text-sm text-gray-500 flex items-center gap-1">
                          <MapPinIcon className="w-4 h-4" />
                          {seller.location}
                        </p>
                      )}
                      {sellerStats && sellerStats.averageRating > 0 && (
                        <div className="flex items-center gap-1 mt-1">
                          <div className="flex items-center">
                            {[1, 2, 3, 4, 5].map((star) => (
                              <StarSolidIcon
                                key={star}
                                className={`w-4 h-4 ${
                                  star <= Math.round(sellerStats.averageRating)
                                    ? 'text-yellow-400'
                                    : 'text-gray-200'
                                }`}
                              />
                            ))}
                          </div>
                          <span className="text-sm text-gray-500 ml-1">
                            {sellerStats.averageRating.toFixed(1)} ({sellerStats.totalReviews} {sellerStats.totalReviews === 1 ? 'review' : 'reviews'})
                          </span>
                        </div>
                      )}
                    </div>
                    <Link
                      href={`/profile/${seller.id}`}
                      className="text-sm text-pink-600 hover:text-pink-700"
                    >
                      View profile
                    </Link>
                  </div>
                </div>
              )}

              {/* Action Buttons */}
              {!isOwnListing && listing.status === 'ACTIVE' && (
                <div className="flex gap-3">
                  <Button onClick={handleContactSeller} className="flex-1">
                    <ChatBubbleLeftRightIcon className="w-5 h-5 mr-2" />
                    Message Seller
                  </Button>
                </div>
              )}

              {isOwnListing && (
                <div className="flex gap-3">
                  <Button
                    variant="outline"
                    onClick={() => router.push(`/sell/${listing.id}/edit`)}
                    className="flex-1"
                  >
                    Edit Listing
                  </Button>
                </div>
              )}

              {/* Details */}
              <div className="bg-white rounded-xl p-6 border border-gray-200 space-y-4">
                <h2 className="font-semibold text-gray-900">Details</h2>
                <div className="grid grid-cols-2 gap-4 text-sm">
                  <div>
                    <span className="text-gray-500">Category</span>
                    <p className="font-medium">
                      {listing.categoryData?.name?.trim() || CATEGORY_LABELS[listing.category as keyof typeof CATEGORY_LABELS] || 'N/A'}
                    </p>
                  </div>
                  <div>
                    <span className="text-gray-500">Condition</span>
                    <p className="font-medium">{CONDITION_LABELS[listing.condition]}</p>
                  </div>
                  {listing.occasion && (
                    <div>
                      <span className="text-gray-500">Occasion</span>
                      <p className="font-medium">{OCCASION_LABELS[listing.occasion]}</p>
                    </div>
                  )}
                  {/* Display all attributes from JSON with proper labels */}
                  {listing.attributes && Object.keys(listing.attributes).length > 0 && Object.entries(listing.attributes).map(([key, value]) => {
                    // Map attribute keys to display labels
                    const labelMap: Record<string, string> = {
                      'size': 'Size',
                      'size-clothing': 'Size',
                      'size-shoes': 'Shoe Size',
                      'brand': 'Brand',
                      'brand-fashion': 'Brand',
                      'brand-consoles': 'Brand',
                      'color': 'Color',
                      'material': 'Material',
                      'storage-capacity': 'Storage',
                      'console-model': 'Model',
                    };
                    const label = labelMap[key] || key.replace(/-/g, ' ').replace(/_/g, ' ').replace(/\b\w/g, c => c.toUpperCase());
                    const displayValue = Array.isArray(value) ? value.join(', ') : String(value);
                    return (
                      <div key={key}>
                        <span className="text-gray-500">{label}</span>
                        <p className="font-medium">{displayValue}</p>
                      </div>
                    );
                  })}
                  {/* Fallback to legacy fields if no attributes JSON or empty object */}
                  {(!listing.attributes || Object.keys(listing.attributes).length === 0) && (
                    <>
                      {listing.size && (
                        <div>
                          <span className="text-gray-500">Size</span>
                          <p className="font-medium">{listing.size}</p>
                        </div>
                      )}
                      {listing.brand && (
                        <div>
                          <span className="text-gray-500">Brand</span>
                          <p className="font-medium">{listing.brand}</p>
                        </div>
                      )}
                      {listing.color && (
                        <div>
                          <span className="text-gray-500">Color</span>
                          <p className="font-medium">{listing.color}</p>
                        </div>
                      )}
                      {listing.material && (
                        <div>
                          <span className="text-gray-500">Material</span>
                          <p className="font-medium">{listing.material}</p>
                        </div>
                      )}
                    </>
                  )}
                  {/* Display location from city/division or legacy field */}
                  {(listing.city || listing.division || listing.location) && (
                    <div>
                      <span className="text-gray-500">Location</span>
                      <p className="font-medium">
                        {listing.division?.name && listing.city?.name
                          ? `${listing.division.name}, ${listing.city.name}`
                          : listing.city?.name || listing.location}
                      </p>
                    </div>
                  )}
                </div>
              </div>

              {/* Description */}
              <div className="bg-white rounded-xl p-6 border border-gray-200 space-y-4">
                <h2 className="font-semibold text-gray-900">Description</h2>
                <p className="text-gray-600 whitespace-pre-wrap">{listing.description}</p>
              </div>

              {/* Stats & Meta */}
              <div className="flex items-center justify-between text-sm text-gray-500">
                <div className="flex items-center gap-4">
                  <span className="flex items-center gap-1">
                    <EyeIcon className="w-4 h-4" />
                    {listing.viewCount} views
                  </span>
                  <span className="flex items-center gap-1">
                    <HeartIcon className="w-4 h-4" />
                    {listing.saveCount} saves
                  </span>
                </div>
                <span>Listed {formatRelativeTime(listing.createdAt)}</span>
              </div>

              {/* Report Button */}
              {!isOwnListing && (
                <button
                  onClick={() => setShowReportModal(true)}
                  className="flex items-center gap-2 text-sm text-gray-500 hover:text-red-600 transition-colors"
                >
                  <FlagIcon className="w-4 h-4" />
                  Report this listing
                </button>
              )}
            </div>
          </div>
        </div>
      </main>

      <Footer />

      {/* Modals */}
      {showReportModal && (
        <ReportModal
          isOpen={showReportModal}
          onClose={() => setShowReportModal(false)}
          listingId={listing.id}
        />
      )}
    </div>
  );
}
