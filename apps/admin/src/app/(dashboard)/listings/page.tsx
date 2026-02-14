'use client';

import { useState, useEffect } from 'react';
import { Header } from '@/components/layout/Header';
import { Card, CardContent, CardHeader, CardTitle } from '@/components/ui/Card';
import { Badge, getStatusVariant } from '@/components/ui/Badge';
import { Button } from '@/components/ui/Button';
import { Modal } from '@/components/ui/Modal';
import { ConfirmDialog } from '@/components/ui/ConfirmDialog';
import {
  Table,
  TableHeader,
  TableBody,
  TableRow,
  TableHead,
  TableCell,
} from '@/components/ui/Table';
import {
  FunnelIcon,
  MagnifyingGlassIcon,
  EyeIcon,
  CheckCircleIcon,
  XCircleIcon,
  TrashIcon,
  PauseCircleIcon,
  XMarkIcon,
} from '@heroicons/react/24/outline';
import { api } from '@/lib/api';
import type { Listing, ListingStatus, ListingCategory } from '@/types';

const statuses: ListingStatus[] = ['PENDING', 'ACTIVE', 'SOLD', 'REJECTED', 'ARCHIVED'];
const categories: ListingCategory[] = [
  'DRESSES',
  'TOPS',
  'BOTTOMS',
  'TRADITIONAL_WEAR',
  'SHOES',
  'ACCESSORIES',
  'BAGS',
  'OTHER',
];

