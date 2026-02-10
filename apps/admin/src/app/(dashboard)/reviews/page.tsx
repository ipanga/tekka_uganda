'use client';

import { useState, useEffect } from 'react';
import { Header } from '@/components/layout/Header';
import { Card, CardContent } from '@/components/ui/Card';
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
  MagnifyingGlassIcon,
  TrashIcon,
  StarIcon,
  EyeIcon,
} from '@heroicons/react/24/outline';
import { StarIcon as StarSolidIcon } from '@heroicons/react/24/solid';
import { api } from '@/lib/api';
import { format } from 'date-fns';
import { Modal, ModalFooter } from '@/components/ui/Modal';
import { ConfirmDialog } from '@/components/ui/ConfirmDialog';

interface Review {
  id: string;
  rating: number;
  comment: string | null;
  type: 'BUYER' | 'SELLER';
  createdAt: string;
  reviewer: {
    id: string;
    displayName: string;
    photoUrl: string | null;
  };
  reviewee: {
    id: string;
    displayName: string;
    photoUrl: string | null;
  };
  listing: {
    id: string;
    title: string;
  } | null;
}

export default function ReviewsPage() {
  const [reviews, setReviews] = useState<Review[]>([]);
  const [loading, setLoading] = useState(true);
  const [search, setSearch] = useState('');
  const [page, setPage] = useState(1);
  const [totalPages, setTotalPages] = useState(1);
  const [selectedReview, setSelectedReview] = useState<Review | null>(null);
  const [deleteTarget, setDeleteTarget] = useState<{ id: string; label: string } | null>(null);
  const [deleteLoading, setDeleteLoading] = useState(false);

  useEffect(() => {
    loadReviews();
  }, [page]);

  const loadReviews = async () => {
    setLoading(true);
    try {
      const response = await api.getReviews({
        page,
        limit: 10,
        search: search || undefined,
      });

      if (response && !Array.isArray(response) && Array.isArray(response.data)) {
        setReviews(response.data);
        setTotalPages(response.totalPages || 1);
      } else if (Array.isArray(response)) {
        setReviews(response);
      } else {
        setReviews([]);
      }
    } catch (error) {
      console.error('Failed to load reviews:', error);
      setReviews([]);
    } finally {
      setLoading(false);
    }
  };

  const handleSearch = () => {
    setPage(1);
    loadReviews();
  };

  const handleConfirmDelete = async () => {
    if (!deleteTarget) return;
    setDeleteLoading(true);
    try {
      await api.deleteReview(deleteTarget.id);
      setDeleteTarget(null);
      setSelectedReview(null);
      loadReviews();
    } catch (error) {
      console.error('Failed to delete review:', error);
    } finally {
      setDeleteLoading(false);
    }
  };

  const renderStars = (rating: number) => {
    return (
      <div className="flex gap-0.5">
        {[1, 2, 3, 4, 5].map((star) => (
          star <= rating ? (
            <StarSolidIcon key={star} className="h-4 w-4 text-yellow-400" />
          ) : (
            <StarIcon key={star} className="h-4 w-4 text-gray-300" />
          )
        ))}
      </div>
    );
  };

  return (
    <div>
      <Header title="Reviews" />

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
                  placeholder="Search by reviewer, reviewee, or comment..."
                  value={search}
                  onChange={(e) => setSearch(e.target.value)}
                  onKeyDown={(e) => e.key === 'Enter' && handleSearch()}
                  className="h-9 w-full rounded-md border border-gray-300 pl-9 pr-3 text-sm focus:border-blue-500 focus:outline-none focus:ring-1 focus:ring-blue-500"
                />
              </div>
              <Button size="sm" onClick={handleSearch}>
                Search
              </Button>
            </div>
          </CardContent>
        </Card>

        {/* Reviews Table */}
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
                      <TableHead>Reviewer</TableHead>
                      <TableHead>Reviewee</TableHead>
                      <TableHead>Rating</TableHead>
                      <TableHead>Comment</TableHead>
                      <TableHead>Type</TableHead>
                      <TableHead>Date</TableHead>
                      <TableHead>Actions</TableHead>
                    </TableRow>
                  </TableHeader>
                  <TableBody>
                    {reviews.length > 0 ? (
                      reviews.map((review) => (
                        <TableRow key={review.id}>
                          <TableCell>
                            <div className="flex items-center">
                              {review.reviewer.photoUrl ? (
                                <img
                                  src={review.reviewer.photoUrl}
                                  alt={review.reviewer.displayName || ''}
                                  className="mr-2 h-8 w-8 rounded-full object-cover"
                                />
                              ) : (
                                <div className="mr-2 h-8 w-8 rounded-full bg-gray-200 flex items-center justify-center">
                                  <span className="text-gray-500 text-xs font-medium">
                                    {review.reviewer.displayName?.charAt(0) || '?'}
                                  </span>
                                </div>
                              )}
                              <span className="text-sm font-medium">
                                {review.reviewer.displayName || 'Unknown'}
                              </span>
                            </div>
                          </TableCell>
                          <TableCell>
                            <div className="flex items-center">
                              {review.reviewee.photoUrl ? (
                                <img
                                  src={review.reviewee.photoUrl}
                                  alt={review.reviewee.displayName || ''}
                                  className="mr-2 h-8 w-8 rounded-full object-cover"
                                />
                              ) : (
                                <div className="mr-2 h-8 w-8 rounded-full bg-gray-200 flex items-center justify-center">
                                  <span className="text-gray-500 text-xs font-medium">
                                    {review.reviewee.displayName?.charAt(0) || '?'}
                                  </span>
                                </div>
                              )}
                              <span className="text-sm font-medium">
                                {review.reviewee.displayName || 'Unknown'}
                              </span>
                            </div>
                          </TableCell>
                          <TableCell>
                            {renderStars(review.rating)}
                          </TableCell>
                          <TableCell>
                            <p className="text-sm text-gray-600 max-w-xs truncate">
                              {review.comment || '-'}
                            </p>
                            {review.listing && (
                              <p className="text-xs text-gray-400 mt-1">
                                Re: {review.listing.title}
                              </p>
                            )}
                          </TableCell>
                          <TableCell>
                            <span className={`inline-flex items-center px-2 py-1 rounded-full text-xs font-medium ${
                              review.type === 'BUYER'
                                ? 'bg-blue-100 text-blue-700'
                                : 'bg-purple-100 text-purple-700'
                            }`}>
                              {review.type === 'BUYER' ? 'Buyer Review' : 'Seller Review'}
                            </span>
                          </TableCell>
                          <TableCell>
                            {format(new Date(review.createdAt), 'MMM d, yyyy')}
                          </TableCell>
                          <TableCell>
                            <div className="flex gap-1">
                              <Button
                                size="sm"
                                variant="ghost"
                                title="View Details"
                                onClick={() => setSelectedReview(review)}
                              >
                                <EyeIcon className="h-4 w-4" />
                              </Button>
                              <Button
                                size="sm"
                                variant="ghost"
                                title="Delete Review"
                                onClick={() => setDeleteTarget({ id: review.id, label: `${review.reviewer.displayName || 'Unknown'}'s review` })}
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
                          No reviews found
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

      {/* Review Detail Modal */}
      {selectedReview && (
        <Modal
          isOpen={!!selectedReview}
          onClose={() => setSelectedReview(null)}
          title="Review Details"
          size="md"
        >
          <div className="space-y-4">
            {/* Reviewer Info */}
            <div className="flex items-center gap-3 p-3 bg-gray-50 rounded-lg">
              {selectedReview.reviewer.photoUrl ? (
                <img
                  src={selectedReview.reviewer.photoUrl}
                  alt={selectedReview.reviewer.displayName || ''}
                  className="h-12 w-12 rounded-full object-cover"
                />
              ) : (
                <div className="h-12 w-12 rounded-full bg-gray-200 flex items-center justify-center">
                  <span className="text-gray-500 font-medium">
                    {selectedReview.reviewer.displayName?.charAt(0) || '?'}
                  </span>
                </div>
              )}
              <div>
                <p className="font-medium">{selectedReview.reviewer.displayName || 'Unknown'}</p>
                <p className="text-sm text-gray-500">Reviewer</p>
              </div>
            </div>

            {/* Reviewee Info */}
            <div className="flex items-center gap-3 p-3 bg-gray-50 rounded-lg">
              {selectedReview.reviewee.photoUrl ? (
                <img
                  src={selectedReview.reviewee.photoUrl}
                  alt={selectedReview.reviewee.displayName || ''}
                  className="h-12 w-12 rounded-full object-cover"
                />
              ) : (
                <div className="h-12 w-12 rounded-full bg-gray-200 flex items-center justify-center">
                  <span className="text-gray-500 font-medium">
                    {selectedReview.reviewee.displayName?.charAt(0) || '?'}
                  </span>
                </div>
              )}
              <div>
                <p className="font-medium">{selectedReview.reviewee.displayName || 'Unknown'}</p>
                <p className="text-sm text-gray-500">Reviewee</p>
              </div>
            </div>

            {/* Rating */}
            <div>
              <p className="text-sm font-medium text-gray-700 mb-1">Rating</p>
              <div className="flex items-center gap-2">
                {renderStars(selectedReview.rating)}
                <span className="text-sm text-gray-600">({selectedReview.rating}/5)</span>
              </div>
            </div>

            {/* Comment */}
            <div>
              <p className="text-sm font-medium text-gray-700 mb-1">Comment</p>
              <p className="text-gray-600 bg-gray-50 p-3 rounded-lg">
                {selectedReview.comment || 'No comment provided'}
              </p>
            </div>

            {/* Listing */}
            {selectedReview.listing && (
              <div>
                <p className="text-sm font-medium text-gray-700 mb-1">Related Listing</p>
                <p className="text-gray-600">{selectedReview.listing.title}</p>
              </div>
            )}

            {/* Type and Date */}
            <div className="flex justify-between text-sm text-gray-500">
              <span className={`inline-flex items-center px-2 py-1 rounded-full text-xs font-medium ${
                selectedReview.type === 'BUYER'
                  ? 'bg-blue-100 text-blue-700'
                  : 'bg-purple-100 text-purple-700'
              }`}>
                {selectedReview.type === 'BUYER' ? 'Buyer Review' : 'Seller Review'}
              </span>
              <span>{format(new Date(selectedReview.createdAt), 'MMM d, yyyy h:mm a')}</span>
            </div>
          </div>

          <ModalFooter>
            <Button variant="secondary" onClick={() => setSelectedReview(null)}>
              Close
            </Button>
            <Button
              variant="danger"
              onClick={() => {
                setDeleteTarget({ id: selectedReview.id, label: `${selectedReview.reviewer.displayName || 'Unknown'}'s review` });
              }}
            >
              Delete Review
            </Button>
          </ModalFooter>
        </Modal>
      )}
      {/* Delete Confirmation */}
      <ConfirmDialog
        isOpen={!!deleteTarget}
        onClose={() => setDeleteTarget(null)}
        onConfirm={handleConfirmDelete}
        title="Delete Review?"
        message={`Are you sure you want to delete ${deleteTarget?.label}? This action cannot be undone.`}
        loading={deleteLoading}
      />
    </div>
  );
}
