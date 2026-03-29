import type { Metadata } from 'next';
import Link from 'next/link';
import { Header } from '@/components/layout/Header';
import { Footer } from '@/components/layout/Footer';

export const metadata: Metadata = {
  title: 'How to Sell Clothes Online in Uganda',
  description:
    'Learn how to sell your used and new clothes online in Uganda with Tekka. Step-by-step guide to listing items, pricing, taking photos, and completing sales in Kampala.',
  alternates: { canonical: 'https://tekka.ug/how-to-sell' },
};

export default function HowToSellPage() {
  return (
    <div className="min-h-screen flex flex-col">
      <Header />
      <main className="flex-1 py-12">
        <div className="max-w-3xl mx-auto px-4">
          <h1 className="text-3xl font-bold text-gray-900 mb-4">
            How to Sell Clothes Online in Uganda
          </h1>
          <p className="text-lg text-gray-600 mb-8">
            Turn your wardrobe into cash. Tekka makes it simple to sell
            second-hand and new clothes to buyers across Uganda.
          </p>

          <div className="space-y-10">
            <section>
              <h2 className="text-2xl font-semibold text-gray-900 mb-3">
                Step 1: Create Your Account
              </h2>
              <p className="text-gray-600">
                Sign up with your phone number in seconds. Verify your identity
                to build trust with buyers and increase your chances of making a
                sale.
              </p>
            </section>

            <section>
              <h2 className="text-2xl font-semibold text-gray-900 mb-3">
                Step 2: Take Great Photos
              </h2>
              <p className="text-gray-600 mb-3">
                Good photos are the key to selling fast. Here are some tips:
              </p>
              <ul className="list-disc pl-6 text-gray-600 space-y-1">
                <li>Use natural lighting for the best results</li>
                <li>Show the item from multiple angles (front, back, details)</li>
                <li>Include close-ups of labels, patterns, or any wear</li>
                <li>Use a clean, simple background</li>
                <li>Upload at least 3 photos per listing</li>
              </ul>
            </section>

            <section>
              <h2 className="text-2xl font-semibold text-gray-900 mb-3">
                Step 3: Write an Honest Description
              </h2>
              <p className="text-gray-600">
                Be specific about the item&apos;s condition, size, brand, and any
                flaws. Honest descriptions build trust and reduce returns. Include
                keywords like the brand name, size, and type of clothing so buyers
                can find your listing easily.
              </p>
            </section>

            <section>
              <h2 className="text-2xl font-semibold text-gray-900 mb-3">
                Step 4: Set a Fair Price
              </h2>
              <p className="text-gray-600">
                Research similar items on Tekka to price competitively. Consider
                the original price, condition, and brand. Items priced fairly sell
                faster. All prices are in Ugandan Shillings (UGX).
              </p>
            </section>

            <section>
              <h2 className="text-2xl font-semibold text-gray-900 mb-3">
                Step 5: Publish &amp; Wait for Buyers
              </h2>
              <p className="text-gray-600">
                Once your listing is reviewed and approved, it goes live for
                buyers to discover. Respond quickly to messages to keep buyers
                interested.
              </p>
            </section>

            <section>
              <h2 className="text-2xl font-semibold text-gray-900 mb-3">
                Step 6: Meet &amp; Complete the Sale
              </h2>
              <p className="text-gray-600">
                Arrange to meet at a safe public location in your area. Tekka
                suggests safe meetup spots in Kampala and other Ugandan cities
                to make transactions smooth and secure.
              </p>
            </section>
          </div>

          <div className="mt-10 bg-primary-50 rounded-xl p-6">
            <h3 className="font-semibold text-gray-900 mb-2">
              Ready to start selling?
            </h3>
            <p className="text-gray-600 mb-4">
              Join thousands of sellers on Uganda&apos;s fastest-growing fashion
              marketplace.
            </p>
            <Link
              href="/sell"
              className="inline-flex items-center justify-center rounded-lg bg-primary-500 px-6 py-3 text-sm font-semibold text-white hover:bg-primary-600 transition"
            >
              List Your First Item
            </Link>
          </div>
        </div>
      </main>
      <Footer />
    </div>
  );
}
