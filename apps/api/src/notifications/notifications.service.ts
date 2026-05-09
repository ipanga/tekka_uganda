import { Injectable, Logger, NotFoundException } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import { PrismaService } from '../prisma/prisma.service';
import { getFirebaseMessaging } from '../auth/firebase-admin';
import {
  SendNotificationDto,
  SendBulkNotificationDto,
  BroadcastNotificationDto,
  BroadcastAudience,
} from './dto';
import { NotificationType, UserRole, Prisma } from '@prisma/client';

const WEB_ORIGIN = 'https://tekka.ug';

/**
 * FCM error codes that indicate the token is permanently dead and should be
 * purged from the FcmToken table. Anything else (network, rate, auth) may be
 * transient and leaves the token in place.
 * Ref: https://firebase.google.com/docs/cloud-messaging/send-message#admin
 */
const DEAD_TOKEN_ERROR_CODES = new Set([
  'messaging/registration-token-not-registered',
  'messaging/invalid-registration-token',
  'messaging/invalid-argument',
]);

@Injectable()
export class NotificationsService {
  private readonly logger = new Logger(NotificationsService.name);

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
        broadcastId: dto.broadcastId ?? null,
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

    // Build canonical deep link (Universal Link / App Link URL).
    // Flutter's PushNotificationService prefers `deep_link` over legacy
    // type/id routing for notification taps. Pass the per-user notification
    // id so SYSTEM (broadcast) taps route to the in-app detail screen.
    const deepLink = this.buildDeepLink(dto.type, dto.data, notification.id);
    const dataPayload: Record<string, string> = {
      ...(dto.data
        ? Object.fromEntries(
            Object.entries(dto.data).map(([k, v]) => [k, String(v)]),
          )
        : {}),
    };
    if (deepLink) dataPayload.deep_link = deepLink;

    // Send push notification
    try {
      const messaging = getFirebaseMessaging();
      if (messaging && tokens.length > 0) {
        const response = await messaging.sendEachForMulticast({
          tokens,
          notification: {
            title: dto.title,
            body: dto.body,
          },
          data: Object.keys(dataPayload).length > 0 ? dataPayload : undefined,
          android: {
            priority: 'high',
            notification: {
              channelId: this.getChannelId(dto.type),
            },
          },
          apns: {
            payload: {
              aps: {
                // Explicit alert — firebase-admin's auto-mapping from the
                // top-level `notification` block is unreliable when an
                // `apns.payload.aps` is also present.
                alert: { title: dto.title, body: dto.body },
                badge: await this.getUnreadCount(dto.userId),
                sound: 'default',
              },
            },
          },
        });
        // Surface multicast outcome so we can tell from logs whether iOS
        // tokens are being rejected by FCM (e.g. APNs key missing in
        // Firebase Console → every iOS token returns "registration-token-
        // not-registered"). Token prefixes only — never log full tokens.
        const failures = response.responses
          .map((r, i) => ({
            ok: r.success,
            tokenPrefix: tokens[i].slice(0, 12),
            code: r.error?.code,
            message: r.error?.message,
          }))
          .filter((r) => !r.ok);
        this.logger.log(
          `FCM multicast type=${dto.type} userId=${dto.userId} ` +
            `success=${response.successCount} failure=${response.failureCount}` +
            (failures.length > 0
              ? ` failures=${JSON.stringify(failures)}`
              : ''),
        );
        // Prune any tokens FCM reports as permanently dead (app uninstalled,
        // token rotated, etc.) so the FcmToken table stays honest and future
        // sends don't keep shipping to ghosts.
        await this.pruneDeadTokens(response.responses, tokens);
      }
    } catch (error) {
      this.logger.error('Failed to send push notification', error as Error);
      // Don't throw - notification was saved
    }

