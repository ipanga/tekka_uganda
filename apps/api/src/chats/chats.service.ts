import {
  Injectable,
  NotFoundException,
  ForbiddenException,
  BadRequestException,
} from '@nestjs/common';
import { PrismaService } from '../prisma/prisma.service';
import { CreateChatDto, SendMessageDto, UpdateMessageDto } from './dto';
import { MessageType, MessageStatus, NotificationType } from '@prisma/client';
import { NotificationsService } from '../notifications/notifications.service';

@Injectable()
export class ChatsService {
  constructor(
    private prisma: PrismaService,
    private notificationsService: NotificationsService,
  ) {}

  /**
   * Get all chats for a user (as buyer or seller)
   */
  async findAllForUser(userId: string) {
    const chats = await this.prisma.chat.findMany({
      where: {
        OR: [{ buyerId: userId }, { sellerId: userId }],
      },
      include: {
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
        listing: {
          select: {
            id: true,
            title: true,
            price: true,
            imageUrls: true,
            status: true,
          },
        },
        messages: {
          take: 1,
          orderBy: { createdAt: 'desc' },
          select: {
            id: true,
            content: true,
            type: true,
            createdAt: true,
            senderId: true,
            status: true,
          },
        },
      },
      orderBy: { updatedAt: 'desc' },
    });

    return chats.map((chat) => {
      const isBuyer = chat.buyerId === userId;
      return {
        ...chat,
        lastMessage: chat.messages[0] || null,
        unreadCount: isBuyer ? chat.buyerUnread : chat.sellerUnread,
        otherUser: isBuyer ? chat.seller : chat.buyer,
        messages: undefined,
      };
    });
  }

  /**
   * Get or create a chat between buyer and seller for a listing
   */
  async findOrCreate(buyerId: string, dto: CreateChatDto) {
    if (!dto.listingId) {
      throw new BadRequestException('Listing ID is required');
    }

    // Get the listing to find the seller
    const listing = await this.prisma.listing.findUnique({
      where: { id: dto.listingId },
      select: { id: true, sellerId: true, title: true },
    });

    if (!listing) {
      throw new NotFoundException('Listing not found');
    }

    // Prevent chatting with self
    if (buyerId === listing.sellerId) {
      throw new BadRequestException('Cannot create chat with yourself');
    }

    // Check if blocked
    const isBlocked = await this.prisma.blockedUser.findFirst({
      where: {
        OR: [
          { blockerId: buyerId, blockedId: listing.sellerId },
          { blockerId: listing.sellerId, blockedId: buyerId },
        ],
      },
    });

    if (isBlocked) {
      throw new ForbiddenException('Cannot chat with this user');
    }

    // Find existing chat
    let chat = await this.prisma.chat.findUnique({
      where: {
        buyerId_sellerId_listingId: {
          buyerId,
          sellerId: listing.sellerId,
          listingId: dto.listingId,
        },
      },
      include: {
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
        listing: {
          select: {
            id: true,
            title: true,
            price: true,
            imageUrls: true,
            status: true,
          },
        },
      },
    });

    if (!chat) {
      // Create new chat
      chat = await this.prisma.chat.create({
        data: {
          buyerId,
          sellerId: listing.sellerId,
          listingId: dto.listingId,
        },
        include: {
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
          listing: {
            select: {
              id: true,
              title: true,
              price: true,
              imageUrls: true,
              status: true,
            },
          },
        },
      });
    }

    return chat;
  }

  /**
   * Get a single chat
   */
  async findOne(chatId: string, userId: string) {
    const chat = await this.prisma.chat.findUnique({
      where: { id: chatId },
      include: {
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
        listing: {
          select: {
            id: true,
            title: true,
            price: true,
            imageUrls: true,
            status: true,
            seller: {
              select: {
                id: true,
                displayName: true,
              },
            },
          },
        },
      },
    });

    if (!chat) {
      throw new NotFoundException('Chat not found');
    }

    // Check if user is participant
    if (chat.buyerId !== userId && chat.sellerId !== userId) {
      throw new ForbiddenException('You are not a participant of this chat');
    }

    return chat;
  }

  /**
   * Get messages for a chat with pagination
   */
  async getMessages(
    chatId: string,
    userId: string,
    cursor?: string,
    limit = 50,
  ) {
    // Verify user is participant
    await this.findOne(chatId, userId);

    const messages = await this.prisma.message.findMany({
      where: { chatId },
      take: limit,
      ...(cursor && {
        skip: 1,
        cursor: { id: cursor },
      }),
      orderBy: { createdAt: 'desc' },
      include: {
        sender: {
          select: {
            id: true,
            displayName: true,
            photoUrl: true,
          },
        },
      },
    });

    return {
      messages: messages.reverse(),
      nextCursor: messages.length === limit ? messages[0].id : null,
    };
  }

