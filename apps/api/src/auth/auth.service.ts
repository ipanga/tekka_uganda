import {
  Injectable,
  UnauthorizedException,
  BadRequestException,
} from '@nestjs/common';
import { JwtService } from '@nestjs/jwt';
import { PrismaService } from '../prisma/prisma.service';
import { OtpService } from './otp.service';
import { EmailService } from '../email/email.service';
import { User } from '@prisma/client';
import * as bcrypt from 'bcrypt';

export interface JwtPayload {
  sub: string;
  phone: string;
  role: string;
}

export interface AuthTokens {
  accessToken: string;
  refreshToken: string;
  user: Partial<User>;
}

@Injectable()
export class AuthService {
  constructor(
    private prisma: PrismaService,
    private jwtService: JwtService,
    private otpService: OtpService,
    private emailService: EmailService,
  ) {}

  /**
   * Format phone number to E.164 format for Uganda
   */
  private formatPhoneNumber(phone: string): string {
    let formatted = phone.replace(/\s+/g, '').replace(/[^\d+]/g, '');

    // If starts with 0, replace with +256
    if (formatted.startsWith('0')) {
      formatted = '+256' + formatted.substring(1);
    }
    // If doesn't start with +, assume Uganda
    else if (!formatted.startsWith('+')) {
      formatted = '+256' + formatted;
    }

    return formatted;
  }

  /**
   * Mask an email address for display (e.g. "john@gmail.com" → "j***@gmail.com")
   */
  private maskEmail(email: string): string {
    const [local, domain] = email.split('@');
    if (!domain) return '***';
    const visible = local.charAt(0);
    return `${visible}***@${domain}`;
  }

  /**
   * Send OTP to phone number
   * Uses WhatsApp as primary channel, SMS as fallback
   */
  async sendOTP(phone: string): Promise<{
    success: boolean;
    message: string;
    channel?: string;
    hasEmail: boolean;
    emailHint: string | null;
  }> {
    const formattedPhone = this.formatPhoneNumber(phone);

    // Validate phone number format
    if (!/^\+256[0-9]{9}$/.test(formattedPhone)) {
      throw new BadRequestException('Invalid Ugandan phone number format');
    }

    const result = await this.otpService.sendOTP(formattedPhone);

    if (!result.success) {
      throw new BadRequestException('Failed to send verification code');
    }

    // Check if this phone has an associated email (for email fallback)
    let hasEmail = false;
    let emailHint: string | null = null;

    const existingUser = await this.prisma.user.findUnique({
      where: { phoneNumber: formattedPhone },
      select: { email: true, isEmailVerified: true },
    });

    if (existingUser?.email) {
      hasEmail = true;
      emailHint = this.maskEmail(existingUser.email);
    }

    return {
      success: true,
      message: result.message || 'Verification code sent successfully',
      channel: result.channel,
      hasEmail,
      emailHint,
    };
  }

  /**
   * Re-send the existing OTP code via email (fallback when SMS is unreliable)
   */
  async sendOtpViaEmail(
    phone: string,
  ): Promise<{ success: boolean; message: string; channel: string }> {
    const formattedPhone = this.formatPhoneNumber(phone);

    // Get the stored OTP (must have been sent via SMS first)
    const code = this.otpService.getStoredCode(formattedPhone);
    if (!code) {
      throw new BadRequestException(
        'No active verification code. Please request a new code via SMS first.',
      );
    }

    // Look up user's email
    const user = await this.prisma.user.findUnique({
      where: { phoneNumber: formattedPhone },
      select: { email: true },
    });

    if (!user?.email) {
      throw new BadRequestException(
        'No email address on file. Please add an email to your profile first.',
      );
    }

    const sent = await this.emailService.sendOtp(user.email, code);
    if (!sent) {
      throw new BadRequestException('Failed to send email. Please try again.');
    }

    return {
      success: true,
      message: 'Verification code sent to your email',
      channel: 'email',
    };
  }

  /**
   * Verify OTP and authenticate user
   */
  async verifyOTP(phone: string, code: string): Promise<AuthTokens> {
    const formattedPhone = this.formatPhoneNumber(phone);

    // Verify the OTP
    const verification = this.otpService.verifyOTP(formattedPhone, code);

    if (!verification.valid) {
      throw new UnauthorizedException('Invalid or expired verification code');
    }

    // Find or create user
    let user = await this.prisma.user.findUnique({
      where: { phoneNumber: formattedPhone },
    });

    if (!user) {
      // Create new user
      user = await this.prisma.user.create({
        data: {
          phoneNumber: formattedPhone,
          isPhoneVerified: true,
          isOnboardingComplete: false,
        },
      });
    } else {
      // Update existing user
      user = await this.prisma.user.update({
        where: { id: user.id },
        data: {
          isPhoneVerified: true,
          lastLoginAt: new Date(),
        },
      });
    }

    // Generate tokens
    const tokens = await this.generateTokens(user);

    return {
      ...tokens,
      user: this.sanitizeUser(user),
    };
  }

