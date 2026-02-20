import {
  Injectable,
  Logger,
  NotFoundException,
  ConflictException,
  BadRequestException,
} from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import * as crypto from 'crypto';
import { PrismaService } from '../prisma/prisma.service';
import { EmailService } from '../email/email.service';
import { User } from '@prisma/client';
import {
  UpdateUserDto,
  UpdateUserSettingsDto,
  RegisterFcmTokenDto,
} from './dto/update-user.dto';

@Injectable()
export class UsersService {
  private readonly logger = new Logger(UsersService.name);
  private readonly isDevelopment: boolean;

  constructor(
    private prisma: PrismaService,
    private emailService: EmailService,
    private configService: ConfigService,
  ) {
    this.isDevelopment =
      this.configService.get<string>('NODE_ENV') === 'development';
  }

  async findById(id: string): Promise<User> {
    const user = await this.prisma.user.findUnique({
      where: { id },
    });

    if (!user) {
      throw new NotFoundException('User not found');
    }

    return user;
  }

  async findByFirebaseUid(firebaseUid: string): Promise<User | null> {
    return this.prisma.user.findUnique({
      where: { firebaseUid },
    });
  }

  async update(userId: string, dto: UpdateUserDto): Promise<User> {
    const user = await this.findById(userId);

    // Check email uniqueness if updating email
    if (dto.email && dto.email !== user.email) {
      const existingUser = await this.prisma.user.findUnique({
        where: { email: dto.email },
      });
      if (existingUser) {
        throw new ConflictException('Email already in use');
      }
    }

    return this.prisma.user.update({
      where: { id: userId },
      data: dto,
    });
  }

  async updateSettings(
    userId: string,
    dto: UpdateUserSettingsDto,
  ): Promise<User> {
    await this.findById(userId);

    return this.prisma.user.update({
      where: { id: userId },
      data: dto,
    });
  }

  async getSettings(userId: string) {
    const user = await this.findById(userId);

    return {
      priceAlertsEnabled: user.priceAlertsEnabled ?? true,
      language: user.language ?? 'en',
      defaultLocation: user.defaultLocation,
      // Notification preferences
      pushEnabled: user.pushEnabled ?? true,
      emailEnabled: user.emailEnabled ?? true,
      marketingEnabled: user.marketingEnabled ?? false,
      messageNotifications: user.messageNotifications ?? true,
      offerNotifications: user.offerNotifications ?? true,
      reviewNotifications: user.reviewNotifications ?? true,
      listingNotifications: user.listingNotifications ?? true,
      systemNotifications: user.systemNotifications ?? true,
      doNotDisturb: user.doNotDisturb ?? false,
      dndStartHour: user.dndStartHour ?? 22,
      dndEndHour: user.dndEndHour ?? 7,
      // Security settings
      pinEnabled: user.pinEnabled ?? false,
      biometricEnabled: user.biometricEnabled ?? false,
      loginAlerts: user.loginAlerts ?? true,
      requireTransactionConfirmation:
        user.requireTransactionConfirmation ?? true,
      transactionThreshold: user.transactionThreshold ?? 500000,
      twoFactorEnabled: user.twoFactorEnabled ?? false,
    };
  }

  async getProfile(userId: string) {
    const user = await this.prisma.user.findUnique({
      where: { id: userId },
      include: {
        _count: {
          select: {
            listings: { where: { status: 'ACTIVE' } },
            reviewsReceived: true,
          },
        },
      },
    });

    if (!user) {
      throw new NotFoundException('User not found');
    }

    // Calculate average rating
    const ratings = await this.prisma.review.aggregate({
      where: { revieweeId: userId },
      _avg: { rating: true },
      _count: { rating: true },
    });

    return {
      ...user,
      totalListings: user._count.listings,
      totalReviews: user._count.reviewsReceived,
      averageRating: ratings._avg.rating || 0,
    };
  }