  /**
   * Send a message
   */
  async sendMessage(chatId: string, userId: string, dto: SendMessageDto) {
    // Verify user is participant
    const chat = await this.findOne(chatId, userId);

    // Determine other user
    const otherUserId = chat.buyerId === userId ? chat.sellerId : chat.buyerId;

    // Check if blocked
    const isBlocked = await this.prisma.blockedUser.findFirst({
      where: {
        OR: [
          { blockerId: userId, blockedId: otherUserId },
          { blockerId: otherUserId, blockedId: userId },
        ],
      },
    });

    if (isBlocked) {
      throw new ForbiddenException('Cannot send messages in this chat');
    }

    // Create message
    const message = await this.prisma.message.create({
      data: {
        chatId,
        senderId: userId,
        content: dto.content,
        type: dto.type || MessageType.TEXT,
        status: MessageStatus.SENT,
        ...(dto.type === MessageType.IMAGE && { imageUrl: dto.content }),
        ...(dto.type === MessageType.OFFER &&
          dto.metadata?.offerAmount && {
            offerAmount: dto.metadata.offerAmount,
          }),
        ...(dto.type === MessageType.MEETUP &&
          dto.metadata && {
            meetupData: dto.metadata,
          }),
      },
      include: {
        sender: {
          select: {
            id: true,
            displayName: true,
            photoUrl: true,
          },
        },
      },
    });

    // Update chat with last message and unread counts
    const isBuyer = chat.buyerId === userId;
    await this.prisma.chat.update({
      where: { id: chatId },
      data: {
        lastMessage: dto.content.substring(0, 100),
        lastMessageAt: new Date(),
        // Increment unread count for the other user
        ...(isBuyer
          ? { sellerUnread: { increment: 1 } }
          : { buyerUnread: { increment: 1 } }),
      },
    });

    // Send push notification to other participant
    const recipientId = isBuyer ? chat.sellerId : chat.buyerId;
    const senderName = message.sender?.displayName || 'Someone';
    await this.notificationsService.send({
      userId: recipientId,
      type: NotificationType.MESSAGE,
      title: `New message from ${senderName}`,
      body: dto.content.substring(0, 100),
      data: { chatId, messageId: message.id },
    });

    return message;
  }

  /**
   * Update a message (only content update for text messages)
   */
  async updateMessage(
    messageId: string,
    userId: string,
    dto: UpdateMessageDto,
  ) {
    const message = await this.prisma.message.findUnique({
      where: { id: messageId },
    });

    if (!message) {
      throw new NotFoundException('Message not found');
    }

    if (message.senderId !== userId) {
      throw new ForbiddenException('You can only edit your own messages');
    }

    if (message.type !== MessageType.TEXT) {
      throw new BadRequestException('Can only edit text messages');
    }

    return this.prisma.message.update({
      where: { id: messageId },
      data: {
        content: dto.content,
      },
      include: {
        sender: {
          select: {
            id: true,
            displayName: true,
            photoUrl: true,
          },
        },
      },
    });
  }

  /**
   * Delete a message
   */
  async deleteMessage(messageId: string, userId: string) {
    const message = await this.prisma.message.findUnique({
      where: { id: messageId },
    });

    if (!message) {
      throw new NotFoundException('Message not found');
    }

    if (message.senderId !== userId) {
      throw new ForbiddenException('You can only delete your own messages');
    }

    await this.prisma.message.delete({
      where: { id: messageId },
    });

    return { success: true };
  }

  /**
   * Mark messages as read
   */
  async markAsRead(chatId: string, userId: string) {
    const chat = await this.findOne(chatId, userId);

    // Update message status
    await this.prisma.message.updateMany({
      where: {
        chatId,
        senderId: { not: userId },
        status: { not: MessageStatus.READ },
      },
      data: {
        status: MessageStatus.READ,
        readAt: new Date(),
      },
    });

    // Reset unread count for this user
    const isBuyer = chat.buyerId === userId;
    await this.prisma.chat.update({
      where: { id: chatId },
      data: isBuyer ? { buyerUnread: 0 } : { sellerUnread: 0 },
    });

    return { success: true };
  }

  /**
   * Get total unread message count for user
   */
  async getUnreadCount(userId: string) {
    const chats = await this.prisma.chat.findMany({
      where: {
        OR: [{ buyerId: userId }, { sellerId: userId }],
      },
      select: {
        buyerId: true,
        buyerUnread: true,
        sellerUnread: true,
      },
    });

    const unreadCount = chats.reduce((total, chat) => {
      return (
        total + (chat.buyerId === userId ? chat.buyerUnread : chat.sellerUnread)
      );
    }, 0);

    return { unreadCount };
  }

  /**
   * Delete a chat
   */
  async deleteChat(chatId: string, userId: string) {
    await this.findOne(chatId, userId);

    await this.prisma.message.deleteMany({
      where: { chatId },
    });

    await this.prisma.chat.delete({
      where: { id: chatId },
    });

    return { success: true };
  }

  /**
   * Archive a chat (per-user archiving)
   */
  async archiveChat(chatId: string, userId: string) {
    const chat = await this.findOne(chatId, userId);
    const isBuyer = chat.buyerId === userId;

    return this.prisma.chat.update({
      where: { id: chatId },
      data: isBuyer ? { isArchivedBuyer: true } : { isArchivedSeller: true },
    });
  }

  /**
   * Unarchive a chat
   */
  async unarchiveChat(chatId: string, userId: string) {
    const chat = await this.findOne(chatId, userId);
    const isBuyer = chat.buyerId === userId;

    return this.prisma.chat.update({
      where: { id: chatId },
      data: isBuyer ? { isArchivedBuyer: false } : { isArchivedSeller: false },
    });
  }

  /**
   * Search messages in user's chats
   */
  async searchMessages(userId: string, query: string, limit = 20) {
    const messages = await this.prisma.message.findMany({
      where: {
        chat: {
          OR: [{ buyerId: userId }, { sellerId: userId }],
        },
        content: {
          contains: query,
          mode: 'insensitive',
        },
      },
      take: limit,
      orderBy: { createdAt: 'desc' },
      include: {
        chat: {
          select: {
            id: true,
            listing: {
              select: {
                id: true,
                title: true,
              },
            },
          },
        },
        sender: {
          select: {
            id: true,
            displayName: true,
            photoUrl: true,
          },
        },
      },
    });

    return messages;
  }
}
