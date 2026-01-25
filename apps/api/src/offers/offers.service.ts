import {
  Injectable,
  NotFoundException,
  ForbiddenException,
  BadRequestException,
  ConflictException,
} from '@nestjs/common';
import { PrismaService } from '../prisma/prisma.service';
import { CreateOfferDto, UpdateOfferDto, CounterOfferDto } from './dto';
import { OfferStatus, ListingStatus, NotificationType } from '@prisma/client';
import { NotificationsService } from '../notifications/notifications.service';

@Injectable()
export class OffersService {
  constructor(
    private prisma: PrismaService,
    private notificationsService: NotificationsService,
  ) {}

  /**
   * Create a new offer on a listing
   */
  async create(buyerId: string, dto: CreateOfferDto) {
    // Get the listing
    const listing = await this.prisma.listing.findUnique({
      where: { id: dto.listingId },
      include: {
        seller: {
          select: { id: true, displayName: true },
        },
      },
    });

    if (!listing) {
      throw new NotFoundException('Listing not found');
    }

    // Can't make offer on own listing
    if (listing.sellerId === buyerId) {
      throw new BadRequestException('Cannot make offer on your own listing');
    }

    // Check listing is active
    if (listing.status !== ListingStatus.ACTIVE) {
      throw new BadRequestException('Listing is not available');
    }

    // Check if user is blocked
    const isBlocked = await this.prisma.blockedUser.findFirst({
      where: {
        OR: [
          { blockerId: listing.sellerId, blockedId: buyerId },
          { blockerId: buyerId, blockedId: listing.sellerId },
        ],
      },
    });

    if (isBlocked) {
      throw new ForbiddenException('Cannot make offer to this seller');
    }

    // Check for existing pending offer from this buyer on this listing
    const existingOffer = await this.prisma.offer.findFirst({
      where: {
        listingId: dto.listingId,
        buyerId,
        status: { in: [OfferStatus.PENDING, OfferStatus.COUNTERED] },
      },
    });

    if (existingOffer) {
      throw new ConflictException(
        'You already have an active offer on this listing',
      );
    }

    // Create the offer
    const offer = await this.prisma.offer.create({
      data: {
        listingId: dto.listingId,
        buyerId,
        sellerId: listing.sellerId,
        amount: dto.amount,
        originalPrice: listing.price,
        message: dto.message,
        status: OfferStatus.PENDING,
        expiresAt: new Date(Date.now() + 48 * 60 * 60 * 1000), // 48 hours
      },
      include: {
        listing: {
          select: {
            id: true,
            title: true,
            price: true,
            imageUrls: true,
          },
        },
        buyer: {
          select: {
            id: true,
            displayName: true,
            photoUrl: true,
          },
        },
        seller: {
          select: {
            id: true,
            displayName: true,
            photoUrl: true,
          },
        },
      },
    });

    // Send push notification to seller
    await this.notificationsService.send({
      userId: listing.sellerId,
      type: NotificationType.OFFER,
      title: 'New Offer Received',
      body: `You received a $${dto.amount} offer on "${listing.title}"`,
      data: { offerId: offer.id, listingId: listing.id },
    });

    return offer;
  }

  /**
   * Get all offers for a user (as buyer or seller)
   */
  async findAllForUser(
    userId: string,
    role: 'buyer' | 'seller' | 'all' = 'all',
    status?: OfferStatus,
  ) {
    const where: any = {};

    if (role === 'buyer') {
      where.buyerId = userId;
    } else if (role === 'seller') {
      where.sellerId = userId;
    } else {
      where.OR = [{ buyerId: userId }, { sellerId: userId }];
    }

    if (status) {
      where.status = status;
    }

    return this.prisma.offer.findMany({
      where,
      include: {
        listing: {
          select: {
            id: true,
            title: true,
            price: true,
            imageUrls: true,
            status: true,
          },
        },
        buyer: {
          select: {
            id: true,
            displayName: true,
            photoUrl: true,
          },
        },
        seller: {
          select: {
            id: true,
            displayName: true,
            photoUrl: true,
          },
        },
      },
      orderBy: { createdAt: 'desc' },
    });
  }

  /**
   * Get offers for a specific listing (seller only)
   */
  async findForListing(listingId: string, userId: string) {
    // Verify user is the seller
    const listing = await this.prisma.listing.findUnique({
      where: { id: listingId },
    });

    if (!listing) {
      throw new NotFoundException('Listing not found');
    }

    if (listing.sellerId !== userId) {
      throw new ForbiddenException('Not authorized to view these offers');
    }

    return this.prisma.offer.findMany({
      where: { listingId },
      include: {
        buyer: {
          select: {
            id: true,
            displayName: true,
            photoUrl: true,
          },
        },
      },
      orderBy: { createdAt: 'desc' },
    });
  }

