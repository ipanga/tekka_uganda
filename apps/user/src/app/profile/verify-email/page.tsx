'use client';

import { useState } from 'react';
import { useRouter } from 'next/navigation';
import { api } from '@/lib/api';
import { Button } from '@/components/ui/Button';
import { Input } from '@/components/ui/Input';
import Header from '@/components/layout/Header';
import Footer from '@/components/layout/Footer';

type Step = 'email' | 'code';

export default function VerifyEmailPage() {
  const router = useRouter();
  const [step, setStep] = useState<Step>('email');
  const [email, setEmail] = useState('');
  const [code, setCode] = useState('');
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState<string | null>(null);

  const handleSendCode = async (e: React.FormEvent) => {
    e.preventDefault();
    setError(null);
    setLoading(true);

    try {
      await api.sendEmailVerification(email.trim());
      setStep('code');
    } catch (err) {
      const message = err instanceof Error ? err.message : 'Failed to send verification code';
      setError(message);
    } finally {
      setLoading(false);
    }
  };

  const handleVerifyCode = async (e: React.FormEvent) => {
    e.preventDefault();
    setError(null);
    setLoading(true);

    try {
      await api.verifyEmailCode(code);
      router.push('/profile/edit?verified=1');
    } catch (err) {
      const message = err instanceof Error ? err.message : 'Invalid verification code';
      setError(message);
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
            <div className="text-center mb-8">
              <h1 className="text-2xl font-bold text-gray-900">
                {step === 'email' ? 'Verify your email' : 'Enter verification code'}
              </h1>
              <p className="text-gray-500 mt-2">
                {step === 'email'
                  ? 'We\'ll send a 6-digit code to verify your email'
                  : `Enter the code sent to ${email}`}
              </p>
            </div>

            {error && (
              <div className="mb-6 p-4 bg-red-50 border border-red-200 rounded-lg">
                <p className="text-sm text-red-600">{error}</p>
              </div>
            )}

            {step === 'email' ? (
              <form onSubmit={handleSendCode} className="space-y-6">
                <Input
                  label="Email address"
                  type="email"
                  placeholder="you@example.com"
                  value={email}
                  onChange={(e) => setEmail(e.target.value)}
                  required
                />

                <Button type="submit" className="w-full" loading={loading}>
                  Send Verification Code
                </Button>
              </form>
            ) : (
              <form onSubmit={handleVerifyCode} className="space-y-6">
                <Input
                  label="Verification Code"
                  type="text"
                  placeholder="000000"
                  value={code}
                  onChange={(e) => setCode(e.target.value.replace(/\D/g, '').slice(0, 6))}
                  maxLength={6}
                  required
                  className="text-center text-2xl tracking-widest"
                />

                <Button type="submit" className="w-full" loading={loading}>
                  Verify Email
                </Button>

                <button
                  type="button"
                  onClick={() => {
                    setStep('email');
                    setCode('');
                    setError(null);
                  }}
                  className="w-full text-center text-sm text-gray-500 hover:text-gray-700"
                >
                  Use a different email
                </button>
              </form>
            )}
          </div>
        </div>
      </main>

      <Footer />
    </div>
  );
}
