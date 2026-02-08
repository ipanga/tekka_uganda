'use client';

import { useState, useEffect } from 'react';
import { useParams, useRouter } from 'next/navigation';
import Link from 'next/link';
import {
  ChatBubbleLeftRightIcon,
  FlagIcon,
  MapPinIcon,
  CalendarIcon,
  ShieldCheckIcon,
  StarIcon,
  NoSymbolIcon,
  PencilSquareIcon,
  PhoneIcon,
} from '@heroicons/react/24/outline';
import { api } from '@/lib/api';
import { User, Listing, UserStats, Review } from '@/types';
import { formatDate } from '@/lib/utils';
import Header from '@/components/layout/Header';
import Footer from '@/components/layout/Footer';
import { Button } from '@/components/ui/Button';
import { Avatar } from '@/components/ui/Avatar';
import { Tabs, TabPanel } from '@/components/ui/Tabs';
import { Card, CardContent } from '@/components/ui/Card';
import { PageLoader } from '@/components/ui/Spinner';
import { ListingCard } from '@/components/listings/ListingCard';
import { ReviewCard } from '@/components/reviews/ReviewCard';
import { ReviewForm } from '@/components/reviews/ReviewForm';
import { ReportModal } from '@/components/modals/ReportModal';
import { useAuthStore } from '@/stores/authStore';

