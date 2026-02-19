import type { Metadata } from 'next';
import { Header } from '@/components/layout/Header';
import { Footer } from '@/components/layout/Footer';

export const metadata: Metadata = {
  title: 'Terms of Service | Tekka.ug',
  description:
    'Read the Terms of Service for Tekka, Uganda\'s C2C fashion marketplace. Understand your rights and responsibilities as a buyer or seller.',
};

export default function TermsPage() {
  return (
    <div className="min-h-screen flex flex-col">
      <Header />

      <main className="flex-1 bg-[var(--background)]">
        <div className="max-w-4xl mx-auto px-4 sm:px-6 lg:px-8 py-12">
          {/* Page Header */}
          <div className="mb-10">
            <h1 className="text-3xl font-bold text-gray-900">Terms of Service</h1>
            <p className="mt-2 text-sm text-gray-500">Last updated: February 2026</p>
          </div>

          <div className="space-y-8">
            {/* 1. Introduction */}
            <section>
              <h2 className="text-xl font-semibold text-gray-900 mb-3">1. Introduction</h2>
              <div className="text-gray-600 leading-relaxed space-y-3">
                <p>
                  Welcome to Tekka (&quot;we,&quot; &quot;our,&quot; or &quot;us&quot;). These Terms of Service
                  (&quot;Terms&quot;) govern your access to and use of the Tekka website, mobile application,
                  and related services (collectively, the &quot;Service&quot;). By accessing or using the Service,
                  you agree to be bound by these Terms.
                </p>
                <p>
                  Tekka is a consumer-to-consumer (C2C) marketplace platform that enables users in Uganda to buy
                  and sell fashion items, including clothing, accessories, and related products.
                </p>
              </div>
            </section>

            {/* 2. Eligibility */}
            <section>
              <h2 className="text-xl font-semibold text-gray-900 mb-3">2. Eligibility</h2>
              <div className="text-gray-600 leading-relaxed">
                <p className="mb-3">To use the Service, you must:</p>
                <ul className="list-disc pl-5 space-y-1">
                  <li>Be at least 18 years old</li>
                  <li>Have the legal capacity to enter into binding contracts</li>
                  <li>Have a valid phone number for account verification</li>
                  <li>Be a resident of Uganda or have a valid Ugandan phone number</li>
                  <li>Not be prohibited from using the Service under applicable laws</li>
                </ul>
              </div>
            </section>

            {/* 3. Account Registration */}
            <section>
              <h2 className="text-xl font-semibold text-gray-900 mb-3">3. Account Registration</h2>
              <div className="text-gray-600 leading-relaxed">
                <p className="mb-3">
                  To access certain features of the Service, you must create an account. When creating an account,
                  you agree to:
                </p>
                <ul className="list-disc pl-5 space-y-1">
                  <li>Provide accurate, current, and complete information</li>
                  <li>Maintain and promptly update your account information</li>
                  <li>Keep your account credentials secure and confidential</li>
                  <li>Notify us immediately of any unauthorized access</li>
                  <li>Accept responsibility for all activities under your account</li>
                </ul>
                <p className="mt-3">
                  We reserve the right to suspend or terminate accounts that violate these Terms or contain false
                  information.
                </p>
              </div>
            </section>

            {/* 4. User Conduct */}
            <section>
              <h2 className="text-xl font-semibold text-gray-900 mb-3">4. User Conduct</h2>
              <div className="text-gray-600 leading-relaxed">
                <p className="mb-3">When using the Service, you agree NOT to:</p>
                <ul className="list-disc pl-5 space-y-1">
                  <li>Post false, misleading, or fraudulent listings</li>
                  <li>Sell counterfeit, stolen, or prohibited items</li>
                  <li>Harass, threaten, or abuse other users</li>
                  <li>Use the Service for illegal purposes</li>
                  <li>Attempt to manipulate prices or reviews</li>
                  <li>Create multiple accounts to circumvent restrictions</li>
                  <li>Share account credentials with third parties</li>
                  <li>Collect user data without consent</li>
                  <li>Interfere with the proper functioning of the Service</li>
                </ul>
              </div>
            </section>

            {/* 5. Listings and Transactions */}
            <section>
              <h2 className="text-xl font-semibold text-gray-900 mb-3">5. Listings and Transactions</h2>
              <div className="text-gray-600 leading-relaxed">
                <p className="mb-2 font-medium text-gray-700">As a Seller, you agree to:</p>
                <ul className="list-disc pl-5 space-y-1 mb-4">
                  <li>Provide accurate descriptions and authentic photos of items</li>
                  <li>Disclose any defects, damage, or wear</li>
                  <li>Set fair and honest prices</li>
                  <li>Respond promptly to buyer inquiries</li>
                  <li>Complete transactions as agreed</li>
                  <li>Deliver items in the condition described</li>
                </ul>
                <p className="mb-2 font-medium text-gray-700">As a Buyer, you agree to:</p>
                <ul className="list-disc pl-5 space-y-1">
                  <li>Read listings carefully before making offers</li>
                  <li>Communicate respectfully with sellers</li>
                  <li>Complete payment as agreed</li>
                  <li>Inspect items at meetup before completing purchase</li>
                </ul>
              </div>
            </section>

            {/* 6. Prohibited Items */}
            <section>
              <h2 className="text-xl font-semibold text-gray-900 mb-3">6. Prohibited Items</h2>
              <div className="text-gray-600 leading-relaxed">
                <p className="mb-3">The following items are prohibited on Tekka:</p>
                <ul className="list-disc pl-5 space-y-1">
                  <li>Counterfeit or replica designer items</li>
                  <li>Stolen or illegally obtained goods</li>
                  <li>Weapons, drugs, or controlled substances</li>
                  <li>Hazardous materials</li>
                  <li>Items that infringe intellectual property rights</li>
                  <li>Adult content or explicit materials</li>
                  <li>Items prohibited by Ugandan law</li>
                  <li>Any items we determine to be inappropriate</li>
                </ul>
              </div>
            </section>

            {/* 7. Fees and Payments */}
            <section>
              <h2 className="text-xl font-semibold text-gray-900 mb-3">7. Fees and Payments</h2>
              <div className="text-gray-600 leading-relaxed space-y-3">
                <p>
                  Tekka does not currently charge fees for listing or selling items. All transactions are conducted
                  directly between buyers and sellers.
                </p>
                <p>
                  We reserve the right to introduce fees in the future with prior notice. Users will be notified of
                  any fee changes through the app or email.
                </p>
              </div>
            </section>

            {/* 8. Safety */}
            <section>
              <h2 className="text-xl font-semibold text-gray-900 mb-3">8. Safety</h2>
              <div className="text-gray-600 leading-relaxed">
                <p className="mb-3">Your safety is important to us. When meeting for transactions:</p>
                <ul className="list-disc pl-5 space-y-1">
                  <li>Meet in public, well-lit locations</li>
                  <li>Bring a friend or inform someone of your whereabouts</li>
                  <li>Inspect items thoroughly before payment</li>
                  <li>Use secure payment methods</li>
                  <li>Trust your instincts &mdash; if something feels wrong, leave</li>
                </ul>
                <p className="mt-3">
                  Tekka is not responsible for any harm, loss, or damage arising from in-person meetings or
                  transactions.
                </p>
              </div>
            </section>

            {/* 9. Intellectual Property */}
            <section>
              <h2 className="text-xl font-semibold text-gray-900 mb-3">9. Intellectual Property</h2>
              <div className="text-gray-600 leading-relaxed space-y-3">
                <p>
                  The Tekka name, logo, and all related graphics, icons, and service names are trademarks of Tekka.
                  You may not use our trademarks without prior written permission.
                </p>
                <p>
                  By posting content on Tekka, you grant us a non-exclusive, worldwide, royalty-free license to use,
                  display, and distribute your content in connection with the Service.
                </p>
              </div>
            </section>

            {/* 10. Limitation of Liability */}
            <section>
              <h2 className="text-xl font-semibold text-gray-900 mb-3">10. Limitation of Liability</h2>
              <div className="text-gray-600 leading-relaxed">
                <p className="mb-3 font-medium text-gray-700 uppercase text-sm">
                  To the maximum extent permitted by law:
                </p>
                <ul className="list-disc pl-5 space-y-1">
                  <li>The Service is provided &quot;AS IS&quot; without warranties of any kind</li>
                  <li>We do not guarantee the quality, safety, or legality of listed items</li>
                  <li>We are not responsible for user conduct or transaction disputes</li>
                  <li>Our liability is limited to the amount you paid us (if any)</li>
                  <li>We are not liable for indirect, incidental, or consequential damages</li>
                </ul>
              </div>
            </section>

            {/* 11. Dispute Resolution */}
            <section>
              <h2 className="text-xl font-semibold text-gray-900 mb-3">11. Dispute Resolution</h2>
              <div className="text-gray-600 leading-relaxed space-y-3">
                <p>
                  Disputes between users should be resolved directly between the parties. Tekka may, at its
                  discretion, assist in mediating disputes but is under no obligation to do so.
                </p>
                <p>
                  Any disputes with Tekka shall be resolved through binding arbitration in Kampala, Uganda, in
                  accordance with Ugandan law.
                </p>
              </div>
            </section>

            {/* 12. Termination */}
            <section>
              <h2 className="text-xl font-semibold text-gray-900 mb-3">12. Termination</h2>
              <div className="text-gray-600 leading-relaxed">
                <p className="mb-3">We may suspend or terminate your account at any time for:</p>
                <ul className="list-disc pl-5 space-y-1">
                  <li>Violation of these Terms</li>
                  <li>Fraudulent or illegal activity</li>
                  <li>Conduct that harms other users or the platform</li>
                  <li>Extended periods of inactivity</li>
                  <li>Any reason at our sole discretion</li>
                </ul>
                <p className="mt-3">You may delete your account at any time through your account settings.</p>
              </div>
            </section>

            {/* 13. Changes to Terms */}
            <section>
              <h2 className="text-xl font-semibold text-gray-900 mb-3">13. Changes to Terms</h2>
              <p className="text-gray-600 leading-relaxed">
                We may update these Terms from time to time. We will notify you of material changes through the
                app, website, or email. Continued use of the Service after changes constitutes acceptance of the
                new Terms.
              </p>
            </section>

            {/* 14. Contact Us */}
            <section>
              <h2 className="text-xl font-semibold text-gray-900 mb-3">14. Contact Us</h2>
              <div className="text-gray-600 leading-relaxed">
                <p className="mb-3">If you have questions about these Terms, please contact us:</p>
                <p>
                  Email:{' '}
                  <a href="mailto:contact@tekka.ug" className="text-primary-500 hover:text-primary-600">
                    contact@tekka.ug
                  </a>
                </p>
                <p>Address: 14c, Ggaba Road, Bunga, Kampala, Uganda</p>
              </div>
            </section>

            {/* Agreement note */}
            <div className="bg-primary-50 border border-primary-200 rounded-lg p-4">
              <p className="text-sm text-gray-700">
                By using Tekka, you acknowledge that you have read, understood, and agree to be bound by these
                Terms of Service.
              </p>
            </div>
          </div>
        </div>
      </main>

      <Footer />
    </div>
  );
}
