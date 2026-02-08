import {
  Injectable,
  NotFoundException,
  ForbiddenException,
  BadRequestException,
  ConflictException,
} from '@nestjs/common';
import { PrismaService } from '../prisma/prisma.service';
import { CreateReviewDto, UpdateReviewDto } from './dto';
import { ReviewType } from '@prisma/client';

@Injectable()
export class ReviewsService {
  constructor(private prisma: PrismaService) {}

  /**
   * Create a review for a user
   * Now supports rating sellers without requiring a listing (purchase)
   */
  async create(reviewerId: string, dto: CreateReviewDto) {
    // Can't review yourself
    if (reviewerId === dto.revieweeId) {
      throw new BadRequestException('Cannot review yourself');
    }

    // Check if reviewee exists
    const reviewee = await this.prisma.user.findUnique({
      where: { id: dto.revieweeId },
    });

    if (!reviewee) {
      throw new NotFoundException('User not found');
    }

    let listing = null;
    let reviewType: ReviewType = ReviewType.BUYER; // Default: buyer reviewing seller

    // If listingId is provided, verify it and determine review type
    if (dto.listingId) {
      listing = await this.prisma.listing.findUnique({
        where: { id: dto.listingId },
      });

      if (!listing) {
        throw new NotFoundException('Listing not found');
      }

      // Check if already reviewed this specific listing
      const existingListingReview = await this.prisma.review.findUnique({
        where: {
          reviewerId_listingId: {
            reviewerId,
            listingId: dto.listingId,
          },
        },
      });

      if (existingListingReview) {
        throw new ConflictException('You have already reviewed this listing');
      }

      // Determine review type based on listing ownership
      if (listing.sellerId === dto.revieweeId) {
        reviewType = ReviewType.BUYER; // Buyer is reviewing the seller
      } else {
        reviewType = ReviewType.SELLER; // Seller is reviewing the buyer
      }
    } else {
      // No listing provided - find a listing from this seller to use
      // Check if reviewer already reviewed this seller through any listing
      const existingSellerReview = await this.prisma.review.findFirst({
        where: {
          reviewerId,
          revieweeId: dto.revieweeId,
        },
      });

      if (existingSellerReview) {
        throw new ConflictException('You have already reviewed this seller');
      }

      // Find the most recent listing from this seller to use as reference
      const sellerListing = await this.prisma.listing.findFirst({
        where: { sellerId: dto.revieweeId },
        orderBy: { createdAt: 'desc' },
      });

      if (!sellerListing) {
        throw new BadRequestException('Cannot review a seller with no listings');
      }

      listing = sellerListing;
      reviewType = ReviewType.BUYER; // General seller review
    }

    // Create review
    const review = await this.prisma.review.create({
      data: {
        reviewerId,
        revieweeId: dto.revieweeId,
        listingId: listing.id,
        rating: dto.rating,
        comment: dto.comment,
        type: reviewType,
      },
      include: {
        reviewer: {
          select: {
            id: true,
            displayName: true,
            photoUrl: true,
          },
        },
        listing: {
          select: {
            id: true,
            title: true,
            imageUrls: true,
          },
        },
      },
    });

    return review;
  }

  /**
   * Get reviews for a user
   */
  async findForUser(
    userId: string,
    type: 'received' | 'given' = 'received',
    limit = 20,
    cursor?: string,
  ) {
    const where =
      type === 'received' ? { revieweeId: userId } : { reviewerId: userId };

    const reviews = await this.prisma.review.findMany({
      where,
      take: limit,
      ...(cursor && {
        skip: 1,
        cursor: { id: cursor },
      }),
      orderBy: { createdAt: 'desc' },
      include: {
        reviewer: {
          select: {
            id: true,
            displayName: true,
            photoUrl: true,
          },
        },
        reviewee: {
          select: {
            id: true,
            displayName: true,
            photoUrl: true,
          },
        },
        listing: {
          select: {
            id: true,
            title: true,
            imageUrls: true,
          },
        },
      },
    });

    return {
      reviews,
      nextCursor:
        reviews.length === limit ? reviews[reviews.length - 1].id : null,
    };
  }

