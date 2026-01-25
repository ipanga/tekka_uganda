import { Injectable, NotFoundException } from '@nestjs/common';
import { PrismaService } from '../prisma/prisma.service';

@Injectable()
export class PriceAlertsService {
  constructor(private prisma: PrismaService) {}

  /**
   * Get all price alerts for a user
   */
  async findAll(userId: string, limit = 50) {
    return this.prisma.priceAlert.findMany({
      where: { userId },
      take: limit,
      orderBy: { createdAt: 'desc' },
      include: {
        listing: {
          select: {
            id: true,
            title: true,
            imageUrls: true,
            price: true,
            status: true,
          },
        },
      },
    });
  }

  /**
   * Get unread count
   */
  async getUnreadCount(userId: string) {
    return this.prisma.priceAlert.count({
      where: {
        userId,
        isRead: false,
        isExpired: false,
      },
    });
  }

  /**
   * Mark a price alert as read
   */
  async markAsRead(alertId: string, userId: string) {
    const alert = await this.prisma.priceAlert.findUnique({
      where: { id: alertId },
    });

    if (!alert || alert.userId !== userId) {
      throw new NotFoundException('Price alert not found');
    }

    return this.prisma.priceAlert.update({
      where: { id: alertId },
      data: { isRead: true },
    });
  }

  /**
   * Mark all price alerts as read
   */
  async markAllAsRead(userId: string) {
    await this.prisma.priceAlert.updateMany({
      where: { userId, isRead: false },
      data: { isRead: true },
    });
    return { success: true };
  }

  /**
   * Delete a price alert
   */
  async delete(alertId: string, userId: string) {
    const alert = await this.prisma.priceAlert.findUnique({
      where: { id: alertId },
    });

    if (!alert || alert.userId !== userId) {
      throw new NotFoundException('Price alert not found');
    }

    await this.prisma.priceAlert.delete({
      where: { id: alertId },
    });

    return { success: true };
  }

  /**
   * Delete all price alerts for a user
   */
  async deleteAll(userId: string) {
    await this.prisma.priceAlert.deleteMany({
      where: { userId },
    });
    return { success: true };
  }

  /**
   * Create a price alert (called internally when price drops)
   */
  async create(data: {
    userId: string;
    listingId: string;
    listingTitle: string;
    listingImageUrl?: string;
    sellerName: string;
    originalPrice: number;
    newPrice: number;
  }) {
    const priceDropAmount = data.originalPrice - data.newPrice;
    const priceDropPercent = (priceDropAmount / data.originalPrice) * 100;

    // Only create for significant drops (5% or more)
    if (priceDropPercent < 5) {
      return null;
    }

    return this.prisma.priceAlert.create({
      data: {
        userId: data.userId,
        listingId: data.listingId,
        listingTitle: data.listingTitle,
        listingImageUrl: data.listingImageUrl,
        sellerName: data.sellerName,
        originalPrice: data.originalPrice,
        newPrice: data.newPrice,
        priceDropAmount,
        priceDropPercent,
      },
    });
  }
}
