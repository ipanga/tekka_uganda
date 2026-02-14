import { ReactNode } from 'react';

interface BadgeProps {
  children: ReactNode;
  variant?: 'default' | 'success' | 'warning' | 'danger' | 'info';
  className?: string;
}

export function Badge({ children, variant = 'default', className = '' }: BadgeProps) {
  const variants = {
    default: 'bg-gray-100 text-gray-800',
    success: 'bg-green-100 text-green-800',
    warning: 'bg-yellow-100 text-yellow-800',
    danger: 'bg-red-100 text-red-800',
    info: 'bg-primary-100 text-primary-800',
  };

  return (
    <span
      className={`inline-flex items-center rounded-full px-2.5 py-0.5 text-xs font-medium ${variants[variant]} ${className}`}
    >
      {children}
    </span>
  );
}

// Helper function to get badge variant from status
export function getStatusVariant(
  status: string
): 'default' | 'success' | 'warning' | 'danger' | 'info' {
  const statusMap: Record<string, 'default' | 'success' | 'warning' | 'danger' | 'info'> = {
    ACTIVE: 'success',
    PENDING: 'warning',
    SOLD: 'info',
    REJECTED: 'danger',
    ARCHIVED: 'default',
    DRAFT: 'default',
    RESOLVED: 'success',
    INVESTIGATING: 'warning',
    DISMISSED: 'default',
    USER: 'default',
    ADMIN: 'info',
    MODERATOR: 'warning',
  };

  return statusMap[status] || 'default';
}