  async getPublicProfile(userId: string) {
    const profile = await this.getProfile(userId);

    // Remove sensitive fields
    const {
      firebaseUid: _firebaseUid,
      email: _email,
      phoneNumber,
      priceAlertsEnabled: _priceAlertsEnabled,
      language: _language,
      defaultLocation: _defaultLocation,
      showPhoneNumber,
      ...publicProfile
    } = profile;

    // Only include phone number if user has enabled it
    return {
      ...publicProfile,
      phoneNumber: showPhoneNumber ? phoneNumber : undefined,
      showPhoneNumber,
    };
  }

  async getStats(userId: string) {
    const [totalListings, activeListings, soldListings, reviews] =
      await Promise.all([
        this.prisma.listing.count({
          where: { sellerId: userId },
        }),
        this.prisma.listing.count({
          where: { sellerId: userId, status: 'ACTIVE' },
        }),
        this.prisma.listing.count({
          where: { sellerId: userId, status: 'SOLD' },
        }),
        this.prisma.review.aggregate({
          where: { revieweeId: userId },
          _avg: { rating: true },
          _count: { rating: true },
        }),
      ]);

    return {
      totalListings,
      activeListings,
      soldListings,
      totalSales: soldListings, // Alias for backward compatibility
      averageRating: reviews._avg.rating || 0,
      totalReviews: reviews._count.rating,
      responseRate: 0, // TODO: Calculate based on message response data
      responseTime: 'N/A', // TODO: Calculate based on message response data
    };
  }

  // FCM Token management
  async registerFcmToken(userId: string, dto: RegisterFcmTokenDto) {
    // Upsert token - if token exists, update userId
    await this.prisma.fcmToken.upsert({
      where: { token: dto.token },
      create: {
        userId,
        token: dto.token,
        platform: dto.platform,
      },
      update: {
        userId,
        platform: dto.platform,
      },
    });
  }

  async removeFcmToken(userId: string, token: string) {
    await this.prisma.fcmToken.deleteMany({
      where: { token, userId },
    });
  }

  async getUserFcmTokens(userId: string): Promise<string[]> {
    const tokens = await this.prisma.fcmToken.findMany({
      where: { userId },
      select: { token: true },
    });
    return tokens.map((t) => t.token);
  }

  // Blocking
  async blockUser(blockerId: string, blockedId: string) {
    if (blockerId === blockedId) {
      throw new ConflictException('Cannot block yourself');
    }

    await this.findById(blockedId); // Verify blocked user exists

    return this.prisma.blockedUser.upsert({
      where: {
        blockerId_blockedId: { blockerId, blockedId },
      },
      create: { blockerId, blockedId },
      update: {},
    });
  }

  async unblockUser(blockerId: string, blockedId: string) {
    await this.prisma.blockedUser.deleteMany({
      where: { blockerId, blockedId },
    });
  }

  async getBlockedUsers(userId: string) {
    const blocked = await this.prisma.blockedUser.findMany({
      where: { blockerId: userId },
      include: {
        blocked: {
          select: {
            id: true,
            displayName: true,
            photoUrl: true,
          },
        },
      },
    });

    return blocked.map((b) => b.blocked);
  }

  async isBlocked(userId: string, otherUserId: string): Promise<boolean> {
    const block = await this.prisma.blockedUser.findFirst({
      where: {
        OR: [
          { blockerId: userId, blockedId: otherUserId },
          { blockerId: otherUserId, blockedId: userId },
        ],
      },
    });
    return !!block;
  }

  // Account Deletion
  async scheduleAccountDeletion(
    userId: string,
    reason: string,
    gracePeriodDays = 7,
  ) {
    // Verify user exists (throws if not found)
    await this.findById(userId);
    const scheduledDate = new Date();
    scheduledDate.setDate(scheduledDate.getDate() + gracePeriodDays);

    // Create or update scheduled deletion record
    await this.prisma.scheduledDeletion.upsert({
      where: { userId },
      create: {
        userId,
        reason,
        scheduledDate,
        status: 'PENDING',
      },
      update: {
        reason,
        scheduledDate,
        status: 'PENDING',
        requestedAt: new Date(),
      },
    });

    // Update user record
    await this.prisma.user.update({
      where: { id: userId },
      data: {
        accountDeletionScheduled: true,
        accountDeletionDate: scheduledDate,
      },
    });

    return {
      scheduledDate: scheduledDate.toISOString(),
      daysUntilDeletion: gracePeriodDays,
    };
  }

