'use client';

import { useState, useEffect } from 'react';
import { useRouter } from 'next/navigation';
import Link from 'next/link';
import {
  PlusIcon,
  PencilIcon,
  TrashIcon,
  ArchiveBoxIcon,
  CheckCircleIcon,
} from '@heroicons/react/24/outline';
import { api } from '@/lib/api';
import { authManager } from '@/lib/auth';
import { Listing, ListingStatus, STATUS_LABELS } from '@/types';
import { formatPrice, formatRelativeTime } from '@/lib/utils';
import Header from '@/components/layout/Header';
import Footer from '@/components/layout/Footer';
import { Button } from '@/components/ui/Button';
import { Tabs, TabPanel } from '@/components/ui/Tabs';
import { Card, CardContent } from '@/components/ui/Card';
import { Badge, getStatusVariant } from '@/components/ui/Badge';
import { PageLoader } from '@/components/ui/Spinner';
import { NoListingsEmptyState } from '@/components/ui/EmptyState';
import { Modal, ModalFooter } from '@/components/ui/Modal';
import { useAuthStore } from '@/stores/authStore';
import Image from 'next/image';

export default function MyListingsPage() {
  const router = useRouter();
  const { isAuthenticated, isLoading: authLoading } = useAuthStore();

  const [listings, setListings] = useState<Listing[]>([]);
  const [loading, setLoading] = useState(true);
  const [activeTab, setActiveTab] = useState('all');
  const [selectedListing, setSelectedListing] = useState<Listing | null>(null);
  const [actionModal, setActionModal] = useState<'delete' | 'archive' | 'sold' | 'publish' | null>(null);
  const [actionLoading, setActionLoading] = useState(false);

  useEffect(() => {
    // authManager.isAuthenticated() ensures initialization and sets API token
    if (!authLoading && !authManager.isAuthenticated()) {
      router.push('/login');
      return;
    }

    if (authManager.isAuthenticated()) {
      loadListings();
    }
  }, [authLoading, isAuthenticated]);

  const loadListings = async () => {
    try {
      setLoading(true);
      const response = await api.getMyListings({ limit: 100 });
      setListings(response.data || []);
    } catch (error) {
      console.error('Error loading listings:', error);
    } finally {
      setLoading(false);
    }
  };

  const getFilteredListings = () => {
    if (activeTab === 'all') return listings;
    return listings.filter((l) => l.status === activeTab.toUpperCase());
  };

  const handleAction = async () => {
    if (!selectedListing || !actionModal) return;

    setActionLoading(true);
    try {
      if (actionModal === 'delete') {
        await api.deleteListing(selectedListing.id);
        setListings(listings.filter((l) => l.id !== selectedListing.id));
      } else if (actionModal === 'archive') {
        await api.archiveListing(selectedListing.id);
        setListings(
          listings.map((l) =>
            l.id === selectedListing.id ? { ...l, status: 'ARCHIVED' as ListingStatus } : l
          )
        );
      } else if (actionModal === 'sold') {
        await api.markListingAsSold(selectedListing.id);
        setListings(
          listings.map((l) =>
            l.id === selectedListing.id ? { ...l, status: 'SOLD' as ListingStatus } : l
          )
        );
      } else if (actionModal === 'publish') {
        await api.publishListing(selectedListing.id);
        setListings(
          listings.map((l) =>
            l.id === selectedListing.id ? { ...l, status: 'PENDING' as ListingStatus } : l
          )
        );
      }
    } catch (error) {
      console.error('Action failed:', error);
    } finally {
      setActionLoading(false);
      setActionModal(null);
      setSelectedListing(null);
    }
  };

  if (authLoading || loading) {
    return (
      <div className="min-h-screen flex flex-col">
        <Header />
        <PageLoader message="Loading your listings..." />
        <Footer />
      </div>
    );
  }

  const tabs = [
    { id: 'all', label: 'All', count: listings.length },
    { id: 'active', label: 'Active', count: listings.filter((l) => l.status === 'ACTIVE').length },
    { id: 'pending', label: 'Pending', count: listings.filter((l) => l.status === 'PENDING').length },
    { id: 'draft', label: 'Drafts', count: listings.filter((l) => l.status === 'DRAFT').length },
    { id: 'sold', label: 'Sold', count: listings.filter((l) => l.status === 'SOLD').length },
  ];

  const filteredListings = getFilteredListings();

  return (
    <div className="min-h-screen flex flex-col bg-gray-50">
      <Header />

      <main className="flex-1 py-8">
        <div className="max-w-4xl mx-auto px-4">
          {/* Header */}
          <div className="flex items-center justify-between mb-6">
            <h1 className="text-2xl font-bold text-gray-900">My Listings</h1>
            <Link href="/sell">
              <Button>
                <PlusIcon className="w-5 h-5 mr-2" />
                New Listing
              </Button>
            </Link>
          </div>

          {/* Tabs */}
          <Tabs tabs={tabs} activeTab={activeTab} onChange={setActiveTab} />

          {/* Listings */}
          <div className="mt-6">
            {filteredListings.length === 0 ? (
              <NoListingsEmptyState onCreateListing={() => router.push('/sell')} />
            ) : (
              <div className="space-y-4">
                {filteredListings.map((listing) => (
                  <Card key={listing.id}>
                    <CardContent className="py-4">
                      <div className="flex gap-4">
                        {/* Image */}
                        <Link href={`/listing/${listing.id}`} className="flex-shrink-0">
                          <div className="relative w-24 h-24 rounded-lg overflow-hidden">
                            {listing.imageUrls[0] ? (
                              <Image
                                src={listing.imageUrls[0]}
                                alt={listing.title}
                                fill
                                className="object-cover"
                              />
                            ) : (
                              <div className="w-full h-full bg-gray-100 flex items-center justify-center">
                                <span className="text-gray-400 text-xs">No image</span>
                              </div>
                            )}
                          </div>
                        </Link>

                        {/* Details */}
                        <div className="flex-1 min-w-0">
                          <div className="flex items-start justify-between">
                            <div>
                              <Link
                                href={`/listing/${listing.id}`}
                                className="font-medium text-gray-900 hover:text-pink-600 line-clamp-1"
                              >
                                {listing.title}
                              </Link>
                              <p className="text-lg font-bold text-pink-600 mt-1">
                                {formatPrice(listing.price)}
                              </p>
                            </div>
                            <Badge variant={getStatusVariant(listing.status)}>
                              {STATUS_LABELS[listing.status]}
                            </Badge>
                          </div>

                          <div className="flex items-center gap-4 mt-2 text-sm text-gray-500">
                            <span>{listing.viewCount} views</span>
                            <span>{listing.saveCount} saves</span>
                            <span>Listed {formatRelativeTime(listing.createdAt)}</span>
                          </div>

                          {/* Actions */}
                          <div className="flex items-center gap-2 mt-3">
                            <Link href={`/sell/${listing.id}/edit`}>
                              <Button variant="outline" size="sm">
                                <PencilIcon className="w-4 h-4 mr-1" />
                                Edit
                              </Button>
                            </Link>

                            {listing.status === 'DRAFT' && (
                              <Button
                                size="sm"
                                onClick={() => {
                                  setSelectedListing(listing);
                                  setActionModal('publish');
                                }}
                              >
                                Publish
                              </Button>
                            )}

                            {listing.status === 'ACTIVE' && (
                              <>
                                <Button
                                  variant="outline"
                                  size="sm"
                                  onClick={() => {
                                    setSelectedListing(listing);
                                    setActionModal('sold');
                                  }}
                                >
                                  <CheckCircleIcon className="w-4 h-4 mr-1" />
                                  Mark Sold
                                </Button>
                                <Button
                                  variant="ghost"
                                  size="sm"
                                  onClick={() => {
                                    setSelectedListing(listing);
                                    setActionModal('archive');
                                  }}
                                >
                                  <ArchiveBoxIcon className="w-4 h-4 mr-1" />
                                  Archive
                                </Button>
                              </>
                            )}

                            <Button
                              variant="ghost"
                              size="sm"
                              onClick={() => {
                                setSelectedListing(listing);
                                setActionModal('delete');
                              }}
                              className="text-red-600 hover:text-red-700 hover:bg-red-50"
                            >
                              <TrashIcon className="w-4 h-4" />
                            </Button>
                          </div>
                        </div>
                      </div>
                    </CardContent>
                  </Card>
                ))}
              </div>
            )}
          </div>
        </div>
      </main>

      <Footer />

      {/* Action Confirmation Modal */}
      {actionModal && selectedListing && (
        <Modal
          isOpen={!!actionModal}
          onClose={() => {
            setActionModal(null);
            setSelectedListing(null);
          }}
          title={
            actionModal === 'delete'
              ? 'Delete Listing'
              : actionModal === 'archive'
              ? 'Archive Listing'
              : actionModal === 'publish'
              ? 'Publish Listing'
              : 'Mark as Sold'
          }
          size="sm"
        >
          <p className="text-gray-600">
            {actionModal === 'delete' && (
              <>
                Are you sure you want to delete &quot;{selectedListing.title}&quot;? This action cannot be
                undone.
              </>
            )}
            {actionModal === 'archive' && (
              <>
                Archive &quot;{selectedListing.title}&quot;? It will be hidden from buyers but you can
                restore it later.
              </>
            )}
            {actionModal === 'sold' && (
              <>
                Mark &quot;{selectedListing.title}&quot; as sold? This will remove it from active listings.
              </>
            )}
            {actionModal === 'publish' && (
              <>
                Publish &quot;{selectedListing.title}&quot;? It will be submitted for review before going live.
              </>
            )}
          </p>

          <ModalFooter>
            <Button
              variant="outline"
              onClick={() => {
                setActionModal(null);
                setSelectedListing(null);
              }}
            >
              Cancel
            </Button>
            <Button
              onClick={handleAction}
              loading={actionLoading}
              className={actionModal === 'delete' ? 'bg-red-600 hover:bg-red-700' : ''}
            >
              {actionModal === 'delete' && 'Delete'}
              {actionModal === 'archive' && 'Archive'}
              {actionModal === 'sold' && 'Mark Sold'}
              {actionModal === 'publish' && 'Publish'}
            </Button>
          </ModalFooter>
        </Modal>
      )}
    </div>
  );
}