  /**
   * Get a single review
   */
  async findOne(reviewId: string) {
    const review = await this.prisma.review.findUnique({
      where: { id: reviewId },
      include: {
        reviewer: {
          select: {
            id: true,
            displayName: true,
            photoUrl: true,
          },
        },
        reviewee: {
          select: {
            id: true,
            displayName: true,
            photoUrl: true,
          },
        },
        listing: {
          select: {
            id: true,
            title: true,
            imageUrls: true,
          },
        },
      },
    });

    if (!review) {
      throw new NotFoundException('Review not found');
    }

    return review;
  }

  /**
   * Update a review
   */
  async update(reviewId: string, userId: string, dto: UpdateReviewDto) {
    const review = await this.findOne(reviewId);

    if (review.reviewerId !== userId) {
      throw new ForbiddenException('You can only edit your own reviews');
    }

    const updated = await this.prisma.review.update({
      where: { id: reviewId },
      data: {
        ...(dto.rating !== undefined && { rating: dto.rating }),
        ...(dto.comment !== undefined && { comment: dto.comment }),
      },
      include: {
        reviewer: {
          select: {
            id: true,
            displayName: true,
            photoUrl: true,
          },
        },
        listing: {
          select: {
            id: true,
            title: true,
          },
        },
      },
    });

    return updated;
  }

  /**
   * Delete a review
   */
  async delete(reviewId: string, userId: string) {
    const review = await this.findOne(reviewId);

    if (review.reviewerId !== userId) {
      throw new ForbiddenException('You can only delete your own reviews');
    }

    await this.prisma.review.delete({
      where: { id: reviewId },
    });

    return { success: true };
  }

  /**
   * Get review statistics for a user
   */
  async getStats(userId: string) {
    const stats = await this.prisma.review.aggregate({
      where: { revieweeId: userId },
      _avg: { rating: true },
      _count: true,
    });

    const distribution = await this.prisma.review.groupBy({
      by: ['rating'],
      where: { revieweeId: userId },
      _count: true,
    });

    return {
      averageRating: stats._avg.rating || 0,
      totalReviews: stats._count,
      distribution: Object.fromEntries(
        distribution.map((d) => [d.rating, d._count]),
      ),
    };
  }

  /**
   * Report a review
   */
  async report(reviewId: string, userId: string, reason: string) {
    const review = await this.findOne(reviewId);

    // Can't report your own review
    if (review.reviewerId === userId) {
      throw new BadRequestException('Cannot report your own review');
    }

    // Create a report
    await this.prisma.report.create({
      data: {
        reporterId: userId,
        reportedUserId: review.reviewerId,
        reason: `Review Report: ${reason}`,
        description: `Review ID: ${reviewId}`,
      },
    });

    return { success: true, message: 'Review reported' };
  }

  /**
   * Admin: List all reviews with pagination
   */
  async adminList(page = 1, limit = 10, search?: string) {
    const skip = (page - 1) * limit;

    const where = search
      ? {
          OR: [
            { comment: { contains: search, mode: 'insensitive' as const } },
            {
              reviewer: {
                displayName: { contains: search, mode: 'insensitive' as const },
              },
            },
            {
              reviewee: {
                displayName: { contains: search, mode: 'insensitive' as const },
              },
            },
          ],
        }
      : {};

    const [reviews, total] = await Promise.all([
      this.prisma.review.findMany({
        where,
        skip,
        take: limit,
        orderBy: { createdAt: 'desc' },
        include: {
          reviewer: {
            select: {
              id: true,
              displayName: true,
              photoUrl: true,
            },
          },
          reviewee: {
            select: {
              id: true,
              displayName: true,
              photoUrl: true,
            },
          },
          listing: {
            select: {
              id: true,
              title: true,
            },
          },
        },
      }),
      this.prisma.review.count({ where }),
    ]);

    return {
      data: reviews,
      total,
      page,
      limit,
      totalPages: Math.ceil(total / limit),
    };
  }

  /**
   * Admin: Remove a review
   */
  async adminRemove(reviewId: string) {
    await this.findOne(reviewId);

    await this.prisma.review.delete({
      where: { id: reviewId },
    });

    return { success: true };
  }
}
