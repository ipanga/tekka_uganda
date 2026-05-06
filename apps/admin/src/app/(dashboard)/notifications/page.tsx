'use client';

import { useEffect, useMemo, useState } from 'react';
import {
  BellIcon,
  PaperAirplaneIcon,
  UsersIcon,
  TagIcon,
  CheckCircleIcon,
  ExclamationCircleIcon,
} from '@heroicons/react/24/outline';
import { api } from '@/lib/api';
import type { Broadcast, BroadcastAudience, BroadcastRole } from '@/types';
import { Card, CardContent, CardHeader, CardTitle } from '@/components/ui/Card';
import { Button } from '@/components/ui/Button';
import { Badge } from '@/components/ui/Badge';
import {
  Table,
  TableHeader,
  TableBody,
  TableRow,
  TableHead,
  TableCell,
} from '@/components/ui/Table';

type BroadcastListItem = Broadcast;

type ListingHit = { id: string; title: string; price: number };

const AUDIENCE_OPTIONS: { value: BroadcastAudience; label: string }[] = [
  { value: 'ALL', label: 'All Users' },
  { value: 'ROLE', label: 'By Role' },
  { value: 'SPECIFIC', label: 'Specific Users' },
];

const ROLE_OPTIONS: { value: BroadcastRole; label: string }[] = [
  { value: 'USER', label: 'Users' },
  { value: 'ADMIN', label: 'Admins' },
  { value: 'MODERATOR', label: 'Moderators' },
];

function formatDate(dateStr: string) {
  return new Date(dateStr).toLocaleDateString('en-UG', {
    year: 'numeric',
    month: 'short',
    day: 'numeric',
    hour: '2-digit',
    minute: '2-digit',
  });
}

function audienceLabel(b: BroadcastListItem) {
  if (b.audience === 'ALL') return 'All Users';
  if (b.audience === 'ROLE') return `${b.role}s`;
  return 'Specific Users';
}

