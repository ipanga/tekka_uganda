'use client';

import { useState, useEffect } from 'react';
import { useRouter } from 'next/navigation';
import Link from 'next/link';
import Image from 'next/image';
import { api } from '@/lib/api';
import { authManager } from '@/lib/auth';
import { Offer, OFFER_STATUS_LABELS } from '@/types';
import { formatPrice, formatRelativeTime } from '@/lib/utils';
import Header from '@/components/layout/Header';
import Footer from '@/components/layout/Footer';
import { Button } from '@/components/ui/Button';
import { Tabs, TabPanel } from '@/components/ui/Tabs';
import { Card, CardContent } from '@/components/ui/Card';
import { Badge, getStatusVariant } from '@/components/ui/Badge';
import { Avatar } from '@/components/ui/Avatar';
import { PageLoader } from '@/components/ui/Spinner';
import { NoOffersEmptyState } from '@/components/ui/EmptyState';
import { Modal, ModalFooter } from '@/components/ui/Modal';
import { Input } from '@/components/ui/Input';
import { useAuthStore } from '@/stores/authStore';
import { ReviewForm } from '@/components/reviews/ReviewForm';

export default function OffersPage() {
  const router = useRouter();
  const { user, isAuthenticated, isLoading: authLoading } = useAuthStore();

  const [receivedOffers, setReceivedOffers] = useState<Offer[]>([]);
  const [sentOffers, setSentOffers] = useState<Offer[]>([]);
  const [loading, setLoading] = useState(true);
  const [activeTab, setActiveTab] = useState('received');
  const [selectedOffer, setSelectedOffer] = useState<Offer | null>(null);
  const [actionModal, setActionModal] = useState<'accept' | 'reject' | 'counter' | null>(null);
  const [counterAmount, setCounterAmount] = useState('');
  const [actionLoading, setActionLoading] = useState(false);
  const [reviewOffer, setReviewOffer] = useState<Offer | null>(null);

  // Get current tab's offers
  const offers = activeTab === 'received' ? receivedOffers : sentOffers;
  const setOffers = activeTab === 'received' ? setReceivedOffers : setSentOffers;

  useEffect(() => {
    if (!authLoading && !isAuthenticated) {
      router.push('/login');
      return;
    }

    if (isAuthenticated) {
      loadAllOffers();
    }
  }, [authLoading, isAuthenticated]);

  const loadAllOffers = async () => {
    // Ensure we have authentication before making API calls
    // authManager.isAuthenticated() also initializes and sets API token
    if (!authManager.isAuthenticated()) {
      setLoading(false);
      return;
    }

    try {
      setLoading(true);
      // Load both received and sent offers in parallel
      const [receivedResponse, sentResponse] = await Promise.all([
        api.getOffers({ role: 'seller', limit: 50 }),
        api.getOffers({ role: 'buyer', limit: 50 }),
      ]);

      // API returns array directly, not wrapped in PaginatedResponse
      const receivedArray = Array.isArray(receivedResponse) ? receivedResponse : (receivedResponse.data || []);
      const sentArray = Array.isArray(sentResponse) ? sentResponse : (sentResponse.data || []);

      setReceivedOffers(receivedArray);
      setSentOffers(sentArray);
    } catch (error) {
      console.error('Error loading offers:', error);
    } finally {
      setLoading(false);
    }
  };

  const handleAction = async () => {
    if (!selectedOffer) return;

    setActionLoading(true);
    try {
      let updatedOffer: Offer;
      const wasAccepted = actionModal === 'accept';
      const offerToReview = selectedOffer;

      if (actionModal === 'accept') {
        updatedOffer = await api.acceptOffer(selectedOffer.id);
      } else if (actionModal === 'reject') {
        updatedOffer = await api.rejectOffer(selectedOffer.id);
      } else if (actionModal === 'counter') {
        const amount = parseInt(counterAmount.replace(/,/g, ''), 10);
        if (isNaN(amount) || amount <= 0) return;
        updatedOffer = await api.counterOffer(selectedOffer.id, { counterAmount: amount });
      } else {
        return;
      }

      setOffers(offers.map((o) => (o.id === updatedOffer.id ? updatedOffer : o)));

      // Prompt seller to review the buyer after accepting
      if (wasAccepted && offerToReview.buyer) {
        setReviewOffer(offerToReview);
      }
    } catch (error) {
      console.error('Action failed:', error);
    } finally {
      setActionLoading(false);
      setActionModal(null);
      setSelectedOffer(null);
      setCounterAmount('');
    }
  };

  const handleWithdraw = async (offer: Offer) => {
    try {
      await api.withdrawOffer(offer.id);
      setOffers(offers.filter((o) => o.id !== offer.id));
    } catch (error) {
      console.error('Failed to withdraw offer:', error);
    }
  };

  const handleAcceptCounter = async (offer: Offer) => {
    try {
      const updatedOffer = await api.acceptCounterOffer(offer.id);
      setOffers(offers.map((o) => (o.id === updatedOffer.id ? updatedOffer : o)));
    } catch (error) {
      console.error('Failed to accept counter:', error);
    }
  };

  if (authLoading || loading) {
    return (
      <div className="min-h-screen flex flex-col">
        <Header />
        <PageLoader message="Loading offers..." />
        <Footer />
      </div>
    );
  }

  const tabs = [
    {
      id: 'received',
      label: 'Received',
      count: receivedOffers.length,
    },
    {
      id: 'sent',
      label: 'Sent',
      count: sentOffers.length,
    },
  ];

  return (
    <div className="min-h-screen flex flex-col bg-gray-50">
      <Header />

      <main className="flex-1 py-8">
        <div className="max-w-4xl mx-auto px-4">
          {/* Header */}
          <div className="mb-6">
            <h1 className="text-2xl font-bold text-gray-900">My Offers</h1>
          </div>

          {/* Tabs */}
          <Tabs tabs={tabs} activeTab={activeTab} onChange={setActiveTab} />

          {/* Offers List */}
          <div className="mt-6">
            {offers.length === 0 ? (
              <NoOffersEmptyState />
            ) : (
              <div className="space-y-4">
                {offers.map((offer) => {
                  const isReceived = offer.sellerId === user?.id;
                  const otherUser = isReceived ? offer.buyer : offer.seller;
                  const listing = offer.listing;

                  return (
                    <Card key={offer.id}>
                      <CardContent className="py-4">
                        <div className="flex gap-4">
                          {/* Listing Image */}
                          {listing && (
                            <Link href={`/listing/${listing.id}`} className="flex-shrink-0">
                              <div className="relative w-20 h-20 rounded-lg overflow-hidden">
                                {listing.imageUrls[0] ? (
                                  <Image
                                    src={listing.imageUrls[0]}
                                    alt={listing.title}
                                    fill
                                    className="object-cover"
                                  />
                                ) : (
                                  <div className="w-full h-full bg-gray-100" />
                                )}
                              </div>
                            </Link>
                          )}

                          {/* Offer Details */}
                          <div className="flex-1 min-w-0">
                            <div className="flex items-start justify-between">
                              <div>
                                {listing && (
                                  <Link
                                    href={`/listing/${listing.id}`}
                                    className="font-medium text-gray-900 hover:text-pink-600 line-clamp-1"
                                  >
                                    {listing.title}
                                  </Link>
                                )}
                                <div className="flex items-center gap-2 mt-1">
                                  <span className="text-lg font-bold text-pink-600">
                                    {formatPrice(offer.amount)}
                                  </span>
                                  {listing && (
                                    <span className="text-sm text-gray-500">
                                      (Listed: {formatPrice(listing.price)})
                                    </span>
                                  )}
                                </div>
                                {offer.status === 'COUNTERED' && offer.counterAmount && (
                                  <p className="text-sm text-yellow-600 mt-1">
                                    Counter offer: {formatPrice(offer.counterAmount)}
                                  </p>
                                )}
                              </div>
                              <Badge variant={getStatusVariant(offer.status)}>
                                {OFFER_STATUS_LABELS[offer.status]}
                              </Badge>
                            </div>

                            {/* Other User */}
                            {otherUser && (
                              <div className="flex items-center gap-2 mt-2">
                                <Avatar
                                  src={otherUser.photoUrl}
                                  name={otherUser.displayName}
                                  size="xs"
                                />
                                <span className="text-sm text-gray-600">
                                  {isReceived ? 'From' : 'To'} {otherUser.displayName}
                                </span>
                              </div>
                            )}

                            {offer.message && (
                              <p className="text-sm text-gray-500 mt-2 line-clamp-2">
                                &quot;{offer.message}&quot;
                              </p>
                            )}

                            <p className="text-xs text-gray-400 mt-2">
                              {formatRelativeTime(offer.createdAt)}
                            </p>

                            {/* Actions */}
                            {offer.status === 'PENDING' && (
                              <div className="flex items-center gap-2 mt-3">
                                {isReceived ? (
                                  <>
                                    <Button
                                      size="sm"
                                      onClick={() => {
                                        setSelectedOffer(offer);
                                        setActionModal('accept');
                                      }}
                                    >
                                      Accept
                                    </Button>
                                    <Button
                                      variant="outline"
                                      size="sm"
                                      onClick={() => {
                                        setSelectedOffer(offer);
                                        setCounterAmount('');
                                        setActionModal('counter');
                                      }}
                                    >
                                      Counter
                                    </Button>
                                    <Button
                                      variant="ghost"
                                      size="sm"
                                      onClick={() => {
                                        setSelectedOffer(offer);
                                        setActionModal('reject');
                                      }}
                                    >
                                      Decline
                                    </Button>
                                  </>
                                ) : (
                                  <Button
                                    variant="outline"
                                    size="sm"
                                    onClick={() => handleWithdraw(offer)}
                                  >
                                    Withdraw Offer
                                  </Button>
                                )}
                              </div>
                            )}

                            {offer.status === 'COUNTERED' && !isReceived && (
                              <div className="flex items-center gap-2 mt-3">
                                <Button size="sm" onClick={() => handleAcceptCounter(offer)}>
                                  Accept Counter
                                </Button>
                                <Button
                                  variant="outline"
                                  size="sm"
                                  onClick={() => handleWithdraw(offer)}
                                >
                                  Decline
                                </Button>
                              </div>
                            )}
                          </div>
                        </div>
                      </CardContent>
                    </Card>
                  );
                })}
              </div>
            )}
          </div>
        </div>
      </main>

      <Footer />

      {/* Action Modal */}
      {actionModal && selectedOffer && (
        <Modal
          isOpen={!!actionModal}
          onClose={() => {
            setActionModal(null);
            setSelectedOffer(null);
          }}
          title={
            actionModal === 'accept'
              ? 'Accept Offer'
              : actionModal === 'reject'
              ? 'Decline Offer'
              : 'Make Counter Offer'
          }
          size="sm"
        >
          {actionModal === 'counter' ? (
            <div className="space-y-4">
              <p className="text-gray-600">
                Current offer: {formatPrice(selectedOffer.amount)}
              </p>
              <Input
                label="Your counter offer (UGX)"
                value={counterAmount}
                onChange={(e) => setCounterAmount(e.target.value.replace(/[^0-9]/g, ''))}
                placeholder="Enter amount"
              />
            </div>
          ) : (
            <p className="text-gray-600">
              {actionModal === 'accept'
                ? `Accept the offer of ${formatPrice(selectedOffer.amount)} for "${selectedOffer.listing?.title}"?`
                : `Decline the offer of ${formatPrice(selectedOffer.amount)} for "${selectedOffer.listing?.title}"?`}
            </p>
          )}

          <ModalFooter>
            <Button
              variant="outline"
              onClick={() => {
                setActionModal(null);
                setSelectedOffer(null);
              }}
            >
              Cancel
            </Button>
            <Button onClick={handleAction} loading={actionLoading}>
              {actionModal === 'accept' && 'Accept'}
              {actionModal === 'reject' && 'Decline'}
              {actionModal === 'counter' && 'Send Counter'}
            </Button>
          </ModalFooter>
        </Modal>
      )}

      {/* Review Form - shown after accepting an offer */}
      {reviewOffer && reviewOffer.buyer && reviewOffer.listing && (
        <ReviewForm
          isOpen={!!reviewOffer}
          onClose={() => setReviewOffer(null)}
          revieweeId={reviewOffer.buyer.id}
          listingId={reviewOffer.listing.id}
          onSuccess={() => setReviewOffer(null)}
        />
      )}
    </div>
  );
}
