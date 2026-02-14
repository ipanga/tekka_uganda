'use client';

import { useState, useEffect } from 'react';
import { useRouter } from 'next/navigation';
import Link from 'next/link';
import {
  Cog6ToothIcon,
  PencilIcon,
  ShoppingBagIcon,
  HeartIcon,
  ChatBubbleLeftRightIcon,
  StarIcon,
  MapPinIcon,
  CalendarIcon,
  ShieldCheckIcon,
} from '@heroicons/react/24/outline';
import { api } from '@/lib/api';
import { Listing, UserStats, Review } from '@/types';
import { formatDate, formatPrice } from '@/lib/utils';
import Header from '@/components/layout/Header';
import Footer from '@/components/layout/Footer';
import { Button } from '@/components/ui/Button';
import { Avatar } from '@/components/ui/Avatar';
import { Tabs, TabPanel } from '@/components/ui/Tabs';
import { Card, CardContent } from '@/components/ui/Card';
import { Badge } from '@/components/ui/Badge';
import { PageLoader } from '@/components/ui/Spinner';
import { NoListingsEmptyState } from '@/components/ui/EmptyState';
import { ListingCard } from '@/components/listings/ListingCard';
import { ReviewCard } from '@/components/reviews/ReviewCard';
import { useAuthStore } from '@/stores/authStore';

