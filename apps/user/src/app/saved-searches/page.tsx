'use client';

import { useState, useEffect } from 'react';
import { useRouter } from 'next/navigation';
import Link from 'next/link';
import {
  MagnifyingGlassIcon,
  BellIcon,
  TrashIcon,
  FunnelIcon,
} from '@heroicons/react/24/outline';
import { api } from '@/lib/api';
import { SavedSearch, CATEGORY_LABELS, CONDITION_LABELS } from '@/types';
import { formatRelativeTime, formatPrice } from '@/lib/utils';
import Header from '@/components/layout/Header';
import Footer from '@/components/layout/Footer';
import { Button } from '@/components/ui/Button';
import { Card, CardContent } from '@/components/ui/Card';
import { Badge } from '@/components/ui/Badge';
import { PageLoader } from '@/components/ui/Spinner';
import { Modal, ModalFooter } from '@/components/ui/Modal';
import { useAuthStore } from '@/stores/authStore';

export default function SavedSearchesPage() {
  const router = useRouter();
  const { isAuthenticated, isLoading: authLoading } = useAuthStore();

  const [savedSearches, setSavedSearches] = useState<SavedSearch[]>([]);
  const [loading, setLoading] = useState(true);
  const [deleteSearchId, setDeleteSearchId] = useState<string | null>(null);
  const [deleteLoading, setDeleteLoading] = useState(false);

  useEffect(() => {
    if (!authLoading && !isAuthenticated) {
      router.push('/login');
      return;
    }

    if (isAuthenticated) {
      loadSavedSearches();
    }
  }, [authLoading, isAuthenticated]);

  const loadSavedSearches = async () => {
    try {
      setLoading(true);
      const data = await api.getSavedSearches();
      setSavedSearches(data);
    } catch (error) {
      console.error('Error loading saved searches:', error);
    } finally {
      setLoading(false);
    }
  };

  const handleDelete = async () => {
    if (!deleteSearchId) return;

    setDeleteLoading(true);
    try {
      await api.deleteSavedSearch(deleteSearchId);
      setSavedSearches(savedSearches.filter((s) => s.id !== deleteSearchId));
      setDeleteSearchId(null);
    } catch (error) {
      console.error('Error deleting saved search:', error);
    } finally {
      setDeleteLoading(false);
    }
  };

  const buildSearchUrl = (search: SavedSearch): string => {
    const params = new URLSearchParams();
    if (search.query) params.set('search', search.query);
    if (search.category) params.set('category', search.category);
    if (search.condition) params.set('condition', search.condition);
    if (search.minPrice) params.set('minPrice', search.minPrice.toString());
    if (search.maxPrice) params.set('maxPrice', search.maxPrice.toString());
    if (search.location) params.set('location', search.location);
    return `/?${params.toString()}`;
  };

  const getFilterSummary = (search: SavedSearch): string[] => {
    const filters: string[] = [];
    if (search.category) {
      filters.push(CATEGORY_LABELS[search.category] || search.category);
    }
    if (search.condition) {
      filters.push(CONDITION_LABELS[search.condition] || search.condition);
    }
    if (search.minPrice || search.maxPrice) {
      if (search.minPrice && search.maxPrice) {
        filters.push(`${formatPrice(search.minPrice)} - ${formatPrice(search.maxPrice)}`);
      } else if (search.minPrice) {
        filters.push(`From ${formatPrice(search.minPrice)}`);
      } else if (search.maxPrice) {
        filters.push(`Up to ${formatPrice(search.maxPrice)}`);
      }
    }
    if (search.location) {
      filters.push(search.location);
    }
    return filters;
  };

  if (authLoading || loading) {
    return (
      <div className="min-h-screen flex flex-col">
        <Header />
        <PageLoader message="Loading saved searches..." />
        <Footer />
      </div>
    );
  }

  return (
    <div className="min-h-screen flex flex-col bg-gray-50">
      <Header />

      <main className="flex-1 py-8">
        <div className="max-w-3xl mx-auto px-4">
          {/* Header */}
          <div className="mb-6">
            <h1 className="text-2xl font-bold text-gray-900">Saved Searches</h1>
            <p className="text-gray-500 mt-1">
              Get notified when new items match your search criteria
            </p>
          </div>

          {/* Saved Searches List */}
          {savedSearches.length === 0 ? (
            <Card>
              <CardContent className="py-12 text-center">
                <MagnifyingGlassIcon className="w-12 h-12 text-gray-300 mx-auto mb-4" />
                <h3 className="text-lg font-medium text-gray-900 mb-2">
                  No saved searches yet
                </h3>
                <p className="text-gray-500 mb-6">
                  Save your searches to get notified when new items are listed
                </p>
                <Button onClick={() => router.push('/')}>
                  Start Browsing
                </Button>
              </CardContent>
            </Card>
          ) : (
            <div className="space-y-4">
              {savedSearches.map((search) => {
                const filters = getFilterSummary(search);
                return (
                  <Card key={search.id}>
                    <CardContent className="py-4">
                      <div className="flex items-start justify-between gap-4">
                        <div className="flex-1 min-w-0">
                          {/* Search Query */}
                          <Link
                            href={buildSearchUrl(search)}
                            className="group"
                          >
                            <div className="flex items-center gap-2">
                              <MagnifyingGlassIcon className="w-5 h-5 text-gray-400" />
                              <span className="font-medium text-gray-900 group-hover:text-pink-600">
                                {search.name || search.query || 'All items'}
                              </span>
                            </div>
                          </Link>

                          {/* Filters */}
                          {filters.length > 0 && (
                            <div className="flex items-center gap-2 mt-2 flex-wrap">
                              <FunnelIcon className="w-4 h-4 text-gray-400" />
                              {filters.map((filter, index) => (
                                <Badge key={index} variant="default" size="sm">
                                  {filter}
                                </Badge>
                              ))}
                            </div>
                          )}

                          {/* Meta info */}
                          <div className="flex items-center gap-4 mt-2 text-sm text-gray-500">
                            {search.newMatchesCount > 0 && (
                              <span className="flex items-center gap-1 text-pink-600">
                                <BellIcon className="w-4 h-4" />
                                {search.newMatchesCount} new items
                              </span>
                            )}
                            <span>
                              Saved {formatRelativeTime(search.createdAt)}
                            </span>
                          </div>
                        </div>

                        {/* Actions */}
                        <div className="flex items-center gap-2">
                          <Link href={buildSearchUrl(search)}>
                            <Button variant="outline" size="sm">
                              View Results
                            </Button>
                          </Link>
                          <button
                            onClick={() => setDeleteSearchId(search.id)}
                            className="p-2 hover:bg-gray-100 rounded-lg text-gray-400 hover:text-red-500"
                          >
                            <TrashIcon className="w-5 h-5" />
                          </button>
                        </div>
                      </div>
                    </CardContent>
                  </Card>
                );
              })}
            </div>
          )}

          {/* How it works */}
          <div className="mt-8 p-6 bg-white rounded-lg border border-gray-200">
            <h3 className="font-medium text-gray-900 mb-4">How saved searches work</h3>
            <ul className="space-y-3 text-sm text-gray-600">
              <li className="flex items-start gap-3">
                <span className="w-6 h-6 rounded-full bg-pink-100 text-pink-600 flex items-center justify-center flex-shrink-0 text-xs font-medium">
                  1
                </span>
                <span>
                  Search for items on the explore page and apply your desired filters
                </span>
              </li>
              <li className="flex items-start gap-3">
                <span className="w-6 h-6 rounded-full bg-pink-100 text-pink-600 flex items-center justify-center flex-shrink-0 text-xs font-medium">
                  2
                </span>
                <span>
                  Click &quot;Save this search&quot; to save your search criteria
                </span>
              </li>
              <li className="flex items-start gap-3">
                <span className="w-6 h-6 rounded-full bg-pink-100 text-pink-600 flex items-center justify-center flex-shrink-0 text-xs font-medium">
                  3
                </span>
                <span>
                  Get notified when new items matching your criteria are listed
                </span>
              </li>
            </ul>
          </div>
        </div>
      </main>

      <Footer />

      {/* Delete Confirmation Modal */}
      <Modal
        isOpen={!!deleteSearchId}
        onClose={() => setDeleteSearchId(null)}
        title="Delete Saved Search"
        size="sm"
      >
        <p className="text-gray-600">
          Are you sure you want to delete this saved search? You will no longer receive
          notifications for new items matching this criteria.
        </p>

        <ModalFooter>
          <Button variant="outline" onClick={() => setDeleteSearchId(null)}>
            Cancel
          </Button>
          <Button
            onClick={handleDelete}
            loading={deleteLoading}
            className="bg-red-600 hover:bg-red-700"
          >
            Delete
          </Button>
        </ModalFooter>
      </Modal>
    </div>
  );
}
