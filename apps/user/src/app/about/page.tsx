import type { Metadata } from 'next';
import Link from 'next/link';
import { Header } from '@/components/layout/Header';
import { Footer } from '@/components/layout/Footer';

export const metadata: Metadata = {
  title: 'About Us',
  description:
    'Tekka is Uganda\'s leading marketplace for buying and selling second-hand clothes. Learn about our mission to make fashion affordable and sustainable across Uganda.',
  alternates: { canonical: 'https://tekka.ug/about' },
};

export default function AboutPage() {
  return (
    <div className="min-h-screen flex flex-col">
      <Header />
      <main className="flex-1 py-12">
        <div className="max-w-3xl mx-auto px-4">
          <h1 className="text-3xl font-bold text-gray-900 mb-6">
            About Tekka
          </h1>

          <section className="prose prose-gray max-w-none space-y-6">
            <p className="text-lg text-gray-600">
              Tekka is Uganda&apos;s leading marketplace for buying and selling
              second-hand and new clothes. We connect buyers and sellers across
              Kampala and the rest of Uganda, making fashion affordable,
              sustainable, and accessible to everyone.
            </p>

            <h2 className="text-2xl font-semibold text-gray-900 mt-8">
              Our Mission
            </h2>
            <p className="text-gray-600">
              We believe that great fashion shouldn&apos;t come at a high price
              &mdash; or at the expense of the environment. Tekka makes it easy
              to give your clothes a second life: sellers earn from items they no
              longer wear, and buyers discover quality fashion at a fraction of
              the retail price.
            </p>

            <h2 className="text-2xl font-semibold text-gray-900 mt-8">
              How Tekka Works
            </h2>
            <div className="grid md:grid-cols-3 gap-6 mt-4">
              <div className="bg-gray-50 rounded-xl p-6">
                <h3 className="font-semibold text-gray-900 mb-2">1. List Your Items</h3>
                <p className="text-sm text-gray-600">
                  Snap photos, set your price, and publish your listing in
                  minutes. Selling clothes online in Uganda has never been easier.
                </p>
              </div>
              <div className="bg-gray-50 rounded-xl p-6">
                <h3 className="font-semibold text-gray-900 mb-2">2. Connect with Buyers</h3>
                <p className="text-sm text-gray-600">
                  Chat directly with interested buyers. Negotiate, answer
                  questions, and agree on a meetup.
                </p>
              </div>
              <div className="bg-gray-50 rounded-xl p-6">
                <h3 className="font-semibold text-gray-900 mb-2">3. Meet & Complete the Sale</h3>
                <p className="text-sm text-gray-600">
                  Arrange a safe meetup at a convenient location. Exchange
                  the item and complete the transaction.
                </p>
              </div>
            </div>

            <h2 className="text-2xl font-semibold text-gray-900 mt-8">
              Why Choose Tekka?
            </h2>
            <ul className="list-disc pl-6 text-gray-600 space-y-2">
              <li>
                <strong>Local focus:</strong> Built specifically for the Ugandan
                market with UGX pricing and local meetup locations.
              </li>
              <li>
                <strong>Safe transactions:</strong> Verified profiles, in-app
                messaging, and safe meetup suggestions in Kampala.
              </li>
              <li>
                <strong>Affordable fashion:</strong> Find quality second-hand
                clothes at prices that fit any budget.
              </li>
              <li>
                <strong>Sustainable shopping:</strong> Extend the life of clothes
                and reduce textile waste in Uganda.
              </li>
            </ul>

            <div className="mt-10 flex flex-col sm:flex-row gap-4">
              <Link
                href="/explore"
                className="inline-flex items-center justify-center rounded-lg bg-primary-500 px-6 py-3 text-sm font-semibold text-white hover:bg-primary-600 transition"
              >
                Start Shopping
              </Link>
              <Link
                href="/sell"
                className="inline-flex items-center justify-center rounded-lg border border-gray-300 px-6 py-3 text-sm font-semibold text-gray-700 hover:bg-gray-50 transition"
              >
                Sell Your Clothes
              </Link>
            </div>
          </section>
        </div>
      </main>
      <Footer />
    </div>
  );
}