export default function ListingsPage() {
  const [listings, setListings] = useState<Listing[]>([]);
  const [loading, setLoading] = useState(true);
  const [search, setSearch] = useState('');
  const [statusFilter, setStatusFilter] = useState<string>('');
  const [categoryFilter, setCategoryFilter] = useState<string>('');
  const [page, setPage] = useState(1);
  const [totalPages, setTotalPages] = useState(1);
  const [viewModalOpen, setViewModalOpen] = useState(false);
  const [selectedListing, setSelectedListing] = useState<Listing | null>(null);
  const [viewLoading, setViewLoading] = useState(false);
  const [deleteTarget, setDeleteTarget] = useState<{ id: string; title: string } | null>(null);
  const [deleteLoading, setDeleteLoading] = useState(false);

  useEffect(() => {
    loadListings();
  }, [page, statusFilter, categoryFilter]);

  const loadListings = async () => {
    setLoading(true);
    try {
      const response = await api.getListings({
        page,
        limit: 10,
        status: statusFilter || undefined,
        category: categoryFilter || undefined,
      });

      if (response && !Array.isArray(response) && response.data) {
        setListings(response.data);
        setTotalPages(response.totalPages || 1);
      } else if (Array.isArray(response)) {
        setListings(response);
      } else {
        // Mock data for demo
        setListings([
          {
            id: '1',
            sellerId: 'user1',
            title: 'Elegant Wedding Dress',
            description: 'Beautiful white wedding dress',
            price: 1500000,
            category: 'DRESSES',
            condition: 'LIKE_NEW',
            imageUrls: ['https://via.placeholder.com/100'],
            status: 'PENDING',
            viewCount: 45,
            saveCount: 12,
            createdAt: new Date().toISOString(),
            updatedAt: new Date().toISOString(),
          },
          {
            id: '2',
            sellerId: 'user2',
            title: 'Designer Handbag',
            description: 'Authentic designer handbag',
            price: 350000,
            category: 'BAGS',
            condition: 'NEW',
            imageUrls: ['https://via.placeholder.com/100'],
            status: 'ACTIVE',
            viewCount: 120,
            saveCount: 35,
            createdAt: new Date().toISOString(),
            updatedAt: new Date().toISOString(),
          },
        ]);
      }
    } catch (error) {
      console.error('Failed to load listings:', error);
      setListings([]);
    } finally {
      setLoading(false);
    }
  };

  const handleApprove = async (id: string) => {
    try {
      await api.approveListing(id);
      loadListings();
    } catch (error) {
      console.error('Failed to approve listing:', error);
    }
  };

  const handleReject = async (id: string) => {
    const reason = prompt('Enter rejection reason:');
    if (reason) {
      try {
        await api.rejectListing(id, reason);
        loadListings();
      } catch (error) {
        console.error('Failed to reject listing:', error);
      }
    }
  };

  const handleConfirmDelete = async () => {
    if (!deleteTarget) return;
    setDeleteLoading(true);
    try {
      await api.deleteListing(deleteTarget.id);
      setDeleteTarget(null);
      loadListings();
    } catch (error) {
      console.error('Failed to delete listing:', error);
    } finally {
      setDeleteLoading(false);
    }
  };

  const handleSuspend = async (id: string) => {
    const reason = prompt('Enter suspension reason (optional):');
    try {
      await api.suspendListing(id, reason || undefined);
      loadListings();
    } catch (error) {
      console.error('Failed to suspend listing:', error);
      alert('Failed to suspend listing');
    }
  };

  const handleView = async (listing: Listing) => {
    setViewLoading(true);
    setViewModalOpen(true);
    try {
      const details = await api.getListing(listing.id);
      setSelectedListing(details);
    } catch (error) {
      console.error('Failed to load listing details:', error);
      setSelectedListing(listing);
    } finally {
      setViewLoading(false);
    }
  };

  const closeViewModal = () => {
    setViewModalOpen(false);
    setSelectedListing(null);
  };

  const filteredListings = listings.filter((listing) =>
    listing.title.toLowerCase().includes(search.toLowerCase())
  );

  return (
    <div>
      <Header title="Listings" />

      <div className="p-6">
        {/* Filters */}
        <Card className="mb-6">
          <CardContent className="py-4">
            <div className="flex flex-wrap items-center gap-4">
              {/* Search */}
              <div className="relative flex-1 min-w-[200px]">
                <MagnifyingGlassIcon className="absolute left-3 top-1/2 h-4 w-4 -translate-y-1/2 text-gray-400" />
                <input
                  type="text"
                  placeholder="Search listings..."
                  value={search}
                  onChange={(e) => setSearch(e.target.value)}
                  className="h-9 w-full rounded-md border border-gray-300 pl-9 pr-3 text-sm focus:border-primary-500 focus:outline-none focus:ring-1 focus:ring-primary-500"
                />
              </div>

              {/* Status Filter */}
              <select
                value={statusFilter}
                onChange={(e) => setStatusFilter(e.target.value)}
                className="h-9 rounded-md border border-gray-300 px-3 text-sm focus:border-primary-500 focus:outline-none focus:ring-1 focus:ring-primary-500"
              >
                <option value="">All Statuses</option>
                {statuses.map((status) => (
                  <option key={status} value={status}>
                    {status}
                  </option>
                ))}
              </select>

              {/* Category Filter */}
              <select
                value={categoryFilter}
                onChange={(e) => setCategoryFilter(e.target.value)}
                className="h-9 rounded-md border border-gray-300 px-3 text-sm focus:border-primary-500 focus:outline-none focus:ring-1 focus:ring-primary-500"
              >
                <option value="">All Categories</option>
                {categories.map((category) => (
                  <option key={category} value={category}>
                    {category.replace('_', ' ')}
                  </option>
                ))}
              </select>
            </div>
          </CardContent>
        </Card>

        {/* Listings Table */}
        <Card>
          <CardContent className="p-0">
            {loading ? (
              <div className="flex items-center justify-center py-12">
                <div className="h-8 w-8 animate-spin rounded-full border-4 border-primary-500 border-t-transparent" />
              </div>
            ) : (
              <>
                <Table>
                  <TableHeader>
                    <TableRow>
                      <TableHead className="w-[35%]">Item</TableHead>
                      <TableHead className="w-[14%]">Category</TableHead>
                      <TableHead className="w-[12%]">Price</TableHead>
                      <TableHead className="w-[10%]">Status</TableHead>
                      <TableHead className="hidden lg:table-cell w-[7%]">Views</TableHead>
                      <TableHead className="hidden lg:table-cell w-[7%]">Saves</TableHead>
                      <TableHead className="w-[15%]">Actions</TableHead>
                    </TableRow>
                  </TableHeader>
                  <TableBody>
                    {filteredListings.length > 0 ? (
                      filteredListings.map((listing) => (
                        <TableRow key={listing.id}>
                          <TableCell>
                            <div className="flex items-center min-w-0">
                              {listing.imageUrls?.[0] && (
                                <img
                                  src={listing.imageUrls[0]}
                                  alt={listing.title}
                                  className="mr-3 h-10 w-10 shrink-0 rounded-md object-cover"
                                />
                              )}
                              <div className="min-w-0">
                                <p className="font-medium truncate" title={listing.title}>{listing.title}</p>
                                <p className="text-xs text-gray-500">
                                  {listing.condition}
                                </p>
                              </div>
                            </div>
                          </TableCell>
                          <TableCell>
                            <Badge>{listing.categoryData?.name || listing.category?.replace('_', ' ') || 'Uncategorized'}</Badge>
                          </TableCell>
                          <TableCell className="whitespace-nowrap">
                            UGX {listing.price.toLocaleString()}
                          </TableCell>
                          <TableCell className="whitespace-nowrap">
                            <Badge variant={getStatusVariant(listing.status)}>
                              {listing.status}
                            </Badge>
                          </TableCell>
                          <TableCell className="hidden lg:table-cell">{listing.viewCount}</TableCell>
                          <TableCell className="hidden lg:table-cell">{listing.saveCount}</TableCell>
                          <TableCell>
                            <div className="flex gap-1">
                              <Button
                                size="sm"
                                variant="ghost"
                                title="View"
                                onClick={() => handleView(listing)}
                              >
                                <EyeIcon className="h-4 w-4" />
                              </Button>
                              {listing.status === 'PENDING' && (
                                <>
                                  <Button
                                    size="sm"
                                    variant="ghost"
                                    title="Approve"
                                    onClick={() => handleApprove(listing.id)}
                                  >
                                    <CheckCircleIcon className="h-4 w-4 text-green-600" />
                                  </Button>
                                  <Button
                                    size="sm"
                                    variant="ghost"
                                    title="Reject"
                                    onClick={() => handleReject(listing.id)}
                                  >
                                    <XCircleIcon className="h-4 w-4 text-red-600" />
                                  </Button>
                                </>
                              )}
                              {listing.status === 'ACTIVE' && (
                                <Button
                                  size="sm"
                                  variant="ghost"
                                  title="Suspend"
                                  onClick={() => handleSuspend(listing.id)}
                                >
                                  <PauseCircleIcon className="h-4 w-4 text-orange-500" />
                                </Button>
                              )}
                              <Button
                                size="sm"
                                variant="ghost"
                                title="Delete"
                                onClick={() => setDeleteTarget({ id: listing.id, title: listing.title })}
                              >
                                <TrashIcon className="h-4 w-4 text-red-600" />
                              </Button>
                            </div>
                          </TableCell>
                        </TableRow>
                      ))
                    ) : (
                      <TableRow>
                        <TableCell className="text-center py-12 text-gray-500" colSpan={7}>
                          No listings found
                        </TableCell>
                      </TableRow>
                    )}
                  </TableBody>
                </Table>

                {/* Pagination */}
                <div className="flex items-center justify-between border-t px-6 py-3">
                  <p className="text-sm text-gray-500">
                    Page {page} of {totalPages}
                  </p>
                  <div className="flex gap-2">
                    <Button
                      size="sm"
                      variant="secondary"
                      disabled={page === 1}
                      onClick={() => setPage((p) => p - 1)}
                    >
                      Previous
                    </Button>
                    <Button
                      size="sm"
                      variant="secondary"
                      disabled={page === totalPages}
                      onClick={() => setPage((p) => p + 1)}
                    >
                      Next
                    </Button>
                  </div>
                </div>
              </>
            )}
          </CardContent>
        </Card>
      </div>

      {/* Delete Confirmation */}
      <ConfirmDialog
        isOpen={!!deleteTarget}
        onClose={() => setDeleteTarget(null)}
        onConfirm={handleConfirmDelete}
        title="Delete Listing?"
        message={`Are you sure you want to delete "${deleteTarget?.title}"? This action cannot be undone.`}
        loading={deleteLoading}
      />

      {/* View Listing Modal */}
      <Modal isOpen={viewModalOpen} onClose={closeViewModal} title="Listing Details">
        {viewLoading ? (
          <div className="flex items-center justify-center py-12">
            <div className="h-8 w-8 animate-spin rounded-full border-4 border-primary-500 border-t-transparent" />
          </div>
        ) : selectedListing ? (
          <div className="space-y-6">
            {/* Images */}
            {selectedListing.imageUrls && selectedListing.imageUrls.length > 0 && (
              <div className="grid grid-cols-3 gap-2">
                {selectedListing.imageUrls.slice(0, 6).map((url, index) => (
                  <img
                    key={index}
                    src={url}
                    alt={`${selectedListing.title} image ${index + 1}`}
                    className="w-full h-24 object-cover rounded-md"
                  />
                ))}
              </div>
            )}

            {/* Basic Info */}
            <div>
              <h3 className="text-lg font-semibold">{selectedListing.title}</h3>
              <p className="text-2xl font-bold text-primary-500 mt-1">
                UGX {selectedListing.price.toLocaleString()}
              </p>
            </div>

            {/* Status & Category */}
            <div className="flex gap-2">
              <Badge variant={getStatusVariant(selectedListing.status)}>
                {selectedListing.status}
              </Badge>
              <Badge>{selectedListing.categoryData?.name || selectedListing.category?.replace('_', ' ') || 'Uncategorized'}</Badge>
              <Badge variant="info">{selectedListing.condition}</Badge>
            </div>

            {/* Description */}
            <div>
              <h4 className="text-sm font-medium text-gray-500 mb-1">Description</h4>
              <p className="text-sm text-gray-700">{selectedListing.description}</p>
            </div>

            {/* Details Grid */}
            <div className="grid grid-cols-2 gap-4 text-sm">
              {/* Display new attributes system if available */}
              {selectedListing.attributes && Object.keys(selectedListing.attributes).length > 0 ? (
                Object.entries(selectedListing.attributes).map(([key, value]) => (
                  <div key={key}>
                    <span className="text-gray-500">{key.replace(/-/g, ' ').replace(/_/g, ' ').replace(/\b\w/g, c => c.toUpperCase())}:</span>{' '}
                    <span className="font-medium">{Array.isArray(value) ? value.join(', ') : String(value)}</span>
                  </div>
                ))
              ) : (
                <>
                  {selectedListing.size && (
                    <div>
                      <span className="text-gray-500">Size:</span>{' '}
                      <span className="font-medium">{selectedListing.size}</span>
                    </div>
                  )}
                  {selectedListing.brand && (
                    <div>
                      <span className="text-gray-500">Brand:</span>{' '}
                      <span className="font-medium">{selectedListing.brand}</span>
                    </div>
                  )}
                  {selectedListing.color && (
                    <div>
                      <span className="text-gray-500">Color:</span>{' '}
                      <span className="font-medium">{selectedListing.color}</span>
                    </div>
                  )}
                </>
              )}
              {/* Location - check for new system or legacy */}
              {(selectedListing.city || selectedListing.division || selectedListing.location) && (
                <div>
                  <span className="text-gray-500">Location:</span>{' '}
                  <span className="font-medium">
                    {selectedListing.division?.name && selectedListing.city?.name
                      ? `${selectedListing.division.name}, ${selectedListing.city.name}`
                      : selectedListing.city?.name || selectedListing.location}
                  </span>
                </div>
              )}
              <div>
                <span className="text-gray-500">Views:</span>{' '}
                <span className="font-medium">{selectedListing.viewCount}</span>
              </div>
              <div>
                <span className="text-gray-500">Saves:</span>{' '}
                <span className="font-medium">{selectedListing.saveCount}</span>
              </div>
            </div>

            {/* Seller Info */}
            {selectedListing.seller && (
              <div className="border-t pt-4">
                <h4 className="text-sm font-medium text-gray-500 mb-2">Seller</h4>
                <div className="flex items-center gap-3">
                  {selectedListing.seller.photoUrl ? (
                    <img
                      src={selectedListing.seller.photoUrl}
                      alt={selectedListing.seller.displayName || 'Seller'}
                      className="h-10 w-10 rounded-full object-cover"
                    />
                  ) : (
                    <div className="h-10 w-10 rounded-full bg-gray-200 flex items-center justify-center">
                      <span className="text-gray-500 text-sm">
                        {(selectedListing.seller.displayName || 'U')[0].toUpperCase()}
                      </span>
                    </div>
                  )}
                  <div>
                    <p className="font-medium">{selectedListing.seller.displayName || 'Unknown'}</p>
                    <p className="text-xs text-gray-500">ID: {selectedListing.sellerId}</p>
                  </div>
                </div>
              </div>
            )}

            {/* Rejection Reason (if any) */}
            {selectedListing.rejectionReason && (
              <div className="bg-red-50 border border-red-200 rounded-md p-3">
                <h4 className="text-sm font-medium text-red-800 mb-1">Rejection/Suspension Reason</h4>
                <p className="text-sm text-red-700">{selectedListing.rejectionReason}</p>
              </div>
            )}

            {/* Actions */}
            <div className="flex gap-2 border-t pt-4">
              {selectedListing.status === 'PENDING' && (
                <>
                  <Button
                    onClick={() => {
                      handleApprove(selectedListing.id);
                      closeViewModal();
                    }}
                  >
                    <CheckCircleIcon className="h-4 w-4 mr-1" />
                    Approve
                  </Button>
                  <Button
                    variant="danger"
                    onClick={() => {
                      handleReject(selectedListing.id);
                      closeViewModal();
                    }}
                  >
                    <XCircleIcon className="h-4 w-4 mr-1" />
                    Reject
                  </Button>
                </>
              )}
              {selectedListing.status === 'ACTIVE' && (
                <Button
                  variant="secondary"
                  onClick={() => {
                    handleSuspend(selectedListing.id);
                    closeViewModal();
                  }}
                >
                  <PauseCircleIcon className="h-4 w-4 mr-1" />
                  Suspend
                </Button>
              )}
              <Button variant="ghost" onClick={closeViewModal}>
                Close
              </Button>
            </div>
          </div>
        ) : (
          <p className="text-gray-500 py-8 text-center">No listing selected</p>
        )}
      </Modal>
    </div>
  );
}
