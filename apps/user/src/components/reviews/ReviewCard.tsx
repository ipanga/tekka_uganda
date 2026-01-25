'use client';

import Link from 'next/link';
import { StarIcon } from '@heroicons/react/24/solid';
import { Review } from '@/types';
import { formatRelativeTime } from '@/lib/utils';
import { Avatar } from '@/components/ui/Avatar';
import { Card, CardContent } from '@/components/ui/Card';

interface ReviewCardProps {
  review: Review;
  showReviewee?: boolean;
}

export function ReviewCard({ review, showReviewee = false }: ReviewCardProps) {
  const displayUser = showReviewee ? review.reviewee : review.reviewer;

  return (
    <Card>
      <CardContent className="py-4">
        <div className="flex items-start gap-4">
          <Link href={`/profile/${displayUser?.id}`}>
            <Avatar
              src={displayUser?.photoUrl}
              name={displayUser?.displayName}
              size="md"
            />
          </Link>

          <div className="flex-1 min-w-0">
            <div className="flex items-center justify-between">
              <Link
                href={`/profile/${displayUser?.id}`}
                className="font-medium text-gray-900 hover:text-pink-600"
              >
                {displayUser?.displayName || 'Anonymous'}
              </Link>
              <span className="text-sm text-gray-500">
                {formatRelativeTime(review.createdAt)}
              </span>
            </div>

            {/* Star Rating */}
            <div className="flex items-center gap-1 mt-1">
              {[1, 2, 3, 4, 5].map((star) => (
                <StarIcon
                  key={star}
                  className={`w-4 h-4 ${
                    star <= review.rating ? 'text-yellow-400' : 'text-gray-200'
                  }`}
                />
              ))}
            </div>

            {/* Comment */}
            {review.comment && (
              <p className="text-gray-600 mt-2">{review.comment}</p>
            )}

            {/* Listing Reference */}
            {review.listing && (
              <Link
                href={`/listing/${review.listing.id}`}
                className="inline-block mt-2 text-sm text-pink-600 hover:text-pink-700"
              >
                View listing: {review.listing.title}
              </Link>
            )}
          </div>
        </div>
      </CardContent>
    </Card>
  );
}

interface ReviewStarsProps {
  rating: number;
  size?: 'sm' | 'md' | 'lg';
  showCount?: number;
}

export function ReviewStars({ rating, size = 'md', showCount }: ReviewStarsProps) {
  const sizeClasses = {
    sm: 'w-3 h-3',
    md: 'w-4 h-4',
    lg: 'w-5 h-5',
  };

  return (
    <div className="flex items-center gap-1">
      {[1, 2, 3, 4, 5].map((star) => (
        <StarIcon
          key={star}
          className={`${sizeClasses[size]} ${
            star <= rating ? 'text-yellow-400' : 'text-gray-200'
          }`}
        />
      ))}
      {showCount !== undefined && (
        <span className="text-sm text-gray-500 ml-1">({showCount})</span>
      )}
    </div>
  );
}