    return notification;
  }

  /**
   * Delete FcmToken rows whose token FCM flagged as permanently invalid.
   * Runs after every multicast; total cost is a single `deleteMany` with
   * the offending tokens inlined (bounded by device count per user, small).
   */
  private async pruneDeadTokens(
    responses: Array<{ success: boolean; error?: { code?: string } }>,
    tokens: string[],
  ) {
    const dead: string[] = [];
    responses.forEach((result, idx) => {
      if (!result.success && result.error?.code) {
        if (DEAD_TOKEN_ERROR_CODES.has(result.error.code)) {
          dead.push(tokens[idx]);
        }
      }
    });
    if (dead.length === 0) return;

    try {
      const { count } = await this.prisma.fcmToken.deleteMany({
        where: { token: { in: dead } },
      });
      if (count > 0) {
        this.logger.log(
          `Pruned ${count} stale FCM token(s) after multicast send`,
        );
      }
    } catch (err) {
      this.logger.warn(
        `Stale-token prune failed: ${(err as Error).message ?? err}`,
      );
    }
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
      data: notifications,
      nextCursor:
        notifications.length === limit
          ? notifications[notifications.length - 1].id
          : null,
      hasMore: notifications.length === limit,
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
   * Build a canonical deep link URL (https://tekka.ug/...) for a given
   * notification type + data payload. Returns null when the type has no
   * in-app destination. Consumed by the Flutter app via `data.deep_link`.
   */
  private buildDeepLink(
    type: NotificationType,
    data?: Record<string, unknown>,
    notificationId?: string,
  ): string | null {
    const pick = (key: string): string | null => {
      const v = data?.[key];
      return typeof v === 'string' && v.length > 0 ? v : null;
    };

    switch (type) {
      case NotificationType.MESSAGE: {
        const chatId = pick('chatId');
        return chatId ? `${WEB_ORIGIN}/chat/${chatId}` : null;
      }
      case NotificationType.NEW_REVIEW: {
        const userId = pick('userId') ?? pick('reviewerId');
        return userId ? `${WEB_ORIGIN}/reviews/${userId}` : null;
      }
      case NotificationType.LISTING_APPROVED:
      case NotificationType.LISTING_REJECTED:
      case NotificationType.LISTING_SUSPENDED:
      case NotificationType.LISTING_SOLD:
      case NotificationType.PRICE_DROP: {
        const listingId = pick('listingId');
        return listingId ? `${WEB_ORIGIN}/listing/${listingId}` : null;
      }
      case NotificationType.MEETUP_PROPOSED:
      case NotificationType.MEETUP_ACCEPTED:
      case NotificationType.MEETUP_DECLINED:
      case NotificationType.MEETUP_CANCELLED:
      case NotificationType.MEETUP_NO_SHOW: {
        const meetupId = pick('meetupId');
        return meetupId
          ? `${WEB_ORIGIN}/meetups/${meetupId}`
          : `${WEB_ORIGIN}/meetups`;
      }
      case NotificationType.SYSTEM: {
        // Admin broadcasts use SYSTEM. Route taps to the per-user notification
        // detail (Flutter `/notifications/:id`) so the recipient sees the
        // broadcast title/body in-app. Product-linked broadcasts still carry
        // data.listingId + data.type='listing', which the detail screen reads
        // to render a "View Listing" action button.
        // Fallback to the list if the caller hasn't passed a notification id
        // (legacy callers / direct admin-send without persisted row).
        return notificationId
          ? `${WEB_ORIGIN}/notifications/${notificationId}`
          : `${WEB_ORIGIN}/notifications`;
      }
      default:
        return null;
    }
  }

  /**
   * Helper: Get notification channel ID for Android
   */
  private getChannelId(type: NotificationType): string {
    const channelMap: Partial<Record<NotificationType, string>> = {
      [NotificationType.MESSAGE]: 'messages',
      [NotificationType.NEW_REVIEW]: 'reviews',
      [NotificationType.LISTING_APPROVED]: 'listings',
      [NotificationType.LISTING_REJECTED]: 'listings',
      [NotificationType.LISTING_SUSPENDED]: 'listings',
      [NotificationType.LISTING_SOLD]: 'listings',
      [NotificationType.PRICE_DROP]: 'price_alerts',
      [NotificationType.MEETUP_PROPOSED]: 'meetups',
      [NotificationType.MEETUP_ACCEPTED]: 'meetups',
      [NotificationType.MEETUP_DECLINED]: 'meetups',
      [NotificationType.MEETUP_CANCELLED]: 'meetups',
      [NotificationType.MEETUP_NO_SHOW]: 'meetups',
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
      // Echo the recipient's id back into data so buildDeepLink can resolve
      // /reviews/:userId — buildDeepLink reads from data, not the top-level
      // userId, so without this the deep_link comes out null and the tap
      // falls back to type-based routing on the client.
      data: { reviewId, userId, type: 'review' },
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

  async sendListingSuspended(
    userId: string,
    listingTitle: string,
    reason: string | undefined,
    listingId: string,
  ) {
    return this.send({
      userId,
      type: NotificationType.LISTING_SUSPENDED,
      title: 'Listing Suspended',
      body: reason
        ? `Your listing "${listingTitle}" has been suspended for review: ${reason}`
        : `Your listing "${listingTitle}" has been suspended and is pending review`,
      data: { listingId, type: 'listing_suspended' },
    });
  }

  async sendListingSold(
    userId: string,
    listingTitle: string,
    listingId: string,
  ) {
    return this.send({
      userId,
      type: NotificationType.LISTING_SOLD,
      title: 'Listing Sold',
      body: `Your listing "${listingTitle}" has been marked as sold. Nice work!`,
      data: { listingId, type: 'listing_sold' },
    });
  }

  // ============================================
  // Admin broadcasts
  // ============================================

  /**
   * Resolve a broadcast audience to a list of recipient user IDs.
   * Suspended users are skipped for ALL/ROLE audiences (they can't act on the
   * notification anyway). SPECIFIC respects whatever the admin explicitly
   * picked — no implicit filtering.
   */
  private async resolveAudience(
    audience: BroadcastAudience,
    role: UserRole | undefined,
    userIds: string[] | undefined,
  ): Promise<string[]> {
    if (audience === BroadcastAudience.SPECIFIC) {
      return userIds ?? [];
    }
    const where: Prisma.UserWhereInput = { isSuspended: false };
    if (audience === BroadcastAudience.ROLE) {
      if (!role) return [];
      where.role = role;
    }
    const users = await this.prisma.user.findMany({
      where,
      select: { id: true },
    });
    return users.map((u) => u.id);
  }

  /** Cheap preview count for the admin "will reach N users" affordance. */
  async getAudienceCount(
    audience: BroadcastAudience,
    role?: UserRole,
  ): Promise<number> {
    if (audience === BroadcastAudience.SPECIFIC) return 0;
    const where: Prisma.UserWhereInput = { isSuspended: false };
    if (audience === BroadcastAudience.ROLE) {
      if (!role) return 0;
      where.role = role;
    }
    return this.prisma.user.count({ where });
  }

  /**
   * Create a Broadcast row and fan out per-user Notification rows + FCM
   * pushes via the existing send() path. Returns the broadcast plus the
   * per-recipient succeeded/failed/total breakdown.
   *
   * Uses NotificationType.SYSTEM for both general and product-linked
   * broadcasts; the buildDeepLink() SYSTEM branch routes to /listing/:id
   * when data.listingId is set, otherwise to /notifications.
   */
  async broadcast(dto: BroadcastNotificationDto, createdById: string) {
    const recipientIds = await this.resolveAudience(
      dto.audience,
      dto.role,
      dto.userIds,
    );

    const broadcast = await this.prisma.broadcast.create({
      data: {
        title: dto.title,
        body: dto.body,
        audience: dto.audience,
        role:
          dto.audience === BroadcastAudience.ROLE ? (dto.role ?? null) : null,
        listingId: dto.listingId ?? null,
        createdById,
        recipientCount: 0,
      },
    });

    // For product-linked broadcasts include `type: 'listing'` so the Flutter
    // notification-detail screen renders a "View Listing" action button
    // (notification_detail_screen.dart:328 switches on data.type, treating it
    // as the targetType). data.listingId alone is enough for the FCM
    // tap-routing path (deep_link), but the in-app detail screen needs the
    // type hint to know what kind of target this is.
    const data: Record<string, unknown> = {};
    if (dto.listingId) {
      data.listingId = dto.listingId;
      data.type = 'listing';
    }

    const results = await Promise.allSettled(
      recipientIds.map((userId) =>
        this.send({
          userId,
          type: NotificationType.SYSTEM,
          title: dto.title,
          body: dto.body,
          data,
          broadcastId: broadcast.id,
        }),
      ),
    );

    const succeeded = results.filter((r) => r.status === 'fulfilled').length;
    const failed = results.filter((r) => r.status === 'rejected').length;

    // recipientCount = how many users we actually wrote a Notification row
    // for. Per-user FCM dispatch can still fail downstream; that's tracked
    // by FcmToken pruning, not here.
    if (succeeded > 0) {
      await this.prisma.broadcast.update({
        where: { id: broadcast.id },
        data: { recipientCount: succeeded },
      });
    }

    return {
      broadcast: { ...broadcast, recipientCount: succeeded },
      result: { succeeded, failed, total: recipientIds.length },
    };
  }

  /**
   * Paginated broadcast history with read-rate aggregate.
   * readCount = how many of the per-user notifications have isRead=true.
   */
  async listBroadcasts(limit = 20, cursor?: string) {
    const broadcasts = await this.prisma.broadcast.findMany({
      take: limit,
      ...(cursor && { skip: 1, cursor: { id: cursor } }),
      orderBy: { createdAt: 'desc' },
      include: {
        createdBy: { select: { id: true, displayName: true, email: true } },
      },
    });

    const ids = broadcasts.map((b) => b.id);
    const readCounts = ids.length
      ? await this.prisma.notification.groupBy({
          by: ['broadcastId'],
          where: { broadcastId: { in: ids }, isRead: true },
          _count: { _all: true },
        })
      : [];
    const readByBroadcast = new Map(
      readCounts.map((r) => [r.broadcastId as string, r._count._all]),
    );

    return {
      data: broadcasts.map((b) => ({
        ...b,
        readCount: readByBroadcast.get(b.id) ?? 0,
      })),
      nextCursor:
        broadcasts.length === limit
          ? broadcasts[broadcasts.length - 1].id
          : null,
      hasMore: broadcasts.length === limit,
    };
  }

  async getBroadcast(id: string) {
    const broadcast = await this.prisma.broadcast.findUnique({
      where: { id },
      include: {
        createdBy: { select: { id: true, displayName: true, email: true } },
      },
    });
    if (!broadcast) {
      throw new NotFoundException('Broadcast not found');
    }
    const readCount = await this.prisma.notification.count({
      where: { broadcastId: id, isRead: true },
    });
    return { ...broadcast, readCount };
  }
}