  async cancelScheduledDeletion(userId: string) {
    await this.findById(userId);

    // Delete the scheduled deletion record
    await this.prisma.scheduledDeletion.deleteMany({
      where: { userId },
    });

    // Update user record
    await this.prisma.user.update({
      where: { id: userId },
      data: {
        accountDeletionScheduled: false,
        accountDeletionDate: null,
      },
    });

    return { cancelled: true };
  }

  async getScheduledDeletion(userId: string) {
    const deletion = await this.prisma.scheduledDeletion.findUnique({
      where: { userId },
    });

    if (!deletion) {
      return { isScheduled: false };
    }

    return {
      isScheduled: true,
      scheduledDate: deletion.scheduledDate.toISOString(),
      daysUntilDeletion: Math.ceil(
        (deletion.scheduledDate.getTime() - Date.now()) / (1000 * 60 * 60 * 24),
      ),
      reason: deletion.reason,
    };
  }

  async deleteAccountImmediately(userId: string) {
    // Delete all user data using transaction
    await this.prisma.$transaction(async (tx) => {
      // Delete user's listings
      await tx.listing.deleteMany({ where: { sellerId: userId } });

      // Delete user's reviews (written)
      await tx.review.deleteMany({ where: { reviewerId: userId } });

      // Delete user's notifications
      await tx.notification.deleteMany({ where: { userId } });

      // Delete user's FCM tokens
      await tx.fcmToken.deleteMany({ where: { userId } });

      // Delete user's saved items
      await tx.savedItem.deleteMany({ where: { userId } });

      // Delete user's blocked users
      await tx.blockedUser.deleteMany({
        where: { OR: [{ blockerId: userId }, { blockedId: userId }] },
      });

      // Delete user's saved searches
      await tx.savedSearch.deleteMany({ where: { userId } });

      // Delete user's price alerts
      await tx.priceAlert.deleteMany({ where: { userId } });

      // Delete user's quick replies
      await tx.quickReplyTemplate.deleteMany({ where: { userId } });

      // Delete user's meetups (via proposerId)
      await tx.meetup.deleteMany({
        where: { proposerId: userId },
      });

      // Delete user's reports
      await tx.report.deleteMany({
        where: { OR: [{ reporterId: userId }, { reportedUserId: userId }] },
      });

      // Delete scheduled deletion record
      await tx.scheduledDeletion.deleteMany({ where: { userId } });

      // Finally delete the user
      await tx.user.delete({ where: { id: userId } });
    });

    return { deleted: true };
  }

  // Session Management
  async getLoginSessions(userId: string) {
    const sessions = await this.prisma.loginSession.findMany({
      where: { userId },
      orderBy: { loginTime: 'desc' },
      take: 10,
    });

    return sessions.map((session) => ({
      id: session.id,
      deviceName: session.deviceName,
      deviceType: session.deviceType,
      location: session.location,
      loginTime: session.loginTime.toISOString(),
      isCurrent: session.isCurrent,
    }));
  }

  async terminateSession(userId: string, sessionId: string) {
    await this.prisma.loginSession.deleteMany({
      where: { id: sessionId, userId },
    });
  }

  async signOutAllDevices(userId: string) {
    await this.prisma.loginSession.deleteMany({
      where: { userId },
    });
  }

  async getVerificationStatus(userId: string) {
    const user = await this.findById(userId);

    return {
      phoneVerified: !!user.phoneNumber,
      phoneVerifiedAt: user.phoneNumber ? user.createdAt?.toISOString() : null,
      emailVerified: user.isEmailVerified ?? false,
      emailVerifiedAt: user.emailVerifiedAt?.toISOString() ?? null,
      identityVerified: user.isIdentityVerified ?? false,
      identityVerifiedAt: user.identityVerifiedAt?.toISOString() ?? null,
    };
  }

  // 2FA Methods
  async get2FAStatus(userId: string) {
    const user = await this.findById(userId);

    return {
      isEnabled: user.twoFactorEnabled ?? false,
      method: user.twoFactorMethod ?? null,
      phoneNumber: user.twoFactorMethod === 'sms' ? user.phoneNumber : null,
      enabledAt: user.twoFactorEnabledAt?.toISOString() ?? null,
    };
  }

