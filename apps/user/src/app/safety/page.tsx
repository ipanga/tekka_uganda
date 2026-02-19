import type { Metadata } from 'next';
import Link from 'next/link';
import { Header } from '@/components/layout/Header';
import { Footer } from '@/components/layout/Footer';

export const metadata: Metadata = {
  title: 'Safety Tips | Tekka.ug',
  description:
    'Stay safe while buying and selling on Tekka. Learn about safe meetup practices, payment safety, and how to avoid scams.',
};

const safetySections = [
  {
    icon: '📍',
    title: 'Meeting Safely',
    tips: [
      {
        title: 'Meet in public places',
        description:
          'Always meet in busy, well-lit public areas like shopping malls, cafes, or bank lobbies. Avoid meeting at private residences.',
      },
      {
        title: 'Use safe locations',
        description:
          'We recommend verified safe meetup spots in Kampala and Entebbe such as major shopping centres and busy commercial areas.',
      },
      {
        title: 'Meet during daylight',
        description:
          'Schedule meetups during daytime hours when possible. If meeting in the evening, choose well-lit locations.',
      },
      {
        title: 'Tell someone',
        description:
          'Let a friend or family member know where you\'re going and who you\'re meeting.',
      },
    ],
  },
  {
    icon: '💳',
    title: 'Payment Safety',
    tips: [
      {
        title: 'Inspect before paying',
        description:
          'Always examine items thoroughly before completing payment. Test electronics, check for defects, and verify authenticity.',
      },
      {
        title: 'Use mobile money',
        description:
          'Mobile money provides a digital record of your transaction. Avoid carrying large amounts of cash.',
      },
      {
        title: 'Never pay in advance',
        description:
          'Don\'t send money before meeting and seeing the item. Legitimate sellers will agree to payment upon delivery.',
      },
      {
        title: 'Get a receipt',
        description:
          'For expensive items, ask for a written receipt with seller details and item description.',
      },
    ],
  },
  {
    icon: '🔍',
    title: 'Avoiding Scams',
    tips: [
      {
        title: 'Watch for red flags',
        description:
          'Be cautious of prices that seem too good to be true, pressure to act quickly, or requests for unusual payment methods.',
      },
      {
        title: 'Verify seller profiles',
        description:
          'Check seller reviews, rating, and account age. New accounts with no history may be riskier.',
      },
      {
        title: 'Keep communication on Tekka',
        description:
          'Scammers often try to move conversations to WhatsApp or email. Stay on the app for your protection.',
      },
      {
        title: 'Trust your instincts',
        description:
          'If something feels wrong, walk away. There will always be other items and other sellers.',
      },
    ],
  },
  {
    icon: '🏪',
    title: 'Selling Safely',
    tips: [
      {
        title: 'Don\'t share personal info',
        description:
          'Avoid sharing your home address, work location, or personal phone number until necessary.',
      },
      {
        title: 'Confirm payment first',
        description:
          'For mobile money payments, wait for confirmation before handing over items. Check your balance.',
      },
      {
        title: 'Be accurate in listings',
        description:
          'Describe items honestly and include photos of any defects. This prevents disputes and builds trust.',
      },
      {
        title: 'Handle cash carefully',
        description:
          'If accepting cash, count it before the buyer leaves. Consider using a bank lobby for large transactions.',
      },
    ],
  },
];

export default function SafetyPage() {
  return (
    <div className="min-h-screen flex flex-col">
      <Header />

      <main className="flex-1 bg-[var(--background)]">
        <div className="max-w-4xl mx-auto px-4 sm:px-6 lg:px-8 py-12">
          {/* Page Header */}
          <div className="mb-10">
            <h1 className="text-3xl font-bold text-gray-900">Safety Tips</h1>
            <p className="mt-2 text-gray-600">
              Follow these guidelines for safe buying and selling on Tekka.
            </p>
          </div>

          {/* Hero Banner */}
          <div className="bg-green-50 border border-green-200 rounded-xl p-6 mb-8 flex items-start gap-4">
            <div className="bg-green-500 text-white rounded-lg p-3 text-2xl flex-shrink-0">🛡️</div>
            <div>
              <h2 className="text-lg font-semibold text-green-900">Stay Safe on Tekka</h2>
              <p className="text-green-800 text-sm mt-1">
                Your safety is our priority. These tips will help you have a positive and secure experience whether
                you&apos;re buying or selling.
              </p>
            </div>
          </div>

          {/* Safety Sections */}
          <div className="space-y-6">
            {safetySections.map((section) => (
              <div key={section.title} className="bg-white rounded-xl border border-gray-200 overflow-hidden">
                <div className="flex items-center gap-3 px-6 py-4 border-b border-gray-100">
                  <span className="text-2xl">{section.icon}</span>
                  <h2 className="text-lg font-semibold text-gray-900">{section.title}</h2>
                </div>
                <div className="divide-y divide-gray-100">
                  {section.tips.map((tip, index) => (
                    <div key={tip.title} className="px-6 py-4 flex gap-4">
                      <div className="flex-shrink-0 w-7 h-7 rounded-full bg-primary-50 text-primary-600 flex items-center justify-center text-sm font-semibold">
                        {index + 1}
                      </div>
                      <div>
                        <h3 className="font-medium text-gray-900">{tip.title}</h3>
                        <p className="text-sm text-gray-600 mt-1">{tip.description}</p>
                      </div>
                    </div>
                  ))}
                </div>
              </div>
            ))}
          </div>

          {/* Report Section */}
          <div className="mt-8 bg-white rounded-xl border border-gray-200 p-6">
            <div className="flex items-center gap-3 mb-3">
              <span className="text-red-500 text-xl">🚩</span>
              <h2 className="text-lg font-semibold text-gray-900">Report Suspicious Activity</h2>
            </div>
            <p className="text-gray-600 text-sm mb-3">
              If you encounter a scam, fraud, or suspicious behavior, report the user immediately. Our team
              reviews all reports and takes action to keep the community safe.
            </p>
            <p className="text-gray-500 text-sm italic">
              To report a user, visit their profile and select &quot;Report User&quot;, or contact us at{' '}
              <a href="mailto:contact@tekka.ug" className="text-primary-500 hover:text-primary-600 not-italic">
                contact@tekka.ug
              </a>
            </p>
          </div>

          {/* Related Links */}
          <div className="mt-8 flex flex-wrap gap-3">
            <Link
              href="/help"
              className="text-sm text-primary-500 hover:text-primary-600 border border-primary-200 rounded-full px-4 py-2"
            >
              Help Center
            </Link>
            <Link
              href="/terms"
              className="text-sm text-primary-500 hover:text-primary-600 border border-primary-200 rounded-full px-4 py-2"
            >
              Terms of Service
            </Link>
            <Link
              href="/contact"
              className="text-sm text-primary-500 hover:text-primary-600 border border-primary-200 rounded-full px-4 py-2"
            >
              Contact Us
            </Link>
          </div>
        </div>
      </main>

      <Footer />
    </div>
  );
}
