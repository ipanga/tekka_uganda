'use client';

import { useState, useEffect, Suspense } from 'react';
import Link from 'next/link';
import { useRouter, useSearchParams } from 'next/navigation';
import { useAuth } from '@/hooks/useAuth';
import { api } from '@/lib/api';
import { City, Division } from '@/types';
import { Button } from '@/components/ui/Button';
import { Input } from '@/components/ui/Input';
import { Select } from '@/components/ui/Select';
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
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState<string | null>(null);

  // Location state (same pattern as product creation)
  const [cities, setCities] = useState<City[]>([]);
  const [citiesLoading, setCitiesLoading] = useState(false);
  const [selectedCity, setSelectedCity] = useState<City | null>(null);
  const [selectedDivision, setSelectedDivision] = useState<Division | null>(null);

  // Check if we should skip to profile step (coming from login)
  useEffect(() => {
    const stepParam = searchParams.get('step');
    if (stepParam === 'profile' && user && !user.isOnboardingComplete) {
      setStep('profile');
    }
  }, [searchParams, user]);

  // Load cities when entering profile step
  useEffect(() => {
    if (step === 'profile' && cities.length === 0) {
      const loadCities = async () => {
        setCitiesLoading(true);
        try {
          const citiesData = await api.getCitiesWithDivisions();
          setCities(citiesData);
        } catch (err) {
          console.error('Failed to load cities:', err);
        } finally {
          setCitiesLoading(false);
        }
      };
      loadCities();
    }
  }, [step, cities.length]);

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

  const handleSendOTP = async (e: React.FormEvent) => {
    e.preventDefault();
    setError(null);
    setLoading(true);

    try {
      const formattedPhone = normalizePhoneNumber(phoneNumber);

      // Validate final format: +256 followed by 9 digits (total 13 characters)
      if (!/^\+256[0-9]{9}$/.test(formattedPhone)) {
        throw new Error('Please enter a valid 9-digit Ugandan phone number');
      }

      const success = await sendOTP(formattedPhone);
      if (success) {
        setStep('otp');
      }
    } catch (err) {
      const message = err instanceof Error ? err.message : 'Failed to send verification code. Please try again.';
      setError(message);
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
      // Format location from selected city/division (same format as product creation)
      let locationString: string | undefined;
      if (selectedCity) {
        locationString = selectedCity.name;
        if (selectedDivision) {
          locationString += `, ${selectedDivision.name}`;
        }
      }

      await completeProfile({
        displayName: displayName.trim(),
        location: locationString,
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
                <div>
                  <label
                    htmlFor="phone"
                    className="block text-sm font-medium text-gray-700 mb-1"
                  >
                    Phone Number
                  </label>
                  <div className="flex">
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
                      className="flex-1 block w-full rounded-r-lg border border-gray-300 px-3 py-2 focus:border-pink-500 focus:outline-none focus:ring-1 focus:ring-pink-500"
                      placeholder="712 345 678"
                      autoComplete="tel-national"
                    />
                  </div>
                  <p className="mt-1.5 text-xs text-gray-500">
                    Enter your number with or without the leading 0
                  </p>
                </div>

                <Button type="submit" className="w-full" loading={loading} disabled={loading || phoneNumber.length < 9}>
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

                {/* Location Selection - Same pattern as product creation */}
                <div className="space-y-4">
                  <label className="block text-sm font-medium text-gray-700">
                    Location (optional)
                  </label>
                  <p className="text-xs text-gray-500 -mt-2">Helps buyers find items near them</p>

                  {citiesLoading ? (
                    <div className="flex items-center py-2">
                      <div className="w-4 h-4 border-2 border-pink-600 border-t-transparent rounded-full animate-spin" />
                      <span className="ml-2 text-sm text-gray-500">Loading locations...</span>
                    </div>
                  ) : (
                    <div className="grid grid-cols-2 gap-3">
                      <Select
                        options={cities.map((c) => ({ value: c.id, label: c.name }))}
                        value={selectedCity?.id || ''}
                        onChange={(e) => {
                          const city = cities.find((c) => c.id === e.target.value);
                          setSelectedCity(city || null);
                          setSelectedDivision(null);
                        }}
                        placeholder="Select city"
                      />

                      {selectedCity && selectedCity.divisions && selectedCity.divisions.length > 0 && (
                        <Select
                          options={selectedCity.divisions.map((d) => ({ value: d.id, label: d.name }))}
                          value={selectedDivision?.id || ''}
                          onChange={(e) => {
                            const division = selectedCity.divisions?.find((d) => d.id === e.target.value);
                            setSelectedDivision(division || null);
                          }}
                          placeholder="Select area"
                        />
                      )}
                    </div>
                  )}
                </div>

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
