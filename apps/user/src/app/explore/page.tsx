'use client';

import { useState, useEffect, useCallback, Suspense } from 'react';
import { useSearchParams, useRouter } from 'next/navigation';
import { Header } from '@/components/layout/Header';
import { Footer } from '@/components/layout/Footer';
import { ListingCard } from '@/components/listings/ListingCard';
import { FunnelIcon, Squares2X2Icon, ListBulletIcon, MagnifyingGlassIcon, XMarkIcon } from '@heroicons/react/24/outline';
import { api } from '@/lib/api';
import type { Listing, PaginatedResponse, Category, City } from '@/types';

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
  const [categoriesLoading, setCategoriesLoading] = useState(true);
  const [categories, setCategories] = useState<Category[]>([]);
  const [cities, setCities] = useState<City[]>([]);
  const [searchQuery, setSearchQuery] = useState(searchParams.get('search') || '');
  const [categoryId, setCategoryId] = useState(searchParams.get('categoryId') || '');
  const [condition, setCondition] = useState(searchParams.get('condition') || '');
  const [minPrice, setMinPrice] = useState(searchParams.get('minPrice') || '');
  const [maxPrice, setMaxPrice] = useState(searchParams.get('maxPrice') || '');
  const [cityId, setCityId] = useState(searchParams.get('cityId') || '');
  const [divisionId, setDivisionId] = useState(searchParams.get('divisionId') || '');
  const [sort, setSort] = useState(
    searchParams.get('sortBy') && searchParams.get('sortOrder')
      ? `${searchParams.get('sortBy')}:${searchParams.get('sortOrder')}`
      : 'createdAt:desc'
  );
  const [showFilters, setShowFilters] = useState(false);
  const [viewMode, setViewMode] = useState<'grid' | 'list'>('grid');

  // Fetch categories and cities on mount
  useEffect(() => {
    async function loadData() {
      try {
        const [cats, citiesData] = await Promise.all([
          api.getCategories(),
          api.getCitiesWithDivisions(),
        ]);
        setCategories(cats);
        setCities(citiesData);
      } catch (error) {
        console.error('Failed to load filter data:', error);
      } finally {
        setCategoriesLoading(false);
      }
    }
    loadData();
  }, []);

  // Sync filters from URL params when they change
  useEffect(() => {
    const urlSearch = searchParams.get('search') || '';
    const urlCategoryId = searchParams.get('categoryId') || '';
    const urlCondition = searchParams.get('condition') || '';
    const urlMinPrice = searchParams.get('minPrice') || '';
    const urlMaxPrice = searchParams.get('maxPrice') || '';
    const urlCityId = searchParams.get('cityId') || '';
    const urlDivisionId = searchParams.get('divisionId') || '';
    if (urlSearch !== searchQuery) setSearchQuery(urlSearch);
    if (urlCategoryId !== categoryId) setCategoryId(urlCategoryId);
    if (urlCondition !== condition) setCondition(urlCondition);
    if (urlMinPrice !== minPrice) setMinPrice(urlMinPrice);
    if (urlMaxPrice !== maxPrice) setMaxPrice(urlMaxPrice);
    if (urlCityId !== cityId) setCityId(urlCityId);
    if (urlDivisionId !== divisionId) setDivisionId(urlDivisionId);
  }, [searchParams]);

  const fetchListings = useCallback(async () => {
    setLoading(true);
    try {
      const params = new URLSearchParams();
      if (searchQuery.trim()) params.append('search', searchQuery.trim());
      if (categoryId) params.append('categoryId', categoryId);
      if (condition) params.append('condition', condition);
      if (minPrice) params.append('minPrice', minPrice);
      if (maxPrice) params.append('maxPrice', maxPrice);
      if (cityId) params.append('cityId', cityId);
      if (divisionId) params.append('divisionId', divisionId);
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
  }, [searchQuery, categoryId, condition, minPrice, maxPrice, cityId, divisionId, sort]);

  // Build flat list of categories for display (main + subcategories)
  const categoryOptions = categories.flatMap(cat => [
    { id: cat.id, name: cat.name, level: 1 },
    ...(cat.children || []).map(sub => ({ id: sub.id, name: `  ${sub.name}`, level: 2 }))
  ]);

  // Get divisions for selected city
  const selectedCity = cities.find(c => c.id === cityId);
  const divisions = selectedCity?.divisions?.filter(d => d.isActive) || [];

  // Count active filters (excluding search and sort)
  const activeFilterCount = [categoryId, condition, minPrice, maxPrice, cityId, divisionId].filter(Boolean).length;

  useEffect(() => {
    const debounce = setTimeout(() => {
      fetchListings();
    }, searchQuery ? 300 : 0);
    return () => clearTimeout(debounce);
  }, [fetchListings]);

  const updateUrl = useCallback(() => {
    const params = new URLSearchParams();
    if (searchQuery.trim()) params.set('search', searchQuery.trim());
    if (categoryId) params.set('categoryId', categoryId);
    if (condition) params.set('condition', condition);
    if (minPrice) params.set('minPrice', minPrice);
    if (maxPrice) params.set('maxPrice', maxPrice);
    if (cityId) params.set('cityId', cityId);
    if (divisionId) params.set('divisionId', divisionId);
    const [sortField, sortOrder] = sort.split(':');
    if (sortField !== 'createdAt' || sortOrder !== 'desc') {
      params.set('sortBy', sortField);
      params.set('sortOrder', sortOrder);
    }
    router.replace(`/explore${params.toString() ? `?${params}` : ''}`);
  }, [searchQuery, categoryId, condition, minPrice, maxPrice, cityId, divisionId, sort, router]);

  const handleSearchSubmit = (e: React.FormEvent) => {
    e.preventDefault();
    updateUrl();
  };

  const clearSearch = () => {
    setSearchQuery('');
    router.replace('/explore');
  };

  const clearAllFilters = () => {
    setSearchQuery('');
    setCategoryId('');
    setCondition('');
    setMinPrice('');
    setMaxPrice('');
    setCityId('');
    setDivisionId('');
    setSort('createdAt:desc');
    router.replace('/explore');
  };

  // Reset divisionId when city changes
  const handleCityChange = (newCityId: string) => {
    setCityId(newCityId);
    setDivisionId('');
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
                className="w-full pl-12 pr-10 py-3 border border-gray-300 rounded-xl focus:outline-none focus:ring-2 focus:ring-primary-500 focus:border-transparent text-gray-900 placeholder-gray-400"
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
              {searchQuery
                ? `Results for "${searchQuery}"`
                : categoryId
                  ? categories.find(c => c.id === categoryId)?.name ||
                    categories.flatMap(c => c.children || []).find(s => s.id === categoryId)?.name ||
                    'Explore'
                  : 'Explore'}
            </h1>

            <div className="flex items-center space-x-4">
              {/* Sort */}
              <select
                value={sort}
                onChange={(e) => setSort(e.target.value)}
                className="px-4 py-2 border border-gray-300 rounded-lg focus:outline-none focus:ring-2 focus:ring-primary-500"
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
                className={`flex items-center px-4 py-2 border rounded-lg transition-colors ${
                  activeFilterCount > 0
                    ? 'border-primary-500 bg-primary-50 text-primary-500'
                    : 'border-gray-300 hover:bg-gray-50'
                }`}
              >
                <FunnelIcon className="h-5 w-5 mr-2" />
                Filters
                {activeFilterCount > 0 && (
                  <span className="ml-2 inline-flex items-center justify-center h-5 w-5 rounded-full bg-primary-500 text-white text-xs font-medium">
                    {activeFilterCount}
                  </span>
                )}
              </button>

              {/* View Mode */}
              <div className="hidden md:flex border border-gray-300 rounded-lg overflow-hidden">
                <button
                  onClick={() => setViewMode('grid')}
                  className={`p-2 ${viewMode === 'grid' ? 'bg-primary-100 text-primary-500' : 'hover:bg-gray-50'}`}
                >
                  <Squares2X2Icon className="h-5 w-5" />
                </button>
                <button
                  onClick={() => setViewMode('list')}
                  className={`p-2 ${viewMode === 'list' ? 'bg-primary-100 text-primary-500' : 'hover:bg-gray-50'}`}
                >
                  <ListBulletIcon className="h-5 w-5" />
                </button>
              </div>
            </div>
          </div>

          {/* Filters Panel */}
          {showFilters && (
            <div className="bg-white p-4 rounded-lg shadow-sm mb-6">
              <div className="grid grid-cols-1 md:grid-cols-3 gap-4">
                {/* Category */}
                <div>
                  <label className="block text-sm font-medium text-gray-700 mb-2">Category</label>
                  <select
                    value={categoryId}
                    onChange={(e) => setCategoryId(e.target.value)}
                    className="w-full px-4 py-2 border border-gray-300 rounded-lg focus:outline-none focus:ring-2 focus:ring-primary-500"
                    disabled={categoriesLoading}
                  >
                    <option value="">All Categories</option>
                    {categoryOptions.map((cat) => (
                      <option key={cat.id} value={cat.id}>
                        {cat.name}
                      </option>
                    ))}
                  </select>
                </div>

                {/* Condition */}
                <div>
                  <label className="block text-sm font-medium text-gray-700 mb-2">Condition</label>
                  <select
                    value={condition}
                    onChange={(e) => setCondition(e.target.value)}
                    className="w-full px-4 py-2 border border-gray-300 rounded-lg focus:outline-none focus:ring-2 focus:ring-primary-500"
                  >
                    {conditions.map((cond) => (
                      <option key={cond.value} value={cond.value}>
                        {cond.label}
                      </option>
                    ))}
                  </select>
                </div>

                {/* City */}
                <div>
                  <label className="block text-sm font-medium text-gray-700 mb-2">City</label>
                  <select
                    value={cityId}
                    onChange={(e) => handleCityChange(e.target.value)}
                    className="w-full px-4 py-2 border border-gray-300 rounded-lg focus:outline-none focus:ring-2 focus:ring-primary-500"
                  >
                    <option value="">All Cities</option>
                    {cities.filter(c => c.isActive).map((city) => (
                      <option key={city.id} value={city.id}>
                        {city.name}
                      </option>
                    ))}
                  </select>
                </div>

                {/* Min Price */}
                <div>
                  <label className="block text-sm font-medium text-gray-700 mb-2">Min Price (UGX)</label>
                  <input
                    type="number"
                    value={minPrice}
                    onChange={(e) => setMinPrice(e.target.value)}
                    placeholder="e.g. 10000"
                    min="0"
                    className="w-full px-4 py-2 border border-gray-300 rounded-lg focus:outline-none focus:ring-2 focus:ring-primary-500"
                  />
                </div>

                {/* Max Price */}
                <div>
                  <label className="block text-sm font-medium text-gray-700 mb-2">Max Price (UGX)</label>
                  <input
                    type="number"
                    value={maxPrice}
                    onChange={(e) => setMaxPrice(e.target.value)}
                    placeholder="e.g. 500000"
                    min="0"
                    className="w-full px-4 py-2 border border-gray-300 rounded-lg focus:outline-none focus:ring-2 focus:ring-primary-500"
                  />
                </div>

                {/* Division (shown when city is selected) */}
                {cityId && divisions.length > 0 && (
                  <div>
                    <label className="block text-sm font-medium text-gray-700 mb-2">Division</label>
                    <select
                      value={divisionId}
                      onChange={(e) => setDivisionId(e.target.value)}
                      className="w-full px-4 py-2 border border-gray-300 rounded-lg focus:outline-none focus:ring-2 focus:ring-primary-500"
                    >
                      <option value="">All Divisions</option>
                      {divisions.map((div) => (
                        <option key={div.id} value={div.id}>
                          {div.name}
                        </option>
                      ))}
                    </select>
                  </div>
                )}
              </div>

              {/* Filter actions */}
              {activeFilterCount > 0 && (
                <div className="mt-4 pt-4 border-t border-gray-100 flex justify-end">
                  <button
                    onClick={clearAllFilters}
                    className="text-sm font-medium text-primary-500 hover:text-primary-600"
                  >
                    Clear all filters
                  </button>
                </div>
              )}
            </div>
          )}

          {/* Category Pills - Show main categories */}
          <div className="flex flex-wrap gap-2 mb-4">
            <button
              onClick={() => setCategoryId('')}
              className={`px-4 py-2 rounded-full text-sm font-medium transition-colors ${
                categoryId === ''
                  ? 'bg-primary-500 text-white'
                  : 'bg-white text-gray-700 hover:bg-primary-50 hover:text-primary-500 border border-gray-200'
              }`}
            >
              All
            </button>
            {categories.map((cat) => (
              <button
                key={cat.id}
                onClick={() => setCategoryId(cat.id)}
                className={`px-4 py-2 rounded-full text-sm font-medium transition-colors ${
                  categoryId === cat.id
                    ? 'bg-primary-500 text-white'
                    : 'bg-white text-gray-700 hover:bg-primary-50 hover:text-primary-500 border border-gray-200'
                }`}
              >
                {cat.name}
              </button>
            ))}
          </div>

          {/* Subcategory Pills - Show when a main category is selected */}
          {categoryId && categories.find(c => c.id === categoryId)?.children && (
            <div className="flex flex-wrap gap-2 mb-4">
              {categories.find(c => c.id === categoryId)?.children?.map((sub) => (
                <button
                  key={sub.id}
                  onClick={() => setCategoryId(sub.id)}
                  className="px-3 py-1 rounded-full text-xs font-medium bg-gray-100 text-gray-700 hover:bg-primary-50 hover:text-primary-500 border border-gray-200 transition-colors"
                >
                  {sub.name}
                </button>
              ))}
            </div>
          )}


          {/* Listings Grid */}
          {loading ? (
            <div className="flex items-center justify-center py-12">
              <div className="h-8 w-8 animate-spin rounded-full border-4 border-primary-500 border-t-transparent" />
            </div>
          ) : !listings || listings.length === 0 ? (
            <div className="text-center py-12">
              <p className="text-gray-500">
                {searchQuery ? `No results for "${searchQuery}"` : 'No listings found'}
              </p>
              {(searchQuery || activeFilterCount > 0) && (
                <button
                  onClick={clearAllFilters}
                  className="mt-3 text-primary-500 hover:text-primary-600 font-medium"
                >
                  Clear all filters
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
          <div className="h-8 w-8 animate-spin rounded-full border-4 border-primary-500 border-t-transparent" />
        </div>
      }
    >
      <ExploreContent />
    </Suspense>
  );
}
