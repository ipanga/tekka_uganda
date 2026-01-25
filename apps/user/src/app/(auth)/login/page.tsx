'use client';

import { useState, FormEvent, useEffect } from 'react';
import { useRouter } from 'next/navigation';
import Link from 'next/link';
import { useAuth } from '@/hooks/useAuth';
import { authManager } from '@/lib/auth';
import { Button } from '@/components/ui/Button';

export default function LoginPage() {
  const [phoneNumber, setPhoneNumber] = useState('');
  const [otp, setOtp] = useState('');
  const [step, setStep] = useState<'phone' | 'otp'>('phone');
  const [error, setError] = useState('');
  const [loading, setLoading] = useState(false);
  const { sendOTP, verifyOTP, user, loading: authLoading } = useAuth();
  const router = useRouter();

  useEffect(() => {
    // Redirect if already authenticated
    if (!authLoading && user && authManager.isAuthenticated()) {
      router.push('/');
    }
  }, [user, authLoading, router]);

  const handleSendOTP = async (e: FormEvent) => {
    e.preventDefault();
    setError('');
    setLoading(true);

    try {
      // Format phone number for Uganda
      let formattedPhone = phoneNumber;
      if (phoneNumber.startsWith('0')) {
        formattedPhone = '+256' + phoneNumber.substring(1);
      } else if (!phoneNumber.startsWith('+')) {
        formattedPhone = '+256' + phoneNumber;
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
            <Link href="/" className="text-3xl font-bold text-pink-600">
              Tekka
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
                  <span className="inline-flex items-center px-3 rounded-l-lg border border-r-0 border-gray-300 bg-gray-50 text-gray-500 text-sm">
                    +256
                  </span>
                  <input
                    id="phone"
                    type="tel"
                    value={phoneNumber}
                    onChange={(e) => setPhoneNumber(e.target.value.replace(/\D/g, ''))}
                    required
                    maxLength={10}
                    className="flex-1 block w-full rounded-r-lg border border-gray-300 px-3 py-2 focus:border-pink-500 focus:outline-none focus:ring-1 focus:ring-pink-500"
                    placeholder="7XXXXXXXX"
                  />
                </div>
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
                  className="mt-2 block w-full rounded-lg border border-gray-300 px-3 py-2 text-center text-2xl tracking-widest focus:border-pink-500 focus:outline-none focus:ring-1 focus:ring-pink-500"
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

              <button
                type="button"
                onClick={() => setStep('phone')}
                className="w-full text-center text-sm text-gray-500 hover:text-pink-600"
              >
                Change phone number
              </button>
            </form>
          )}

          {/* Footer */}
          <p className="mt-6 text-center text-sm text-gray-500">
            Don&apos;t have an account?{' '}
            <Link href="/register" className="text-pink-600 hover:text-pink-700 font-medium">
              Sign up
            </Link>
          </p>
        </div>
      </div>
    </div>
  );
}
