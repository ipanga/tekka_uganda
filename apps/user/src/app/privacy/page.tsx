import type { Metadata } from 'next';
import { Header } from '@/components/layout/Header';
import { Footer } from '@/components/layout/Footer';

export const metadata: Metadata = {
  title: 'Privacy Policy | Tekka.ug',
  description:
    'Learn how Tekka collects, uses, and protects your personal data. Read our Privacy Policy for details on data handling and your rights.',
};

export default function PrivacyPage() {
  return (
    <div className="min-h-screen flex flex-col">
      <Header />

      <main className="flex-1 bg-[var(--background)]">
        <div className="max-w-4xl mx-auto px-4 sm:px-6 lg:px-8 py-12">
          {/* Page Header */}
          <div className="mb-10">
            <h1 className="text-3xl font-bold text-gray-900">Privacy Policy</h1>
            <p className="mt-2 text-sm text-gray-500">Last updated: February 2026</p>
          </div>

          <div className="space-y-8">
            {/* 1. Introduction */}
            <section>
              <h2 className="text-xl font-semibold text-gray-900 mb-3">1. Introduction</h2>
              <div className="text-gray-600 leading-relaxed space-y-3">
                <p>
                  Tekka (&quot;we,&quot; &quot;our,&quot; or &quot;us&quot;) respects your privacy and is committed
                  to protecting your personal data. This Privacy Policy explains how we collect, use, store, and
                  protect your information when you use the Tekka website, mobile application, and related services.
                </p>
                <p>By using Tekka, you consent to the data practices described in this policy.</p>
              </div>
            </section>

            {/* 2. Information We Collect */}
            <section>
              <h2 className="text-xl font-semibold text-gray-900 mb-3">2. Information We Collect</h2>
              <div className="text-gray-600 leading-relaxed space-y-4">
                <div>
                  <p className="font-medium text-gray-700 mb-2">Account Information:</p>
                  <ul className="list-disc pl-5 space-y-1">
                    <li>Phone number (required for OTP verification)</li>
                    <li>Display name and profile photo</li>
                    <li>Email address (optional)</li>
                    <li>Location (city/area)</li>
                  </ul>
                </div>
                <div>
                  <p className="font-medium text-gray-700 mb-2">Listing Information:</p>
                  <ul className="list-disc pl-5 space-y-1">
                    <li>Product photos and descriptions</li>
                    <li>Pricing information</li>
                    <li>Category and condition details</li>
                  </ul>
                </div>
                <div>
                  <p className="font-medium text-gray-700 mb-2">Usage Information:</p>
                  <ul className="list-disc pl-5 space-y-1">
                    <li>Device information and identifiers</li>
                    <li>App and website usage patterns</li>
                    <li>Search history within the platform</li>
                    <li>Communication logs between users</li>
                  </ul>
                </div>
                <div>
                  <p className="font-medium text-gray-700 mb-2">Cookies and Local Storage:</p>
                  <ul className="list-disc pl-5 space-y-1">
                    <li>Authentication tokens (JWT) stored in local storage for session management</li>
                    <li>User preferences and settings</li>
                    <li>See our <a href="/cookies" className="text-primary-500 hover:text-primary-600">Cookie Policy</a> for full details</li>
                  </ul>
                </div>
              </div>
            </section>

            {/* 3. How We Use Your Information */}
            <section>
              <h2 className="text-xl font-semibold text-gray-900 mb-3">3. How We Use Your Information</h2>
              <div className="text-gray-600 leading-relaxed">
                <p className="mb-3">We use your information to:</p>
                <ul className="list-disc pl-5 space-y-1">
                  <li>Create and manage your account</li>
                  <li>Verify your identity via phone number OTP</li>
                  <li>Enable buying and selling features</li>
                  <li>Facilitate communication between users</li>
                  <li>Improve our services and user experience</li>
                  <li>Send important notifications and updates</li>
                  <li>Detect and prevent fraud or abuse</li>
                  <li>Comply with legal obligations</li>
                  <li>Resolve disputes and enforce our policies</li>
                </ul>
              </div>
            </section>

            {/* 4. Information Sharing */}
            <section>
              <h2 className="text-xl font-semibold text-gray-900 mb-3">4. Information Sharing</h2>
              <div className="text-gray-600 leading-relaxed space-y-4">
                <div>
                  <p className="font-medium text-gray-700 mb-2">Other Users:</p>
                  <ul className="list-disc pl-5 space-y-1">
                    <li>Your public profile (name, photo, location, listings)</li>
                    <li>Verification status badges</li>
                    <li>Reviews and ratings</li>
                  </ul>
                </div>
                <div>
                  <p className="font-medium text-gray-700 mb-2">Service Providers:</p>
                  <ul className="list-disc pl-5 space-y-1">
                    <li>Cloud hosting and storage providers</li>
                    <li>Image hosting via Cloudinary (listing photos and profile images)</li>
                    <li>SMS delivery services for OTP verification</li>
                    <li>Analytics and monitoring services</li>
                    <li>Push notification services (Firebase)</li>
                  </ul>
                </div>
                <div>
                  <p className="font-medium text-gray-700 mb-2">Legal Requirements:</p>
                  <ul className="list-disc pl-5 space-y-1">
                    <li>When required by law or legal process</li>
                    <li>To protect our rights and safety</li>
                    <li>To prevent fraud or illegal activity</li>
                  </ul>
                </div>
                <p className="font-medium">We do NOT sell your personal information to third parties.</p>
              </div>
            </section>

            {/* 5. Data Security */}
            <section>
              <h2 className="text-xl font-semibold text-gray-900 mb-3">5. Data Security</h2>
              <div className="text-gray-600 leading-relaxed">
                <p className="mb-3">We implement security measures to protect your data:</p>
                <ul className="list-disc pl-5 space-y-1">
                  <li>Encryption of data in transit (HTTPS/TLS)</li>
                  <li>Secure authentication with OTP verification and JWT tokens</li>
                  <li>Regular security audits and updates</li>
                  <li>Access controls and monitoring</li>
                  <li>Secure cloud infrastructure</li>
                </ul>
                <p className="mt-3">
                  While we strive to protect your information, no system is completely secure. We cannot guarantee
                  absolute security.
                </p>
              </div>
            </section>

            {/* 6. Data Retention */}
            <section>
              <h2 className="text-xl font-semibold text-gray-900 mb-3">6. Data Retention</h2>
              <div className="text-gray-600 leading-relaxed space-y-3">
                <div>
                  <p className="mb-2">We retain your data for as long as:</p>
                  <ul className="list-disc pl-5 space-y-1">
                    <li>Your account is active</li>
                    <li>Necessary to provide our services</li>
                    <li>Required by law or for legal claims</li>
                  </ul>
                </div>
                <div>
                  <p className="mb-2">When you delete your account:</p>
                  <ul className="list-disc pl-5 space-y-1">
                    <li>Personal data is removed within 30 days</li>
                    <li>Some data may be retained for legal compliance</li>
                    <li>Anonymized data may be retained for analytics</li>
                  </ul>
                </div>
              </div>
            </section>

            {/* 7. Your Rights */}
            <section>
              <h2 className="text-xl font-semibold text-gray-900 mb-3">7. Your Rights</h2>
              <div className="text-gray-600 leading-relaxed">
                <p className="mb-3">You have the right to:</p>
                <ul className="list-disc pl-5 space-y-1">
                  <li>Access your personal data</li>
                  <li>Correct inaccurate information</li>
                  <li>Delete your account and data</li>
                  <li>Export your data</li>
                  <li>Opt out of marketing communications</li>
                  <li>Control your privacy settings</li>
                </ul>
                <p className="mt-3">
                  To exercise these rights, visit your account settings or contact us at{' '}
                  <a href="mailto:privacy@tekka.ug" className="text-primary-500 hover:text-primary-600">
                    privacy@tekka.ug
                  </a>
                </p>
              </div>
            </section>

            {/* 8. Privacy Controls */}
            <section>
              <h2 className="text-xl font-semibold text-gray-900 mb-3">8. Privacy Controls</h2>
              <div className="text-gray-600 leading-relaxed space-y-3">
                <p>You can control your privacy through your account settings:</p>
                <div>
                  <p className="font-medium text-gray-700 mb-2">Profile Visibility:</p>
                  <ul className="list-disc pl-5 space-y-1">
                    <li>Public &mdash; visible to all users</li>
                    <li>Buyers Only &mdash; visible to past buyers</li>
                    <li>Private &mdash; limited visibility</li>
                  </ul>
                </div>
                <div>
                  <p className="font-medium text-gray-700 mb-2">Information Sharing:</p>
                  <ul className="list-disc pl-5 space-y-1">
                    <li>Show/hide location</li>
                    <li>Show/hide phone number</li>
                    <li>Show/hide online status</li>
                    <li>Control who can message you</li>
                  </ul>
                </div>
              </div>
            </section>

            {/* 9. Children's Privacy */}
            <section>
              <h2 className="text-xl font-semibold text-gray-900 mb-3">9. Children&apos;s Privacy</h2>
              <div className="text-gray-600 leading-relaxed space-y-3">
                <p>
                  Tekka is not intended for users under 18 years old. We do not knowingly collect personal
                  information from children.
                </p>
                <p>
                  If we become aware that we have collected data from a child, we will delete it promptly.
                </p>
              </div>
            </section>

            {/* 10. Data Location */}
            <section>
              <h2 className="text-xl font-semibold text-gray-900 mb-3">10. Data Location</h2>
              <p className="text-gray-600 leading-relaxed">
                Your data is stored and processed on secure cloud servers. Images are stored via Cloudinary&apos;s
                global CDN infrastructure. By using Tekka, you consent to the transfer and processing of your data
                as described in this policy.
              </p>
            </section>

            {/* 11. Analytics and Tracking */}
            <section>
              <h2 className="text-xl font-semibold text-gray-900 mb-3">11. Analytics and Tracking</h2>
              <div className="text-gray-600 leading-relaxed">
                <p className="mb-3">
                  We use analytics tools to understand how users interact with our platform. This includes:
                </p>
                <ul className="list-disc pl-5 space-y-1">
                  <li>Crash reports and error logs</li>
                  <li>Feature usage statistics</li>
                  <li>Performance monitoring</li>
                </ul>
                <p className="mt-3">
                  This data is used to improve the platform and is not used for advertising purposes.
                </p>
              </div>
            </section>

            {/* 12. Changes to This Policy */}
            <section>
              <h2 className="text-xl font-semibold text-gray-900 mb-3">12. Changes to This Policy</h2>
              <div className="text-gray-600 leading-relaxed">
                <p className="mb-3">
                  We may update this Privacy Policy from time to time. We will notify you of significant changes
                  through:
                </p>
                <ul className="list-disc pl-5 space-y-1">
                  <li>In-app and website notifications</li>
                  <li>Email (if provided)</li>
                  <li>Updated &quot;Last updated&quot; date on this page</li>
                </ul>
                <p className="mt-3">
                  Continued use after changes constitutes acceptance of the updated policy.
                </p>
              </div>
            </section>

            {/* 13. Contact Us */}
            <section>
              <h2 className="text-xl font-semibold text-gray-900 mb-3">13. Contact Us</h2>
              <div className="text-gray-600 leading-relaxed">
                <p className="mb-3">For privacy-related questions or concerns:</p>
                <p>
                  Email:{' '}
                  <a href="mailto:privacy@tekka.ug" className="text-primary-500 hover:text-primary-600">
                    privacy@tekka.ug
                  </a>
                </p>
                <p>Address: 14c, Ggaba Road, Bunga, Kampala, Uganda</p>
                <p className="mt-3">We will respond to your inquiry within 30 days.</p>
              </div>
            </section>

            {/* Privacy note */}
            <div className="bg-primary-50 border border-primary-200 rounded-lg p-4">
              <p className="text-sm text-gray-700">
                Your privacy matters to us. We are committed to being transparent about our data practices and
                giving you control over your information.
              </p>
            </div>
          </div>
        </div>
      </main>

      <Footer />
    </div>
  );
}