  async setup2FA(userId: string, method: 'sms' | 'authenticatorApp') {
    const user = await this.findById(userId);

    if (method === 'sms') {
      return {
        method: 'sms',
        phoneNumber: user.phoneNumber,
      };
    } else {
      // Generate secret for authenticator app
      const secret = this.generateBase32Secret(32);
      const email = user.email || user.phoneNumber || 'user';
      const qrCodeUrl = `otpauth://totp/Tekka:${email}?secret=${secret}&issuer=Tekka&algorithm=SHA1&digits=6&period=30`;

      // Generate backup codes
      const backupCodes = this.generateBackupCodes(10);

      // Store pending 2FA setup
      await this.prisma.user.update({
        where: { id: userId },
        data: {
          twoFactorPendingSecret: secret,
          twoFactorPendingMethod: method,
          twoFactorBackupCodes: backupCodes,
        },
      });

      return {
        method: 'authenticatorApp',
        secretKey: secret,
        qrCodeUrl,
        backupCodes,
      };
    }
  }

  async send2FASmsCode(userId: string) {
    const user = await this.findById(userId);

    if (!user.phoneNumber) {
      throw new BadRequestException('No phone number registered');
    }

    // Generate 6-digit code
    const code = crypto.randomInt(100000, 1000000).toString();
    const expiry = new Date(Date.now() + 10 * 60 * 1000); // 10 minutes

    await this.prisma.user.update({
      where: { id: userId },
      data: {
        twoFactorPendingCode: code,
        twoFactorCodeExpiry: expiry,
        twoFactorPendingMethod: 'sms',
      },
    });

    // In production, send SMS via Twilio or similar service
    // For now, just return success
    return { sent: true, expiresAt: expiry.toISOString() };
  }

  async verify2FACode(
    userId: string,
    code: string,
    method: 'sms' | 'authenticatorApp',
  ) {
    const user = await this.findById(userId);

    if (method === 'sms') {
      if (!user.twoFactorPendingCode || !user.twoFactorCodeExpiry) {
        throw new BadRequestException('No pending verification code');
      }

      if (new Date() > user.twoFactorCodeExpiry) {
        throw new BadRequestException('Code has expired');
      }

      if (code !== user.twoFactorPendingCode) {
        throw new BadRequestException('Invalid code');
      }
    } else {
      // For authenticator app, accept any 6-digit code for demo
      // In production, use proper TOTP validation
      if (!/^\d{6}$/.test(code)) {
        throw new BadRequestException('Invalid code format');
      }
    }

    // Enable 2FA
    const backupCodes =
      user.twoFactorBackupCodes || this.generateBackupCodes(10);

    await this.prisma.user.update({
      where: { id: userId },
      data: {
        twoFactorEnabled: true,
        twoFactorMethod: method,
        twoFactorEnabledAt: new Date(),
        twoFactorBackupCodes: backupCodes,
        twoFactorPendingCode: null,
        twoFactorCodeExpiry: null,
        twoFactorPendingSecret: null,
        twoFactorPendingMethod: null,
      },
    });

    return {
      enabled: true,
      method,
      backupCodes,
    };
  }

  async disable2FA(userId: string) {
    await this.prisma.user.update({
      where: { id: userId },
      data: {
        twoFactorEnabled: false,
        twoFactorMethod: null,
        twoFactorSecret: null,
        twoFactorBackupCodes: [],
        twoFactorPendingCode: null,
        twoFactorCodeExpiry: null,
        twoFactorPendingSecret: null,
        twoFactorPendingMethod: null,
      },
    });

    return { disabled: true };
  }

  async regenerateBackupCodes(userId: string) {
    const backupCodes = this.generateBackupCodes(10);

    await this.prisma.user.update({
      where: { id: userId },
      data: {
        twoFactorBackupCodes: backupCodes,
      },
    });

    return { backupCodes };
  }

