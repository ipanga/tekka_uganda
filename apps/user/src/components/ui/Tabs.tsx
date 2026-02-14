'use client';

import { useState } from 'react';
import { cn } from '@/lib/utils';

export interface Tab {
  id: string;
  label: string;
  count?: number;
  icon?: React.ReactNode;
}

export interface TabsProps {
  tabs: Tab[];
  activeTab: string;
  onChange: (tabId: string) => void;
  variant?: 'underline' | 'pills';
  className?: string;
}

export function Tabs({
  tabs,
  activeTab,
  onChange,
  variant = 'underline',
  className,
}: TabsProps) {
  if (variant === 'pills') {
    return (
      <div className={cn('flex gap-2 flex-wrap', className)}>
        {tabs.map((tab) => (
          <button
            key={tab.id}
            onClick={() => onChange(tab.id)}
            className={cn(
              'inline-flex items-center gap-2 px-4 py-2 rounded-full text-sm font-medium transition-colors',
              activeTab === tab.id
                ? 'bg-primary-500 text-white'
                : 'bg-gray-100 text-gray-600 hover:bg-gray-200'
            )}
          >
            {tab.icon}
            {tab.label}
            {tab.count !== undefined && (
              <span
                className={cn(
                  'ml-1 px-2 py-0.5 rounded-full text-xs',
                  activeTab === tab.id
                    ? 'bg-primary-500 text-white'
                    : 'bg-gray-200 text-gray-600'
                )}
              >
                {tab.count}
              </span>
            )}
          </button>
        ))}
      </div>
    );
  }

  return (
    <div className={cn('border-b border-gray-200', className)}>
      <nav className="flex gap-8 -mb-px">
        {tabs.map((tab) => (
          <button
            key={tab.id}
            onClick={() => onChange(tab.id)}
            className={cn(
              'inline-flex items-center gap-2 py-4 px-1 text-sm font-medium border-b-2 transition-colors',
              activeTab === tab.id
                ? 'border-primary-500 text-primary-500'
                : 'border-transparent text-gray-500 hover:text-gray-700 hover:border-gray-300'
            )}
          >
            {tab.icon}
            {tab.label}
            {tab.count !== undefined && (
              <span
                className={cn(
                  'ml-1 px-2 py-0.5 rounded-full text-xs',
                  activeTab === tab.id
                    ? 'bg-primary-100 text-primary-500'
                    : 'bg-gray-100 text-gray-600'
                )}
              >
                {tab.count}
              </span>
            )}
          </button>
        ))}
      </nav>
    </div>
  );
}

// Controlled tab panel wrapper
export interface TabPanelProps {
  children: React.ReactNode;
  tabId: string;
  activeTab: string;
  className?: string;
}

export function TabPanel({ children, tabId, activeTab, className }: TabPanelProps) {
  if (tabId !== activeTab) return null;

  return <div className={className}>{children}</div>;
}

// Uncontrolled tabs with built-in state
export interface UncontrolledTabsProps {
  tabs: Tab[];
  defaultTab?: string;
  variant?: 'underline' | 'pills';
  children: (activeTab: string) => React.ReactNode;
  className?: string;
}

export function UncontrolledTabs({
  tabs,
  defaultTab,
  variant = 'underline',
  children,
  className,
}: UncontrolledTabsProps) {
  const [activeTab, setActiveTab] = useState(defaultTab || tabs[0]?.id);

  return (
    <div className={className}>
      <Tabs
        tabs={tabs}
        activeTab={activeTab}
        onChange={setActiveTab}
        variant={variant}
      />
      <div className="mt-4">{children(activeTab)}</div>
    </div>
  );
}
