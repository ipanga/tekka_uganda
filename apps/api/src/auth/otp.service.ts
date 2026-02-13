import {
  Injectable,
  BadRequestException,
  OnModuleInit,
  OnModuleDestroy,
} from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import * as crypto from 'crypto';
import { ThinkXCloudService } from './thinkxcloud.service';

interface OtpStore {
  code: string;
  expiresAt: Date;
  attempts: number;
}

interface OtpSendResult {
  success: boolean;
  channel: 'sms' | 'mock';
  message?: string;
}

/**
 * Unified OTP Service
 *
 * Handles OTP generation, storage, and delivery via SMS (ThinkX Cloud)
 */
@Injectable()
export class OtpService implements OnModuleInit, OnModuleDestroy {
  private otpStore: Map<string, OtpStore> = new Map();
  private cleanupInterval: NodeJS.Timeout | null = null;

  // OTP configuration
  private readonly OTP_LENGTH = 6;
  private readonly OTP_EXPIRY_MINUTES = 10;
  private readonly MAX_VERIFICATION_ATTEMPTS = 3;
  private readonly MAX_OTP_REQUESTS_PER_HOUR = 5;
  private readonly CLEANUP_INTERVAL_MINUTES = 5;

  // Rate limiting store
  private otpRequestCount: Map<string, { count: number; resetAt: Date }> =
    new Map();

  constructor(
    private configService: ConfigService,
    private thinkXCloudService: ThinkXCloudService,
  ) {
    console.log('OTP Service initialized with ThinkX Cloud provider.');
  }

  onModuleInit() {
    // Start periodic cleanup of expired OTPs
    this.cleanupInterval = setInterval(
      () => this.cleanupExpiredOTPs(),
      this.CLEANUP_INTERVAL_MINUTES * 60 * 1000,
    );
    console.log(
      `[OTP] Cleanup scheduler started (every ${this.CLEANUP_INTERVAL_MINUTES} minutes)`,
    );
  }

  onModuleDestroy() {
    // Clear cleanup interval on shutdown
    if (this.cleanupInterval) {
      clearInterval(this.cleanupInterval);
      this.cleanupInterval = null;
      console.log('[OTP] Cleanup scheduler stopped');
    }
  }

  /**
   * Generate a secure random OTP
   */
  private generateOTP(): string {
    const min = Math.pow(10, this.OTP_LENGTH - 1);
    const max = Math.pow(10, this.OTP_LENGTH);
    return crypto.randomInt(min, max).toString();
  }

  /**
   * Check rate limiting for OTP requests
   */
  private checkRateLimit(phoneNumber: string): void {
    const now = new Date();
    const rateLimit = this.otpRequestCount.get(phoneNumber);

    if (rateLimit) {
      if (now < rateLimit.resetAt) {
        if (rateLimit.count >= this.MAX_OTP_REQUESTS_PER_HOUR) {
          throw new BadRequestException(
            'Too many OTP requests. Please try again later.',
          );
        }
        rateLimit.count++;
      } else {
        // Reset the counter
        this.otpRequestCount.set(phoneNumber, {
          count: 1,
          resetAt: new Date(now.getTime() + 60 * 60 * 1000), // 1 hour
        });
      }
    } else {
      this.otpRequestCount.set(phoneNumber, {
        count: 1,
        resetAt: new Date(now.getTime() + 60 * 60 * 1000), // 1 hour
      });
    }
  }