  /**
   * Get a single offer
   */
  async findOne(offerId: string, userId: string) {
    const offer = await this.prisma.offer.findUnique({
      where: { id: offerId },
      include: {
        listing: {
          select: {
            id: true,
            title: true,
            price: true,
            imageUrls: true,
            status: true,
          },
        },
        buyer: {
          select: {
            id: true,
            displayName: true,
            photoUrl: true,
          },
        },
        seller: {
          select: {
            id: true,
            displayName: true,
            photoUrl: true,
          },
        },
      },
    });

    if (!offer) {
      throw new NotFoundException('Offer not found');
    }

    // Only buyer or seller can view
    if (offer.buyerId !== userId && offer.sellerId !== userId) {
      throw new ForbiddenException('Not authorized to view this offer');
    }

    return offer;
  }

  /**
   * Update an offer (buyer only, while pending)
   */
  async update(offerId: string, userId: string, dto: UpdateOfferDto) {
    const offer = await this.findOne(offerId, userId);

    if (offer.buyerId !== userId) {
      throw new ForbiddenException('Only buyer can update offer');
    }

    if (offer.status !== OfferStatus.PENDING) {
      throw new BadRequestException('Can only update pending offers');
    }

    return this.prisma.offer.update({
      where: { id: offerId },
      data: {
        ...(dto.amount !== undefined && { amount: dto.amount }),
        ...(dto.message !== undefined && { message: dto.message }),
      },
      include: {
        listing: {
          select: {
            id: true,
            title: true,
            price: true,
            imageUrls: true,
          },
        },
      },
    });
  }

  /**
   * Accept an offer (seller only)
   */
  async accept(offerId: string, userId: string) {
    const offer = await this.findOne(offerId, userId);

    if (offer.sellerId !== userId) {
      throw new ForbiddenException('Only seller can accept offers');
    }

    if (
      offer.status !== OfferStatus.PENDING &&
      offer.status !== OfferStatus.COUNTERED
    ) {
      throw new BadRequestException('Cannot accept this offer');
    }

    // Check listing is still active
    if (offer.listing.status !== ListingStatus.ACTIVE) {
      throw new BadRequestException('Listing is no longer available');
    }

    // Start a transaction to accept offer and reject others
    const result = await this.prisma.$transaction(async (tx) => {
      // Accept this offer
      const acceptedOffer = await tx.offer.update({
        where: { id: offerId },
        data: {
          status: OfferStatus.ACCEPTED,
          respondedAt: new Date(),
        },
        include: {
          listing: true,
          buyer: {
            select: {
              id: true,
              displayName: true,
              photoUrl: true,
            },
          },
        },
      });

      // Reject all other pending offers for this listing
      await tx.offer.updateMany({
        where: {
          listingId: offer.listing.id,
          id: { not: offerId },
          status: { in: [OfferStatus.PENDING, OfferStatus.COUNTERED] },
        },
        data: {
          status: OfferStatus.DECLINED,
          respondedAt: new Date(),
        },
      });

      // Mark listing as sold
      await tx.listing.update({
        where: { id: offer.listing.id },
        data: { status: ListingStatus.SOLD, soldAt: new Date() },
      });

      // Create a purchase record
      await tx.purchase.create({
        data: {
          buyerId: offer.buyerId,
          listingId: offer.listing.id,
          finalPrice: acceptedOffer.counterAmount || acceptedOffer.amount,
        },
      });

      return acceptedOffer;
    });

    // Send push notification to buyer
    await this.notificationsService.send({
      userId: offer.buyerId,
      type: NotificationType.OFFER_ACCEPTED,
      title: 'Offer Accepted!',
      body: `Your offer on "${offer.listing.title}" has been accepted`,
      data: { offerId, listingId: offer.listing.id },
    });

    return result;
  }

  /**
   * Reject an offer (seller only)
   */
  async reject(offerId: string, userId: string) {
    const offer = await this.findOne(offerId, userId);

    if (offer.sellerId !== userId) {
      throw new ForbiddenException('Only seller can reject offers');
    }

    if (
      offer.status !== OfferStatus.PENDING &&
      offer.status !== OfferStatus.COUNTERED
    ) {
      throw new BadRequestException('Cannot reject this offer');
    }

    const rejected = await this.prisma.offer.update({
      where: { id: offerId },
      data: {
        status: OfferStatus.DECLINED,
        respondedAt: new Date(),
      },
    });

    // Send push notification to buyer
    await this.notificationsService.send({
      userId: offer.buyerId,
      type: NotificationType.OFFER_DECLINED,
      title: 'Offer Declined',
      body: `Your offer on "${offer.listing.title}" was declined`,
      data: { offerId, listingId: offer.listing.id },
    });

    return rejected;
  }

