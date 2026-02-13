'use client';

import Image from 'next/image';
import { cn, getInitials } from '@/lib/utils';

export type AvatarSize = 'xs' | 'sm' | 'md' | 'lg' | 'xl';

export interface AvatarProps {
  src?: string | null;
  alt?: string;
  name?: string;
  size?: AvatarSize;
  className?: string;
  showBadge?: boolean;
  badgeColor?: 'green' | 'yellow' | 'red' | 'gray';
}

const sizeStyles: Record<AvatarSize, { container: string; text: string; badge: string }> = {
  xs: { container: 'h-6 w-6', text: 'text-xs', badge: 'h-2 w-2' },
  sm: { container: 'h-8 w-8', text: 'text-sm', badge: 'h-2.5 w-2.5' },
  md: { container: 'h-10 w-10', text: 'text-base', badge: 'h-3 w-3' },
  lg: { container: 'h-12 w-12', text: 'text-lg', badge: 'h-3.5 w-3.5' },
  xl: { container: 'h-16 w-16', text: 'text-xl', badge: 'h-4 w-4' },
};

const badgeColors = {
  green: 'bg-green-500',
  yellow: 'bg-yellow-500',
  red: 'bg-red-500',
  gray: 'bg-gray-400',
};

export function Avatar({
  src,
  alt,
  name,
  size = 'md',
  className,
  showBadge,
  badgeColor = 'green',
}: AvatarProps) {
  const styles = sizeStyles[size];
  const initials = getInitials(name);

  return (
    <div className={cn('relative inline-flex', className)}>
      {src ? (
        <div
          className={cn(
            styles.container,
            'relative rounded-full overflow-hidden bg-gray-100 dark:bg-gray-800'
          )}
        >
          <Image
            src={src}
            alt={alt || name || 'Avatar'}
            fill
            className="object-cover"
          />
        </div>
      ) : (
        <div
          className={cn(
            styles.container,
            'flex items-center justify-center rounded-full bg-primary-100 dark:bg-primary-900 text-primary-600 dark:text-primary-300 font-medium',
            styles.text
          )}
        >
          {initials}
        </div>
      )}
      {showBadge && (
        <span
          className={cn(
            'absolute bottom-0 right-0 block rounded-full ring-2 ring-white dark:ring-gray-800',
            styles.badge,
            badgeColors[badgeColor]
          )}
        />
      )}
    </div>
  );
}

export interface AvatarGroupProps {
  avatars: Array<{ src?: string; name?: string }>;
  max?: number;
  size?: AvatarSize;
  className?: string;
}

export function AvatarGroup({
  avatars,
  max = 4,
  size = 'sm',
  className,
}: AvatarGroupProps) {
  const displayedAvatars = avatars.slice(0, max);
  const remainingCount = avatars.length - max;
  const styles = sizeStyles[size];

  return (
    <div className={cn('flex -space-x-2', className)}>
      {displayedAvatars.map((avatar, index) => (
        <Avatar
          key={index}
          src={avatar.src}
          name={avatar.name}
          size={size}
          className="ring-2 ring-white"
        />
      ))}
      {remainingCount > 0 && (
        <div
          className={cn(
            styles.container,
            'flex items-center justify-center rounded-full bg-gray-100 dark:bg-gray-800 text-gray-600 dark:text-gray-300 font-medium ring-2 ring-white dark:ring-gray-800',
            styles.text
          )}
        >
          +{remainingCount}
        </div>
      )}
    </div>
  );
}
