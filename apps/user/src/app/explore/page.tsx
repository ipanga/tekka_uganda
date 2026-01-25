'use client';

import { useState, useEffect, useCallback, Suspense } from 'react';
import { useSearchParams, useRouter } from 'next/navigation';
import { Header } from '@/components/layout/Header';
import { Footer } from '@/components/layout/Footer';
import { ListingCard } from '@/components/listings/ListingCard';
import { FunnelIcon, Squares2X2Icon, ListBulletIcon, MagnifyingGlassIcon, XMarkIcon } from '@heroicons/react/24/outline';
import { api } from '@/lib/api';
import type { Listing, PaginatedResponse } from '@/types';

const categories = [
  { label: 'All', value: '' },
  { label: 'Dresses', value: 'DRESSES' },
  { label: 'Tops', value: 'TOPS' },
  { label: 'Bottoms', value: 'BOTTOMS' },
  { label: 'Traditional Wear', value: 'TRADITIONAL_WEAR' },
  { label: 'Shoes', value: 'SHOES' },
  { label: 'Accessories', value: 'ACCESSORIES' },
  { label: 'Bags', value: 'BAGS' },
];

const conditions = [
  { label: 'Any Condition', value: '' },
  { label: 'New', value: 'NEW' },
  { label: 'Like New', value: 'LIKE_NEW' },
  { label: 'Good', value: 'GOOD' },
  { label: 'Fair', value: 'FAIR' },
];

const sortOptions = [
  { label: 'Newest', value: 'createdAt:desc' },
  { label: 'Price: Low to High', value: 'price:asc' },
  { label: 'Price: High to Low', value: 'price:desc' },
  { label: 'Most Viewed', value: 'viewCount:desc' },
];

