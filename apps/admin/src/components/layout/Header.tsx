'use client';

import { useState, useEffect, useRef } from 'react';
import { useRouter } from 'next/navigation';
import { useTheme } from 'next-themes';
import {
  BellIcon,
  MagnifyingGlassIcon,
  ClipboardDocumentListIcon,
  FlagIcon,
  ShieldCheckIcon,
  SunIcon,
  MoonIcon,
} from '@heroicons/react/24/outline';
import { api } from '@/lib/api';

interface HeaderProps {
  title: string;
}

interface AdminNotifications {
  pendingListings: number;
  pendingReports: number;
  pendingVerifications: number;
  total: number;
}

export function Header({ title }: HeaderProps) {
  const router = useRouter();
  const { resolvedTheme, setTheme } = useTheme();
  const [mounted, setMounted] = useState(false);
  const [notifications, setNotifications] = useState<AdminNotifications>({
    pendingListings: 0,
    pendingReports: 0,
    pendingVerifications: 0,
    total: 0,
  });
  const [showDropdown, setShowDropdown] = useState(false);
  const [loading, setLoading] = useState(true);
  const dropdownRef = useRef<HTMLDivElement>(null);

  useEffect(() => setMounted(true), []);

  useEffect(() => {
    loadNotifications();
    // Refresh notifications every 30 seconds
    const interval = setInterval(loadNotifications, 30000);
    return () => clearInterval(interval);
  }, []);

  useEffect(() => {
    // Close dropdown when clicking outside
    function handleClickOutside(event: MouseEvent) {
      if (dropdownRef.current && !dropdownRef.current.contains(event.target as Node)) {
        setShowDropdown(false);
      }
    }
    document.addEventListener('mousedown', handleClickOutside);
    return () => document.removeEventListener('mousedown', handleClickOutside);
  }, []);

  const loadNotifications = async () => {
    try {
      const stats = await api.getDashboardStats();
      const pendingListings = stats.pendingListings || 0;
      const pendingReports = stats.pendingReports || 0;
      // Estimate pending verifications (not directly in stats, set to 0)
      const pendingVerifications = 0;

      setNotifications({
        pendingListings,
        pendingReports,
        pendingVerifications,
        total: pendingListings + pendingReports + pendingVerifications,
      });
    } catch (error) {
      console.error('Failed to load notifications:', error);
    } finally {
      setLoading(false);
    }
  };

  const notificationItems = [
    {
      label: 'Pending Listings',
      count: notifications.pendingListings,
      icon: ClipboardDocumentListIcon,
      href: '/listings?status=PENDING',
      color: 'text-orange-500',
      bgColor: 'bg-orange-100 dark:bg-orange-900/30',
    },
    {
      label: 'Pending Reports',
      count: notifications.pendingReports,
      icon: FlagIcon,
      href: '/reports?status=PENDING',
      color: 'text-red-500',
      bgColor: 'bg-red-100 dark:bg-red-900/30',
    },
    {
      label: 'Pending Verifications',
      count: notifications.pendingVerifications,
      icon: ShieldCheckIcon,
      href: '/verifications?status=PENDING',
      color: 'text-primary-500 dark:text-primary-300',
      bgColor: 'bg-primary-100 dark:bg-primary-900/30',
    },
  ].filter(item => item.count > 0);

  return (
    <header className="sticky top-0 z-10 flex h-16 items-center gap-4 border-b border-gray-200 bg-white px-6 dark:border-gray-700 dark:bg-gray-800">
      <h1 className="text-xl font-semibold text-gray-900 dark:text-gray-100">{title}</h1>

      <div className="ml-auto flex items-center gap-4">
        {/* Search */}
        <div className="relative">
          <MagnifyingGlassIcon className="absolute left-3 top-1/2 h-4 w-4 -translate-y-1/2 text-gray-400" />
          <input
            type="text"
            placeholder="Search..."
            className="h-9 w-40 lg:w-64 rounded-md border border-gray-300 bg-white pl-9 pr-3 text-sm focus:border-primary-500 focus:outline-none focus:ring-1 focus:ring-primary-500 dark:border-gray-600 dark:bg-gray-700 dark:text-gray-100 dark:placeholder-gray-400"
          />
        </div>

        {/* Theme Toggle */}
        {mounted && (
          <button
            onClick={() => setTheme(resolvedTheme === 'dark' ? 'light' : 'dark')}
            className="rounded-md p-2 text-gray-400 hover:bg-gray-100 hover:text-gray-500 dark:hover:bg-gray-700 dark:hover:text-gray-300 transition-colors"
            aria-label="Toggle theme"
          >
            {resolvedTheme === 'dark' ? <SunIcon className="h-5 w-5" /> : <MoonIcon className="h-5 w-5" />}
          </button>
        )}

        {/* Notifications */}
        <div className="relative" ref={dropdownRef}>
          <button
            onClick={() => setShowDropdown(!showDropdown)}
            className="relative rounded-md p-2 text-gray-400 hover:bg-gray-100 hover:text-gray-500 dark:hover:bg-gray-700 dark:hover:text-gray-300"
          >
            <BellIcon className="h-5 w-5" />
            {notifications.total > 0 && (
              <span className="absolute -right-1 -top-1 flex h-5 w-5 items-center justify-center rounded-full bg-red-500 text-xs font-medium text-white">
                {notifications.total > 99 ? '99+' : notifications.total}
              </span>
            )}
          </button>

          {/* Dropdown */}
          {showDropdown && (
            <div className="absolute right-0 mt-2 w-80 rounded-lg border border-gray-200 bg-white shadow-lg dark:border-gray-700 dark:bg-gray-800">
              <div className="border-b border-gray-200 px-4 py-3 dark:border-gray-700">
                <h3 className="font-semibold text-gray-900 dark:text-gray-100">Admin Notifications</h3>
                <p className="text-xs text-gray-500 dark:text-gray-400">Items requiring your attention</p>
              </div>

              {loading ? (
                <div className="flex items-center justify-center py-8">
                  <div className="h-6 w-6 animate-spin rounded-full border-2 border-primary-500 border-t-transparent" />
                </div>
              ) : notificationItems.length > 0 ? (
                <div className="divide-y divide-gray-200 dark:divide-gray-700">
                  {notificationItems.map((item) => (
                    <button
                      key={item.label}
                      onClick={() => {
                        router.push(item.href);
                        setShowDropdown(false);
                      }}
                      className="flex w-full items-center gap-3 px-4 py-3 hover:bg-gray-50 dark:hover:bg-gray-700 transition-colors"
                    >
                      <div className={`rounded-full p-2 ${item.bgColor}`}>
                        <item.icon className={`h-5 w-5 ${item.color}`} />
                      </div>
                      <div className="flex-1 text-left">
                        <p className="text-sm font-medium text-gray-900 dark:text-gray-100">{item.label}</p>
                        <p className="text-xs text-gray-500 dark:text-gray-400">
                          {item.count} {item.count === 1 ? 'item' : 'items'} pending
                        </p>
                      </div>
                      <span className={`rounded-full px-2.5 py-0.5 text-xs font-medium ${item.bgColor} ${item.color}`}>
                        {item.count}
                      </span>
                    </button>
                  ))}
                </div>
              ) : (
                <div className="py-8 text-center">
                  <BellIcon className="mx-auto h-8 w-8 text-gray-300 dark:text-gray-600" />
                  <p className="mt-2 text-sm text-gray-500 dark:text-gray-400">All caught up!</p>
                  <p className="text-xs text-gray-400 dark:text-gray-500">No pending items</p>
                </div>
              )}

              <div className="border-t border-gray-200 px-4 py-2 dark:border-gray-700">
                <button
                  onClick={() => {
                    router.push('/overview');
                    setShowDropdown(false);
                  }}
                  className="w-full text-center text-sm text-primary-500 hover:text-primary-600 dark:text-primary-300 dark:hover:text-primary-200"
                >
                  View Dashboard
                </button>
              </div>
            </div>
          )}
        </div>
      </div>
    </header>
  );
}
