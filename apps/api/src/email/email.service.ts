import { Injectable, Logger } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import { Resend } from 'resend';

@Injectable()
export class EmailService {
  private resend: Resend | null = null;
  private readonly from: string;
  private readonly logger = new Logger(EmailService.name);

  constructor(private configService: ConfigService) {
    const apiKey = this.configService.get<string>('RESEND_API_KEY');
    this.from =
      this.configService.get<string>('EMAIL_FROM') ||
      'Tekka <noreply@tekka.ug>';

    if (apiKey) {
      this.resend = new Resend(apiKey);
      this.logger.log('Email service initialized with Resend');
    } else {
      this.logger.warn(
        'RESEND_API_KEY not configured — emails will be logged but not sent',
      );
    }
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

  private async send(
    to: string,
    subject: string,
    html: string,
  ): Promise<boolean> {
    if (!this.resend) {
      this.logger.warn(`[NO-SEND] Would send "${subject}" to ${to}`);
      return true;
    }

    try {
      await this.resend.emails.send({ from: this.from, to, subject, html });
      this.logger.log(`Email sent to ${to}: "${subject}"`);
      return true;
    } catch (error) {
      this.logger.error(`Failed to send email to ${to}: ${error}`);
      return false;
    }
  }
}