export default function NotificationsPage() {
  const [broadcasts, setBroadcasts] = useState<BroadcastListItem[]>([]);
  const [loading, setLoading] = useState(true);
  const [loadError, setLoadError] = useState<string | null>(null);
  const [showCreate, setShowCreate] = useState(false);
  const [toast, setToast] = useState<
    | { kind: 'success'; message: string }
    | { kind: 'error'; message: string }
    | null
  >(null);

  const loadBroadcasts = async () => {
    try {
      setLoading(true);
      setLoadError(null);
      const response = await api.getBroadcasts({ limit: 20 });
      setBroadcasts(response.data ?? []);
    } catch (err) {
      console.error('Error loading broadcasts:', err);
      setLoadError('Failed to load broadcast history.');
    } finally {
      setLoading(false);
    }
  };

  useEffect(() => {
    loadBroadcasts();
  }, []);

  useEffect(() => {
    if (!toast) return;
    const t = setTimeout(() => setToast(null), 4000);
    return () => clearTimeout(t);
  }, [toast]);

  const stats = useMemo(() => {
    const totalRecipients = broadcasts.reduce(
      (sum, b) => sum + (b.recipientCount ?? 0),
      0,
    );
    const totalReads = broadcasts.reduce(
      (sum, b) => sum + (b.readCount ?? 0),
      0,
    );
    const overallReadRate =
      totalRecipients > 0
        ? Math.round((totalReads / totalRecipients) * 100)
        : 0;
    return {
      total: broadcasts.length,
      totalRecipients,
      overallReadRate,
    };
  }, [broadcasts]);

  return (
    <div className="space-y-6">
      <div className="flex items-center justify-between">
        <div>
          <h1 className="text-2xl font-bold text-gray-900">Notifications</h1>
          <p className="text-gray-500">Send broadcasts and product alerts to users</p>
        </div>
        <Button onClick={() => setShowCreate(true)}>
          <PaperAirplaneIcon className="w-5 h-5 mr-2" />
          New Broadcast
        </Button>
      </div>

      {/* Stats */}
      <div className="grid grid-cols-1 md:grid-cols-3 gap-6">
        <StatCard
          icon={<PaperAirplaneIcon className="w-6 h-6 text-primary-500" />}
          tint="bg-primary-100"
          value={stats.total}
          label="Broadcasts Sent"
        />
        <StatCard
          icon={<UsersIcon className="w-6 h-6 text-green-600" />}
          tint="bg-green-100"
          value={stats.totalRecipients.toLocaleString()}
          label="Total Recipients"
        />
        <StatCard
          icon={<BellIcon className="w-6 h-6 text-amber-600" />}
          tint="bg-amber-100"
          value={`${stats.overallReadRate}%`}
          label="Average Read Rate"
        />
      </div>

      {/* History Table */}
      <Card>
        <CardHeader>
          <CardTitle>Broadcast History</CardTitle>
        </CardHeader>
        <CardContent>
          {loading ? (
            <div className="flex justify-center py-8">
              <div className="animate-spin rounded-full h-8 w-8 border-b-2 border-primary-500"></div>
            </div>
          ) : loadError ? (
            <div className="text-center py-8 text-red-600">{loadError}</div>
          ) : broadcasts.length === 0 ? (
            <div className="text-center py-8">
              <BellIcon className="w-12 h-12 text-gray-300 mx-auto mb-4" />
              <p className="text-gray-500">No broadcasts sent yet</p>
            </div>
          ) : (
            <Table>
              <TableHeader>
                <TableRow>
                  <TableHead>Broadcast</TableHead>
                  <TableHead>Audience</TableHead>
                  <TableHead>Linked product</TableHead>
                  <TableHead>Recipients</TableHead>
                  <TableHead>Read rate</TableHead>
                  <TableHead>Sent</TableHead>
                </TableRow>
              </TableHeader>
              <TableBody>
                {broadcasts.map((b) => {
                  const rate =
                    b.recipientCount > 0
                      ? Math.round((b.readCount / b.recipientCount) * 100)
                      : 0;
                  return (
                    <TableRow key={b.id}>
                      <TableCell>
                        <div className="max-w-xs">
                          <p className="font-medium text-gray-900 truncate">
                            {b.title}
                          </p>
                          <p className="text-sm text-gray-500 truncate">
                            {b.body}
                          </p>
                        </div>
                      </TableCell>
                      <TableCell>
                        <span className="text-gray-900">{audienceLabel(b)}</span>
                      </TableCell>
                      <TableCell>
                        {b.listingId ? (
                          <Badge variant="info">
                            <TagIcon className="w-3.5 h-3.5 mr-1 inline" />
                            {b.listingId.slice(0, 8)}…
                          </Badge>
                        ) : (
                          <span className="text-gray-400">—</span>
                        )}
                      </TableCell>
                      <TableCell>
                        <span className="font-medium">
                          {b.recipientCount.toLocaleString()}
                        </span>
                      </TableCell>
                      <TableCell>
                        <div className="flex items-center gap-2">
                          <span className="font-medium">{rate}%</span>
                          <span className="text-sm text-gray-500">
                            ({b.readCount.toLocaleString()} read)
                          </span>
                        </div>
                      </TableCell>
                      <TableCell>
                        <p className="text-gray-900 text-sm">
                          {formatDate(b.createdAt)}
                        </p>
                        {b.createdBy?.displayName && (
                          <p className="text-xs text-gray-500">
                            by {b.createdBy.displayName}
                          </p>
                        )}
                      </TableCell>
                    </TableRow>
                  );
                })}
              </TableBody>
            </Table>
          )}
        </CardContent>
      </Card>

      {showCreate && (
        <CreateBroadcastModal
          onClose={() => setShowCreate(false)}
          onSent={(succeeded, total) => {
            setShowCreate(false);
            setToast({
              kind: 'success',
              message: `Broadcast sent to ${succeeded.toLocaleString()} of ${total.toLocaleString()} users.`,
            });
            loadBroadcasts();
          }}
          onError={(message) => setToast({ kind: 'error', message })}
        />
      )}

      {toast && (
        <div
          className={`fixed bottom-6 right-6 z-50 flex items-center gap-3 px-4 py-3 rounded-lg shadow-lg text-white ${
            toast.kind === 'success' ? 'bg-green-600' : 'bg-red-600'
          }`}
        >
          {toast.kind === 'success' ? (
            <CheckCircleIcon className="w-5 h-5" />
          ) : (
            <ExclamationCircleIcon className="w-5 h-5" />
          )}
          <span>{toast.message}</span>
        </div>
      )}
    </div>
  );
}

function StatCard({
  icon,
  tint,
  value,
  label,
}: {
  icon: React.ReactNode;
  tint: string;
  value: string | number;
  label: string;
}) {
  return (
    <Card>
      <CardContent className="py-4">
        <div className="flex items-center gap-4">
          <div className={`p-3 rounded-lg ${tint}`}>{icon}</div>
          <div>
            <p className="text-2xl font-bold text-gray-900">{value}</p>
            <p className="text-sm text-gray-500">{label}</p>
          </div>
        </div>
      </CardContent>
    </Card>
  );
}

