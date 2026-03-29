import type { Metadata } from 'next';
import Link from 'next/link';
import { Header } from '@/components/layout/Header';
import { Footer } from '@/components/layout/Footer';

export const metadata: Metadata = {
  title: 'Buy Second-Hand Clothes in Uganda',
  description:
    'Shop affordable second-hand clothes in Uganda on Tekka. Find quality pre-loved dresses, tops, shoes, and accessories in Kampala and across Uganda. Save money on fashion.',
  alternates: { canonical: 'https://tekka.ug/buy-second-hand-clothes' },
};

export default function BuySecondHandPage() {
  return (
    <div className="min-h-screen flex flex-col">
      <Header />
      <main className="flex-1 py-12">
        <div className="max-w-3xl mx-auto px-4">
          <h1 className="text-3xl font-bold text-gray-900 mb-4">
            Buy Second-Hand Clothes in Uganda
          </h1>
          <p className="text-lg text-gray-600 mb-8">
            Discover quality pre-loved fashion at affordable prices. From
            everyday wear to special occasions, Tekka has thousands of items
            from sellers across Uganda.
          </p>

          <section className="mb-10">
            <h2 className="text-2xl font-semibold text-gray-900 mb-4">
              Why Buy Second-Hand?
            </h2>
            <div className="grid md:grid-cols-2 gap-6">
              <div className="bg-gray-50 rounded-xl p-6">
                <h3 className="font-semibold text-gray-900 mb-2">Save Money</h3>
                <p className="text-sm text-gray-600">
                  Get quality clothes at 50-80% less than retail prices. Your
                  budget goes further when you shop second-hand in Uganda.
                </p>
              </div>
              <div className="bg-gray-50 rounded-xl p-6">
                <h3 className="font-semibold text-gray-900 mb-2">Unique Finds</h3>
                <p className="text-sm text-gray-600">
                  Discover one-of-a-kind pieces and brands that may not be
                  available in local shops. Stand out with unique fashion.
                </p>
              </div>
              <div className="bg-gray-50 rounded-xl p-6">
                <h3 className="font-semibold text-gray-900 mb-2">Shop Sustainably</h3>
                <p className="text-sm text-gray-600">
                  Reduce textile waste by giving clothes a second life. Every
                  purchase helps the environment.
                </p>
              </div>
              <div className="bg-gray-50 rounded-xl p-6">
                <h3 className="font-semibold text-gray-900 mb-2">Quality Assured</h3>
                <p className="text-sm text-gray-600">
                  Every listing on Tekka shows the item&apos;s condition clearly.
                  See detailed photos and descriptions before you buy.
                </p>
              </div>
            </div>
          </section>

          <section className="mb-10">
            <h2 className="text-2xl font-semibold text-gray-900 mb-4">
              What You Can Find on Tekka
            </h2>
            <ul className="list-disc pl-6 text-gray-600 space-y-2">
              <li>Dresses and gowns for weddings, kwanjula, and parties</li>
              <li>Casual wear: tops, t-shirts, blouses, and shirts</li>
              <li>Bottoms: trousers, skirts, jeans, and shorts</li>
              <li>Traditional Ugandan wear and African print clothing</li>
              <li>Shoes, sandals, and sneakers</li>
              <li>Bags, handbags, and backpacks</li>
              <li>Accessories: jewelry, watches, belts, and scarves</li>
            </ul>
          </section>

          <section className="mb-10">
            <h2 className="text-2xl font-semibold text-gray-900 mb-4">
              How to Buy on Tekka
            </h2>
            <ol className="list-decimal pl-6 text-gray-600 space-y-3">
              <li>
                <strong>Browse or search</strong> &mdash; Use filters to find
                items by category, size, price range, or location.
              </li>
              <li>
                <strong>Check the details</strong> &mdash; View photos, read the
                description, and check the seller&apos;s profile and reviews.
              </li>
              <li>
                <strong>Message the seller</strong> &mdash; Ask questions, request
                more photos, or negotiate the price.
              </li>
              <li>
                <strong>Arrange a meetup</strong> &mdash; Meet at a safe public
                location to inspect the item and complete the purchase.
              </li>
            </ol>
          </section>

          <div className="bg-primary-50 rounded-xl p-6">
            <h3 className="font-semibold text-gray-900 mb-2">
              Start shopping now
            </h3>
            <p className="text-gray-600 mb-4">
              Browse thousands of affordable items from sellers across Uganda.
            </p>
            <Link
              href="/explore"
              className="inline-flex items-center justify-center rounded-lg bg-primary-500 px-6 py-3 text-sm font-semibold text-white hover:bg-primary-600 transition"
            >
              Explore Items
            </Link>
          </div>
        </div>
      </main>
      <Footer />
    </div>
  );
}
