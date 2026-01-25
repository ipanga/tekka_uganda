import {
  Injectable,
  NotFoundException,
  ForbiddenException,
  BadRequestException,
} from '@nestjs/common';
import { PrismaService } from '../prisma/prisma.service';
import { CreateMeetupDto } from './dto';
import { MeetupStatus, NotificationType } from '@prisma/client';
import { NotificationsService } from '../notifications/notifications.service';

@Injectable()
export class MeetupsService {
  constructor(
    private prisma: PrismaService,
    private notificationsService: NotificationsService,
  ) {}

  /**
   * Get all safe locations
   */
  async getSafeLocations(city?: string) {
    return this.prisma.safeLocation.findMany({
      where: {
        ...(city && { city: { contains: city, mode: 'insensitive' } }),
      },
      orderBy: [{ isVerified: 'desc' }, { name: 'asc' }],
    });
  }

  /**
   * Get a safe location by ID
   */
  async getSafeLocation(id: string) {
    const location = await this.prisma.safeLocation.findUnique({
      where: { id },
    });

    if (!location) {
      throw new NotFoundException('Location not found');
    }

    return location;
  }

  /**
   * Schedule a meetup
   */
  async create(userId: string, dto: CreateMeetupDto) {
    // Verify location exists if locationId provided
    let locationName = dto.locationName;
    let locationAddress = dto.locationAddress;
    let latitude = dto.latitude;
    let longitude = dto.longitude;

    if (dto.locationId) {
      const location = await this.getSafeLocation(dto.locationId);
      locationName = location.name;
      locationAddress = location.address;
      latitude = location.latitude;
      longitude = location.longitude;
    }

    // Verify chat exists and user is a participant
    const chat = await this.prisma.chat.findUnique({
      where: { id: dto.chatId },
      include: { listing: true },
    });

    if (!chat || (chat.buyerId !== userId && chat.sellerId !== userId)) {
      throw new ForbiddenException('Chat not found or access denied');
    }

    // Create meetup
    const meetup = await this.prisma.meetup.create({
      data: {
        chatId: dto.chatId,
        proposerId: userId,
        locationName,
        locationAddress,
        latitude,
        longitude,
        scheduledAt: new Date(dto.scheduledAt),
        notes: dto.notes,
        status: MeetupStatus.PROPOSED,
      },
      include: {
        chat: {
          include: {
            listing: { select: { id: true, title: true } },
          },
        },
      },
    });

    // Notify the other user
    const otherUserId = chat.buyerId === userId ? chat.sellerId : chat.buyerId;
    await this.notificationsService.send({
      userId: otherUserId,
      type: NotificationType.MEETUP_PROPOSED,
      title: 'Meetup Proposed',
      body: `A meetup has been proposed at ${locationName}`,
      data: { meetupId: meetup.id, chatId: dto.chatId },
    });

    return meetup;
  }

  /**
   * Get meetup by ID
   */
  async findOne(id: string, userId: string) {
    const meetup = await this.prisma.meetup.findUnique({
      where: { id },
      include: {
        chat: {
          include: {
            listing: { select: { id: true, title: true, imageUrls: true } },
            buyer: { select: { id: true, displayName: true, photoUrl: true } },
            seller: { select: { id: true, displayName: true, photoUrl: true } },
          },
        },
      },
    });

    if (!meetup) {
      throw new NotFoundException('Meetup not found');
    }

    // Check if user is a participant via the chat
    if (meetup.chat.buyerId !== userId && meetup.chat.sellerId !== userId) {
      throw new ForbiddenException('Access denied');
    }

    return meetup;
  }

  /**
   * Get meetups for a chat
   */
  async findForChat(chatId: string, userId: string) {
    // Verify user is a participant
    const chat = await this.prisma.chat.findUnique({
      where: { id: chatId },
    });

    if (!chat || (chat.buyerId !== userId && chat.sellerId !== userId)) {
      throw new ForbiddenException('Chat not found or access denied');
    }

    return this.prisma.meetup.findMany({
      where: { chatId },
      include: {
        chat: {
          include: {
            listing: { select: { id: true, title: true } },
          },
        },
      },
      orderBy: { scheduledAt: 'desc' },
    });
  }