export default function ProfilePage() {
  const router = useRouter();
  const { user, isAuthenticated, isLoading: authLoading } = useAuthStore();

  const [activeTab, setActiveTab] = useState('listings');
  const [stats, setStats] = useState<UserStats | null>(null);
  const [listings, setListings] = useState<Listing[]>([]);
  const [pendingListings, setPendingListings] = useState<Listing[]>([]);
  const [reviews, setReviews] = useState<Review[]>([]);
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    if (!authLoading && !isAuthenticated) {
      router.push('/login');
      return;
    }

    if (user) {
      loadProfileData();
    }
  }, [user, authLoading, isAuthenticated]);

  const loadProfileData = async () => {
    if (!user) return;

    try {
      setLoading(true);
      const [statsData, listingsData, pendingData, rejectedData, reviewsData] = await Promise.all([
        api.getMyStats(),
        api.getMyListings({ status: 'ACTIVE', limit: 20 }),
        api.getMyListings({ status: 'PENDING', limit: 20 }),
        api.getMyListings({ status: 'REJECTED', limit: 20 }),
        api.getUserReviews(user.id, 'received'),
      ]);

      setStats(statsData);
      setListings(listingsData.data || []);
      // Combine pending and rejected listings for the "Pending Review" tab
      const allPendingListings = [
        ...(pendingData.data || []),
        ...(rejectedData.data || []),
      ].sort((a, b) => new Date(b.updatedAt).getTime() - new Date(a.updatedAt).getTime());
      setPendingListings(allPendingListings);
      setReviews(reviewsData.reviews || []);
    } catch (error) {
      console.error('Error loading profile:', error);
    } finally {
      setLoading(false);
    }
  };

  if (authLoading || loading) {
    return (
      <div className="min-h-screen flex flex-col">
        <Header />
        <PageLoader message="Loading profile..." />
        <Footer />
      </div>
    );
  }

  if (!user) {
    return null;
  }

  const tabs = [
    { id: 'listings', label: 'Listings', count: stats?.activeListings },
    { id: 'pending', label: 'Pending Review', count: pendingListings.length || undefined },
    { id: 'reviews', label: 'Reviews', count: stats?.totalReviews },
  ];

  return (
    <div className="min-h-screen flex flex-col bg-gray-50">
      <Header />

      <main className="flex-1 py-8">
        <div className="max-w-4xl mx-auto px-4">
          {/* Profile Header */}
          <Card className="mb-6">
            <CardContent className="py-6">
              <div className="flex flex-col sm:flex-row items-center sm:items-start gap-6">
                <Avatar
                  src={user.photoUrl}
                  name={user.displayName}
                  size="xl"
                  showBadge={user.isVerified}
                  badgeColor="green"
                />

                <div className="flex-1 text-center sm:text-left">
                  <div className="flex items-center justify-center sm:justify-start gap-2">
                    <h1 className="text-2xl font-bold text-gray-900">
                      {user.displayName || 'Anonymous'}
                    </h1>
                    {user.isVerified && (
                      <ShieldCheckIcon className="w-5 h-5 text-green-500" />
                    )}
                  </div>

                  {user.bio && (
                    <p className="text-gray-600 mt-2">{user.bio}</p>
                  )}

                  <div className="flex flex-wrap items-center justify-center sm:justify-start gap-4 mt-3 text-sm text-gray-500">
                    {user.location && (
                      <span className="flex items-center gap-1">
                        <MapPinIcon className="w-4 h-4" />
                        {user.location}
                      </span>
                    )}
                    <span className="flex items-center gap-1">
                      <CalendarIcon className="w-4 h-4" />
                      Joined {formatDate(user.createdAt)}
                    </span>
                  </div>
                </div>

                <div className="flex gap-2">
                  <Link href="/profile/edit">
                    <Button variant="outline" size="sm">
                      <PencilIcon className="w-4 h-4 mr-2" />
                      Edit Profile
                    </Button>
                  </Link>
                  <Link href="/settings">
                    <Button variant="ghost" size="sm">
                      <Cog6ToothIcon className="w-4 h-4" />
                    </Button>
                  </Link>
                </div>
              </div>
            </CardContent>
          </Card>

          {/* Stats Grid */}
          <div className="grid grid-cols-2 sm:grid-cols-4 gap-4 mb-6">
            <Card>
              <CardContent className="py-4 text-center">
                <ShoppingBagIcon className="w-6 h-6 text-primary-500 mx-auto mb-2" />
                <div className="text-2xl font-bold text-gray-900">{stats?.activeListings || 0}</div>
                <div className="text-sm text-gray-500">Active Listings</div>
              </CardContent>
            </Card>
            <Card>
              <CardContent className="py-4 text-center">
                <HeartIcon className="w-6 h-6 text-primary-500 mx-auto mb-2" />
                <div className="text-2xl font-bold text-gray-900">{stats?.soldListings || 0}</div>
                <div className="text-sm text-gray-500">Items Sold</div>
              </CardContent>
            </Card>
            <Card>
              <CardContent className="py-4 text-center">
                <StarIcon className="w-6 h-6 text-primary-500 mx-auto mb-2" />
                <div className="text-2xl font-bold text-gray-900">
                  {stats?.averageRating?.toFixed(1) || '-'}
                </div>
                <div className="text-sm text-gray-500">Rating</div>
              </CardContent>
            </Card>
            <Card>
              <CardContent className="py-4 text-center">
                <ChatBubbleLeftRightIcon className="w-6 h-6 text-primary-500 mx-auto mb-2" />
                <div className="text-2xl font-bold text-gray-900">{stats?.responseRate || 0}%</div>
                <div className="text-sm text-gray-500">Response Rate</div>
              </CardContent>
            </Card>
          </div>

          {/* Quick Links */}
          <div className="grid grid-cols-2 sm:grid-cols-4 gap-4 mb-6">
            <Link href="/my-listings">
              <Card hoverable>
                <CardContent className="py-4 text-center">
                  <span className="text-primary-500 font-medium">My Listings</span>
                </CardContent>
              </Card>
            </Link>
            <Link href="/saved">
              <Card hoverable>
                <CardContent className="py-4 text-center">
                  <span className="text-primary-500 font-medium">Saved Items</span>
                </CardContent>
              </Card>
            </Link>
            <Link href="/messages">
              <Card hoverable>
                <CardContent className="py-4 text-center">
                  <span className="text-primary-500 font-medium">Messages</span>
                </CardContent>
              </Card>
            </Link>
          </div>

          {/* Tabs */}
          <Tabs tabs={tabs} activeTab={activeTab} onChange={setActiveTab} />

          <div className="mt-6">
            <TabPanel tabId="listings" activeTab={activeTab}>
              {listings.length === 0 ? (
                <NoListingsEmptyState onCreateListing={() => router.push('/sell')} />
              ) : (
                <div className="grid grid-cols-2 sm:grid-cols-3 lg:grid-cols-4 gap-4">
                  {listings.map((listing) => (
                    <ListingCard key={listing.id} listing={listing} />
                  ))}
                </div>
              )}
            </TabPanel>

            <TabPanel tabId="pending" activeTab={activeTab}>
              {pendingListings.length === 0 ? (
                <Card>
                  <CardContent className="py-12 text-center">
                    <ShoppingBagIcon className="w-12 h-12 text-gray-300 mx-auto mb-4" />
                    <h3 className="text-lg font-semibold text-gray-900 mb-2">No listings under review</h3>
                    <p className="text-gray-500">Listings pending review, suspended, or rejected will appear here.</p>
                  </CardContent>
                </Card>
              ) : (
                <div className="space-y-4">
                  <div className="bg-yellow-50 border border-yellow-200 rounded-lg p-4">
                    <p className="text-sm text-yellow-800">
                      These listings are pending review, suspended, or rejected. Active listings will be visible to buyers once approved.
                    </p>
                  </div>
                  <div className="grid grid-cols-2 sm:grid-cols-3 lg:grid-cols-4 gap-4">
                    {pendingListings.map((listing) => (
                      <ListingCard key={listing.id} listing={listing} showStatus />
                    ))}
                  </div>
                </div>
              )}
            </TabPanel>

            <TabPanel tabId="reviews" activeTab={activeTab}>
              {!Array.isArray(reviews) || reviews.length === 0 ? (
                <Card>
                  <CardContent className="py-12 text-center">
                    <StarIcon className="w-12 h-12 text-gray-300 mx-auto mb-4" />
                    <h3 className="text-lg font-semibold text-gray-900 mb-2">No reviews yet</h3>
                    <p className="text-gray-500">Reviews from your transactions will appear here.</p>
                  </CardContent>
                </Card>
              ) : (
                <div className="space-y-4">
                  {reviews.map((review) => (
                    <ReviewCard key={review.id} review={review} />
                  ))}
                </div>
              )}
            </TabPanel>
          </div>
        </div>
      </main>

      <Footer />
    </div>
  );
}