  // Helper methods
  private generateBase32Secret(length: number): string {
    const chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ234567';
    let result = '';
    const randomBytes = crypto.randomBytes(length);
    for (let i = 0; i < length; i++) {
      result += chars[randomBytes[i] % chars.length];
    }
    return result;
  }

  private generateBackupCodes(count: number): string[] {
    const codes: string[] = [];
    for (let i = 0; i < count; i++) {
      codes.push(crypto.randomInt(10000000, 100000000).toString());
    }
    return codes;
  }

  // Identity Verification Methods
  async getIdentityVerificationStatus(userId: string) {
    const verification = await this.prisma.identityVerification.findUnique({
      where: { userId },
    });

    if (!verification) {
      return {
        state: 'initial',
        documentType: null,
        documentNumber: null,
        fullName: null,
        dateOfBirth: null,
        frontImageUrl: null,
        backImageUrl: null,
        selfieUrl: null,
        rejectionReason: null,
        submittedAt: null,
        verifiedAt: null,
      };
    }

    return {
      state: verification.state,
      documentType: verification.documentType,
      documentNumber: verification.documentNumber,
      fullName: verification.fullName,
      dateOfBirth: verification.dateOfBirth?.toISOString() ?? null,
      frontImageUrl: verification.frontImageUrl,
      backImageUrl: verification.backImageUrl,
      selfieUrl: verification.selfieUrl,
      rejectionReason: verification.rejectionReason,
      submittedAt: verification.submittedAt?.toISOString() ?? null,
      verifiedAt: verification.verifiedAt?.toISOString() ?? null,
    };
  }

  async submitIdentityVerification(
    userId: string,
    dto: {
      documentType: string;
      documentNumber: string;
      fullName: string;
      dateOfBirth: string;
      frontImageUrl: string;
      backImageUrl?: string;
      selfieUrl?: string;
    },
  ) {
    const verification = await this.prisma.identityVerification.upsert({
      where: { userId },
      create: {
        userId,
        state: 'underReview',
        documentType: dto.documentType,
        documentNumber: dto.documentNumber,
        fullName: dto.fullName,
        dateOfBirth: new Date(dto.dateOfBirth),
        frontImageUrl: dto.frontImageUrl,
        backImageUrl: dto.backImageUrl,
        selfieUrl: dto.selfieUrl,
        submittedAt: new Date(),
      },
      update: {
        state: 'underReview',
        documentType: dto.documentType,
        documentNumber: dto.documentNumber,
        fullName: dto.fullName,
        dateOfBirth: new Date(dto.dateOfBirth),
        frontImageUrl: dto.frontImageUrl,
        backImageUrl: dto.backImageUrl,
        selfieUrl: dto.selfieUrl,
        submittedAt: new Date(),
        rejectionReason: null,
      },
    });

    // Update user's verification pending status
    await this.prisma.user.update({
      where: { id: userId },
      data: { identityVerificationPending: true },
    });

    return {
      success: true,
      state: verification.state,
      submittedAt: verification.submittedAt?.toISOString(),
    };
  }

  // Email Verification Methods
  async sendEmailVerificationCode(userId: string, email: string) {
    // Check if email is already in use
    const existingUser = await this.prisma.user.findFirst({
      where: {
        email,
        isEmailVerified: true,
        NOT: { id: userId },
      },
    });

    if (existingUser) {
      throw new ConflictException(
        'This email is already linked to another account',
      );
    }

    // Generate 6-digit code
    const code = crypto.randomInt(100000, 1000000).toString();
    const expiresAt = new Date(Date.now() + 10 * 60 * 1000); // 10 minutes

    // Store verification data
    await this.prisma.emailVerification.upsert({
      where: { userId },
      create: {
        userId,
        email,
        code,
        expiresAt,
      },
      update: {
        email,
        code,
        expiresAt,
        verified: false,
      },
    });

    // Send verification email via Resend
    const sent = await this.emailService.sendEmailVerification(email, code);

    if (!sent) {
      // Email delivery failed
      if (this.isDevelopment) {
        // In dev mode, log the code so developers can still test the flow
        this.logger.warn(
          `[DEV] Email delivery failed. Verification code for ${email}: ${code}`,
        );
        return {
          sent: true,
          email,
          expiresAt: expiresAt.toISOString(),
          channel: 'mock' as const,
          message:
            'Email delivery failed — code logged to console (dev mode)',
        };
      }

      // In production, clean up and throw
      await this.prisma.emailVerification.delete({ where: { userId } });
      throw new BadRequestException(
        'Failed to send verification email. Please try again later.',
      );
    }

    this.logger.log(`Verification email sent to ${email} for user ${userId}`);

    return {
      sent: true,
      email,
      expiresAt: expiresAt.toISOString(),
      channel: 'email' as const,
    };
  }