function CreateBroadcastModal({
  onClose,
  onSent,
  onError,
}: {
  onClose: () => void;
  onSent: (succeeded: number, total: number) => void;
  onError: (message: string) => void;
}) {
  const [title, setTitle] = useState('');
  const [body, setBody] = useState('');
  const [audience, setAudience] = useState<BroadcastAudience>('ALL');
  const [role, setRole] = useState<BroadcastRole>('USER');
  const [userIdsRaw, setUserIdsRaw] = useState('');
  const [listing, setListing] = useState<ListingHit | null>(null);
  const [audienceCount, setAudienceCount] = useState<number | null>(null);
  const [submitting, setSubmitting] = useState(false);

  // Audience preview — server resolves the count for ALL/ROLE.
  useEffect(() => {
    if (audience === 'SPECIFIC') {
      const ids = userIdsRaw
        .split(/[\s,]+/)
        .map((s) => s.trim())
        .filter(Boolean);
      setAudienceCount(ids.length);
      return;
    }
    let cancelled = false;
    setAudienceCount(null);
    api
      .getBroadcastAudienceCount(audience, audience === 'ROLE' ? role : undefined)
      .then((r) => {
        if (!cancelled) setAudienceCount(r.count);
      })
      .catch(() => {
        if (!cancelled) setAudienceCount(null);
      });
    return () => {
      cancelled = true;
    };
  }, [audience, role, userIdsRaw]);

  const canSubmit =
    !submitting &&
    title.trim().length > 0 &&
    body.trim().length > 0 &&
    (audience !== 'SPECIFIC' || userIdsRaw.trim().length > 0);

  const handleSubmit = async () => {
    setSubmitting(true);
    try {
      const payload = {
        title: title.trim(),
        body: body.trim(),
        audience,
        ...(audience === 'ROLE' && { role }),
        ...(audience === 'SPECIFIC' && {
          userIds: userIdsRaw
            .split(/[\s,]+/)
            .map((s) => s.trim())
            .filter(Boolean),
        }),
        ...(listing && { listingId: listing.id }),
      };
      const result = (await api.broadcastNotification(payload)) as {
        broadcast: Broadcast;
        result: { succeeded: number; failed: number; total: number };
      };
      onSent(result.result.succeeded, result.result.total);
    } catch (err) {
      console.error('Broadcast failed:', err);
      onError(
        err instanceof Error ? err.message : 'Failed to send broadcast.',
      );
    } finally {
      setSubmitting(false);
    }
  };

  return (
    <div className="fixed inset-0 bg-black/50 flex items-center justify-center z-50">
      <div className="bg-white rounded-lg p-6 max-w-lg w-full mx-4 max-h-[90vh] overflow-y-auto">
        <h3 className="text-lg font-bold text-gray-900 mb-4">New Broadcast</h3>

        <div className="space-y-4">
          <div>
            <label className="block text-sm font-medium text-gray-700 mb-1">
              Title
            </label>
            <input
              type="text"
              value={title}
              onChange={(e) => setTitle(e.target.value)}
              className="w-full px-3 py-2 border border-gray-300 rounded-lg focus:outline-none focus:ring-2 focus:ring-primary-500"
              placeholder="Notification title…"
            />
          </div>

          <div>
            <label className="block text-sm font-medium text-gray-700 mb-1">
              Message
            </label>
            <textarea
              value={body}
              onChange={(e) => setBody(e.target.value)}
              className="w-full px-3 py-2 border border-gray-300 rounded-lg focus:outline-none focus:ring-2 focus:ring-primary-500"
              rows={4}
              placeholder="Notification message…"
            />
          </div>

          <div>
            <label className="block text-sm font-medium text-gray-700 mb-1">
              Audience
            </label>
            <select
              value={audience}
              onChange={(e) => setAudience(e.target.value as BroadcastAudience)}
              className="w-full px-3 py-2 border border-gray-300 rounded-lg focus:outline-none focus:ring-2 focus:ring-primary-500"
            >
              {AUDIENCE_OPTIONS.map((o) => (
                <option key={o.value} value={o.value}>
                  {o.label}
                </option>
              ))}
            </select>
          </div>

          {audience === 'ROLE' && (
            <div>
              <label className="block text-sm font-medium text-gray-700 mb-1">
                Role
              </label>
              <select
                value={role}
                onChange={(e) => setRole(e.target.value as BroadcastRole)}
                className="w-full px-3 py-2 border border-gray-300 rounded-lg focus:outline-none focus:ring-2 focus:ring-primary-500"
              >
                {ROLE_OPTIONS.map((o) => (
                  <option key={o.value} value={o.value}>
                    {o.label}
                  </option>
                ))}
              </select>
            </div>
          )}

          {audience === 'SPECIFIC' && (
            <div>
              <label className="block text-sm font-medium text-gray-700 mb-1">
                User IDs
              </label>
              <textarea
                value={userIdsRaw}
                onChange={(e) => setUserIdsRaw(e.target.value)}
                className="w-full px-3 py-2 border border-gray-300 rounded-lg focus:outline-none focus:ring-2 focus:ring-primary-500 font-mono text-sm"
                rows={3}
                placeholder="Comma- or whitespace-separated user IDs"
              />
            </div>
          )}

          <ProductPicker selected={listing} onChange={setListing} />

          <div className="rounded-md bg-gray-50 px-3 py-2 text-sm text-gray-700 flex items-center gap-2">
            <UsersIcon className="w-4 h-4 text-gray-500" />
            {audienceCount === null
              ? 'Calculating audience…'
              : `Will reach ${audienceCount.toLocaleString()} user${
                  audienceCount === 1 ? '' : 's'
                }`}
          </div>
        </div>

        <div className="flex justify-end gap-2 mt-6">
          <Button variant="secondary" onClick={onClose} disabled={submitting}>
            Cancel
          </Button>
          <Button onClick={handleSubmit} disabled={!canSubmit}>
            {submitting ? 'Sending…' : 'Send broadcast'}
          </Button>
        </div>
      </div>
    </div>
  );
}

