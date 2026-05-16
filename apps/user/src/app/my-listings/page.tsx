'use client';

import { useCallback, useEffect, useMemo, useRef, useState } from 'react';
import { useRouter } from 'next/navigation';
import Link from 'next/link';
import {
  PlusIcon,
  PencilIcon,
  TrashIcon,
  ArchiveBoxIcon,
  CheckCircleIcon,
} from '@heroicons/react/24/outline';
import { api } from '@/lib/api';
import { authManager } from '@/lib/auth';
import { Listing, ListingStatus, STATUS_LABELS } from '@/types';
import { formatPrice, formatRelativeTime, getListingHref } from '@/lib/utils';
import Header from '@/components/layout/Header';
import Footer from '@/components/layout/Footer';
import { Button } from '@/components/ui/Button';
import { Tabs } from '@/components/ui/Tabs';
import { Card, CardContent } from '@/components/ui/Card';
import { Badge, getStatusVariant } from '@/components/ui/Badge';
import { PageLoader } from '@/components/ui/Spinner';
import { NoListingsEmptyState } from '@/components/ui/EmptyState';
import { Modal, ModalFooter } from '@/components/ui/Modal';
import { useAuthStore } from '@/stores/authStore';
import Image from 'next/image';

const PAGE_SIZE = 20;

/** One tab on the My Listings page. `status` is the server filter sent as a
 *  query param; `null` means "All" (no filter). */
type TabSpec = {
  id: string;
  label: string;
  status: ListingStatus | null;
};

const TABS: TabSpec[] = [
  { id: 'all', label: 'All', status: null },
  { id: 'active', label: 'Active', status: 'ACTIVE' },
  { id: 'draft', label: 'Drafts', status: 'DRAFT' },
  { id: 'pending', label: 'Under Review', status: 'PENDING' },
  { id: 'rejected', label: 'Rejected', status: 'REJECTED' },
  { id: 'sold', label: 'Sold', status: 'SOLD' },
];

/** Per-tab pagination state. Each tab maintains its own items + cursor so
 *  switching tabs doesn't reset the user's progress. */
type TabState = {
  items: Listing[];
  nextCursor: string | null;
  hasMore: boolean;
  total: number;
  isInitialLoading: boolean;
  isLoadingMore: boolean;
  isRefreshing: boolean;
  error: string | null;
};

const emptyTabState: TabState = {
  items: [],
  nextCursor: null,
  hasMore: true,
  total: 0,
  isInitialLoading: true,
  isLoadingMore: false,
  isRefreshing: false,
  error: null,
};

type TabStateMap = Record<string, TabState>;

