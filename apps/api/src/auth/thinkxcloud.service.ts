import { Injectable, Logger } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';

interface ThinkXSendResult {
  success: boolean;
  messageReference?: string;
  error?: string;
}

interface ThinkXApiResponse {
  response: string;
  data?: {
    message_reference?: string;
    message_credit_balance?: string;
  };
  message?: string;
}

/**
 * ThinkX Cloud SMS Service
 * Handles sending OTP messages via SMS using ThinkX Cloud API
 * Documentation: https://sms.thinkxcloud.com/documentation
 */
@Injectable()
export class ThinkXCloudService {
  private readonly logger = new Logger(ThinkXCloudService.name);
  private readonly baseUrl = 'https://sms.thinkxcloud.com/api';
  private readonly apiKey: string;
  private _isConfigured: boolean = false;

  constructor(private configService: ConfigService) {
    this.apiKey = this.configService.get<string>('THINKXCLOUD_API_KEY') || '';

    // Check if credentials are configured
    if (!this.apiKey || this.apiKey === 'your_thinkxcloud_api_key') {
      this.logger.warn(
        'ThinkX Cloud credentials not configured. SMS OTP will be unavailable.',
      );
      return;
    }

    this._isConfigured = true;
    this.logger.log('ThinkX Cloud SMS service initialized successfully.');
  }

  /**
   * Check if the service is properly configured
   */
  isConfigured(): boolean {
    return this._isConfigured;
  }

  /**
   * Send OTP via SMS using ThinkX Cloud
   * @param phoneNumber - Phone number in E.164 format (e.g., +256776000000)
   * @param otp - The OTP code to send
   * @param expiryMinutes - OTP expiry time in minutes (for message content)
   */
  async sendOTP(
    phoneNumber: string,
    otp: string,
    expiryMinutes: number,
  ): Promise<ThinkXSendResult> {
    if (!this._isConfigured) {
      this.logger.debug(
        `[MOCK] SMS would be sent to ${phoneNumber} (ThinkX Cloud not configured)`,
      );
      return { success: false, error: 'ThinkX Cloud not configured' };
    }

    try {
      // Format phone number for ThinkX Cloud
      // API accepts: 776XXXXXX or +256776XXXXXX
      let formattedPhone = phoneNumber;
      if (formattedPhone.startsWith('+256')) {
        // Keep as is - API accepts +256 format
      } else if (formattedPhone.startsWith('256')) {
        formattedPhone = '+' + formattedPhone;
      } else if (formattedPhone.startsWith('0')) {
        formattedPhone = '+256' + formattedPhone.substring(1);
      }

      const message = `Your Tekka verification code is: ${otp}. This code expires in ${expiryMinutes} minutes. Do not share this code with anyone.`;

      const requestBody = {
        api_key: this.apiKey,
        number: formattedPhone,
        message: message,
      };

      this.logger.log(`Sending OTP to ${phoneNumber}...`);

      const response = await fetch(`${this.baseUrl}/send-message`, {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
        },
        body: JSON.stringify(requestBody),
      });

      const result: ThinkXApiResponse = await response.json();

      if (result.response === 'OK' && result.data?.message_reference) {
        this.logger.log(
          `OTP sent successfully to ${phoneNumber}`,
        );
        return {
          success: true,
          messageReference: result.data.message_reference,
        };
      }

      this.logger.error(`Delivery failed: ${result.message || 'Unknown error'}`);
      return {
        success: false,
        error: result.message || 'SMS delivery failed',
      };
    } catch (error: any) {
      this.logger.error('sendOTP error:', error?.message || error);
      return { success: false, error: error?.message || 'Request failed' };
    }
  }

  /**
   * Check message delivery status
   */
  async checkMessageStatus(
    messageReference: string,
  ): Promise<{ success: boolean; status?: string; error?: string }> {
    if (!this._isConfigured) {
      return { success: false, error: 'ThinkX Cloud not configured' };
    }

    try {
      const response = await fetch(`${this.baseUrl}/check-message-status`, {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
        },
        body: JSON.stringify({
          api_key: this.apiKey,
          message_reference: messageReference,
        }),
      });

      const result = await response.json();

      if (result.response === 'OK' && result.data?.status) {
        return { success: true, status: result.data.status };
      }

      return { success: false, error: result.message || 'Failed to get status' };
    } catch (error: any) {
      return { success: false, error: error?.message || 'Request failed' };
    }
  }

  /**
   * Check account credit balance
   */
  async getBalance(): Promise<{ success: boolean; balance?: string; error?: string }> {
    if (!this._isConfigured) {
      return { success: false, error: 'ThinkX Cloud not configured' };
    }

    try {
      const response = await fetch(`${this.baseUrl}/message-credit-balance`, {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
        },
        body: JSON.stringify({
          api_key: this.apiKey,
        }),
      });

      const result = await response.json();

      if (result.response === 'OK' && result.data?.message_credit_balance) {
        return { success: true, balance: result.data.message_credit_balance };
      }

      return { success: false, error: result.message || 'Failed to get balance' };
    } catch (error: any) {
      return { success: false, error: error?.message || 'Request failed' };
    }
  }
}
