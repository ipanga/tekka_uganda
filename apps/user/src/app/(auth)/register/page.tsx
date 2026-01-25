'use client';

import { useState, useEffect, Suspense } from 'react';
import Link from 'next/link';
import { useRouter, useSearchParams } from 'next/navigation';
import { useAuth } from '@/hooks/useAuth';
import { Button } from '@/components/ui/Button';
import { Input } from '@/components/ui/Input';
import Header from '@/components/layout/Header';
import Footer from '@/components/layout/Footer';
import { PageLoader } from '@/components/ui/Spinner';

type Step = 'phone' | 'otp' | 'profile';

function RegisterContent() {
  const router = useRouter();
  const searchParams = useSearchParams();
  const { sendOTP, verifyOTP, completeProfile, user, error: authError } = useAuth();

  const [step, setStep] = useState<Step>('phone');
  const [phoneNumber, setPhoneNumber] = useState('');
  const [otp, setOtp] = useState('');
  const [displayName, setDisplayName] = useState('');
  const [location, setLocation] = useState('');
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState<string | null>(null);

  // Check if we should skip to profile step (coming from login)
  useEffect(() => {
    const stepParam = searchParams.get('step');
    if (stepParam === 'profile' && user && !user.isOnboardingComplete) {
      setStep('profile');
    }
  }, [searchParams, user]);

  const handleSendOTP = async (e: React.FormEvent) => {
    e.preventDefault();
    setError(null);
    setLoading(true);

    try {
      // Format phone number for Uganda
      let formattedPhone = phoneNumber.trim();
      if (formattedPhone.startsWith('0')) {
        formattedPhone = '+256' + formattedPhone.slice(1);
      } else if (!formattedPhone.startsWith('+')) {
        formattedPhone = '+256' + formattedPhone;
      }

      const success = await sendOTP(formattedPhone);
      if (success) {
        setStep('otp');
      }
    } catch {
      setError('Failed to send verification code. Please try again.');
    } finally {
      setLoading(false);
    }
  };

  const handleVerifyOTP = async (e: React.FormEvent) => {
    e.preventDefault();
    setError(null);
    setLoading(true);

    try {
      await verifyOTP(otp);
      setStep('profile');
    } catch {
      setError('Invalid verification code. Please try again.');
    } finally {
      setLoading(false);
    }
  };

  const handleCompleteProfile = async (e: React.FormEvent) => {
    e.preventDefault();
    setError(null);
    setLoading(true);

    try {
      await completeProfile({
        displayName: displayName.trim(),
        location: location.trim() || undefined,
      });
      router.push('/');
    } catch {
      setError('Failed to save profile. Please try again.');
    } finally {
      setLoading(false);
    }
  };

  return (
    <div className="min-h-screen flex flex-col bg-gray-50">
      <Header />

      <main className="flex-1 flex items-center justify-center px-4 py-12">
        <div className="w-full max-w-md">
          <div className="bg-white rounded-2xl shadow-lg p-8">
            {/* Header */}
            <div className="text-center mb-8">
              <h1 className="text-2xl font-bold text-gray-900">
                {step === 'phone' && 'Create your account'}
                {step === 'otp' && 'Verify your phone'}
                {step === 'profile' && 'Complete your profile'}
              </h1>
              <p className="text-gray-500 mt-2">
                {step === 'phone' && 'Enter your phone number to get started'}
                {step === 'otp' && 'Enter the code sent to your phone'}
                {step === 'profile' && 'Tell us a bit about yourself'}
              </p>
            </div>

            {/* Progress Steps */}
            <div className="flex items-center justify-center gap-2 mb-8">
              {['phone', 'otp', 'profile'].map((s, index) => (
                <div key={s} className="flex items-center">
                  <div
                    className={`w-8 h-8 rounded-full flex items-center justify-center text-sm font-medium ${
                      step === s
                        ? 'bg-pink-600 text-white'
                        : index < ['phone', 'otp', 'profile'].indexOf(step)
                        ? 'bg-green-500 text-white'
                        : 'bg-gray-200 text-gray-500'
                    }`}
                  >
                    {index < ['phone', 'otp', 'profile'].indexOf(step) ? '✓' : index + 1}
                  </div>
                  {index < 2 && (
                    <div
                      className={`w-12 h-1 mx-1 ${
                        index < ['phone', 'otp', 'profile'].indexOf(step)
                          ? 'bg-green-500'
                          : 'bg-gray-200'
                      }`}
                    />
                  )}
                </div>
              ))}
            </div>

            {/* Dev Mode Notice */}
            {process.env.NODE_ENV === 'development' && step === 'otp' && (
              <div className="mb-4 rounded-lg bg-blue-50 p-3 text-sm text-blue-700">
                <strong>Dev Mode:</strong> Use code <code className="bg-blue-100 px-1 rounded">123456</code> to verify
              </div>
            )}

            {/* Error Message */}
            {(error || authError) && (
              <div className="mb-6 p-4 bg-red-50 border border-red-200 rounded-lg">
                <p className="text-sm text-red-600">{error || authError}</p>
              </div>
            )}

            {/* Phone Step */}
            {step === 'phone' && (
              <form onSubmit={handleSendOTP} className="space-y-6">
                <Input
                  label="Phone Number"
                  type="tel"
                  placeholder="0700 000 000"
                  value={phoneNumber}
                  onChange={(e) => setPhoneNumber(e.target.value)}
                  required
                  helperText="We'll send you a verification code"
                />

                <Button type="submit" className="w-full" loading={loading}>
                  Send Verification Code
                </Button>

                <p className="text-center text-sm text-gray-500">
                  Already have an account?{' '}
                  <Link href="/login" className="text-pink-600 hover:text-pink-700 font-medium">
                    Sign in
                  </Link>
                </p>
              </form>
            )}

            {/* OTP Step */}
            {step === 'otp' && (
              <form onSubmit={handleVerifyOTP} className="space-y-6">
                <Input
                  label="Verification Code"
                  type="text"
                  placeholder="000000"
                  value={otp}
                  onChange={(e) => setOtp(e.target.value.replace(/\D/g, '').slice(0, 6))}
                  maxLength={6}
                  required
                  className="text-center text-2xl tracking-widest"
                />

                <Button type="submit" className="w-full" loading={loading}>
                  Verify Code
                </Button>

                <button
                  type="button"
                  onClick={() => setStep('phone')}
                  className="w-full text-center text-sm text-gray-500 hover:text-gray-700"
                >
                  Use a different phone number
                </button>
              </form>
            )}

            {/* Profile Step */}
            {step === 'profile' && (
              <form onSubmit={handleCompleteProfile} className="space-y-6">
                <Input
                  label="Your Name"
                  type="text"
                  placeholder="Enter your name"
                  value={displayName}
                  onChange={(e) => setDisplayName(e.target.value)}
                  required
                  helperText="This is how other users will see you"
                />

                <Input
                  label="Location (optional)"
                  type="text"
                  placeholder="e.g., Kampala, Entebbe"
                  value={location}
                  onChange={(e) => setLocation(e.target.value)}
                  helperText="Helps buyers find items near them"
                />

                <Button type="submit" className="w-full" loading={loading}>
                  Complete Registration
                </Button>
              </form>
            )}
          </div>

          {/* Terms */}
          <p className="text-center text-xs text-gray-500 mt-6">
            By creating an account, you agree to our{' '}
            <Link href="/terms" className="text-pink-600 hover:underline">
              Terms of Service
            </Link>{' '}
            and{' '}
            <Link href="/privacy" className="text-pink-600 hover:underline">
              Privacy Policy
            </Link>
          </p>
        </div>
      </main>

      <Footer />
    </div>
  );
}

export default function RegisterPage() {
  return (
    <Suspense fallback={<PageLoader message="Loading..." />}>
      <RegisterContent />
    </Suspense>
  );
}
