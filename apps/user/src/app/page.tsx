import Link from 'next/link';
import { Header } from '@/components/layout/Header';
import { Footer } from '@/components/layout/Footer';

const categories = [
  { name: 'Dresses', slug: 'dresses', image: '/categories/dresses.jpg' },
  { name: 'Tops', slug: 'tops', image: '/categories/tops.jpg' },
  { name: 'Traditional Wear', slug: 'traditional-wear', image: '/categories/traditional.jpg' },
  { name: 'Shoes', slug: 'shoes', image: '/categories/shoes.jpg' },
  { name: 'Accessories', slug: 'accessories', image: '/categories/accessories.jpg' },
  { name: 'Bags', slug: 'bags', image: '/categories/bags.jpg' },
];

const occasions = [
  { name: 'Wedding', slug: 'wedding' },
  { name: 'Kwanjula', slug: 'kwanjula' },
  { name: 'Church', slug: 'church' },
  { name: 'Corporate', slug: 'corporate' },
  { name: 'Casual', slug: 'casual' },
  { name: 'Party', slug: 'party' },
];

export default function HomePage() {
  return (
    <div className="min-h-screen flex flex-col">
      <Header />

      <main className="flex-1">
        {/* Hero Section */}
        <section className="relative bg-gradient-to-r from-pink-500 to-rose-500 text-white">
          <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 py-24">
            <div className="max-w-2xl">
              <h1 className="text-4xl md:text-5xl font-bold leading-tight">
                Pre-loved Fashion,
                <br />
                Freshly Styled
              </h1>
              <p className="mt-6 text-lg text-pink-100">
                Discover unique fashion pieces from sellers across Uganda.
                Buy and sell with confidence on Tekka.
              </p>
              <div className="mt-8 flex flex-col sm:flex-row gap-4">
                <Link
                  href="/explore"
                  className="inline-flex items-center justify-center px-6 py-3 bg-white text-pink-600 font-semibold rounded-full hover:bg-pink-50 transition-colors"
                >
                  Start Shopping
                </Link>
                <Link
                  href="/sell"
                  className="inline-flex items-center justify-center px-6 py-3 border-2 border-white text-white font-semibold rounded-full hover:bg-white/10 transition-colors"
                >
                  Sell Your Items
                </Link>
              </div>
            </div>
          </div>
        </section>

        {/* Categories Section */}
        <section className="py-16 bg-gray-50">
          <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8">
            <h2 className="text-2xl font-bold text-gray-900 mb-8">Shop by Category</h2>
            <div className="grid grid-cols-2 md:grid-cols-3 lg:grid-cols-6 gap-4">
              {categories.map((category) => (
                <Link
                  key={category.slug}
                  href={`/explore?category=${category.slug}`}
                  className="group relative aspect-square rounded-xl overflow-hidden bg-gray-200"
                >
                  <div className="absolute inset-0 bg-gradient-to-t from-black/60 to-transparent" />
                  <div className="absolute bottom-0 left-0 right-0 p-4">
                    <h3 className="text-white font-semibold text-center group-hover:text-pink-300 transition-colors">
                      {category.name}
                    </h3>
                  </div>
                </Link>
              ))}
            </div>
          </div>
        </section>

        {/* Shop by Occasion */}
        <section className="py-16">
          <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8">
            <h2 className="text-2xl font-bold text-gray-900 mb-8">Shop by Occasion</h2>
            <div className="flex flex-wrap gap-3">
              {occasions.map((occasion) => (
                <Link
                  key={occasion.slug}
                  href={`/explore?occasion=${occasion.slug}`}
                  className="px-6 py-3 bg-white border border-gray-200 rounded-full text-gray-700 hover:border-pink-500 hover:text-pink-600 transition-colors"
                >
                  {occasion.name}
                </Link>
              ))}
            </div>
          </div>
        </section>

        {/* How It Works */}
        <section className="py-16 bg-gray-50">
          <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8">
            <h2 className="text-2xl font-bold text-gray-900 text-center mb-12">How Tekka Works</h2>
            <div className="grid grid-cols-1 md:grid-cols-3 gap-8">
              <div className="text-center">
                <div className="w-16 h-16 mx-auto bg-pink-100 rounded-full flex items-center justify-center mb-4">
                  <span className="text-2xl">📸</span>
                </div>
                <h3 className="text-lg font-semibold mb-2">List Your Items</h3>
                <p className="text-gray-600">
                  Take photos, set your price, and list your pre-loved items in minutes.
                </p>
              </div>
              <div className="text-center">
                <div className="w-16 h-16 mx-auto bg-pink-100 rounded-full flex items-center justify-center mb-4">
                  <span className="text-2xl">💬</span>
                </div>
                <h3 className="text-lg font-semibold mb-2">Connect with Buyers</h3>
                <p className="text-gray-600">
                  Chat directly with interested buyers and negotiate the best deal.
                </p>
              </div>
              <div className="text-center">
                <div className="w-16 h-16 mx-auto bg-pink-100 rounded-full flex items-center justify-center mb-4">
                  <span className="text-2xl">🤝</span>
                </div>
                <h3 className="text-lg font-semibold mb-2">Meet Safely</h3>
                <p className="text-gray-600">
                  Arrange to meet at one of our verified safe locations across Uganda.
                </p>
              </div>
            </div>
          </div>
        </section>

        {/* CTA Section */}
        <section className="py-16 bg-pink-600 text-white">
          <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 text-center">
            <h2 className="text-3xl font-bold mb-4">Ready to Start Selling?</h2>
            <p className="text-pink-100 mb-8 max-w-2xl mx-auto">
              Turn your closet into cash. List your first item today and join thousands of sellers on Tekka.
            </p>
            <Link
              href="/sell"
              className="inline-flex items-center justify-center px-8 py-4 bg-white text-pink-600 font-semibold rounded-full hover:bg-pink-50 transition-colors"
            >
              Start Selling Now
            </Link>
          </div>
        </section>
      </main>

      <Footer />
    </div>
  );
}
