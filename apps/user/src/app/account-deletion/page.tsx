import type { Metadata } from 'next';
import Link from 'next/link';
import { Header } from '@/components/layout/Header';
import { Footer } from '@/components/layout/Footer';

export const metadata: Metadata = {
  title: 'Delete your account – Tekka',
  description:
    'Learn how to delete your Tekka account and what happens to your data. Step-by-step instructions for the mobile app and web, plus details on the 7-day grace period and contact for support.',
  alternates: { canonical: 'https://tekka.ug/account-deletion' },
};

export default function AccountDeletionPage() {
  return (
    <div className="min-h-screen flex flex-col">
      <Header />

      <main className="flex-1 bg-[var(--background)]">
        <div className="max-w-4xl mx-auto px-4 sm:px-6 lg:px-8 py-12">
          {/* Page Header */}
          <div className="mb-10">
            <h1 className="text-3xl font-bold text-gray-900">Delete your Tekka account</h1>
            <p className="mt-2 text-sm text-gray-500">Last updated: April 2026</p>
            <p className="mt-4 text-gray-600 leading-relaxed">
              You can delete your Tekka account at any time, directly from the mobile app or from the web.
              This page explains the steps, what data is removed, and how the 7-day grace period works.
            </p>
          </div>

          <div className="space-y-8">
            {/* 1. How to delete in the mobile app */}
            <section>
              <h2 className="text-xl font-semibold text-gray-900 mb-3">
                1. Delete your account in the Tekka mobile app
              </h2>
              <div className="text-gray-600 leading-relaxed">
                <ol className="list-decimal pl-5 space-y-2">
                  <li>Open the Tekka app and sign in.</li>
                  <li>Go to the <span className="font-medium">Profile</span> tab and tap the settings icon in the top-right.</li>
                  <li>Scroll to the <span className="font-medium">Danger Zone</span> section at the bottom.</li>
                  <li>Tap <span className="font-medium">Delete Account</span>.</li>
                  <li>Choose a reason (optional) and tick the two confirmation boxes.</li>
                  <li>
                    Choose how to proceed:
                    <ul className="list-disc pl-5 mt-2 space-y-1">
                      <li>
                        <span className="font-medium">Schedule (7 days)</span> — your account is locked for 7 days, then permanently deleted.
                        You can cancel during this window by signing in again.
                      </li>
                      <li>
                        <span className="font-medium">Delete Now</span> — your account and data are removed immediately. This cannot be undone.
                      </li>
                    </ul>
                  </li>
                </ol>
              </div>
            </section>

            {/* 2. How to delete on the web */}
            <section>
              <h2 className="text-xl font-semibold text-gray-900 mb-3">
                2. Delete your account on the web
              </h2>
              <div className="text-gray-600 leading-relaxed space-y-3">
                <ol className="list-decimal pl-5 space-y-2">
                  <li>Sign in at <a href="https://tekka.ug" className="text-primary-500 hover:text-primary-600">tekka.ug</a>.</li>
                  <li>
                    Open <Link href="/settings" className="text-primary-500 hover:text-primary-600">Settings</Link>.
                  </li>
                  <li>Scroll to the <span className="font-medium">Account</span> section.</li>
                  <li>Click <span className="font-medium">Delete Account</span> and confirm in the dialog.</li>
                </ol>
                <p>
                  Don&apos;t have access to the app or web settings? Email{' '}
                  <a href="mailto:privacy@tekka.ug" className="text-primary-500 hover:text-primary-600">privacy@tekka.ug</a>
                  {' '}from the address linked to your account and we&apos;ll process the deletion for you.
                </p>
              </div>
            </section>

            {/* 3. What gets deleted */}
            <section>
              <h2 className="text-xl font-semibold text-gray-900 mb-3">
                3. What gets deleted
              </h2>
              <div className="text-gray-600 leading-relaxed space-y-3">
                <p>When your account is deleted, the following are permanently removed from our database:</p>
                <ul className="list-disc pl-5 space-y-1">
                  <li>Your profile (name, photo, phone number, email, location)</li>
                  <li>All your active and draft listings, including their photos</li>
                  <li>Messages you&apos;ve sent and received, and the conversations they belong to</li>
                  <li>Offers you&apos;ve made or received</li>
                  <li>Reviews you&apos;ve written</li>
                  <li>Notifications addressed to you</li>
                  <li>Push-notification tokens (your device stops receiving Tekka pushes)</li>
                  <li>Saved items and saved searches</li>
                  <li>Price alerts you&apos;ve set up</li>
                  <li>Quick-reply templates</li>
                  <li>Meetups you&apos;ve proposed</li>
                  <li>User blocks you&apos;ve created or that target you</li>
                  <li>Reports you&apos;ve filed and reports filed against you</li>
                </ul>
              </div>
            </section>

            {/* 4. What's retained, and for how long */}
            <section>
              <h2 className="text-xl font-semibold text-gray-900 mb-3">
                4. What is retained, and for how long
              </h2>
              <div className="text-gray-600 leading-relaxed space-y-3">
                <p>
                  Once the deletion is final, no personal data tied to your account remains in our systems.
                </p>
                <p>
                  Where required by law (for example, financial or anti-fraud records), we may retain a minimal
                  set of records solely to comply with that obligation. These records are not used for any other purpose.
                  Anonymized analytics that cannot be linked back to you may also be retained, as described in our{' '}
                  <Link href="/privacy" className="text-primary-500 hover:text-primary-600">Privacy Policy</Link>.
                </p>
              </div>
            </section>

            {/* 5. Grace period */}
            <section>
              <h2 className="text-xl font-semibold text-gray-900 mb-3">
                5. Grace period (7 days)
              </h2>
              <div className="text-gray-600 leading-relaxed space-y-3">
                <p>
                  When you choose <span className="font-medium">Schedule</span>, your account is locked immediately
                  but the data is not yet deleted. You have <span className="font-medium">7 days</span> to change your mind.
                </p>
                <p>To cancel a scheduled deletion:</p>
                <ol className="list-decimal pl-5 space-y-1">
                  <li>Sign back in within the 7-day window.</li>
                  <li>You&apos;ll be prompted to either continue with deletion or cancel it.</li>
                  <li>If you cancel, your account is fully restored.</li>
                </ol>
                <p>
                  After the 7-day window expires, the deletion is finalized automatically and cannot be reversed.
                </p>
              </div>
            </section>

            {/* 6. Contact support */}
            <section>
              <h2 className="text-xl font-semibold text-gray-900 mb-3">
                6. Need help?
              </h2>
              <div className="text-gray-600 leading-relaxed space-y-3">
                <p>
                  If you can&apos;t complete the deletion yourself, or you have questions about how your data is handled,
                  contact us:
                </p>
                <ul className="list-disc pl-5 space-y-1">
                  <li>
                    Email:{' '}
                    <a href="mailto:privacy@tekka.ug" className="text-primary-500 hover:text-primary-600">
                      privacy@tekka.ug
                    </a>
                  </li>
                  <li>
                    <Link href="/contact" className="text-primary-500 hover:text-primary-600">Contact form</Link>
                  </li>
                </ul>
                <p>We respond to deletion requests within 30 days, and usually much sooner.</p>
              </div>
            </section>

            {/* Footer note */}
            <div className="bg-primary-50 border border-primary-200 rounded-lg p-4">
              <p className="text-sm text-gray-700">
                Deleting your account is permanent. If you only want to take a break, sign out from
                Settings instead — your listings and messages will be preserved until you return.
              </p>
            </div>
          </div>
        </div>
      </main>

      <Footer />
    </div>
  );
}
