import { api } from './api';

export interface AuthUser {
  id: string;
  phoneNumber: string;
  email: string | null;
  displayName: string | null;
  photoUrl: string | null;
  bio: string | null;
  location: string | null;
  isOnboardingComplete: boolean;
  isPhoneVerified: boolean;
  isVerified: boolean;
  role: string;
}

export interface AuthTokens {
  accessToken: string;
  refreshToken: string;
  user: AuthUser;
}

const TOKEN_KEY = 'tekka_access_token';
const REFRESH_TOKEN_KEY = 'tekka_refresh_token';
const USER_KEY = 'tekka_user';

class AuthManager {
  private accessToken: string | null = null;
  private refreshToken: string | null = null;
  private user: AuthUser | null = null;
  private initialized: boolean = false;

  constructor() {
    // Try to initialize on construction (client-side only)
    this.ensureInitialized();

    // Wire up silent 401 refresh in the API client
    api.setTokenRefreshHandler(async () => {
      const result = await this.refreshTokens();
      return result?.accessToken ?? null;
    });
  }

  /**
   * Ensure tokens are loaded from localStorage (handles SSR/hydration)
   */
  ensureInitialized(): void {
    if (this.initialized) return;

    if (typeof window !== 'undefined') {
      this.accessToken = localStorage.getItem(TOKEN_KEY);
      this.refreshToken = localStorage.getItem(REFRESH_TOKEN_KEY);
      const userStr = localStorage.getItem(USER_KEY);
      this.user = userStr ? JSON.parse(userStr) : null;

      // Set token on API client
      if (this.accessToken) {
        api.setToken(this.accessToken);
      }
      this.initialized = true;
    }
  }

  // Email fallback info from last sendOTP response
  private _hasEmail: boolean = false;
  private _emailHint: string | null = null;

  get hasEmail(): boolean { return this._hasEmail; }
  get emailHint(): string | null { return this._emailHint; }

  /**
   * Send OTP to phone number
   */
  async sendOTP(phone: string): Promise<{ success: boolean; message: string; hasEmail: boolean; emailHint: string | null }> {
    const response = await fetch(
      `${process.env.NEXT_PUBLIC_API_URL || 'http://localhost:4000/api/v1'}/auth/send-otp`,
      {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ phone }),
      }
    );

    if (!response.ok) {
      const error = await response.json().catch(() => ({}));
      throw new Error(error.message || 'Failed to send OTP');
    }

    const data = await response.json();
    this._hasEmail = data.hasEmail === true;
    this._emailHint = data.emailHint ?? null;
    return data;
  }

  /**
   * Re-send OTP via email (fallback when SMS is unreliable)
   */
  async sendOtpViaEmail(phone: string): Promise<{ success: boolean; message: string }> {
    const response = await fetch(
      `${process.env.NEXT_PUBLIC_API_URL || 'http://localhost:4000/api/v1'}/auth/send-otp-email`,
      {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ phone }),
      }
    );

    if (!response.ok) {
      const error = await response.json().catch(() => ({}));
      throw new Error(error.message || 'Failed to send OTP via email');
    }

    return response.json();
  }

  /**
   * Verify OTP and authenticate
   */
  async verifyOTP(phone: string, code: string): Promise<AuthTokens> {
    const response = await fetch(
      `${process.env.NEXT_PUBLIC_API_URL || 'http://localhost:4000/api/v1'}/auth/verify-otp`,
      {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ phone, code }),
      }
    );

    if (!response.ok) {
      const error = await response.json().catch(() => ({}));
      throw new Error(error.message || 'Invalid OTP');
    }

    const data: AuthTokens = await response.json();
    this.setTokens(data);
    return data;
  }

  /**
   * Complete user profile after registration
   */
  async completeProfile(data: {
    displayName: string;
    location?: string;
    bio?: string;
    email?: string;
  }): Promise<AuthUser> {
    const response = await fetch(
      `${process.env.NEXT_PUBLIC_API_URL || 'http://localhost:4000/api/v1'}/auth/complete-profile`,
      {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
          Authorization: `Bearer ${this.accessToken}`,
        },
        body: JSON.stringify(data),
      }
    );

    if (!response.ok) {
      const error = await response.json().catch(() => ({}));
      throw new Error(error.message || 'Failed to complete profile');
    }

    const user: AuthUser = await response.json();
    this.user = user;
    localStorage.setItem(USER_KEY, JSON.stringify(user));
    return user;
  }

  /**
   * Refresh access token
   */
  async refreshTokens(): Promise<AuthTokens | null> {
    if (!this.refreshToken) {
      return null;
    }

    try {
      const response = await fetch(
        `${process.env.NEXT_PUBLIC_API_URL || 'http://localhost:4000/api/v1'}/auth/refresh`,
        {
          method: 'POST',
          headers: { 'Content-Type': 'application/json' },
          body: JSON.stringify({ refreshToken: this.refreshToken }),
        }
      );

      if (!response.ok) {
        // Only clear tokens on definitive auth rejection (401/403)
        // Network errors or 5xx should NOT wipe the session
        if (response.status === 401 || response.status === 403) {
          this.clearTokens();
        }
        return null;
      }

      const data: AuthTokens = await response.json();
      this.setTokens(data);
      return data;
    } catch {
      // Network error (offline, DNS, etc.) — keep tokens, don't logout
      return null;
    }
  }

  /**
   * Sign out
   */
  signOut(): void {
    this.clearTokens();
  }

  /**
   * Get current user
   */
  getUser(): AuthUser | null {
    this.ensureInitialized();
    return this.user;
  }

  /**
   * Check if user is authenticated
   */
  isAuthenticated(): boolean {
    this.ensureInitialized();
    return !!this.accessToken && !!this.user;
  }

  /**
   * Get access token
   */
  getAccessToken(): string | null {
    this.ensureInitialized();
    return this.accessToken;
  }

  private setTokens(data: AuthTokens): void {
    this.accessToken = data.accessToken;
    this.refreshToken = data.refreshToken;
    this.user = data.user;

    localStorage.setItem(TOKEN_KEY, data.accessToken);
    localStorage.setItem(REFRESH_TOKEN_KEY, data.refreshToken);
    localStorage.setItem(USER_KEY, JSON.stringify(data.user));

    api.setToken(data.accessToken);
  }

  private clearTokens(): void {
    this.accessToken = null;
    this.refreshToken = null;
    this.user = null;

    localStorage.removeItem(TOKEN_KEY);
    localStorage.removeItem(REFRESH_TOKEN_KEY);
    localStorage.removeItem(USER_KEY);

    api.clearToken();
  }
}

export const authManager = new AuthManager();
