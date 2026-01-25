'use client';

import Link from 'next/link';
import { usePathname } from 'next/navigation';
import {
  HomeIcon,
  ShoppingBagIcon,
  UsersIcon,
  FlagIcon,
  Cog6ToothIcon,
  ArrowLeftOnRectangleIcon,
  CurrencyDollarIcon,
  ChartBarIcon,
  ShieldCheckIcon,
  BellIcon,
  UserGroupIcon,
  FolderIcon,
  TagIcon,
  MapPinIcon,
  StarIcon,
} from '@heroicons/react/24/outline';
import { useAuth } from '@/hooks/useAuth';

const navigation = [
  { name: 'Dashboard', href: '/overview', icon: HomeIcon },
  { name: 'Analytics', href: '/analytics', icon: ChartBarIcon },
  { name: 'Listings', href: '/listings', icon: ShoppingBagIcon },
  { name: 'Categories', href: '/categories', icon: FolderIcon },
  { name: 'Attributes', href: '/attributes', icon: TagIcon },
  { name: 'Locations', href: '/locations', icon: MapPinIcon },
  { name: 'Users', href: '/users', icon: UsersIcon },
  { name: 'Reviews', href: '/reviews', icon: StarIcon },
  { name: 'Transactions', href: '/transactions', icon: CurrencyDollarIcon },
  { name: 'Verifications', href: '/verifications', icon: ShieldCheckIcon },
  { name: 'Reports', href: '/reports', icon: FlagIcon },
  { name: 'Notifications', href: '/notifications', icon: BellIcon },
  { name: 'Admin Users', href: '/admins', icon: UserGroupIcon },
  { name: 'Settings', href: '/settings', icon: Cog6ToothIcon },
];

export function Sidebar() {
  const pathname = usePathname();
  const { signOut, user } = useAuth();

  return (
    <div className="flex h-full w-64 flex-col bg-gray-900">
      {/* Logo */}
      <div className="flex h-16 items-center justify-center border-b border-gray-800">
        <span className="text-2xl font-bold text-white">Tekka Admin</span>
      </div>

      {/* Navigation */}
      <nav className="flex-1 space-y-1 px-2 py-4">
        {navigation.map((item) => {
          const isActive = pathname === item.href || pathname.startsWith(item.href + '/');
          return (
            <Link
              key={item.name}
              href={item.href}
              className={`group flex items-center rounded-md px-3 py-2 text-sm font-medium ${
                isActive
                  ? 'bg-gray-800 text-white'
                  : 'text-gray-300 hover:bg-gray-700 hover:text-white'
              }`}
            >
              <item.icon
                className={`mr-3 h-5 w-5 flex-shrink-0 ${
                  isActive ? 'text-white' : 'text-gray-400 group-hover:text-gray-300'
                }`}
              />
              {item.name}
            </Link>
          );
        })}
      </nav>

      {/* User section */}
      <div className="border-t border-gray-800 p-4">
        <div className="flex items-center">
          <div className="flex-shrink-0">
            <div className="h-8 w-8 rounded-full bg-gray-700 flex items-center justify-center">
              <span className="text-sm font-medium text-white">
                {user?.email?.charAt(0).toUpperCase() || 'A'}
              </span>
            </div>
          </div>
          <div className="ml-3 flex-1 min-w-0">
            <p className="truncate text-sm font-medium text-white">
              {user?.email || 'Admin'}
            </p>
            <p className="truncate text-xs text-gray-400">Administrator</p>
          </div>
          <button
            onClick={signOut}
            className="ml-2 rounded-md p-1.5 text-gray-400 hover:bg-gray-700 hover:text-white"
            title="Sign out"
          >
            <ArrowLeftOnRectangleIcon className="h-5 w-5" />
          </button>
        </div>
      </div>
    </div>
  );
}
