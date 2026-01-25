'use client';

import { useState, useEffect } from 'react';
import { Header } from '@/components/layout/Header';
import { Card, CardContent } from '@/components/ui/Card';
import { Badge, getStatusVariant } from '@/components/ui/Badge';
import { Button } from '@/components/ui/Button';
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

  const handleDelete = async (id: string) => {
    if (confirm('Are you sure you want to delete this listing?')) {
      try {
        await api.deleteListing(id);
        loadListings();
      } catch (error) {
        console.error('Failed to delete listing:', error);
      }
    }
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
                  className="h-9 w-full rounded-md border border-gray-300 pl-9 pr-3 text-sm focus:border-blue-500 focus:outline-none focus:ring-1 focus:ring-blue-500"
                />
              </div>

              {/* Status Filter */}
              <select
                value={statusFilter}
                onChange={(e) => setStatusFilter(e.target.value)}
                className="h-9 rounded-md border border-gray-300 px-3 text-sm focus:border-blue-500 focus:outline-none focus:ring-1 focus:ring-blue-500"
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
                className="h-9 rounded-md border border-gray-300 px-3 text-sm focus:border-blue-500 focus:outline-none focus:ring-1 focus:ring-blue-500"
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
                <div className="h-8 w-8 animate-spin rounded-full border-4 border-blue-600 border-t-transparent" />
              </div>
            ) : (
              <>
                <Table>
                  <TableHeader>
                    <TableRow>
                      <TableHead>Item</TableHead>
                      <TableHead>Category</TableHead>
                      <TableHead>Price</TableHead>
                      <TableHead>Status</TableHead>
                      <TableHead>Views</TableHead>
                      <TableHead>Saves</TableHead>
                      <TableHead>Actions</TableHead>
                    </TableRow>
                  </TableHeader>
                  <TableBody>
                    {filteredListings.length > 0 ? (
                      filteredListings.map((listing) => (
                        <TableRow key={listing.id}>
                          <TableCell>
                            <div className="flex items-center">
                              {listing.imageUrls?.[0] && (
                                <img
                                  src={listing.imageUrls[0]}
                                  alt={listing.title}
                                  className="mr-3 h-12 w-12 rounded-md object-cover"
                                />
                              )}
                              <div>
                                <p className="font-medium">{listing.title}</p>
                                <p className="text-xs text-gray-500">
                                  {listing.condition}
                                </p>
                              </div>
                            </div>
                          </TableCell>
                          <TableCell>
                            <Badge>{listing.category?.replace('_', ' ') || 'Uncategorized'}</Badge>
                          </TableCell>
                          <TableCell>
                            UGX {listing.price.toLocaleString()}
                          </TableCell>
                          <TableCell>
                            <Badge variant={getStatusVariant(listing.status)}>
                              {listing.status}
                            </Badge>
                          </TableCell>
                          <TableCell>{listing.viewCount}</TableCell>
                          <TableCell>{listing.saveCount}</TableCell>
                          <TableCell>
                            <div className="flex gap-1">
                              <Button size="sm" variant="ghost" title="View">
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
                              <Button
                                size="sm"
                                variant="ghost"
                                title="Delete"
                                onClick={() => handleDelete(listing.id)}
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
    </div>
  );
}