  /**
   * Counter an offer (seller only)
   */
  async counter(offerId: string, userId: string, dto: CounterOfferDto) {
    const offer = await this.findOne(offerId, userId);

    if (offer.sellerId !== userId) {
      throw new ForbiddenException('Only seller can counter offers');
    }

    if (offer.status !== OfferStatus.PENDING) {
      throw new BadRequestException('Can only counter pending offers');
    }

    const countered = await this.prisma.offer.update({
      where: { id: offerId },
      data: {
        status: OfferStatus.COUNTERED,
        counterAmount: dto.amount,
        respondedAt: new Date(),
        expiresAt: new Date(Date.now() + 48 * 60 * 60 * 1000), // Reset 48h timer
      },
      include: {
        listing: {
          select: {
            id: true,
            title: true,
            price: true,
          },
        },
        buyer: {
          select: {
            id: true,
            displayName: true,
          },
        },
      },
    });

    // Send push notification to buyer
    await this.notificationsService.send({
      userId: offer.buyerId,
      type: NotificationType.OFFER_COUNTERED,
      title: 'Counter Offer Received',
      body: `Seller countered with $${dto.amount} for "${offer.listing.title}"`,
      data: { offerId, listingId: offer.listing.id },
    });

    return countered;
  }

  /**
   * Accept a counter offer (buyer only)
   */
  async acceptCounter(offerId: string, userId: string) {
    const offer = await this.findOne(offerId, userId);

    if (offer.buyerId !== userId) {
      throw new ForbiddenException('Only buyer can accept counter offers');
    }

    if (offer.status !== OfferStatus.COUNTERED) {
      throw new BadRequestException('No counter offer to accept');
    }

    // Start transaction
    const result = await this.prisma.$transaction(async (tx) => {
      // Accept the counter offer
      const accepted = await tx.offer.update({
        where: { id: offerId },
        data: {
          status: OfferStatus.ACCEPTED,
          amount: offer.counterAmount!, // Update to counter amount
        },
        include: {
          listing: true,
          seller: {
            select: {
              id: true,
              displayName: true,
            },
          },
        },
      });

      // Reject other offers
      await tx.offer.updateMany({
        where: {
          listingId: offer.listing.id,
          id: { not: offerId },
          status: { in: [OfferStatus.PENDING, OfferStatus.COUNTERED] },
        },
        data: {
          status: OfferStatus.DECLINED,
          respondedAt: new Date(),
        },
      });

      // Mark listing as sold
      await tx.listing.update({
        where: { id: offer.listing.id },
        data: { status: ListingStatus.SOLD, soldAt: new Date() },
      });

      // Create a purchase record
      await tx.purchase.create({
        data: {
          buyerId: offer.buyerId,
          listingId: offer.listing.id,
          finalPrice: offer.counterAmount!,
        },
      });

      return accepted;
    });

    // Send push notification to seller
    await this.notificationsService.send({
      userId: offer.sellerId,
      type: NotificationType.OFFER_ACCEPTED,
      title: 'Counter Offer Accepted!',
      body: `Your counter offer for "${offer.listing.title}" has been accepted`,
      data: { offerId, listingId: offer.listing.id },
    });

    return result;
  }

  /**
   * Decline a counter offer (buyer only)
   */
  async declineCounter(offerId: string, userId: string) {
    const offer = await this.findOne(offerId, userId);

    if (offer.buyerId !== userId) {
      throw new ForbiddenException('Only buyer can decline counter offers');
    }

    if (offer.status !== OfferStatus.COUNTERED) {
      throw new BadRequestException('No counter offer to decline');
    }

    return this.prisma.offer.update({
      where: { id: offerId },
      data: {
        status: OfferStatus.DECLINED,
      },
    });
  }

  /**
   * Cancel/withdraw an offer (buyer only)
   */
  async cancel(offerId: string, userId: string) {
    const offer = await this.findOne(offerId, userId);

    if (offer.buyerId !== userId) {
      throw new ForbiddenException('Only buyer can cancel their offers');
    }

    if (
      offer.status !== OfferStatus.PENDING &&
      offer.status !== OfferStatus.COUNTERED
    ) {
      throw new BadRequestException('Cannot cancel this offer');
    }

    return this.prisma.offer.update({
      where: { id: offerId },
      data: {
        status: OfferStatus.WITHDRAWN,
      },
    });
  }

  /**
   * Get offer statistics for a user
   */
  async getStats(userId: string) {
    const [sentStats, receivedStats] = await Promise.all([
      this.prisma.offer.groupBy({
        by: ['status'],
        where: { buyerId: userId },
        _count: true,
      }),
      this.prisma.offer.groupBy({
        by: ['status'],
        where: { sellerId: userId },
        _count: true,
      }),
    ]);

    return {
      sent: {
        total: sentStats.reduce((sum, s) => sum + s._count, 0),
        byStatus: Object.fromEntries(
          sentStats.map((s) => [s.status, s._count]),
        ),
      },
      received: {
        total: receivedStats.reduce((sum, s) => sum + s._count, 0),
        byStatus: Object.fromEntries(
          receivedStats.map((s) => [s.status, s._count]),
        ),
      },
    };
  }

  /**
   * Expire old offers (to be called by cron job)
   */
  async expireOffers() {
    const expired = await this.prisma.offer.updateMany({
      where: {
        status: { in: [OfferStatus.PENDING, OfferStatus.COUNTERED] },
        expiresAt: { lt: new Date() },
      },
      data: {
        status: OfferStatus.EXPIRED,
      },
    });

    return { expiredCount: expired.count };
  }
}
