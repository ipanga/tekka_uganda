import { Injectable, Logger } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import { Resend } from 'resend';

@Injectable()
export class EmailService {
  private resend: Resend | null = null;
  private readonly from: string;
  private readonly isDevelopment: boolean;
  private readonly logger = new Logger(EmailService.name);

  constructor(private configService: ConfigService) {
    const apiKey = this.configService.get<string>('RESEND_API_KEY');
    this.from =
      this.configService.get<string>('EMAIL_FROM') ||
      'Tekka <noreply@tekka.ug>';
    this.isDevelopment =
      this.configService.get<string>('NODE_ENV') === 'development';

    if (apiKey) {
      this.resend = new Resend(apiKey);
      this.logger.log(
        `Email service initialized with Resend (from: ${this.from})`,
      );
    } else {
      this.logger.warn(
        'RESEND_API_KEY not configured — emails will be logged but not sent',
      );
    }
  }

  /** Whether Resend is configured and can attempt to send */
  isConfigured(): boolean {
    return this.resend !== null;
  }

  /**
   * Send OTP code via email (fallback when SMS fails)
   */
  async sendOtp(email: string, code: string): Promise<boolean> {
    const subject = 'Your Tekka verification code';
    const html = `
      <div style="font-family: sans-serif; max-width: 480px; margin: 0 auto;">
        <h2 style="color: #111;">Your verification code</h2>
        <p style="font-size: 32px; font-weight: bold; letter-spacing: 8px; color: #111;">${code}</p>
        <p style="color: #666;">This code expires in 10 minutes. If you didn't request this, you can safely ignore this email.</p>
        <hr style="border: none; border-top: 1px solid #eee; margin: 24px 0;" />
        <p style="color: #999; font-size: 12px;">Tekka — Uganda's Fashion Marketplace</p>
      </div>
    `;

    return this.send(email, subject, html);
  }

  /**
   * Send email verification code
   */
  async sendEmailVerification(email: string, code: string): Promise<boolean> {
    const subject = 'Verify your email on Tekka';
    const html = `
      <div style="font-family: sans-serif; max-width: 480px; margin: 0 auto;">
        <h2 style="color: #111;">Verify your email</h2>
        <p>Enter this code in the app to verify your email address:</p>
        <p style="font-size: 32px; font-weight: bold; letter-spacing: 8px; color: #111;">${code}</p>
        <p style="color: #666;">This code expires in 10 minutes.</p>
        <hr style="border: none; border-top: 1px solid #eee; margin: 24px 0;" />
        <p style="color: #999; font-size: 12px;">Tekka — Uganda's Fashion Marketplace</p>
      </div>
    `;

    return this.send(email, subject, html);
  }

  async sendAccountDeletionScheduled(
    email: string,
    scheduledDate: Date,
  ): Promise<boolean> {
    const subject = 'Your Tekka account is scheduled for deletion';
    const formatted = scheduledDate.toUTCString();
    const html = `
      <div style="font-family: sans-serif; max-width: 480px; margin: 0 auto;">
        <h2 style="color: #111;">Account deletion scheduled</h2>
        <p>We received a request to delete your Tekka account.</p>
        <p>Your account is locked and will be permanently deleted on <strong>${formatted}</strong>.</p>
        <p>If you change your mind, sign back into the Tekka app or website before that date and cancel the deletion. After that, the deletion is final and cannot be reversed.</p>
        <p style="color: #666;">Didn't request this? Sign in immediately and cancel the deletion, then change your password / contact us at <a href="mailto:privacy@tekka.ug">privacy@tekka.ug</a>.</p>
        <hr style="border: none; border-top: 1px solid #eee; margin: 24px 0;" />
        <p style="color: #999; font-size: 12px;">Tekka — Uganda's Fashion Marketplace</p>
      </div>
    `;

    return this.send(email, subject, html);
  }

  async sendAccountDeletionCancelled(email: string): Promise<boolean> {
    const subject = 'Your Tekka account deletion was cancelled';
    const html = `
      <div style="font-family: sans-serif; max-width: 480px; margin: 0 auto;">
        <h2 style="color: #111;">Account deletion cancelled</h2>
        <p>The pending deletion of your Tekka account has been cancelled. Your account and data are intact and you can keep using Tekka as usual.</p>
        <p style="color: #666;">If you didn't cancel this yourself, please sign in and review your account security, then contact us at <a href="mailto:privacy@tekka.ug">privacy@tekka.ug</a>.</p>
        <hr style="border: none; border-top: 1px solid #eee; margin: 24px 0;" />
        <p style="color: #999; font-size: 12px;">Tekka — Uganda's Fashion Marketplace</p>
      </div>
    `;

    return this.send(email, subject, html);
  }

  async sendAccountDeletionCompleted(email: string): Promise<boolean> {
    const subject = 'Your Tekka account has been deleted';
    const html = `
      <div style="font-family: sans-serif; max-width: 480px; margin: 0 auto;">
        <h2 style="color: #111;">Account deleted</h2>
        <p>Your Tekka account and the personal data associated with it have been permanently deleted from our systems.</p>
        <p>This action cannot be undone. If you'd like to use Tekka again in the future, you're welcome to create a new account.</p>
        <p style="color: #666;">Didn't expect this email? Reach out at <a href="mailto:privacy@tekka.ug">privacy@tekka.ug</a> and we'll investigate.</p>
        <hr style="border: none; border-top: 1px solid #eee; margin: 24px 0;" />
        <p style="color: #999; font-size: 12px;">Tekka — Uganda's Fashion Marketplace</p>
      </div>
    `;

    return this.send(email, subject, html);
  }

  private async send(
    to: string,
    subject: string,
    html: string,
  ): Promise<boolean> {
    if (!this.resend) {
      this.logger.warn(`[NO-SEND] Would send "${subject}" to ${to}`);
      // In dev without API key, treat as success so flows don't block
      return this.isDevelopment;
    }

    try {
      const result = await this.resend.emails.send({
        from: this.from,
        to,
        subject,
        html,
      });
      this.logger.log(
        `Email sent to ${to}: "${subject}" (id: ${result.data?.id})`,
      );
      return true;
    } catch (error: any) {
      const errorMessage =
        error?.message || error?.statusCode || JSON.stringify(error);
      this.logger.error(`Failed to send email to ${to}: ${errorMessage}`);
      return false;
    }
  }
}
