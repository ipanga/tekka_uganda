import { Injectable, NotFoundException } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import { PrismaService } from '../prisma/prisma.service';
import { getFirebaseMessaging } from '../auth/firebase-admin';
import { SendNotificationDto, SendBulkNotificationDto } from './dto';
import { NotificationType } from '@prisma/client';

@Injectable()
export class NotificationsService {
  constructor(
    private prisma: PrismaService,
    private configService: ConfigService,
  ) {}

  /**
   * Send a push notification to a user
   */
  async send(dto: SendNotificationDto) {
    // Create notification record
    const notification = await this.prisma.notification.create({
      data: {
        userId: dto.userId,
        type: dto.type,
        title: dto.title,
        body: dto.body,
        data: dto.data || {},
      },
    });

    // Get user's FCM tokens from FcmToken table
    const fcmTokens = await this.prisma.fcmToken.findMany({
      where: { userId: dto.userId },
      select: { token: true },
    });

    if (fcmTokens.length === 0) {
      return notification;
    }

    const tokens = fcmTokens.map((t) => t.token);

    // Send push notification
    try {
      const messaging = getFirebaseMessaging();
      if (messaging && tokens.length > 0) {
        await messaging.sendEachForMulticast({
          tokens,
          notification: {
            title: dto.title,
            body: dto.body,
          },
          data: dto.data
            ? Object.fromEntries(
                Object.entries(dto.data).map(([k, v]) => [k, String(v)]),
              )
            : undefined,
          android: {
            priority: 'high',
            notification: {
              channelId: this.getChannelId(dto.type),
            },
          },
          apns: {
            payload: {
              aps: {
                badge: await this.getUnreadCount(dto.userId),
                sound: 'default',
              },
            },
          },
        });
      }
    } catch (error) {
      console.error('Failed to send push notification:', error);
      // Don't throw - notification was saved
    }

    return notification;
  }

  /**
   * Send bulk notifications
   */
  async sendBulk(dto: SendBulkNotificationDto) {
    const results = await Promise.allSettled(
      dto.userIds.map((userId) =>
        this.send({
          userId,
          type: dto.type,
          title: dto.title,
          body: dto.body,
          data: dto.data,
        }),
      ),
    );

    const succeeded = results.filter((r) => r.status === 'fulfilled').length;
    const failed = results.filter((r) => r.status === 'rejected').length;

    return { succeeded, failed, total: dto.userIds.length };
  }

  /**
   * Get notifications for a user
   */
  async findAllForUser(userId: string, limit = 50, cursor?: string) {
    const notifications = await this.prisma.notification.findMany({
      where: { userId },
      take: limit,
      ...(cursor && {
        skip: 1,
        cursor: { id: cursor },
      }),
      orderBy: { createdAt: 'desc' },
    });

    return {
      notifications,
      nextCursor:
        notifications.length === limit
          ? notifications[notifications.length - 1].id
          : null,
    };
  }

  /**
   * Get a single notification
   */
  async findOne(notificationId: string, userId: string) {
    const notification = await this.prisma.notification.findUnique({
      where: { id: notificationId },
    });

    if (!notification || notification.userId !== userId) {
      throw new NotFoundException('Notification not found');
    }

    return notification;
  }

  /**
   * Mark notification as read
   */
  async markAsRead(notificationId: string, userId: string) {
    await this.findOne(notificationId, userId);

    return this.prisma.notification.update({
      where: { id: notificationId },
      data: { isRead: true },
    });
  }

  /**
   * Mark all notifications as read
   */
  async markAllAsRead(userId: string) {
    await this.prisma.notification.updateMany({
      where: { userId, isRead: false },
      data: { isRead: true },
    });

    return { success: true };
  }

  /**
   * Delete a notification
   */
  async delete(notificationId: string, userId: string) {
    await this.findOne(notificationId, userId);

    await this.prisma.notification.delete({
      where: { id: notificationId },
    });

    return { success: true };
  }

  /**
   * Delete all notifications for a user
   */
  async deleteAll(userId: string) {
    await this.prisma.notification.deleteMany({
      where: { userId },
    });

    return { success: true };
  }

  /**
   * Get unread count
   */
  async getUnreadCount(userId: string) {
    return this.prisma.notification.count({
      where: { userId, isRead: false },
    });
  }