  async verifyEmailCode(userId: string, code: string) {
    const verification = await this.prisma.emailVerification.findUnique({
      where: { userId },
    });

    if (!verification) {
      throw new BadRequestException(
        'No pending verification. Please request a new code.',
      );
    }

    if (new Date() > verification.expiresAt) {
      throw new BadRequestException(
        'Verification code expired. Please request a new code.',
      );
    }

    if (code !== verification.code) {
      throw new BadRequestException('Invalid verification code.');
    }

    // Update user email
    await this.prisma.user.update({
      where: { id: userId },
      data: {
        email: verification.email,
        isEmailVerified: true,
        emailVerifiedAt: new Date(),
      },
    });

    // Delete verification record
    await this.prisma.emailVerification.delete({
      where: { userId },
    });

    return {
      verified: true,
      email: verification.email,
    };
  }

  async removeEmail(userId: string) {
    await this.prisma.user.update({
      where: { id: userId },
      data: {
        email: null,
        isEmailVerified: false,
        emailVerifiedAt: null,
      },
    });

    return { removed: true };
  }

  // Privacy Settings Methods
  async getPrivacySettings(userId: string) {
    const user = await this.findById(userId);

    return {
      profileVisibility: user.profileVisibility ?? 'public',
      showLocation: user.showLocation ?? true,
      showPhoneNumber: user.showPhoneNumber ?? false,
      messagePermission: user.messagePermission ?? 'everyone',
      showOnlineStatus: user.showOnlineStatus ?? true,
      showPurchaseHistory: user.showPurchaseHistory ?? false,
      showListingsCount: user.showListingsCount ?? true,
      appearInSearch: user.appearInSearch ?? true,
      allowProfileSharing: user.allowProfileSharing ?? true,
    };
  }

  async updatePrivacySettings(
    userId: string,
    dto: {
      profileVisibility?: string;
      showLocation?: boolean;
      showPhoneNumber?: boolean;
      messagePermission?: string;
      showOnlineStatus?: boolean;
      showPurchaseHistory?: boolean;
      showListingsCount?: boolean;
      appearInSearch?: boolean;
      allowProfileSharing?: boolean;
    },
  ) {
    await this.prisma.user.update({
      where: { id: userId },
      data: dto,
    });

    return this.getPrivacySettings(userId);
  }

  async canViewProfile(currentUserId: string, targetUserId: string) {
    // Can always view own profile
    if (currentUserId === targetUserId) {
      return { canView: true };
    }

    const targetPrivacy = await this.getPrivacySettings(targetUserId);

    switch (targetPrivacy.profileVisibility) {
      case 'public':
        return { canView: true };
      case 'buyersOnly': {
        // Check if current user has purchased from target user via Purchase model
        const purchase = await this.prisma.purchase.findFirst({
          where: {
            buyerId: currentUserId,
            listing: {
              sellerId: targetUserId,
            },
          },
        });
        return { canView: !!purchase };
      }
      case 'private':
        return { canView: false };
      default:
        return { canView: true };
    }
  }

  async canMessageUser(currentUserId: string, targetUserId: string) {
    // Can't message yourself
    if (currentUserId === targetUserId) {
      return { canMessage: false };
    }

    const targetPrivacy = await this.getPrivacySettings(targetUserId);

    switch (targetPrivacy.messagePermission) {
      case 'everyone':
        return { canMessage: true };
      case 'verifiedOnly':
        // For now, all authenticated users are considered verified
        return { canMessage: true };
      case 'noOne':
        return { canMessage: false };
      default:
        return { canMessage: true };
    }
  }
}
