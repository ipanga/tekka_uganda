'use client';

import { BellIcon, MagnifyingGlassIcon } from '@heroicons/react/24/outline';

interface HeaderProps {
  title: string;
}

export function Header({ title }: HeaderProps) {
  return (
    <header className="sticky top-0 z-10 flex h-16 items-center gap-4 border-b bg-white px-6">
      <h1 className="text-xl font-semibold text-gray-900">{title}</h1>

      <div className="ml-auto flex items-center gap-4">
        {/* Search */}
        <div className="relative">
          <MagnifyingGlassIcon className="absolute left-3 top-1/2 h-4 w-4 -translate-y-1/2 text-gray-400" />
          <input
            type="text"
            placeholder="Search..."
            className="h-9 w-64 rounded-md border border-gray-300 pl-9 pr-3 text-sm focus:border-blue-500 focus:outline-none focus:ring-1 focus:ring-blue-500"
          />
        </div>

        {/* Notifications */}
        <button className="relative rounded-md p-2 text-gray-400 hover:bg-gray-100 hover:text-gray-500">
          <BellIcon className="h-5 w-5" />
          <span className="absolute right-1 top-1 h-2 w-2 rounded-full bg-red-500" />
        </button>
      </div>
    </header>
  );
}
