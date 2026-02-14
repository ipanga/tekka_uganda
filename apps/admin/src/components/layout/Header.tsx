'use client';

import { useState, useEffect, useRef } from 'react';
import { useRouter } from 'next/navigation';
import {
  BellIcon,
  MagnifyingGlassIcon,
  ClipboardDocumentListIcon,
  FlagIcon,
  ShieldCheckIcon,
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
  const [notifications, setNotifications] = useState<AdminNotifications>({
    pendingListings: 0,
    pendingReports: 0,
    pendingVerifications: 0,
    total: 0,
  });
  const [showDropdown, setShowDropdown] = useState(false);
  const [loading, setLoading] = useState(true);
  const dropdownRef = useRef<HTMLDivElement>(null);

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
      bgColor: 'bg-orange-100',
    },
    {
      label: 'Pending Reports',
      count: notifications.pendingReports,
      icon: FlagIcon,
      href: '/reports?status=PENDING',
      color: 'text-red-500',
      bgColor: 'bg-red-100',
    },
    {
      label: 'Pending Verifications',
      count: notifications.pendingVerifications,
      icon: ShieldCheckIcon,
      href: '/verifications?status=PENDING',
      color: 'text-primary-500',
      bgColor: 'bg-primary-100',
    },
  ].filter(item => item.count > 0);

  return (
    <header className="sticky top-0 z-10 flex h-16 items-center gap-4 border-b border-[var(--border)] bg-[var(--surface)] px-6">
      <h1 className="text-xl font-semibold text-gray-900">{title}</h1>

      <div className="ml-auto flex items-center gap-4">
        {/* Search */}
        <div className="relative">
          <MagnifyingGlassIcon className="absolute left-3 top-1/2 h-4 w-4 -translate-y-1/2 text-gray-400" />
          <input
            type="text"
            placeholder="Search..."
            className="h-9 w-40 lg:w-64 rounded-md border border-gray-300 bg-white pl-9 pr-3 text-sm focus:border-primary-500 focus:outline-none focus:ring-1 focus:ring-primary-500"
          />
        </div>

        {/* Notifications */}
        <div className="relative" ref={dropdownRef}>
          <button
            onClick={() => setShowDropdown(!showDropdown)}
            className="relative rounded-md p-2 text-gray-400 hover:bg-gray-100 hover:text-gray-500"
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
            <div className="absolute right-0 mt-2 w-80 rounded-lg border border-gray-200 bg-white shadow-lg">
              <div className="border-b border-gray-200 px-4 py-3">
                <h3 className="font-semibold text-gray-900">Admin Notifications</h3>
                <p className="text-xs text-gray-500">Items requiring your attention</p>
              </div>

              {loading ? (
                <div className="flex items-center justify-center py-8">
                  <div className="h-6 w-6 animate-spin rounded-full border-2 border-primary-500 border-t-transparent" />
                </div>
              ) : notificationItems.length > 0 ? (
                <div className="divide-y divide-gray-200">
                  {notificationItems.map((item) => (
                    <button
                      key={item.label}
                      onClick={() => {
                        router.push(item.href);
                        setShowDropdown(false);
                      }}
                      className="flex w-full items-center gap-3 px-4 py-3 hover:bg-gray-50 transition-colors"
                    >
                      <div className={`rounded-full p-2 ${item.bgColor}`}>
                        <item.icon className={`h-5 w-5 ${item.color}`} />
                      </div>
                      <div className="flex-1 text-left">
                        <p className="text-sm font-medium text-gray-900">{item.label}</p>
                        <p className="text-xs text-gray-500">
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
                  <BellIcon className="mx-auto h-8 w-8 text-gray-300" />
                  <p className="mt-2 text-sm text-gray-500">All caught up!</p>
                  <p className="text-xs text-gray-400">No pending items</p>
                </div>
              )}

              <div className="border-t border-gray-200 px-4 py-2">
                <button
                  onClick={() => {
                    router.push('/overview');
                    setShowDropdown(false);
                  }}
                  className="w-full text-center text-sm text-primary-500 hover:text-primary-600"
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
