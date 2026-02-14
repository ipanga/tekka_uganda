'use client';

import { cn } from '@/lib/utils';

export type BadgeVariant = 'default' | 'success' | 'warning' | 'danger' | 'info' | 'primary';

export interface BadgeProps {
  children: React.ReactNode;
  variant?: BadgeVariant;
  size?: 'sm' | 'md';
  className?: string;
}

const variantStyles: Record<BadgeVariant, string> = {
  default: 'bg-gray-100 text-gray-700',
  success: 'bg-green-100 text-green-700',
  warning: 'bg-yellow-100 text-yellow-700',
  danger: 'bg-red-100 text-red-700',
  info: 'bg-blue-100 text-blue-700',
  primary: 'bg-primary-100 text-primary-600',
};

const sizeStyles = {
  sm: 'px-2 py-0.5 text-xs',
  md: 'px-2.5 py-1 text-sm',
};

export function Badge({
  children,
  variant = 'default',
  size = 'sm',
  className,
}: BadgeProps) {
  return (
    <span
      className={cn(
        'inline-flex items-center font-medium rounded-full',
        variantStyles[variant],
        sizeStyles[size],
        className
      )}
    >
      {children}
    </span>
  );
}

// Helper function to map status to badge variant
export function getStatusVariant(status: string): BadgeVariant {
  const statusMap: Record<string, BadgeVariant> = {
    // Listing statuses
    ACTIVE: 'success',
    PENDING: 'warning',
    DRAFT: 'default',
    SOLD: 'info',
    ARCHIVED: 'default',
    REJECTED: 'danger',
    // Meetup statuses
    PROPOSED: 'warning',
    COMPLETED: 'success',
    CANCELLED: 'danger',
    // Condition statuses
    NEW: 'success',
    LIKE_NEW: 'success',
    GOOD: 'info',
    FAIR: 'warning',
  };

  return statusMap[status] || 'default';
}