  /**
   * Send OTP via SMS using ThinkX Cloud
   * @param phoneNumber - Phone number in E.164 format (+256XXXXXXXXX)
   */
  async sendOTP(phoneNumber: string): Promise<OtpSendResult> {
    // Check rate limiting
    this.checkRateLimit(phoneNumber);

    // Generate OTP
    const otp = this.generateOTP();
    const expiresAt = new Date(
      Date.now() + this.OTP_EXPIRY_MINUTES * 60 * 1000,
    );

    console.log(`[OTP] Initiating OTP delivery to ${phoneNumber}`);

    // Store OTP
    this.otpStore.set(phoneNumber, {
      code: otp,
      expiresAt: expiresAt,
      attempts: 0,
    });

    // Development/Mock mode check
    const isDevelopment =
      this.configService.get<string>('NODE_ENV') === 'development';
    const isSmsConfigured = this.thinkXCloudService.isConfigured();

    // Send via ThinkX Cloud
    if (isSmsConfigured) {
      console.log(`[OTP] Attempting SMS delivery to ${phoneNumber}...`);

      try {
        const smsResult = await this.thinkXCloudService.sendOTP(
          phoneNumber,
          otp,
          this.OTP_EXPIRY_MINUTES,
        );

        if (smsResult.success) {
          console.log(
            `[OTP] ✓ SMS delivery successful to ${phoneNumber}, messageRef: ${smsResult.messageReference}`,
          );

          return {
            success: true,
            channel: 'sms',
            message: 'Verification code sent via SMS',
          };
        }

        console.error(
          `[OTP] SMS delivery failed for ${phoneNumber}: ${smsResult.error}`,
        );

        // Fall back to mock mode in development
        if (isDevelopment) {
          console.log(
            `[OTP] [MOCK] Development mode - OTP sent to ${phoneNumber} (expires at ${expiresAt.toISOString()})`,
          );
          return {
            success: true,
            channel: 'mock',
            message: 'Verification code sent (development mode)',
          };
        }

        // Clean up stored OTP on failure
        this.otpStore.delete(phoneNumber);
        throw new BadRequestException(
          'Failed to send verification code. Please try again.',
        );
      } catch (error: any) {
        // If SMS fails and we're in development, use mock mode
        if (isDevelopment) {
          console.log(
            `[OTP] [MOCK] Development mode - OTP sent to ${phoneNumber} (expires at ${expiresAt.toISOString()})`,
          );
          return {
            success: true,
            channel: 'mock',
            message: 'Verification code sent (development mode)',
          };
        }

        // Clean up stored OTP on failure
        this.otpStore.delete(phoneNumber);

        throw new BadRequestException(
          error?.message || 'Failed to send verification code. Please try again.',
        );
      }
    }

    // SMS not configured - use mock mode in development
    if (isDevelopment) {
      console.log(
        `[OTP] [MOCK] Development mode - OTP ${otp} for ${phoneNumber} (expires at ${expiresAt.toISOString()})`,
      );
      return {
        success: true,
        channel: 'mock',
        message: 'Verification code sent (development mode)',
      };
    }

    // Production without configured SMS provider
    this.otpStore.delete(phoneNumber);
    throw new BadRequestException(
      'SMS service is not configured. Please contact support.',
    );
  }

  /**
   * Verify OTP code
   */
  verifyOTP(phoneNumber: string, code: string): { valid: boolean } {
    const storedOtp = this.otpStore.get(phoneNumber);
    const isDevelopment =
      this.configService.get<string>('NODE_ENV') === 'development';

    // Development/testing mode - always accept "123456" as valid code
    if (isDevelopment && code === '123456') {
      console.log(`[OTP] [DEV] Accepting test OTP code for ${phoneNumber}`);
      this.otpStore.delete(phoneNumber);
      return { valid: true };
    }

    if (!storedOtp) {
      console.log(`[OTP] No OTP found for ${phoneNumber}`);
      return { valid: false };
    }

    // Check if OTP has expired
    if (new Date() > storedOtp.expiresAt) {
      console.log(`[OTP] OTP expired for ${phoneNumber}`);
      this.otpStore.delete(phoneNumber);
      return { valid: false };
    }

    // Check max attempts
    if (storedOtp.attempts >= this.MAX_VERIFICATION_ATTEMPTS) {
      console.log(`[OTP] Max verification attempts exceeded for ${phoneNumber}`);
      this.otpStore.delete(phoneNumber);
      return { valid: false };
    }

    // Increment attempts
    storedOtp.attempts++;

    // Verify the code
    if (storedOtp.code === code) {
      console.log(`[OTP] ✓ OTP verified successfully for ${phoneNumber}`);
      this.otpStore.delete(phoneNumber);
      return { valid: true };
    }

    console.log(
      `[OTP] Invalid OTP for ${phoneNumber}. Attempt ${storedOtp.attempts}/${this.MAX_VERIFICATION_ATTEMPTS}`,
    );
    return { valid: false };
  }

  /**
   * Clean up expired OTPs and rate limits
   */
  cleanupExpiredOTPs(): void {
    const now = new Date();
    let otpsCleaned = 0;
    let rateLimitsCleaned = 0;

    // Clean up expired OTPs
    for (const [phoneNumber, otp] of this.otpStore.entries()) {
      if (now > otp.expiresAt) {
        this.otpStore.delete(phoneNumber);
        otpsCleaned++;
      }
    }

    // Clean up expired rate limits
    for (const [phoneNumber, rateLimit] of this.otpRequestCount.entries()) {
      if (now > rateLimit.resetAt) {
        this.otpRequestCount.delete(phoneNumber);
        rateLimitsCleaned++;
      }
    }

    if (otpsCleaned > 0 || rateLimitsCleaned > 0) {
      console.log(
        `[OTP] Cleanup: removed ${otpsCleaned} expired OTPs, ${rateLimitsCleaned} expired rate limits`,
      );
    }
  }
}