export default function PublicProfilePage() {
  const params = useParams();
  const router = useRouter();
  const userId = params.userId as string;

  const { user: currentUser, isAuthenticated } = useAuthStore();

  const [profileUser, setProfileUser] = useState<User | null>(null);
  const [stats, setStats] = useState<UserStats | null>(null);
  const [listings, setListings] = useState<Listing[]>([]);
  const [reviews, setReviews] = useState<Review[]>([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);
  const [activeTab, setActiveTab] = useState('listings');
  const [showReportModal, setShowReportModal] = useState(false);
  const [showReviewModal, setShowReviewModal] = useState(false);
  const [isBlocked, setIsBlocked] = useState(false);
  const [showPhoneNumber, setShowPhoneNumber] = useState(false);

  // Redirect to own profile if viewing self
  useEffect(() => {
    if (currentUser && currentUser.id === userId) {
      router.replace('/profile');
    }
  }, [currentUser, userId]);

  useEffect(() => {
    loadProfile();
  }, [userId]);

  const loadProfile = async () => {
    try {
      setLoading(true);
      const [userData, statsData, listingsData, reviewsData] = await Promise.all([
        api.getUser(userId),
        api.getUserStats(userId),
        api.getSellerListings(userId, { status: 'ACTIVE', limit: 20 }),
        api.getUserReviews(userId, 'received'),
      ]);

      setProfileUser(userData);
      setStats(statsData);
      setListings(listingsData.data || []);
      setReviews(reviewsData.reviews || []);
    } catch (err) {
      setError('Failed to load profile');
      console.error(err);
    } finally {
      setLoading(false);
    }
  };

  const handleMessage = async () => {
    if (!isAuthenticated) {
      router.push('/login');
      return;
    }

    try {
      const chat = await api.createChat({ participantId: userId });
      router.push(`/messages/${chat.id}`);
    } catch (err) {
      console.error('Failed to create chat:', err);
    }
  };

  const handleBlock = async () => {
    if (!isAuthenticated) {
      router.push('/login');
      return;
    }

    try {
      if (isBlocked) {
        await api.unblockUser(userId);
        setIsBlocked(false);
      } else {
        await api.blockUser(userId);
        setIsBlocked(true);
      }
    } catch (err) {
      console.error('Failed to block/unblock user:', err);
    }
  };

  if (loading) {
    return (
      <div className="min-h-screen flex flex-col">
        <Header />
        <PageLoader message="Loading profile..." />
        <Footer />
      </div>
    );
  }

  if (error || !profileUser) {
    return (
      <div className="min-h-screen flex flex-col">
        <Header />
        <main className="flex-1 flex items-center justify-center">
          <div className="text-center">
            <h1 className="text-2xl font-bold text-gray-900 mb-2">User not found</h1>
            <p className="text-gray-500 mb-6">This profile may not exist or has been removed.</p>
            <Button onClick={() => router.push('/')}>Browse Listings</Button>
          </div>
        </main>
        <Footer />
      </div>
    );
  }

  const tabs = [
    { id: 'listings', label: 'Listings', count: stats?.activeListings },
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
                  src={profileUser.photoUrl}
                  name={profileUser.displayName}
                  size="xl"
                  showBadge={profileUser.isVerified}
                  badgeColor="green"
                />

                <div className="flex-1 text-center sm:text-left">
                  <div className="flex items-center justify-center sm:justify-start gap-2">
                    <h1 className="text-2xl font-bold text-gray-900">
                      {profileUser.displayName || 'Anonymous'}
                    </h1>
                    {profileUser.isVerified && (
                      <ShieldCheckIcon className="w-5 h-5 text-green-500" />
                    )}
                  </div>

                  {profileUser.bio && (
                    <p className="text-gray-600 mt-2">{profileUser.bio}</p>
                  )}

                  <div className="flex flex-wrap items-center justify-center sm:justify-start gap-4 mt-3 text-sm text-gray-500">
                    {profileUser.location && (
                      <span className="flex items-center gap-1">
                        <MapPinIcon className="w-4 h-4" />
                        {profileUser.location}
                      </span>
                    )}
                    <span className="flex items-center gap-1">
                      <CalendarIcon className="w-4 h-4" />
                      Joined {formatDate(profileUser.createdAt)}
                    </span>
                    {stats?.averageRating && stats.averageRating > 0 && (
                      <span className="flex items-center gap-1">
                        <StarIcon className="w-4 h-4 text-yellow-500" />
                        {stats.averageRating.toFixed(1)} ({stats.totalReviews} reviews)
                      </span>
                    )}
                  </div>
                </div>

                <div className="flex flex-col gap-2">
                  <div className="flex flex-wrap gap-2">
                    <Button onClick={handleMessage}>
                      <ChatBubbleLeftRightIcon className="w-5 h-5 mr-2" />
                      Message
                    </Button>
                    {profileUser.showPhoneNumber && profileUser.phoneNumber && (
                      <Button
                        variant="outline"
                        onClick={() => setShowPhoneNumber(!showPhoneNumber)}
                      >
                        <PhoneIcon className="w-5 h-5 mr-2" />
                        {showPhoneNumber ? profileUser.phoneNumber : 'Show Contact'}
                      </Button>
                    )}
                    {isAuthenticated && (
                      <Button variant="outline" onClick={() => setShowReviewModal(true)}>
                        <PencilSquareIcon className="w-5 h-5 mr-2" />
                        Review
                      </Button>
                    )}
                  </div>
                  <div className="flex gap-2">
                    <Button
                      variant="ghost"
                      size="sm"
                      onClick={handleBlock}
                      className="text-gray-500"
                    >
                      <NoSymbolIcon className="w-4 h-4 mr-1" />
                      {isBlocked ? 'Unblock' : 'Block'}
                    </Button>
                    <Button
                      variant="ghost"
                      size="sm"
                      onClick={() => setShowReportModal(true)}
                      className="text-gray-500"
                    >
                      <FlagIcon className="w-4 h-4 mr-1" />
                      Report
                    </Button>
                  </div>
                </div>
              </div>
            </CardContent>
          </Card>

          {/* Stats */}
          <div className="grid grid-cols-3 gap-4 mb-6">
            <Card>
              <CardContent className="py-4 text-center">
                <div className="text-2xl font-bold text-gray-900">{stats?.activeListings || 0}</div>
                <div className="text-sm text-gray-500">Active Listings</div>
              </CardContent>
            </Card>
            <Card>
              <CardContent className="py-4 text-center">
                <div className="text-2xl font-bold text-gray-900">{stats?.soldListings || 0}</div>
                <div className="text-sm text-gray-500">Items Sold</div>
              </CardContent>
            </Card>
            <Card>
              <CardContent className="py-4 text-center">
                <div className="text-2xl font-bold text-gray-900">{stats?.responseRate || 0}%</div>
                <div className="text-sm text-gray-500">Response Rate</div>
              </CardContent>
            </Card>
          </div>

          {/* Tabs */}
          <Tabs tabs={tabs} activeTab={activeTab} onChange={setActiveTab} />

          <div className="mt-6">
            <TabPanel tabId="listings" activeTab={activeTab}>
              {listings.length === 0 ? (
                <Card>
                  <CardContent className="py-12 text-center">
                    <p className="text-gray-500">No active listings</p>
                  </CardContent>
                </Card>
              ) : (
                <div className="grid grid-cols-2 sm:grid-cols-3 lg:grid-cols-4 gap-4">
                  {listings.map((listing) => (
                    <ListingCard key={listing.id} listing={listing} />
                  ))}
                </div>
              )}
            </TabPanel>

            <TabPanel tabId="reviews" activeTab={activeTab}>
              {reviews.length === 0 ? (
                <Card>
                  <CardContent className="py-12 text-center">
                    <StarIcon className="w-12 h-12 text-gray-300 mx-auto mb-4" />
                    <p className="text-gray-500">No reviews yet</p>
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

      {/* Report Modal */}
      {showReportModal && (
        <ReportModal
          isOpen={showReportModal}
          onClose={() => setShowReportModal(false)}
          userId={userId}
        />
      )}

      {/* Review Modal */}
      {showReviewModal && (
        <ReviewForm
          isOpen={showReviewModal}
          onClose={() => setShowReviewModal(false)}
          revieweeId={userId}
          onSuccess={(review) => {
            // Add the new review to the reviews list
            setReviews((prev) => [review, ...prev]);
            // Update stats if needed
            if (stats) {
              setStats({
                ...stats,
                totalReviews: stats.totalReviews + 1,
              });
            }
          }}
        />
      )}
    </div>
  );
}
