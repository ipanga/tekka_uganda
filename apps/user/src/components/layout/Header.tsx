'use client';

import Link from 'next/link';
import { useRouter } from 'next/navigation';
import { Logo } from '@/components/ui/Logo';
import { useState, useEffect, Fragment } from 'react';
import { Menu, MenuButton, MenuItems, MenuItem, Transition } from '@headlessui/react';
import {
  MagnifyingGlassIcon,
  HeartIcon,
  ChatBubbleLeftIcon,
  BellIcon,
  Bars3Icon,
  XMarkIcon,
  UserCircleIcon,
  Cog6ToothIcon,
  ShoppingBagIcon,
  ArrowRightOnRectangleIcon,
  TagIcon,
  SunIcon,
  MoonIcon,
} from '@heroicons/react/24/outline';
import { useTheme } from 'next-themes';
import { signOut } from 'firebase/auth';
import { auth } from '@/lib/firebase';
import { api } from '@/lib/api';
import { authManager } from '@/lib/auth';
import { Avatar } from '@/components/ui/Avatar';
import { useAuthStore } from '@/stores/authStore';
import { useNotificationStore } from '@/stores/notificationStore';
import { useChatStore } from '@/stores/chatStore';

export function Header() {
  const router = useRouter();
  const [isMenuOpen, setIsMenuOpen] = useState(false);
  const [searchQuery, setSearchQuery] = useState('');
  const { setTheme, resolvedTheme } = useTheme();
  const [mounted, setMounted] = useState(false);

  const { user, isAuthenticated, logout } = useAuthStore();
  const { unreadCount: notificationCount, setUnreadCount: setNotificationCount } = useNotificationStore();
  const { unreadCount: chatCount, setUnreadCount: setChatCount } = useChatStore();

  useEffect(() => {
    const frame = requestAnimationFrame(() => setMounted(true));
    return () => cancelAnimationFrame(frame);
  }, []);

  useEffect(() => {
    const loadCounts = async () => {
      // Ensure authManager has initialized and API client has token
      // authManager.isAuthenticated() also initializes and sets API token
      if (!authManager.isAuthenticated()) {
        return;
      }
      try {
        const [notifCount, chatCountData] = await Promise.all([
          api.getUnreadNotificationCount(),
          api.getUnreadChatCount(),
        ]);
        setNotificationCount(notifCount.count);
        // Backend returns { unreadCount } but API type expects { count }
        const chatResponse = chatCountData as { unreadCount?: number; count?: number };
        setChatCount(chatResponse.unreadCount ?? chatResponse.count ?? 0);
      } catch (error) {
        console.error('Error loading counts:', error);
        // If we get an auth error, clear state
        if (error instanceof Error && (error.message.includes('token') || error.message.includes('Unauthorized'))) {
          authManager.signOut();
          logout();
        }
      }
    };

    if (isAuthenticated) {
      loadCounts();
    }
  }, [isAuthenticated, setNotificationCount, setChatCount, logout]);

  const handleSearch = (e: React.FormEvent) => {
    e.preventDefault();
    if (searchQuery.trim()) {
      router.push(`/explore?search=${encodeURIComponent(searchQuery.trim())}`);
      setSearchQuery('');
    }
  };

  const handleSignOut = async () => {
    try {
      // Sign out from Firebase (if used)
      await signOut(auth).catch(() => {});
      // Sign out from authManager (clears tokens)
      authManager.signOut();
      // Clear Zustand store
      logout();
      router.push('/');
    } catch (error) {
      console.error('Error signing out:', error);
    }
  };

  return (
    <header className="sticky top-0 z-50 bg-[var(--surface)] border-b border-[var(--border)]">
      <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8">
        <div className="flex items-center justify-between h-16">
          {/* Logo */}
          <Link href="/" className="flex items-center">
            <Logo variant="auto" height={28} />
          </Link>

          {/* Search Bar - Desktop */}
          <form onSubmit={handleSearch} className="hidden md:flex flex-1 max-w-2xl mx-8">
            <div className="relative w-full">
              <MagnifyingGlassIcon className="absolute left-3 top-1/2 -translate-y-1/2 h-5 w-5 text-gray-400 dark:text-gray-500" />
              <input
                type="text"
                value={searchQuery}
                onChange={(e) => setSearchQuery(e.target.value)}
                placeholder="Search for fashion items..."
                className="w-full pl-10 pr-4 py-2 border border-gray-300 dark:border-gray-600 bg-white dark:bg-gray-800 text-gray-900 dark:text-gray-100 rounded-full focus:outline-none focus:ring-2 focus:ring-primary-500 focus:border-transparent placeholder-gray-400 dark:placeholder-gray-500"
              />
            </div>
          </form>

          {/* Desktop Navigation */}
          <nav className="hidden md:flex items-center space-x-4">
            {isAuthenticated ? (
              <>
                {/* Saved */}
                <Link
                  href="/saved"
                  className="relative p-2 text-gray-600 dark:text-gray-300 hover:text-primary-500 dark:hover:text-primary-300 transition-colors"
                >
                  <HeartIcon className="h-6 w-6" />
                </Link>

                {/* Messages */}
                <Link
                  href="/messages"
                  className="relative p-2 text-gray-600 dark:text-gray-300 hover:text-primary-500 dark:hover:text-primary-300 transition-colors"
                >
                  <ChatBubbleLeftIcon className="h-6 w-6" />
                  {chatCount > 0 && (
                    <span className="absolute -top-1 -right-1 min-w-[18px] h-[18px] bg-primary-500 dark:bg-primary-400 text-white text-xs rounded-full flex items-center justify-center px-1">
                      {chatCount > 9 ? '9+' : chatCount}
                    </span>
                  )}
                </Link>

                {/* Notifications */}
                <Link
                  href="/notifications"
                  className="relative p-2 text-gray-600 dark:text-gray-300 hover:text-primary-500 dark:hover:text-primary-300 transition-colors"
                >
                  <BellIcon className="h-6 w-6" />
                  {notificationCount > 0 && (
                    <span className="absolute -top-1 -right-1 min-w-[18px] h-[18px] bg-primary-500 dark:bg-primary-400 text-white text-xs rounded-full flex items-center justify-center px-1">
                      {notificationCount > 9 ? '9+' : notificationCount}
                    </span>
                  )}
                </Link>

                {mounted && (
                  <ThemeModeToggle
                    resolvedTheme={resolvedTheme}
                    onLight={() => setTheme('light')}
                    onDark={() => setTheme('dark')}
                  />
                )}

                {/* User Menu */}
                <Menu as="div" className="relative">
                  <MenuButton className="flex items-center p-1 rounded-full hover:bg-gray-100 dark:hover:bg-gray-700">
                    <Avatar
                      src={user?.photoUrl}
                      name={user?.displayName}
                      size="sm"
                    />
                  </MenuButton>

                  <Transition
                    as={Fragment}
                    enter="transition ease-out duration-100"
                    enterFrom="transform opacity-0 scale-95"
                    enterTo="transform opacity-100 scale-100"
                    leave="transition ease-in duration-75"
                    leaveFrom="transform opacity-100 scale-100"
                    leaveTo="transform opacity-0 scale-95"
                  >
                    <MenuItems className="absolute right-0 mt-2 w-56 origin-top-right bg-white dark:bg-gray-800 rounded-xl shadow-lg ring-1 ring-black/5 dark:ring-white/10 focus:outline-none divide-y divide-gray-100 dark:divide-gray-700">
                      {/* User Info */}
                      <div className="px-4 py-3">
                        <p className="text-sm font-medium text-gray-900 dark:text-gray-100">
                          {user?.displayName || 'User'}
                        </p>
                        <p className="text-xs text-gray-500 dark:text-gray-400 truncate">
                          {user?.phoneNumber}
                        </p>
                      </div>

                      {/* Menu Items */}
                      <div className="py-1">
                        <MenuItem>
                          {({ active }) => (
                            <Link
                              href="/profile"
                              className={`${
                                active ? 'bg-gray-50 dark:bg-gray-700' : ''
                              } flex items-center px-4 py-2 text-sm text-gray-700 dark:text-gray-300`}
                            >
                              <UserCircleIcon className="w-5 h-5 mr-3 text-gray-400 dark:text-gray-500" />
                              Profile
                            </Link>
                          )}
                        </MenuItem>
                        <MenuItem>
                          {({ active }) => (
                            <Link
                              href="/my-listings"
                              className={`${
                                active ? 'bg-gray-50 dark:bg-gray-700' : ''
                              } flex items-center px-4 py-2 text-sm text-gray-700 dark:text-gray-300`}
                            >
                              <ShoppingBagIcon className="w-5 h-5 mr-3 text-gray-400 dark:text-gray-500" />
                              My Listings
                            </Link>
                          )}
                        </MenuItem>
                        <MenuItem>
                          {({ active }) => (
                            <Link
                              href="/settings"
                              className={`${
                                active ? 'bg-gray-50 dark:bg-gray-700' : ''
                              } flex items-center px-4 py-2 text-sm text-gray-700 dark:text-gray-300`}
                            >
                              <Cog6ToothIcon className="w-5 h-5 mr-3 text-gray-400 dark:text-gray-500" />
                              Settings
                            </Link>
                          )}
                        </MenuItem>
                      </div>

                      <div className="py-1">
                        <MenuItem>
                          {({ active }) => (
                            <button
                              onClick={handleSignOut}
                              className={`${
                                active ? 'bg-gray-50 dark:bg-gray-700' : ''
                              } flex items-center w-full px-4 py-2 text-sm text-gray-700 dark:text-gray-300`}
                            >
                              <ArrowRightOnRectangleIcon className="w-5 h-5 mr-3 text-gray-400 dark:text-gray-500" />
                              Sign Out
                            </button>
                          )}
                        </MenuItem>
                      </div>
                    </MenuItems>
                  </Transition>
                </Menu>

                {/* Sell Button */}
                <Link
                  href="/sell"
                  className="bg-primary-500 dark:bg-primary-400 text-white px-4 py-2 rounded-full hover:bg-primary-600 dark:hover:bg-primary-300 transition-colors flex items-center gap-2"
                >
                  <TagIcon className="w-4 h-4" />
                  Sell Now
                </Link>
              </>
            ) : (
              <>
                {mounted && (
                  <ThemeModeToggle
                    resolvedTheme={resolvedTheme}
                    onLight={() => setTheme('light')}
                    onDark={() => setTheme('dark')}
                  />
                )}
                <Link
                  href="/login"
                  className="text-gray-600 dark:text-gray-300 hover:text-primary-500 dark:hover:text-primary-300 transition-colors"
                >
                  Sign In
                </Link>
                <Link
                  href="/register"
                  className="bg-primary-500 dark:bg-primary-400 text-white px-4 py-2 rounded-full hover:bg-primary-600 dark:hover:bg-primary-300 transition-colors"
                >
                  Get Started
                </Link>
              </>
            )}
          </nav>

          {/* Mobile menu button */}
          <button
            onClick={() => setIsMenuOpen(!isMenuOpen)}
            className="md:hidden p-2 rounded-lg text-gray-600 dark:text-gray-300 hover:bg-gray-100 dark:hover:bg-gray-700"
          >
            {isMenuOpen ? (
              <XMarkIcon className="h-6 w-6" />
            ) : (
              <Bars3Icon className="h-6 w-6" />
            )}
          </button>
        </div>

        {/* Mobile menu */}
        {isMenuOpen && (
          <div className="md:hidden py-4 space-y-4">
            <form onSubmit={handleSearch}>
              <div className="relative">
                <MagnifyingGlassIcon className="absolute left-3 top-1/2 -translate-y-1/2 h-5 w-5 text-gray-400 dark:text-gray-500" />
                <input
                  type="text"
                  value={searchQuery}
                  onChange={(e) => setSearchQuery(e.target.value)}
                  placeholder="Search..."
                  className="w-full pl-10 pr-4 py-2 border border-gray-300 dark:border-gray-600 bg-white dark:bg-gray-800 text-gray-900 dark:text-gray-100 rounded-full focus:outline-none focus:ring-2 focus:ring-primary-500 placeholder-gray-400 dark:placeholder-gray-500"
                />
              </div>
            </form>
            <nav className="flex flex-col space-y-3">
              {mounted && (
                <ThemeModeToggle
                  resolvedTheme={resolvedTheme}
                  onLight={() => setTheme('light')}
                  onDark={() => setTheme('dark')}
                  mobile
                />
              )}
              {isAuthenticated ? (
                <>
                  <Link
                    href="/saved"
                    className="text-gray-600 dark:text-gray-300 hover:text-primary-500 dark:hover:text-primary-300 py-2"
                    onClick={() => setIsMenuOpen(false)}
                  >
                    Saved Items
                  </Link>
                  <Link
                    href="/messages"
                    className="text-gray-600 dark:text-gray-300 hover:text-primary-500 dark:hover:text-primary-300 py-2 flex items-center justify-between"
                    onClick={() => setIsMenuOpen(false)}
                  >
                    Messages
                    {chatCount > 0 && (
                      <span className="bg-primary-500 dark:bg-primary-400 text-white text-xs px-2 py-1 rounded-full">
                        {chatCount}
                      </span>
                    )}
                  </Link>
                  <Link
                    href="/notifications"
                    className="text-gray-600 dark:text-gray-300 hover:text-primary-500 dark:hover:text-primary-300 py-2 flex items-center justify-between"
                    onClick={() => setIsMenuOpen(false)}
                  >
                    Notifications
                    {notificationCount > 0 && (
                      <span className="bg-primary-500 dark:bg-primary-400 text-white text-xs px-2 py-1 rounded-full">
                        {notificationCount}
                      </span>
                    )}
                  </Link>
                  <Link
                    href="/my-listings"
                    className="text-gray-600 dark:text-gray-300 hover:text-primary-500 dark:hover:text-primary-300 py-2"
                    onClick={() => setIsMenuOpen(false)}
                  >
                    My Listings
                  </Link>
                  <Link
                    href="/profile"
                    className="text-gray-600 dark:text-gray-300 hover:text-primary-500 dark:hover:text-primary-300 py-2"
                    onClick={() => setIsMenuOpen(false)}
                  >
                    Profile
                  </Link>
                  <Link
                    href="/settings"
                    className="text-gray-600 dark:text-gray-300 hover:text-primary-500 dark:hover:text-primary-300 py-2"
                    onClick={() => setIsMenuOpen(false)}
                  >
                    Settings
                  </Link>
                  <Link
                    href="/sell"
                    className="bg-primary-500 dark:bg-primary-400 text-white px-4 py-2 rounded-full text-center hover:bg-primary-600 dark:hover:bg-primary-300"
                    onClick={() => setIsMenuOpen(false)}
                  >
                    Sell Now
                  </Link>
                  <button
                    onClick={() => {
                      setIsMenuOpen(false);
                      handleSignOut();
                    }}
                    className="text-gray-600 dark:text-gray-300 hover:text-primary-500 dark:hover:text-primary-300 py-2 text-left"
                  >
                    Sign Out
                  </button>
                </>
              ) : (
                <>
                  <Link
                    href="/login"
                    className="text-gray-600 dark:text-gray-300 hover:text-primary-500 dark:hover:text-primary-300 py-2"
                    onClick={() => setIsMenuOpen(false)}
                  >
                    Sign In
                  </Link>
                  <Link
                    href="/register"
                    className="bg-primary-500 dark:bg-primary-400 text-white px-4 py-2 rounded-full text-center hover:bg-primary-600 dark:hover:bg-primary-300"
                    onClick={() => setIsMenuOpen(false)}
                  >
                    Get Started
                  </Link>
                </>
              )}
            </nav>
          </div>
        )}
      </div>
    </header>
  );
}

