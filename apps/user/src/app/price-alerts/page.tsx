'use client';

import { useState, useEffect } from 'react';
import { useRouter } from 'next/navigation';
import Link from 'next/link';
import Image from 'next/image';
import {
  BellAlertIcon,
  TrashIcon,
  ArrowTrendingDownIcon,
  TagIcon,
} from '@heroicons/react/24/outline';
import { api } from '@/lib/api';
import { PriceAlert } from '@/types';
import { formatPrice, formatRelativeTime } from '@/lib/utils';
import Header from '@/components/layout/Header';
import Footer from '@/components/layout/Footer';
import { Button } from '@/components/ui/Button';
import { Card, CardContent } from '@/components/ui/Card';
import { Badge } from '@/components/ui/Badge';
import { PageLoader } from '@/components/ui/Spinner';
import { Modal, ModalFooter } from '@/components/ui/Modal';
import { useAuthStore } from '@/stores/authStore';

export default function PriceAlertsPage() {
  const router = useRouter();
  const { isAuthenticated, isLoading: authLoading } = useAuthStore();

  const [priceAlerts, setPriceAlerts] = useState<PriceAlert[]>([]);
  const [loading, setLoading] = useState(true);
  const [deleteAlertId, setDeleteAlertId] = useState<string | null>(null);
  const [deleteLoading, setDeleteLoading] = useState(false);

  useEffect(() => {
    if (!authLoading && !isAuthenticated) {
      router.push('/login');
      return;
    }

    if (isAuthenticated) {
      loadPriceAlerts();
    }
  }, [authLoading, isAuthenticated]);

  const loadPriceAlerts = async () => {
    try {
      setLoading(true);
      const data = await api.getPriceAlerts();
      setPriceAlerts(data);
    } catch (error) {
      console.error('Error loading price alerts:', error);
    } finally {
      setLoading(false);
    }
  };

  const handleDelete = async () => {
    if (!deleteAlertId) return;

    setDeleteLoading(true);
    try {
      await api.deletePriceAlert(deleteAlertId);
      setPriceAlerts(priceAlerts.filter((a) => a.id !== deleteAlertId));
      setDeleteAlertId(null);
    } catch (error) {
      console.error('Error deleting price alert:', error);
    } finally {
      setDeleteLoading(false);
    }
  };

  const handleMarkAsRead = async (alertId: string) => {
    try {
      await api.markPriceAlertAsRead(alertId);
      setPriceAlerts(
        priceAlerts.map((a) => (a.id === alertId ? { ...a, isRead: true } : a))
      );
    } catch (error) {
      console.error('Error marking alert as read:', error);
    }
  };

  const getStatusBadge = (alert: PriceAlert) => {
    if (alert.isExpired) {
      return <Badge variant="default">Expired</Badge>;
    }
    if (!alert.isRead) {
      return <Badge variant="success">New</Badge>;
    }
    return <Badge variant="info">Price Drop</Badge>;
  };

  if (authLoading || loading) {
    return (
      <div className="min-h-screen flex flex-col">
        <Header />
        <PageLoader message="Loading price alerts..." />
        <Footer />
      </div>
    );
  }

  return (
    <div className="min-h-screen flex flex-col bg-gray-50 dark:bg-gray-900">
      <Header />

      <main className="flex-1 py-8">
        <div className="max-w-3xl mx-auto px-4">
          {/* Header */}
          <div className="mb-6">
            <h1 className="text-2xl font-bold text-gray-900 dark:text-gray-100">Price Alerts</h1>
            <p className="text-gray-500 dark:text-gray-400 mt-1">
              Notifications when items you&apos;ve saved drop in price
            </p>
          </div>

          {/* Price Alerts List */}
          {priceAlerts.length === 0 ? (
            <Card>
              <CardContent className="py-12 text-center">
                <BellAlertIcon className="w-12 h-12 text-gray-300 mx-auto mb-4" />
                <h3 className="text-lg font-medium text-gray-900 dark:text-gray-100 mb-2">
                  No price alerts yet
                </h3>
                <p className="text-gray-500 dark:text-gray-400 mb-6">
                  Save items you like - we&apos;ll notify you when their prices drop
                </p>
                <Button onClick={() => router.push('/')}>
                  Browse Listings
                </Button>
              </CardContent>
            </Card>
          ) : (
            <div className="space-y-4">
              {priceAlerts.map((alert) => (
                <Card
                  key={alert.id}
                  className={!alert.isRead ? 'ring-2 ring-primary-200 dark:ring-primary-700' : ''}
                >
                  <CardContent className="py-4">
                    <div className="flex gap-4">
                      {/* Listing Image */}
                      <Link
                        href={`/listing/${alert.listingId}`}
                        className="relative w-20 h-20 rounded-lg overflow-hidden flex-shrink-0"
                        onClick={() => !alert.isRead && handleMarkAsRead(alert.id)}
                      >
                        {alert.listingImageUrl ? (
                          <Image
                            src={alert.listingImageUrl}
                            alt={alert.listingTitle}
                            fill
                            className="object-cover"
                          />
                        ) : (
                          <div className="w-full h-full bg-gray-200 flex items-center justify-center">
                            <TagIcon className="w-8 h-8 text-gray-400" />
                          </div>
                        )}
                      </Link>

                      {/* Alert Details */}
                      <div className="flex-1 min-w-0">
                        <div className="flex items-start justify-between gap-2">
                          <Link
                            href={`/listing/${alert.listingId}`}
                            className="font-medium text-gray-900 dark:text-gray-100 hover:text-primary-500 dark:hover:text-primary-300 truncate"
                            onClick={() => !alert.isRead && handleMarkAsRead(alert.id)}
                          >
                            {alert.listingTitle}
                          </Link>
                          {getStatusBadge(alert)}
                        </div>

                        {/* Seller Info */}
                        <p className="text-sm text-gray-500 dark:text-gray-400 mt-1">
                          by {alert.sellerName}
                        </p>

                        {/* Price Info */}
                        <div className="mt-2 space-y-1">
                          <div className="flex items-center gap-2 text-sm">
                            <span className="text-gray-400 line-through">
                              {formatPrice(alert.originalPrice)}
                            </span>
                            <span className="font-bold text-primary-500 dark:text-primary-400">
                              {formatPrice(alert.newPrice)}
                            </span>
                          </div>

                          <div className="flex items-center gap-1 text-sm text-green-600">
                            <ArrowTrendingDownIcon className="w-4 h-4" />
                            <span>
                              Price dropped {Math.round(alert.priceDropPercent)}% (
                              {formatPrice(alert.priceDropAmount)} off)
                            </span>
                          </div>
                        </div>

                        {/* Meta */}
                        <p className="text-xs text-gray-400 dark:text-gray-500 mt-2">
                          {formatRelativeTime(alert.createdAt)}
                        </p>
                      </div>

                      {/* Actions */}
                      <div className="flex flex-col gap-2">
                        <Link href={`/listing/${alert.listingId}`}>
                          <Button
                            variant="outline"
                            size="sm"
                            onClick={() => !alert.isRead && handleMarkAsRead(alert.id)}
                          >
                            View
                          </Button>
                        </Link>
                        <button
                          onClick={() => setDeleteAlertId(alert.id)}
                          className="p-2 hover:bg-gray-100 rounded-lg text-gray-400 hover:text-red-500"
                        >
                          <TrashIcon className="w-5 h-5" />
                        </button>
                      </div>
                    </div>
                  </CardContent>
                </Card>
              ))}
            </div>
          )}

          {/* How it works */}
          <div className="mt-8 p-6 bg-white dark:bg-gray-800 rounded-lg border border-gray-200 dark:border-gray-700">
            <h3 className="font-medium text-gray-900 dark:text-gray-100 mb-4">How price alerts work</h3>
            <ul className="space-y-3 text-sm text-gray-600 dark:text-gray-300">
              <li className="flex items-start gap-3">
                <span className="w-6 h-6 rounded-full bg-primary-100 dark:bg-primary-900 text-primary-500 dark:text-primary-300 flex items-center justify-center flex-shrink-0 text-xs font-medium">
                  1
                </span>
                <span>
                  Save items you like by clicking the heart icon
                </span>
              </li>
              <li className="flex items-start gap-3">
                <span className="w-6 h-6 rounded-full bg-primary-100 dark:bg-primary-900 text-primary-500 dark:text-primary-300 flex items-center justify-center flex-shrink-0 text-xs font-medium">
                  2
                </span>
                <span>
                  When a seller reduces the price by 5% or more, you&apos;ll get notified
                </span>
              </li>
              <li className="flex items-start gap-3">
                <span className="w-6 h-6 rounded-full bg-primary-100 dark:bg-primary-900 text-primary-500 dark:text-primary-300 flex items-center justify-center flex-shrink-0 text-xs font-medium">
                  3
                </span>
                <span>
                  Act fast! Great deals don&apos;t last long
                </span>
              </li>
            </ul>
          </div>

          {/* Tips */}
          <div className="mt-4 p-4 bg-blue-50 rounded-lg">
            <p className="text-sm text-blue-800">
              <strong>Tip:</strong> Enable price alerts in your settings to receive
              push notifications when prices drop.
            </p>
          </div>
        </div>
      </main>

      <Footer />

      {/* Delete Confirmation Modal */}
      <Modal
        isOpen={!!deleteAlertId}
        onClose={() => setDeleteAlertId(null)}
        title="Delete Price Alert"
        size="sm"
      >
        <p className="text-gray-600 dark:text-gray-300">
          Are you sure you want to delete this price alert? This action cannot be
          undone.
        </p>

        <ModalFooter>
          <Button variant="outline" onClick={() => setDeleteAlertId(null)}>
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