  /**
   * Register a new user with profile info
   */
  async completeProfile(
    userId: string,
    data: {
      displayName: string;
      location?: string;
      bio?: string;
      email?: string;
    },
  ): Promise<User> {
    const user = await this.prisma.user.update({
      where: { id: userId },
      data: {
        displayName: data.displayName,
        location: data.location,
        bio: data.bio,
        ...(data.email && { email: data.email.toLowerCase() }),
        isOnboardingComplete: true,
      },
    });

    return user;
  }

  /**
   * Refresh access token
   */
  async refreshTokens(refreshToken: string): Promise<AuthTokens> {
    try {
      const payload = this.jwtService.verify<JwtPayload>(refreshToken);

      const user = await this.prisma.user.findUnique({
        where: { id: payload.sub },
      });

      if (!user || user.isSuspended) {
        throw new UnauthorizedException('User not found or suspended');
      }

      const tokens = await this.generateTokens(user);

      return {
        ...tokens,
        user: this.sanitizeUser(user),
      };
    } catch {
      throw new UnauthorizedException('Invalid refresh token');
    }
  }

  /**
   * Generate JWT tokens
   */
  private async generateTokens(
    user: User,
  ): Promise<{ accessToken: string; refreshToken: string }> {
    const payload: JwtPayload = {
      sub: user.id,
      phone: user.phoneNumber,
      role: user.role,
    };

    const [accessToken, refreshToken] = await Promise.all([
      this.jwtService.signAsync(payload, { expiresIn: '1h' }),
      this.jwtService.signAsync(payload, { expiresIn: '7d' }),
    ]);

    return { accessToken, refreshToken };
  }

  /**
   * Remove sensitive fields from user object
   */
  sanitizeUser(user: User): Partial<User> {
    const {
      passwordHash: _passwordHash,
      twoFactorSecret: _twoFactorSecret,
      twoFactorBackupCodes: _twoFactorBackupCodes,
      twoFactorPendingSecret: _twoFactorPendingSecret,
      twoFactorPendingCode: _twoFactorPendingCode,
      ...sanitized
    } = user;
    return sanitized;
  }

  /**
   * Validate user from JWT payload
   */
  async validateUser(payload: JwtPayload): Promise<User> {
    const user = await this.prisma.user.findUnique({
      where: { id: payload.sub },
    });

    if (!user || user.isSuspended) {
      throw new UnauthorizedException('User not found or suspended');
    }

    return user;
  }

  /**
   * Admin login with email and password
   */
  async adminLoginWithEmail(
    email: string,
    password: string,
  ): Promise<AuthTokens> {
    const user = await this.prisma.user.findUnique({
      where: { email: email.toLowerCase() },
    });

    if (!user || !['ADMIN', 'MODERATOR'].includes(user.role)) {
      throw new UnauthorizedException('Invalid credentials');
    }

    if (!user.passwordHash) {
      throw new UnauthorizedException(
        'Password not set. Please contact support.',
      );
    }

    const isPasswordValid = await bcrypt.compare(password, user.passwordHash);
    if (!isPasswordValid) {
      throw new UnauthorizedException('Invalid credentials');
    }

    if (user.isSuspended) {
      throw new UnauthorizedException('Account is suspended');
    }

    // Update last login
    await this.prisma.user.update({
      where: { id: user.id },
      data: { lastLoginAt: new Date() },
    });

    const tokens = await this.generateTokens(user);

    return {
      ...tokens,
      user: this.sanitizeUser(user),
    };
  }

  /**
   * Create admin user with email and password
   */
  async createAdminUser(data: {
    email: string;
    password: string;
    displayName: string;
    role: 'ADMIN' | 'MODERATOR';
  }): Promise<User> {
    // Check if email already exists
    const existingUser = await this.prisma.user.findUnique({
      where: { email: data.email.toLowerCase() },
    });

    if (existingUser) {
      throw new BadRequestException('Email already exists');
    }

    // Hash password
    const passwordHash = await bcrypt.hash(data.password, 12);

    // Generate a placeholder phone number for admin users
    const placeholderPhone = `admin_${Date.now()}`;

    const user = await this.prisma.user.create({
      data: {
        email: data.email.toLowerCase(),
        passwordHash,
        displayName: data.displayName,
        phoneNumber: placeholderPhone,
        role: data.role,
        isOnboardingComplete: true,
        isEmailVerified: true,
      },
    });

    return user;
  }

  /**
   * Update admin password
   */
  async updateAdminPassword(
    userId: string,
    currentPassword: string,
    newPassword: string,
  ): Promise<void> {
    const user = await this.prisma.user.findUnique({
      where: { id: userId },
    });

    if (!user || !['ADMIN', 'MODERATOR'].includes(user.role)) {
      throw new UnauthorizedException('Not authorized');
    }

    if (user.passwordHash) {
      const isPasswordValid = await bcrypt.compare(
        currentPassword,
        user.passwordHash,
      );
      if (!isPasswordValid) {
        throw new UnauthorizedException('Current password is incorrect');
      }
    }

    const passwordHash = await bcrypt.hash(newPassword, 12);

    await this.prisma.user.update({
      where: { id: userId },
      data: { passwordHash },
    });
  }
}