  /**
   * Get upcoming meetups for a user
   */
  async findUpcoming(userId: string) {
    return this.prisma.meetup.findMany({
      where: {
        chat: {
          OR: [{ buyerId: userId }, { sellerId: userId }],
        },
        scheduledAt: { gte: new Date() },
        status: { in: [MeetupStatus.PROPOSED, MeetupStatus.ACCEPTED] },
      },
      include: {
        chat: {
          include: {
            listing: { select: { id: true, title: true, imageUrls: true } },
            buyer: { select: { id: true, displayName: true, photoUrl: true } },
            seller: { select: { id: true, displayName: true, photoUrl: true } },
          },
        },
      },
      orderBy: { scheduledAt: 'asc' },
    });
  }

  /**
   * Accept a meetup
   */
  async accept(id: string, userId: string) {
    const meetup = await this.findOne(id, userId);

    if (meetup.status !== MeetupStatus.PROPOSED) {
      throw new BadRequestException('Meetup cannot be accepted');
    }

    // Only the non-proposer can accept
    if (meetup.proposerId === userId) {
      throw new BadRequestException('Cannot accept your own meetup proposal');
    }

    const updated = await this.prisma.meetup.update({
      where: { id },
      data: { status: MeetupStatus.ACCEPTED },
    });

    // Notify the proposer
    await this.notificationsService.send({
      userId: meetup.proposerId,
      type: NotificationType.MEETUP_ACCEPTED,
      title: 'Meetup Accepted',
      body: `Your meetup at ${meetup.locationName} has been accepted`,
      data: { meetupId: id },
    });

    return updated;
  }

  /**
   * Decline a meetup
   */
  async decline(id: string, userId: string) {
    const meetup = await this.findOne(id, userId);

    if (meetup.status !== MeetupStatus.PROPOSED) {
      throw new BadRequestException('Meetup cannot be declined');
    }

    const updated = await this.prisma.meetup.update({
      where: { id },
      data: { status: MeetupStatus.DECLINED },
    });

    // Notify the proposer
    await this.notificationsService.send({
      userId: meetup.proposerId,
      type: NotificationType.SYSTEM,
      title: 'Meetup Declined',
      body: `Your meetup at ${meetup.locationName} has been declined`,
      data: { meetupId: id },
    });

    return updated;
  }

  /**
   * Cancel a meetup
   */
  async cancel(id: string, userId: string) {
    const meetup = await this.findOne(id, userId);

    if (
      meetup.status === MeetupStatus.COMPLETED ||
      meetup.status === MeetupStatus.CANCELLED
    ) {
      throw new BadRequestException('Meetup cannot be cancelled');
    }

    const updated = await this.prisma.meetup.update({
      where: { id },
      data: { status: MeetupStatus.CANCELLED },
    });

    // Notify the other user
    const otherUserId =
      meetup.chat.buyerId === userId
        ? meetup.chat.sellerId
        : meetup.chat.buyerId;
    await this.notificationsService.send({
      userId: otherUserId,
      type: NotificationType.SYSTEM,
      title: 'Meetup Cancelled',
      body: `The meetup at ${meetup.locationName} has been cancelled`,
      data: { meetupId: id },
    });

    return updated;
  }

  /**
   * Complete a meetup
   */
  async complete(id: string, userId: string) {
    const meetup = await this.findOne(id, userId);

    if (meetup.status !== MeetupStatus.ACCEPTED) {
      throw new BadRequestException('Only accepted meetups can be completed');
    }

    return this.prisma.meetup.update({
      where: { id },
      data: { status: MeetupStatus.COMPLETED },
    });
  }

  /**
   * Mark a meetup as no-show
   */
  async noShow(id: string, userId: string) {
    const meetup = await this.findOne(id, userId);

    if (meetup.status !== MeetupStatus.ACCEPTED) {
      throw new BadRequestException(
        'Only accepted meetups can be marked as no-show',
      );
    }

    const updated = await this.prisma.meetup.update({
      where: { id },
      data: { status: MeetupStatus.NO_SHOW },
    });

    // Notify the other user
    const otherUserId =
      meetup.chat.buyerId === userId
        ? meetup.chat.sellerId
        : meetup.chat.buyerId;
    await this.notificationsService.send({
      userId: otherUserId,
      type: NotificationType.SYSTEM,
      title: 'Meetup No-Show',
      body: `The meetup at ${meetup.locationName} was marked as no-show`,
      data: { meetupId: id },
    });

    return updated;
  }
}