function ProductPicker({
  selected,
  onChange,
}: {
  selected: ListingHit | null;
  onChange: (l: ListingHit | null) => void;
}) {
  const [query, setQuery] = useState('');
  const [results, setResults] = useState<ListingHit[]>([]);
  const [searching, setSearching] = useState(false);

  useEffect(() => {
    if (selected || query.trim().length < 2) return;
    let cancelled = false;
    const t = setTimeout(() => {
      setSearching(true);
      api
        .searchListingsForBroadcast(query.trim(), 8)
        .then((r) => {
          if (!cancelled) setResults(r.data ?? []);
        })
        .catch(() => {
          if (!cancelled) setResults([]);
        })
        .finally(() => {
          if (!cancelled) setSearching(false);
        });
    }, 250);
    return () => {
      cancelled = true;
      clearTimeout(t);
    };
  }, [query, selected]);

  // Reset cached results when picker becomes hidden or query is cleared.
  const resultsToShow =
    selected || query.trim().length < 2 ? [] : results;

  return (
    <div>
      <label className="block text-sm font-medium text-gray-700 mb-1">
        Linked product (optional)
      </label>
      {selected ? (
        <div className="flex items-center justify-between rounded-lg border border-gray-300 px-3 py-2">
          <div className="min-w-0">
            <p className="font-medium text-gray-900 truncate">{selected.title}</p>
            <p className="text-xs text-gray-500 font-mono">{selected.id}</p>
          </div>
          <button
            type="button"
            onClick={() => {
              onChange(null);
              setQuery('');
            }}
            className="text-sm text-gray-500 hover:text-gray-700 ml-2"
          >
            Remove
          </button>
        </div>
      ) : (
        <>
          <input
            type="text"
            value={query}
            onChange={(e) => setQuery(e.target.value)}
            className="w-full px-3 py-2 border border-gray-300 rounded-lg focus:outline-none focus:ring-2 focus:ring-primary-500"
            placeholder="Search by listing title…"
          />
          {query.trim().length >= 2 && (
            <div className="mt-2 border border-gray-200 rounded-lg max-h-40 overflow-y-auto">
              {searching ? (
                <p className="px-3 py-2 text-sm text-gray-500">Searching…</p>
              ) : resultsToShow.length === 0 ? (
                <p className="px-3 py-2 text-sm text-gray-500">No matches.</p>
              ) : (
                resultsToShow.map((r) => (
                  <button
                    key={r.id}
                    type="button"
                    onClick={() => onChange(r)}
                    className="w-full text-left px-3 py-2 hover:bg-gray-50 border-b border-gray-100 last:border-0"
                  >
                    <p className="text-sm font-medium text-gray-900 truncate">
                      {r.title}
                    </p>
                    <p className="text-xs text-gray-500">
                      UGX {r.price.toLocaleString()}
                    </p>
                  </button>
                ))
              )}
            </div>
          )}
        </>
      )}
    </div>
  );
}
