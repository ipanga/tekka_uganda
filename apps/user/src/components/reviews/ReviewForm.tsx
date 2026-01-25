'use client';

import { useState } from 'react';
import { StarIcon } from '@heroicons/react/24/solid';
import { StarIcon as StarOutlineIcon } from '@heroicons/react/24/outline';
import { api } from '@/lib/api';
import { Review } from '@/types';
import { Button } from '@/components/ui/Button';
import { Textarea } from '@/components/ui/Textarea';
import { Modal, ModalFooter } from '@/components/ui/Modal';

interface ReviewFormProps {
  isOpen: boolean;
  onClose: () => void;
  revieweeId: string;
  listingId?: string;
  offerId?: string;
  onSuccess?: (review: Review) => void;
}

const RATING_LABELS = [
  '',
  'Poor',
  'Fair',
  'Good',
  'Very Good',
  'Excellent',
];

export function ReviewForm({
  isOpen,
  onClose,
  revieweeId,
  listingId,
  offerId,
  onSuccess,
}: ReviewFormProps) {
  const [rating, setRating] = useState(0);
  const [hoverRating, setHoverRating] = useState(0);
  const [comment, setComment] = useState('');
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState<string | null>(null);

  const handleSubmit = async () => {
    if (rating === 0) {
      setError('Please select a rating');
      return;
    }

    setError(null);
    setLoading(true);

    try {
      const review = await api.createReview({
        revieweeId,
        listingId,
        rating,
        comment: comment.trim() || undefined,
      });

      onSuccess?.(review);
      handleClose();
    } catch (err) {
      setError(err instanceof Error ? err.message : 'Failed to submit review');
    } finally {
      setLoading(false);
    }
  };

  const handleClose = () => {
    setRating(0);
    setHoverRating(0);
    setComment('');
    setError(null);
    onClose();
  };

  const displayRating = hoverRating || rating;

  return (
    <Modal isOpen={isOpen} onClose={handleClose} title="Leave a Review" size="md">
      <div className="space-y-6">
        {/* Rating Stars */}
        <div className="text-center">
          <p className="text-sm text-gray-500 mb-3">
            How was your experience with this seller?
          </p>

          <div className="flex justify-center gap-2">
            {[1, 2, 3, 4, 5].map((star) => (
              <button
                key={star}
                type="button"
                onClick={() => setRating(star)}
                onMouseEnter={() => setHoverRating(star)}
                onMouseLeave={() => setHoverRating(0)}
                className="p-1 transition-transform hover:scale-110"
              >
                {star <= displayRating ? (
                  <StarIcon className="w-10 h-10 text-yellow-400" />
                ) : (
                  <StarOutlineIcon className="w-10 h-10 text-gray-300" />
                )}
              </button>
            ))}
          </div>

          {displayRating > 0 && (
            <p className="text-lg font-medium text-gray-900 mt-2">
              {RATING_LABELS[displayRating]}
            </p>
          )}
        </div>

        {/* Comment */}
        <Textarea
          label="Your Review (Optional)"
          value={comment}
          onChange={(e) => setComment(e.target.value)}
          placeholder="Tell others about your experience..."
          rows={4}
          maxLength={500}
          helperText={`${comment.length}/500 characters`}
        />

        {/* Error */}
        {error && (
          <div className="p-3 bg-red-50 border border-red-200 rounded-lg">
            <p className="text-sm text-red-600">{error}</p>
          </div>
        )}

        {/* Guidelines */}
        <div className="p-4 bg-gray-50 rounded-lg text-sm text-gray-600">
          <p className="font-medium text-gray-700 mb-2">Review Guidelines</p>
          <ul className="list-disc list-inside space-y-1">
            <li>Be honest and helpful to other buyers</li>
            <li>Focus on the transaction experience</li>
            <li>Avoid personal attacks or inappropriate language</li>
            <li>Your review will be visible to the public</li>
          </ul>
        </div>
      </div>

      <ModalFooter>
        <Button variant="outline" onClick={handleClose}>
          Cancel
        </Button>
        <Button onClick={handleSubmit} loading={loading} disabled={rating === 0}>
          Submit Review
        </Button>
      </ModalFooter>
    </Modal>
  );
}