export default Header;

function ThemeModeToggle({
  resolvedTheme,
  onLight,
  onDark,
  mobile = false,
}: {
  resolvedTheme?: string;
  onLight: () => void;
  onDark: () => void;
  mobile?: boolean;
}) {
  const buttonBase = mobile
    ? 'flex-1 items-center justify-center gap-2 rounded-lg border px-3 py-2 text-sm font-medium transition-colors'
    : 'inline-flex items-center gap-1 rounded-md px-2 py-1 text-xs font-medium transition-colors';

  const lightActive = resolvedTheme !== 'dark';
  const darkActive = resolvedTheme === 'dark';

  return (
    <div
      className={mobile ? 'flex items-center gap-2' : 'flex items-center gap-1 rounded-lg bg-gray-100 p-1 dark:bg-gray-800'}
      aria-label="Theme mode"
    >
      <button
        onClick={onLight}
        className={`${buttonBase} ${
          lightActive
            ? 'border-primary-500 bg-primary-500 text-white'
            : 'border-gray-300 text-gray-600 hover:border-primary-300 hover:text-primary-500 dark:border-gray-600 dark:text-gray-300 dark:hover:border-primary-300 dark:hover:text-primary-300'
        }`}
        aria-label="Set light theme"
      >
        <SunIcon className="h-4 w-4" />
        {mobile && 'Light'}
      </button>
      <button
        onClick={onDark}
        className={`${buttonBase} ${
          darkActive
            ? 'border-primary-500 bg-primary-500 text-white'
            : 'border-gray-300 text-gray-600 hover:border-primary-300 hover:text-primary-500 dark:border-gray-600 dark:text-gray-300 dark:hover:border-primary-300 dark:hover:text-primary-300'
        }`}
        aria-label="Set dark theme"
      >
        <MoonIcon className="h-4 w-4" />
        {mobile && 'Dark'}
      </button>
    </div>
  );
}
