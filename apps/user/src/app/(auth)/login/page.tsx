'use client';

import { useState, FormEvent, useEffect } from 'react';
import { useRouter } from 'next/navigation';
import Link from 'next/link';
import { useAuth } from '@/hooks/useAuth';
import { authManager } from '@/lib/auth';
import { Button } from '@/components/ui/Button';
import { Logo } from '@/components/ui/Logo';

export default function LoginPage() {
  const [phoneNumber, setPhoneNumber] = useState('');
  const [otp, setOtp] = useState('');
  const [step, setStep] = useState<'phone' | 'otp'>('phone');
  const [error, setError] = useState('');
  const [loading, setLoading] = useState(false);
  const { sendOTP, sendOtpViaEmail, verifyOTP, user, loading: authLoading, hasEmail, emailHint } = useAuth();
  const router = useRouter();

  useEffect(() => {
    // Redirect if already authenticated
    if (!authLoading && user && authManager.isAuthenticated()) {
      router.push('/');
    }
  }, [user, authLoading, router]);

  /**
   * Normalize phone number to E.164 format for Uganda (+2567XXXXXXXX)
   * Handles:
   * - Input with leading 0 (0712345678 → +256712345678)
   * - Input without leading 0 (712345678 → +256712345678)
   * - Input with country code (256712345678 → +256712345678)
   * - Already normalized (+256712345678 → +256712345678)
   */
  const normalizePhoneNumber = (phone: string): string => {
    // Remove all non-digit characters except +
    let cleaned = phone.replace(/[^\d+]/g, '');

    // Handle already normalized number
    if (cleaned.startsWith('+256')) {
      return cleaned;
    }

    // Handle number with 256 prefix (no +)
    if (cleaned.startsWith('256') && cleaned.length >= 12) {
      return '+' + cleaned;
    }

    // Handle number with leading 0 (local format)
    if (cleaned.startsWith('0')) {
      return '+256' + cleaned.substring(1);
    }

    // Handle number without country code (assume Uganda)
    return '+256' + cleaned;
  };

  const handleSendOTP = async (e: FormEvent) => {
    e.preventDefault();
    setError('');
    setLoading(true);

    try {
      const formattedPhone = normalizePhoneNumber(phoneNumber);

      // Validate final format: +256 followed by 9 digits (total 13 characters)
      if (!/^\+256[0-9]{9}$/.test(formattedPhone)) {
        throw new Error('Please enter a valid 9-digit Ugandan phone number');
      }

      await sendOTP(formattedPhone);
      setStep('otp');
    } catch (err: unknown) {
      const message = err instanceof Error ? err.message : 'Failed to send OTP';
      setError(message);
    } finally {
      setLoading(false);
    }
  };

  const handleVerifyOTP = async (e: FormEvent) => {
    e.preventDefault();
    setError('');
    setLoading(true);

    try {
      const user = await verifyOTP(otp);
      // Check if user needs to complete profile
      if (!user.isOnboardingComplete) {
        router.push('/register?step=profile');
      } else {
        router.push('/');
      }
    } catch (err: unknown) {
      const message = err instanceof Error ? err.message : 'Invalid OTP';
      setError(message);
    } finally {
      setLoading(false);
    }
  };

  return (
    <div className="flex min-h-screen items-center justify-center bg-gray-50 px-4">
      <div className="w-full max-w-md">
        <div className="rounded-2xl bg-white p-8 shadow-lg">
          {/* Logo */}
          <div className="mb-8 text-center">
            <Link href="/" className="inline-block mx-auto">
              <Logo height={40} className="mx-auto" />
            </Link>
            <p className="mt-2 text-gray-600">Welcome back!</p>
          </div>

          {/* Dev Mode Notice */}
          {process.env.NODE_ENV === 'development' && (
            <div className="mb-4 rounded-lg bg-blue-50 p-3 text-sm text-blue-700">
              <strong>Dev Mode:</strong> Use code <code className="bg-blue-100 px-1 rounded">123456</code> to verify
            </div>
          )}

          {/* Error */}
          {error && (
            <div className="mb-4 rounded-lg bg-red-50 p-3 text-sm text-red-700">
              {error}
            </div>
          )}

          {step === 'phone' ? (
            <form onSubmit={handleSendOTP} className="space-y-6">
              <div>
                <label
                  htmlFor="phone"
                  className="block text-sm font-medium text-gray-700"
                >
                  Phone Number
                </label>
                <div className="mt-1 flex">
                  <span className="inline-flex items-center px-3 rounded-l-lg border border-r-0 border-gray-300 bg-gray-100 text-gray-600 text-sm font-medium select-none">
                    🇺🇬 +256
                  </span>
                  <input
                    id="phone"
                    type="tel"
                    inputMode="numeric"
                    value={phoneNumber}
                    onChange={(e) => setPhoneNumber(e.target.value.replace(/\D/g, '').slice(0, 10))}
                    required
                    maxLength={10}
                    className="flex-1 block w-full rounded-r-lg border border-gray-300 bg-white text-gray-900 px-3 py-2 focus:border-primary-500 focus:outline-none focus:ring-1 focus:ring-primary-500"
                    placeholder="712 345 678"
                    autoComplete="tel-national"
                  />
                </div>
                <p className="mt-1.5 text-xs text-gray-500">
                  Enter your number with or without the leading 0
                </p>
              </div>

              <Button
                type="submit"
                className="w-full"
                loading={loading}
                disabled={loading || phoneNumber.length < 9}
              >
                Send OTP
              </Button>
            </form>
          ) : (
            <form onSubmit={handleVerifyOTP} className="space-y-6">
              <div>
                <label
                  htmlFor="otp"
                  className="block text-sm font-medium text-gray-700"
                >
                  Enter OTP
                </label>
                <p className="text-sm text-gray-500 mt-1">
                  We sent a code to +256{phoneNumber}
                </p>
                <input
                  id="otp"
                  type="text"
                  value={otp}
                  onChange={(e) => setOtp(e.target.value.replace(/\D/g, ''))}
                  required
                  maxLength={6}
                  className="mt-2 block w-full rounded-lg border border-gray-300 bg-white text-gray-900 px-3 py-2 text-center text-2xl tracking-widest focus:border-primary-500 focus:outline-none focus:ring-1 focus:ring-primary-500"
                  placeholder="000000"
                />
              </div>

              <Button
                type="submit"
                className="w-full"
                loading={loading}
                disabled={loading || otp.length < 6}
              >
                Verify
              </Button>

              {hasEmail && (
                <button
                  type="button"
                  onClick={async () => {
                    try {
                      await sendOtpViaEmail();
                      setError('');
                      alert(emailHint ? `Code sent to ${emailHint}` : 'Code sent to your email');
                    } catch (err: unknown) {
                      const message = err instanceof Error ? err.message : 'Failed to send code via email';
                      setError(message);
                    }
                  }}
                  className="w-full text-center text-sm text-primary-500 hover:text-primary-600"
                >
                  {emailHint ? `Send code to ${emailHint}` : 'Send code via email instead'}
                </button>
              )}

              <button
                type="button"
                onClick={() => setStep('phone')}
                className="w-full text-center text-sm text-gray-500 hover:text-primary-500"
              >
                Change phone number
              </button>
            </form>
          )}

          {/* Footer */}
          <p className="mt-6 text-center text-sm text-gray-500">
            Don&apos;t have an account?{' '}
            <Link href="/register" className="text-primary-500 hover:text-primary-600 font-medium">
              Sign up
            </Link>
          </p>
        </div>
      </div>
    </div>
  );
}