  /**
   * Helper: Get notification channel ID for Android
   */
  private getChannelId(type: NotificationType): string {
    const channelMap: Partial<Record<NotificationType, string>> = {
      [NotificationType.MESSAGE]: 'messages',
      [NotificationType.OFFER]: 'offers',
      [NotificationType.OFFER_ACCEPTED]: 'offers',
      [NotificationType.OFFER_DECLINED]: 'offers',
      [NotificationType.OFFER_COUNTERED]: 'offers',
      [NotificationType.OFFER_EXPIRED]: 'offers',
      [NotificationType.NEW_REVIEW]: 'reviews',
      [NotificationType.LISTING_APPROVED]: 'listings',
      [NotificationType.LISTING_REJECTED]: 'listings',
      [NotificationType.LISTING_SOLD]: 'listings',
      [NotificationType.PRICE_DROP]: 'price_alerts',
      [NotificationType.MEETUP_PROPOSED]: 'meetups',
      [NotificationType.MEETUP_ACCEPTED]: 'meetups',
      [NotificationType.SYSTEM]: 'system',
    };

    return channelMap[type] || 'default';
  }

  /**
   * Send specific notification types (convenience methods)
   */

  async sendNewMessage(
    userId: string,
    senderName: string,
    message: string,
    chatId: string,
  ) {
    return this.send({
      userId,
      type: NotificationType.MESSAGE,
      title: senderName,
      body: message.length > 100 ? message.substring(0, 100) + '...' : message,
      data: { chatId, type: 'message' },
    });
  }

  async sendNewOffer(
    sellerId: string,
    buyerName: string,
    listingTitle: string,
    amount: number,
    offerId: string,
  ) {
    return this.send({
      userId: sellerId,
      type: NotificationType.OFFER,
      title: 'New Offer',
      body: `${buyerName} offered UGX ${amount.toLocaleString()} for ${listingTitle}`,
      data: { offerId, type: 'offer' },
    });
  }

  async sendOfferAccepted(
    buyerId: string,
    listingTitle: string,
    offerId: string,
  ) {
    return this.send({
      userId: buyerId,
      type: NotificationType.OFFER_ACCEPTED,
      title: 'Offer Accepted!',
      body: `Your offer on ${listingTitle} was accepted`,
      data: { offerId, type: 'offer_accepted' },
    });
  }

  async sendOfferDeclined(
    buyerId: string,
    listingTitle: string,
    offerId: string,
  ) {
    return this.send({
      userId: buyerId,
      type: NotificationType.OFFER_DECLINED,
      title: 'Offer Declined',
      body: `Your offer on ${listingTitle} was declined`,
      data: { offerId, type: 'offer_declined' },
    });
  }

  async sendCounterOffer(
    buyerId: string,
    listingTitle: string,
    counterAmount: number,
    offerId: string,
  ) {
    return this.send({
      userId: buyerId,
      type: NotificationType.OFFER_COUNTERED,
      title: 'Counter Offer',
      body: `Seller countered with UGX ${counterAmount.toLocaleString()} for ${listingTitle}`,
      data: { offerId, type: 'counter_offer' },
    });
  }

  async sendNewReview(
    userId: string,
    reviewerName: string,
    rating: number,
    reviewId: string,
  ) {
    return this.send({
      userId,
      type: NotificationType.NEW_REVIEW,
      title: 'New Review',
      body: `${reviewerName} gave you ${rating} stars`,
      data: { reviewId, type: 'review' },
    });
  }

  async sendPriceDrop(
    userId: string,
    listingTitle: string,
    newPrice: number,
    listingId: string,
  ) {
    return this.send({
      userId,
      type: NotificationType.PRICE_DROP,
      title: 'Price Drop Alert',
      body: `${listingTitle} dropped to UGX ${newPrice.toLocaleString()}`,
      data: { listingId, type: 'price_drop' },
    });
  }

  async sendListingApproved(
    userId: string,
    listingTitle: string,
    listingId: string,
  ) {
    return this.send({
      userId,
      type: NotificationType.LISTING_APPROVED,
      title: 'Listing Approved',
      body: `Your listing "${listingTitle}" has been approved and is now live`,
      data: { listingId, type: 'listing_approved' },
    });
  }

  async sendListingRejected(
    userId: string,
    listingTitle: string,
    reason: string,
    listingId: string,
  ) {
    return this.send({
      userId,
      type: NotificationType.LISTING_REJECTED,
      title: 'Listing Rejected',
      body: `Your listing "${listingTitle}" was rejected: ${reason}`,
      data: { listingId, type: 'listing_rejected' },
    });
  }
}