function ExploreContent() {
  const searchParams = useSearchParams();
  const router = useRouter();
  const [listings, setListings] = useState<Listing[]>([]);
  const [loading, setLoading] = useState(true);
  const [searchQuery, setSearchQuery] = useState(searchParams.get('search') || '');
  const [category, setCategory] = useState('');
  const [condition, setCondition] = useState('');
  const [sort, setSort] = useState('createdAt:desc');
  const [showFilters, setShowFilters] = useState(false);
  const [viewMode, setViewMode] = useState<'grid' | 'list'>('grid');

  // Sync search query from URL params when they change
  useEffect(() => {
    const urlSearch = searchParams.get('search') || '';
    if (urlSearch !== searchQuery) {
      setSearchQuery(urlSearch);
    }
  }, [searchParams]);

  const fetchListings = useCallback(async () => {
    setLoading(true);
    try {
      const params = new URLSearchParams();
      if (searchQuery.trim()) params.append('search', searchQuery.trim());
      if (category) params.append('category', category);
      if (condition) params.append('condition', condition);
      params.append('status', 'ACTIVE');
      const [sortField, sortOrder] = sort.split(':');
      params.append('sortBy', sortField);
      params.append('sortOrder', sortOrder);

      const response = await api.get<PaginatedResponse<Listing> & { listings?: Listing[] }>(`/listings?${params}`);
      setListings(response?.data || response?.listings || []);
    } catch (error) {
      console.error('Failed to fetch listings:', error);
      setListings([]);
    } finally {
      setLoading(false);
    }
  }, [searchQuery, category, condition, sort]);

  useEffect(() => {
    const debounce = setTimeout(() => {
      fetchListings();
    }, searchQuery ? 300 : 0);
    return () => clearTimeout(debounce);
  }, [fetchListings]);

  const handleSearchSubmit = (e: React.FormEvent) => {
    e.preventDefault();
    // Update URL to reflect search
    const params = new URLSearchParams();
    if (searchQuery.trim()) params.set('search', searchQuery.trim());
    router.replace(`/explore${params.toString() ? `?${params}` : ''}`);
  };

  const clearSearch = () => {
    setSearchQuery('');
    router.replace('/explore');
  };

  return (
    <div className="min-h-screen flex flex-col bg-gray-50">
      <Header />

      <main className="flex-1">
        <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 py-8">
          {/* Search Bar */}
          <form onSubmit={handleSearchSubmit} className="mb-6">
            <div className="relative">
              <MagnifyingGlassIcon className="absolute left-4 top-1/2 -translate-y-1/2 h-5 w-5 text-gray-400" />
              <input
                type="text"
                value={searchQuery}
                onChange={(e) => setSearchQuery(e.target.value)}
                placeholder="Search for items..."
                className="w-full pl-12 pr-10 py-3 border border-gray-300 rounded-xl focus:outline-none focus:ring-2 focus:ring-pink-500 focus:border-transparent text-gray-900 placeholder-gray-400"
              />
              {searchQuery && (
                <button
                  type="button"
                  onClick={clearSearch}
                  className="absolute right-4 top-1/2 -translate-y-1/2 text-gray-400 hover:text-gray-600"
                >
                  <XMarkIcon className="h-5 w-5" />
                </button>
              )}
            </div>
          </form>

          {/* Header */}
          <div className="flex flex-col md:flex-row md:items-center md:justify-between mb-6">
            <h1 className="text-2xl font-bold text-gray-900 mb-4 md:mb-0">
              {searchQuery ? `Results for "${searchQuery}"` : 'Explore'}
            </h1>

            <div className="flex items-center space-x-4">
              {/* Sort */}
              <select
                value={sort}
                onChange={(e) => setSort(e.target.value)}
                className="px-4 py-2 border border-gray-300 rounded-lg focus:outline-none focus:ring-2 focus:ring-pink-500"
              >
                {sortOptions.map((option) => (
                  <option key={option.value} value={option.value}>
                    {option.label}
                  </option>
                ))}
              </select>

              {/* Filter Toggle */}
              <button
                onClick={() => setShowFilters(!showFilters)}
                className="flex items-center px-4 py-2 border border-gray-300 rounded-lg hover:bg-gray-50"
              >
                <FunnelIcon className="h-5 w-5 mr-2" />
                Filters
              </button>

              {/* View Mode */}
              <div className="hidden md:flex border border-gray-300 rounded-lg overflow-hidden">
                <button
                  onClick={() => setViewMode('grid')}
                  className={`p-2 ${viewMode === 'grid' ? 'bg-pink-100 text-pink-600' : 'hover:bg-gray-50'}`}
                >
                  <Squares2X2Icon className="h-5 w-5" />
                </button>
                <button
                  onClick={() => setViewMode('list')}
                  className={`p-2 ${viewMode === 'list' ? 'bg-pink-100 text-pink-600' : 'hover:bg-gray-50'}`}
                >
                  <ListBulletIcon className="h-5 w-5" />
                </button>
              </div>
            </div>
          </div>

          {/* Filters */}
          {showFilters && (
            <div className="bg-white p-4 rounded-lg shadow-sm mb-6">
              <div className="grid grid-cols-1 md:grid-cols-3 gap-4">
                <div>
                  <label className="block text-sm font-medium text-gray-700 mb-2">Category</label>
                  <select
                    value={category}
                    onChange={(e) => setCategory(e.target.value)}
                    className="w-full px-4 py-2 border border-gray-300 rounded-lg focus:outline-none focus:ring-2 focus:ring-pink-500"
                  >
                    {categories.map((cat) => (
                      <option key={cat.value} value={cat.value}>
                        {cat.label}
                      </option>
                    ))}
                  </select>
                </div>

                <div>
                  <label className="block text-sm font-medium text-gray-700 mb-2">Condition</label>
                  <select
                    value={condition}
                    onChange={(e) => setCondition(e.target.value)}
                    className="w-full px-4 py-2 border border-gray-300 rounded-lg focus:outline-none focus:ring-2 focus:ring-pink-500"
                  >
                    {conditions.map((cond) => (
                      <option key={cond.value} value={cond.value}>
                        {cond.label}
                      </option>
                    ))}
                  </select>
                </div>
              </div>
            </div>
          )}

          {/* Category Pills */}
          <div className="flex flex-wrap gap-2 mb-6">
            {categories.map((cat) => (
              <button
                key={cat.value}
                onClick={() => setCategory(cat.value)}
                className={`px-4 py-2 rounded-full text-sm font-medium transition-colors ${
                  category === cat.value
                    ? 'bg-pink-600 text-white'
                    : 'bg-white text-gray-700 hover:bg-pink-50 hover:text-pink-600 border border-gray-200'
                }`}
              >
                {cat.label}
              </button>
            ))}
          </div>

          {/* Listings Grid */}
          {loading ? (
            <div className="flex items-center justify-center py-12">
              <div className="h-8 w-8 animate-spin rounded-full border-4 border-pink-600 border-t-transparent" />
            </div>
          ) : !listings || listings.length === 0 ? (
            <div className="text-center py-12">
              <p className="text-gray-500">
                {searchQuery ? `No results for "${searchQuery}"` : 'No listings found'}
              </p>
              {searchQuery && (
                <button
                  onClick={clearSearch}
                  className="mt-3 text-pink-600 hover:text-pink-700 font-medium"
                >
                  Clear search
                </button>
              )}
            </div>
          ) : (
            <div
              className={
                viewMode === 'grid'
                  ? 'grid grid-cols-2 md:grid-cols-3 lg:grid-cols-4 gap-4'
                  : 'space-y-4'
              }
            >
              {listings.map((listing) => (
                <ListingCard key={listing.id} listing={listing} />
              ))}
            </div>
          )}
        </div>
      </main>

      <Footer />
    </div>
  );
}

export default function ExplorePage() {
  return (
    <Suspense
      fallback={
        <div className="min-h-screen flex items-center justify-center">
          <div className="h-8 w-8 animate-spin rounded-full border-4 border-pink-600 border-t-transparent" />
        </div>
      }
    >
      <ExploreContent />
    </Suspense>
  );
}
