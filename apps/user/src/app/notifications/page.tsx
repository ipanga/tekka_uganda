'use client';

import { useState, useEffect } from 'react';
import { useRouter } from 'next/navigation';
import Link from 'next/link';
import {
  ChatBubbleLeftRightIcon,
  CheckCircleIcon,
  XCircleIcon,
  TagIcon,
  StarIcon,
  MapPinIcon,
  BellIcon,
  TrashIcon,
} from '@heroicons/react/24/outline';
import { api } from '@/lib/api';
import { Notification, NotificationType } from '@/types';
import { formatRelativeTime, cn } from '@/lib/utils';
import Header from '@/components/layout/Header';
import Footer from '@/components/layout/Footer';
import { Button } from '@/components/ui/Button';
import { Card, CardContent } from '@/components/ui/Card';
import { PageLoader } from '@/components/ui/Spinner';
import { NoNotificationsEmptyState } from '@/components/ui/EmptyState';
import { useAuthStore } from '@/stores/authStore';
import { useNotificationStore } from '@/stores/notificationStore';

const NOTIFICATION_ICONS: Record<NotificationType, React.ReactNode> = {
  MESSAGE: <ChatBubbleLeftRightIcon className="w-5 h-5" />,
  LISTING_APPROVED: <CheckCircleIcon className="w-5 h-5 text-green-500" />,
  LISTING_REJECTED: <XCircleIcon className="w-5 h-5 text-red-500" />,
  LISTING_SOLD: <TagIcon className="w-5 h-5 text-primary-500 dark:text-primary-400" />,
  PRICE_DROP: <TagIcon className="w-5 h-5 text-green-500" />,
  NEW_REVIEW: <StarIcon className="w-5 h-5 text-yellow-500" />,
  MEETUP_PROPOSED: <MapPinIcon className="w-5 h-5" />,
  MEETUP_ACCEPTED: <MapPinIcon className="w-5 h-5 text-green-500" />,
  SYSTEM: <BellIcon className="w-5 h-5" />,
};

export default function NotificationsPage() {
  const router = useRouter();
  const { isAuthenticated, isLoading: authLoading } = useAuthStore();
  const {
    notifications,
    setNotifications,
    markAsRead,
    markAllAsRead,
    removeNotification,
  } = useNotificationStore();

  const [loading, setLoading] = useState(true);

  useEffect(() => {
    if (!authLoading && !isAuthenticated) {
      router.push('/login');
      return;
    }

    if (isAuthenticated) {
      loadNotifications();
    }
  }, [authLoading, isAuthenticated]);

  const loadNotifications = async () => {
    try {
      setLoading(true);
      const response = await api.getNotifications();
      setNotifications(response.data || []);
    } catch (error) {
      console.error('Error loading notifications:', error);
    } finally {
      setLoading(false);
    }
  };

  const handleMarkAsRead = async (notification: Notification) => {
    if (notification.isRead) return;

    try {
      await api.markNotificationAsRead(notification.id);
      markAsRead(notification.id);
    } catch (error) {
      console.error('Error marking as read:', error);
    }
  };

  const handleMarkAllAsRead = async () => {
    try {
      await api.markAllNotificationsAsRead();
      markAllAsRead();
    } catch (error) {
      console.error('Error marking all as read:', error);
    }
  };

  const handleDelete = async (notification: Notification) => {
    try {
      await api.deleteNotification(notification.id);
      removeNotification(notification.id);
    } catch (error) {
      console.error('Error deleting notification:', error);
    }
  };

  const getNotificationLink = (notification: Notification): string | undefined => {
    const data = notification.data;
    if (!data) return undefined;

    if (data.chatId) return `/messages/${data.chatId}`;
    if (data.listingId) return `/listing/${data.listingId}`;
    if (data.userId) return `/profile/${data.userId}`;
    return undefined;
  };

  if (authLoading || loading) {
    return (
      <div className="min-h-screen flex flex-col">
        <Header />
        <PageLoader message="Loading notifications..." />
        <Footer />
      </div>
    );
  }

  const unreadCount = notifications.filter((n) => !n.isRead).length;

  return (
    <div className="min-h-screen flex flex-col bg-gray-50 dark:bg-gray-900">
      <Header />

      <main className="flex-1 py-8">
        <div className="max-w-3xl mx-auto px-4">
          {/* Header */}
          <div className="flex items-center justify-between mb-6">
            <div>
              <h1 className="text-2xl font-bold text-gray-900 dark:text-gray-100">Notifications</h1>
              {unreadCount > 0 && (
                <p className="text-gray-500 dark:text-gray-400 mt-1">{unreadCount} unread</p>
              )}
            </div>
            {unreadCount > 0 && (
              <Button variant="outline" size="sm" onClick={handleMarkAllAsRead}>
                Mark all as read
              </Button>
            )}
          </div>

          {/* Notifications List */}
          {notifications.length === 0 ? (
            <NoNotificationsEmptyState />
          ) : (
            <div className="space-y-2">
              {notifications.map((notification) => {
                const link = getNotificationLink(notification);
                const content = (
                  <div
                    className={cn(
                      'flex items-start gap-4 py-4',
                      !notification.isRead && 'bg-primary-50 dark:bg-primary-900/20'
                    )}
                  >
                    {/* Icon */}
                    <div
                      className={cn(
                        'p-2 rounded-full flex-shrink-0',
                        notification.isRead ? 'bg-gray-100 dark:bg-gray-700' : 'bg-primary-100 dark:bg-primary-900'
                      )}
                    >
                      {NOTIFICATION_ICONS[notification.type]}
                    </div>

                    {/* Content */}
                    <div className="flex-1 min-w-0">
                      <p
                        className={cn(
                          'font-medium',
                          notification.isRead ? 'text-gray-700 dark:text-gray-300' : 'text-gray-900 dark:text-gray-100'
                        )}
                      >
                        {notification.title}
                      </p>
                      <p className="text-sm text-gray-500 dark:text-gray-400 mt-1">{notification.body}</p>
                      <p className="text-xs text-gray-400 dark:text-gray-500 mt-2">
                        {formatRelativeTime(notification.createdAt)}
                      </p>
                    </div>

                    {/* Actions */}
                    <div className="flex items-center gap-2">
                      {!notification.isRead && (
                        <div className="w-2 h-2 bg-primary-500 dark:bg-primary-400 rounded-full" />
                      )}
                      <button
                        onClick={(e) => {
                          e.preventDefault();
                          e.stopPropagation();
                          handleDelete(notification);
                        }}
                        className="p-1 hover:bg-gray-200 dark:hover:bg-gray-700 rounded"
                      >
                        <TrashIcon className="w-4 h-4 text-gray-400" />
                      </button>
                    </div>
                  </div>
                );

                return (
                  <Card key={notification.id}>
                    <CardContent className="py-0">
                      {link ? (
                        <Link
                          href={link}
                          onClick={() => handleMarkAsRead(notification)}
                        >
                          {content}
                        </Link>
                      ) : (
                        <div onClick={() => handleMarkAsRead(notification)}>
                          {content}
                        </div>
                      )}
                    </CardContent>
                  </Card>
                );
              })}
            </div>
          )}
        </div>
      </main>

      <Footer />
    </div>
  );
}