export default function MyListingsPage() {
  const router = useRouter();
  const { isAuthenticated, isLoading: authLoading } = useAuthStore();

  const [activeTab, setActiveTab] = useState<string>('all');
  const [tabStates, setTabStates] = useState<TabStateMap>(() =>
    Object.fromEntries(TABS.map((t) => [t.id, { ...emptyTabState }])),
  );

  // Set of tab ids that have been fetched at least once. Tabs are loaded
  // lazily on first activation so we don't fire 6 parallel requests at
  // mount.
  const fetchedTabsRef = useRef<Set<string>>(new Set());

  const [selectedListing, setSelectedListing] = useState<Listing | null>(null);
  const [actionModal, setActionModal] = useState<
    'delete' | 'archive' | 'sold' | 'publish' | null
  >(null);
  const [actionLoading, setActionLoading] = useState(false);
  const [actionError, setActionError] = useState<string | null>(null);

  // Auth gate
  useEffect(() => {
    if (!authLoading && !authManager.isAuthenticated()) {
      router.push('/login');
    }
  }, [authLoading, isAuthenticated, router]);

  /** Patch state for one tab. */
  const updateTab = useCallback(
    (tabId: string, patch: Partial<TabState> | ((s: TabState) => Partial<TabState>)) => {
      setTabStates((prev) => {
        const current = prev[tabId] ?? { ...emptyTabState };
        const next = typeof patch === 'function' ? patch(current) : patch;
        return { ...prev, [tabId]: { ...current, ...next } };
      });
    },
    [],
  );

  /** Fetch the first page of a tab. */
  const loadInitial = useCallback(
    async (tab: TabSpec) => {
      fetchedTabsRef.current.add(tab.id);
      updateTab(tab.id, { isInitialLoading: true, error: null });
      try {
        const response = await api.getMyListings({
          status: tab.status ?? undefined,
          limit: PAGE_SIZE,
        });
        updateTab(tab.id, {
          items: response.data ?? [],
          nextCursor: response.nextCursor ?? null,
          hasMore: response.hasMore ?? false,
          total: response.total ?? response.data?.length ?? 0,
          isInitialLoading: false,
          error: null,
        });
      } catch (error) {
        updateTab(tab.id, {
          isInitialLoading: false,
          error: error instanceof Error ? error.message : 'Failed to load listings',
        });
      }
    },
    [updateTab],
  );

  /** Refresh — same as loadInitial but flags isRefreshing instead of
   *  isInitialLoading so the existing list stays visible while reloading. */
  const refresh = useCallback(
    async (tab: TabSpec) => {
      updateTab(tab.id, { isRefreshing: true, error: null });
      try {
        const response = await api.getMyListings({
          status: tab.status ?? undefined,
          limit: PAGE_SIZE,
        });
        updateTab(tab.id, {
          items: response.data ?? [],
          nextCursor: response.nextCursor ?? null,
          hasMore: response.hasMore ?? false,
          total: response.total ?? response.data?.length ?? 0,
          isInitialLoading: false,
          isRefreshing: false,
          error: null,
        });
      } catch (error) {
        updateTab(tab.id, {
          isRefreshing: false,
          error: error instanceof Error ? error.message : 'Failed to refresh',
        });
      }
    },
    [updateTab],
  );

  /** Append the next page. No-op when there's nothing more / a request is
   *  already in flight / we're mid-refresh. */
  const loadMore = useCallback(
    async (tab: TabSpec) => {
      const state = tabStates[tab.id];
      if (!state || !state.hasMore || state.isLoadingMore || state.isRefreshing) return;
      if (!state.nextCursor) return;
      const cursor = state.nextCursor;
      updateTab(tab.id, { isLoadingMore: true, error: null });
      try {
        const response = await api.getMyListings({
          status: tab.status ?? undefined,
          limit: PAGE_SIZE,
          cursor,
        });
        updateTab(tab.id, (current) => ({
          items: [...current.items, ...(response.data ?? [])],
          nextCursor: response.nextCursor ?? null,
          hasMore: response.hasMore ?? false,
          total: response.total ?? current.total,
          isLoadingMore: false,
        }));
      } catch (error) {
        updateTab(tab.id, {
          isLoadingMore: false,
          error: error instanceof Error ? error.message : 'Failed to load more',
        });
      }
    },
    [tabStates, updateTab],
  );

  // Lazy-load the initial page for a tab the first time it becomes active.
  useEffect(() => {
    if (authLoading || !authManager.isAuthenticated()) return;
    const tab = TABS.find((t) => t.id === activeTab);
    if (!tab) return;
    if (!fetchedTabsRef.current.has(tab.id)) {
      void loadInitial(tab);
    }
  }, [activeTab, authLoading, loadInitial]);

  // IntersectionObserver on a sentinel <div> at the end of the list drives
  // infinite scroll. Recreated whenever the active tab changes so the
  // observer targets the current tab's sentinel.
  const sentinelRef = useRef<HTMLDivElement | null>(null);
  useEffect(() => {
    const node = sentinelRef.current;
    if (!node) return;
    const tab = TABS.find((t) => t.id === activeTab);
    if (!tab) return;
    const observer = new IntersectionObserver(
      (entries) => {
        if (entries.some((e) => e.isIntersecting)) {
          void loadMore(tab);
        }
      },
      { rootMargin: '600px 0px' }, // Prefetch well before the user reaches the bottom.
    );
    observer.observe(node);
    return () => observer.disconnect();
  }, [activeTab, loadMore, tabStates[activeTab]?.items.length]);

  // ---- Tab UI list (with counts once loaded) -----------------------------

  const tabsForUi = useMemo(
    () =>
      TABS.map((t) => {
        const s = tabStates[t.id];
        const showCount = s && !s.isInitialLoading && s.total > 0;
        return {
          id: t.id,
          label: t.label,
          count: showCount ? s.total : undefined,
        };
      }),
    [tabStates],
  );

  // ---- Actions: delete / archive / sold / publish ------------------------

  /** After a successful mutation, refresh affected tabs so the UI matches
   *  the server. Refetching is cheap (one page, 20 rows) and avoids the
   *  drift the previous version had when patching local state. */
  const refreshAffectedTabs = useCallback(
    (extra: ListingStatus[] = []) => {
      const affected = new Set<string>(['all', activeTab]);
      for (const s of extra) {
        const target = TABS.find((t) => t.status === s);
        if (target) affected.add(target.id);
      }
      for (const id of affected) {
        const tab = TABS.find((t) => t.id === id);
        if (!tab) continue;
        // Only refresh tabs that have actually been loaded; the lazy-load
        // effect handles first-time activation.
        if (fetchedTabsRef.current.has(tab.id)) {
          void refresh(tab);
        }
      }
    },
    [activeTab, refresh],
  );

  const handleAction = async () => {
    if (!selectedListing || !actionModal) return;
    setActionLoading(true);
    setActionError(null);
    try {
      if (actionModal === 'delete') {
        await api.deleteListing(selectedListing.id);
        refreshAffectedTabs();
      } else if (actionModal === 'archive') {
        await api.archiveListing(selectedListing.id);
        refreshAffectedTabs(['ARCHIVED']);
      } else if (actionModal === 'sold') {
        await api.markListingAsSold(selectedListing.id);
        refreshAffectedTabs(['SOLD']);
      } else if (actionModal === 'publish') {
        await api.publishListing(selectedListing.id);
        refreshAffectedTabs(['PENDING']);
      }
      setActionModal(null);
      setSelectedListing(null);
    } catch (error) {
      setActionError(error instanceof Error ? error.message : 'Action failed');
    } finally {
      setActionLoading(false);
    }
  };

  // ---- Render ------------------------------------------------------------

  if (authLoading) {
    return (
      <div className="min-h-screen flex flex-col">
        <Header />
        <PageLoader message="Loading your listings..." />
        <Footer />
      </div>
    );
  }

  const activeState = tabStates[activeTab] ?? emptyTabState;
  const activeTabSpec = TABS.find((t) => t.id === activeTab) ?? TABS[0];

  return (
    <div className="min-h-screen flex flex-col bg-gray-50">
      <Header />

      <main className="flex-1 py-8">
        <div className="max-w-4xl mx-auto px-4">
          <div className="flex items-center justify-between mb-6">
            <h1 className="text-2xl font-bold text-gray-900">My Listings</h1>
            <Link href="/sell">
              <Button>
                <PlusIcon className="w-5 h-5 mr-2" />
                New Listing
              </Button>
            </Link>
          </div>

          <Tabs tabs={tabsForUi} activeTab={activeTab} onChange={setActiveTab} />

          <div className="mt-6">
            {activeState.isInitialLoading ? (
              <PageLoader message="Loading..." />
            ) : activeState.error && activeState.items.length === 0 ? (
              <Card>
                <CardContent className="py-8 text-center">
                  <p className="text-gray-700 mb-4">{activeState.error}</p>
                  <Button onClick={() => refresh(activeTabSpec)}>Retry</Button>
                </CardContent>
              </Card>
            ) : activeState.items.length === 0 ? (
              <NoListingsEmptyState onCreateListing={() => router.push('/sell')} />
            ) : (
              <div className="space-y-4">
                {activeState.items.map((listing) => (
                  <Card key={listing.id}>
                    <CardContent className="py-4">
                      <div className="flex gap-4">
                        <Link href={getListingHref(listing)} className="flex-shrink-0">
                          <div className="relative w-24 h-24 rounded-lg overflow-hidden">
                            {listing.imageUrls[0] ? (
                              <Image
                                src={listing.imageUrls[0]}
                                alt={listing.title}
                                fill
                                className="object-cover"
                              />
                            ) : (
                              <div className="w-full h-full bg-gray-100 flex items-center justify-center">
                                <span className="text-gray-400 text-xs">No image</span>
                              </div>
                            )}
                          </div>
                        </Link>

                        <div className="flex-1 min-w-0">
                          <div className="flex items-start justify-between">
                            <div>
                              <Link
                                href={getListingHref(listing)}
                                className="font-medium text-gray-900 hover:text-primary-500 line-clamp-1"
                              >
                                {listing.title}
                              </Link>
                              <p className="text-lg font-bold text-primary-500 mt-1">
                                {formatPrice(listing.price)}
                              </p>
                            </div>
                            <Badge variant={getStatusVariant(listing.status)}>
                              {STATUS_LABELS[listing.status]}
                            </Badge>
                          </div>

                          <div className="flex items-center gap-4 mt-2 text-sm text-gray-500">
                            <span>{listing.viewCount} views</span>
                            <span>{listing.saveCount} saves</span>
                            <span>Listed {formatRelativeTime(listing.createdAt)}</span>
                          </div>

                          <div className="flex items-center gap-2 mt-3">
                            <Link href={`/sell/${listing.id}/edit`}>
                              <Button variant="outline" size="sm">
                                <PencilIcon className="w-4 h-4 mr-1" />
                                Edit
                              </Button>
                            </Link>

                            {listing.status === 'DRAFT' && (
                              <Button
                                size="sm"
                                onClick={() => {
                                  setSelectedListing(listing);
                                  setActionModal('publish');
                                }}
                              >
                                Publish
                              </Button>
                            )}

                            {listing.status === 'ACTIVE' && (
                              <>
                                <Button
                                  variant="outline"
                                  size="sm"
                                  onClick={() => {
                                    setSelectedListing(listing);
                                    setActionModal('sold');
                                  }}
                                >
                                  <CheckCircleIcon className="w-4 h-4 mr-1" />
                                  Mark Sold
                                </Button>
                                <Button
                                  variant="ghost"
                                  size="sm"
                                  onClick={() => {
                                    setSelectedListing(listing);
                                    setActionModal('archive');
                                  }}
                                >
                                  <ArchiveBoxIcon className="w-4 h-4 mr-1" />
                                  Archive
                                </Button>
                              </>
                            )}

                            <Button
                              variant="ghost"
                              size="sm"
                              onClick={() => {
                                setSelectedListing(listing);
                                setActionModal('delete');
                              }}
                              className="text-red-600 hover:text-red-700 hover:bg-red-50"
                            >
                              <TrashIcon className="w-4 h-4" />
                            </Button>
                          </div>
                        </div>
                      </div>
                    </CardContent>
                  </Card>
                ))}

                {/* Infinite-scroll sentinel + trailing state. */}
                <div ref={sentinelRef} aria-hidden="true" />

                {activeState.isLoadingMore && (
                  <p className="py-4 text-center text-sm text-gray-500">
                    Loading more…
                  </p>
                )}
                {!activeState.hasMore && activeState.items.length > 0 && (
                  <p className="py-4 text-center text-sm text-gray-400">
                    You&apos;ve reached the end.
                  </p>
                )}
                {activeState.error && activeState.items.length > 0 && (
                  <div className="py-4 text-center">
                    <p className="text-sm text-red-600 mb-2">{activeState.error}</p>
                    <Button variant="outline" size="sm" onClick={() => loadMore(activeTabSpec)}>
                      Retry
                    </Button>
                  </div>
                )}
              </div>
            )}
          </div>
        </div>
      </main>

      <Footer />

      {actionModal && selectedListing && (
        <Modal
          isOpen={!!actionModal}
          onClose={() => {
            setActionModal(null);
            setSelectedListing(null);
            setActionError(null);
          }}
          title={
            actionModal === 'delete'
              ? 'Delete Listing'
              : actionModal === 'archive'
              ? 'Archive Listing'
              : actionModal === 'publish'
              ? 'Publish Listing'
              : 'Mark as Sold'
          }
          size="sm"
        >
          <p className="text-gray-600">
            {actionModal === 'delete' && (
              <>
                Are you sure you want to delete &quot;{selectedListing.title}&quot;? This action cannot be undone.
              </>
            )}
            {actionModal === 'archive' && (
              <>
                Archive &quot;{selectedListing.title}&quot;? It will be hidden from buyers but you can restore it later.
              </>
            )}
            {actionModal === 'sold' && (
              <>
                Mark &quot;{selectedListing.title}&quot; as sold? This will remove it from active listings.
              </>
            )}
            {actionModal === 'publish' && (
              <>
                Publish &quot;{selectedListing.title}&quot;? It will be submitted for review before going live.
              </>
            )}
          </p>

          {actionError && (
            <p className="text-sm text-red-600 mt-3">{actionError}</p>
          )}

          <ModalFooter>
            <Button
              variant="outline"
              onClick={() => {
                setActionModal(null);
                setSelectedListing(null);
                setActionError(null);
              }}
            >
              Cancel
            </Button>
            <Button
              onClick={handleAction}
              loading={actionLoading}
              className={actionModal === 'delete' ? 'bg-red-600 hover:bg-red-700' : ''}
            >
              {actionModal === 'delete' && 'Delete'}
              {actionModal === 'archive' && 'Archive'}
              {actionModal === 'sold' && 'Mark Sold'}
              {actionModal === 'publish' && 'Publish'}
            </Button>
          </ModalFooter>
        </Modal>
      )}
    </div>
  );
}
