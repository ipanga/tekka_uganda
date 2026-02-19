import type { Metadata } from 'next';
import { Header } from '@/components/layout/Header';
import { Footer } from '@/components/layout/Footer';

export const metadata: Metadata = {
  title: 'Cookie Policy | Tekka.ug',
  description:
    'Understand how Tekka uses cookies and local storage on our website to provide a secure and personalized experience.',
};

export default function CookiesPage() {
  return (
    <div className="min-h-screen flex flex-col">
      <Header />

      <main className="flex-1 bg-[var(--background)]">
        <div className="max-w-4xl mx-auto px-4 sm:px-6 lg:px-8 py-12">
          {/* Page Header */}
          <div className="mb-10">
            <h1 className="text-3xl font-bold text-gray-900">Cookie Policy</h1>
            <p className="mt-2 text-sm text-gray-500">Last updated: February 2026</p>
          </div>

          <div className="space-y-8">
            {/* 1. What Are Cookies */}
            <section>
              <h2 className="text-xl font-semibold text-gray-900 mb-3">1. What Are Cookies</h2>
              <div className="text-gray-600 leading-relaxed space-y-3">
                <p>
                  Cookies are small text files placed on your device when you visit a website. They help the
                  website remember your preferences and improve your experience. We also use similar technologies
                  such as local storage and session storage (collectively referred to as &quot;cookies&quot; in
                  this policy).
                </p>
              </div>
            </section>

            {/* 2. How We Use Cookies */}
            <section>
              <h2 className="text-xl font-semibold text-gray-900 mb-3">2. How We Use Cookies</h2>
              <div className="text-gray-600 leading-relaxed space-y-4">
                <div className="bg-white rounded-xl border border-gray-200 p-5">
                  <h3 className="font-medium text-gray-900 mb-2">Essential Cookies</h3>
                  <p className="text-sm mb-2">Required for the website to function. Cannot be disabled.</p>
                  <ul className="list-disc pl-5 space-y-1 text-sm">
                    <li>Authentication tokens (JWT) &mdash; keeps you signed in securely</li>
                    <li>Session management &mdash; maintains your login state across pages</li>
                    <li>Security tokens &mdash; protects against cross-site request forgery</li>
                  </ul>
                </div>

                <div className="bg-white rounded-xl border border-gray-200 p-5">
                  <h3 className="font-medium text-gray-900 mb-2">Functional Cookies</h3>
                  <p className="text-sm mb-2">Enhance your experience with personalized features.</p>
                  <ul className="list-disc pl-5 space-y-1 text-sm">
                    <li>User preferences (theme, language)</li>
                    <li>Recently viewed items</li>
                    <li>Search preferences and filters</li>
                  </ul>
                </div>

                <div className="bg-white rounded-xl border border-gray-200 p-5">
                  <h3 className="font-medium text-gray-900 mb-2">Analytics Cookies</h3>
                  <p className="text-sm mb-2">Help us understand how you use our platform so we can improve it.</p>
                  <ul className="list-disc pl-5 space-y-1 text-sm">
                    <li>Page visit counts and navigation patterns</li>
                    <li>Feature usage and performance metrics</li>
                    <li>Error reporting and crash analytics</li>
                  </ul>
                </div>
              </div>
            </section>

            {/* 3. Third-Party Cookies */}
            <section>
              <h2 className="text-xl font-semibold text-gray-900 mb-3">3. Third-Party Services</h2>
              <div className="text-gray-600 leading-relaxed">
                <p className="mb-3">
                  Some cookies may be set by third-party services we use to operate Tekka:
                </p>
                <ul className="list-disc pl-5 space-y-1">
                  <li>
                    <span className="font-medium text-gray-700">Cloudinary</span> &mdash; hosts and delivers listing
                    images via their CDN; may set performance-related cookies
                  </li>
                  <li>
                    <span className="font-medium text-gray-700">Firebase</span> &mdash; provides authentication and
                    push notification services; may set session cookies
                  </li>
                </ul>
                <p className="mt-3">
                  These third-party services have their own privacy and cookie policies. We encourage you to review
                  them.
                </p>
              </div>
            </section>

            {/* 4. Managing Cookies */}
            <section>
              <h2 className="text-xl font-semibold text-gray-900 mb-3">4. Managing Cookies</h2>
              <div className="text-gray-600 leading-relaxed space-y-3">
                <p>
                  You can control cookies through your browser settings. Most browsers allow you to:
                </p>
                <ul className="list-disc pl-5 space-y-1">
                  <li>View and delete existing cookies</li>
                  <li>Block all or certain cookies</li>
                  <li>Set preferences for specific websites</li>
                  <li>Get notified when a cookie is being set</li>
                </ul>
                <p>
                  Please note that disabling essential cookies may prevent you from using certain features of the
                  website, such as signing in to your account.
                </p>
              </div>
            </section>

            {/* 5. Local Storage */}
            <section>
              <h2 className="text-xl font-semibold text-gray-900 mb-3">5. Local Storage</h2>
              <div className="text-gray-600 leading-relaxed space-y-3">
                <p>
                  In addition to cookies, we use your browser&apos;s local storage to store:
                </p>
                <ul className="list-disc pl-5 space-y-1">
                  <li>Authentication tokens for persistent login</li>
                  <li>User interface preferences</li>
                  <li>Cached data for improved performance</li>
                </ul>
                <p>
                  You can clear local storage through your browser&apos;s developer tools or settings. Clearing
                  local storage will sign you out and reset your preferences.
                </p>
              </div>
            </section>

            {/* 6. Changes */}
            <section>
              <h2 className="text-xl font-semibold text-gray-900 mb-3">6. Changes to This Policy</h2>
              <p className="text-gray-600 leading-relaxed">
                We may update this Cookie Policy from time to time to reflect changes in our practices or for
                operational, legal, or regulatory reasons. The &quot;Last updated&quot; date at the top of this page
                indicates when this policy was last revised.
              </p>
            </section>

            {/* 7. Contact */}
            <section>
              <h2 className="text-xl font-semibold text-gray-900 mb-3">7. Contact Us</h2>
              <div className="text-gray-600 leading-relaxed">
                <p>If you have questions about our use of cookies, please contact us:</p>
                <p className="mt-2">
                  Email:{' '}
                  <a href="mailto:contact@tekka.ug" className="text-primary-500 hover:text-primary-600">
                    contact@tekka.ug
                  </a>
                </p>
                <p>Address: 14c, Ggaba Road, Bunga, Kampala, Uganda</p>
              </div>
            </section>
          </div>
        </div>
      </main>

      <Footer />
    </div>
  );
}
