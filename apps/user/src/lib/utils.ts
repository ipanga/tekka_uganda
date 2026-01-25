import { formatDistanceToNow, format, isToday, isYesterday } from 'date-fns';

// ============================================
// CURRENCY FORMATTING
// ============================================

export function formatPrice(amount: number): string {
  return new Intl.NumberFormat('en-UG', {
    style: 'currency',
    currency: 'UGX',
    minimumFractionDigits: 0,
    maximumFractionDigits: 0,
  }).format(amount);
}

export function formatPriceShort(amount: number): string {
  if (amount >= 1000000) {
    return `UGX ${(amount / 1000000).toFixed(1)}M`;
  }
  if (amount >= 1000) {
    return `UGX ${(amount / 1000).toFixed(0)}K`;
  }
  return formatPrice(amount);
}

// ============================================
// DATE FORMATTING
// ============================================

export function formatDate(date: string | Date): string {
  const d = typeof date === 'string' ? new Date(date) : date;
  return format(d, 'MMM d, yyyy');
}

export function formatDateTime(date: string | Date): string {
  const d = typeof date === 'string' ? new Date(date) : date;
  return format(d, 'MMM d, yyyy h:mm a');
}

export function formatRelativeTime(date: string | Date): string {
  const d = typeof date === 'string' ? new Date(date) : date;
  return formatDistanceToNow(d, { addSuffix: true });
}

export function formatMessageTime(date: string | Date): string {
  const d = typeof date === 'string' ? new Date(date) : date;

  if (isToday(d)) {
    return format(d, 'h:mm a');
  }

  if (isYesterday(d)) {
    return `Yesterday ${format(d, 'h:mm a')}`;
  }

  return format(d, 'MMM d, h:mm a');
}

export function formatChatDate(date: string | Date): string {
  const d = typeof date === 'string' ? new Date(date) : date;

  if (isToday(d)) {
    return format(d, 'h:mm a');
  }

  if (isYesterday(d)) {
    return 'Yesterday';
  }

  return format(d, 'MMM d');
}

export function formatTime(time: string): string {
  // Handle time strings like "14:30" or "2:30 PM"
  if (time.includes(':')) {
    const [hours, minutes] = time.split(':');
    const h = parseInt(hours, 10);
    const ampm = h >= 12 ? 'PM' : 'AM';
    const hour12 = h % 12 || 12;
    return `${hour12}:${minutes} ${ampm}`;
  }
  return time;
}

// ============================================
// PHONE NUMBER FORMATTING
// ============================================

export function formatPhoneNumber(phone: string): string {
  // Format Ugandan phone numbers
  if (phone.startsWith('+256')) {
    const number = phone.slice(4);
    return `+256 ${number.slice(0, 3)} ${number.slice(3, 6)} ${number.slice(6)}`;
  }
  return phone;
}

export function normalizePhoneNumber(phone: string): string {
  // Remove all non-digit characters except +
  let normalized = phone.replace(/[^\d+]/g, '');

  // Handle Ugandan numbers
  if (normalized.startsWith('0')) {
    normalized = '+256' + normalized.slice(1);
  } else if (normalized.startsWith('256')) {
    normalized = '+' + normalized;
  } else if (!normalized.startsWith('+')) {
    normalized = '+256' + normalized;
  }

  return normalized;
}

// ============================================
// TEXT HELPERS
// ============================================

export function truncateText(text: string, maxLength: number): string {
  if (text.length <= maxLength) return text;
  return text.slice(0, maxLength - 3) + '...';
}

export function capitalizeFirst(text: string): string {
  return text.charAt(0).toUpperCase() + text.slice(1).toLowerCase();
}

export function formatEnumLabel(value: string): string {
  return value
    .split('_')
    .map(word => capitalizeFirst(word))
    .join(' ');
}

export function slugify(text: string): string {
  return text
    .toLowerCase()
    .replace(/[^\w\s-]/g, '')
    .replace(/\s+/g, '-')
    .replace(/--+/g, '-')
    .trim();
}

// ============================================
// NUMBER HELPERS
// ============================================

export function formatNumber(num: number): string {
  return new Intl.NumberFormat('en-UG').format(num);
}

export function formatCompactNumber(num: number): string {
  if (num >= 1000000) {
    return `${(num / 1000000).toFixed(1)}M`;
  }
  if (num >= 1000) {
    return `${(num / 1000).toFixed(1)}K`;
  }
  return num.toString();
}

export function calculateDiscount(originalPrice: number, currentPrice: number): number {
  if (originalPrice <= 0) return 0;
  return Math.round(((originalPrice - currentPrice) / originalPrice) * 100);
}

// ============================================
// VALIDATION HELPERS
// ============================================

export function isValidEmail(email: string): boolean {
  const emailRegex = /^[^\s@]+@[^\s@]+\.[^\s@]+$/;
  return emailRegex.test(email);
}

export function isValidUgandanPhone(phone: string): boolean {
  const normalized = normalizePhoneNumber(phone);
  // Ugandan phone numbers are +256 followed by 9 digits
  return /^\+256[0-9]{9}$/.test(normalized);
}

export function isValidPassword(password: string): boolean {
  // At least 8 characters, 1 uppercase, 1 lowercase, 1 number
  return password.length >= 8 &&
    /[A-Z]/.test(password) &&
    /[a-z]/.test(password) &&
    /[0-9]/.test(password);
}

// ============================================
// IMAGE HELPERS
// ============================================

export function getImageUrl(url: string | undefined, fallback: string = '/placeholder.jpg'): string {
  if (!url) return fallback;

  // Handle Firebase Storage URLs
  if (url.includes('firebasestorage.googleapis.com')) {
    return url;
  }

  // Handle Cloudinary URLs
  if (url.includes('cloudinary.com')) {
    return url;
  }

  return url;
}

export function getInitials(name: string | undefined): string {
  if (!name) return '?';

  const words = name.trim().split(/\s+/);
  if (words.length === 1) {
    return words[0].charAt(0).toUpperCase();
  }

  return (words[0].charAt(0) + words[words.length - 1].charAt(0)).toUpperCase();
}

// ============================================
// ARRAY HELPERS
// ============================================

export function groupBy<T>(array: T[], key: keyof T): Record<string, T[]> {
  return array.reduce((result, item) => {
    const groupKey = String(item[key]);
    if (!result[groupKey]) {
      result[groupKey] = [];
    }
    result[groupKey].push(item);
    return result;
  }, {} as Record<string, T[]>);
}

export function uniqueBy<T>(array: T[], key: keyof T): T[] {
  const seen = new Set();
  return array.filter(item => {
    const value = item[key];
    if (seen.has(value)) return false;
    seen.add(value);
    return true;
  });
}

// ============================================
// CLASSNAME HELPER
// ============================================

export function cn(...classes: (string | boolean | undefined | null)[]): string {
  return classes.filter(Boolean).join(' ');
}

// ============================================
// LOCAL STORAGE HELPERS
// ============================================

export function getStoredValue<T>(key: string, defaultValue: T): T {
  if (typeof window === 'undefined') return defaultValue;

  try {
    const item = window.localStorage.getItem(key);
    return item ? JSON.parse(item) : defaultValue;
  } catch {
    return defaultValue;
  }
}

export function setStoredValue<T>(key: string, value: T): void {
  if (typeof window === 'undefined') return;

  try {
    window.localStorage.setItem(key, JSON.stringify(value));
  } catch {
    console.error('Failed to store value in localStorage');
  }
}

export function removeStoredValue(key: string): void {
  if (typeof window === 'undefined') return;

  try {
    window.localStorage.removeItem(key);
  } catch {
    console.error('Failed to remove value from localStorage');
  }
}

// ============================================
// DEBOUNCE & THROTTLE
// ============================================

export function debounce<T extends (...args: Parameters<T>) => ReturnType<T>>(
  func: T,
  wait: number
): (...args: Parameters<T>) => void {
  let timeout: NodeJS.Timeout | null = null;

  return (...args: Parameters<T>) => {
    if (timeout) clearTimeout(timeout);
    timeout = setTimeout(() => func(...args), wait);
  };
}

export function throttle<T extends (...args: Parameters<T>) => ReturnType<T>>(
  func: T,
  limit: number
): (...args: Parameters<T>) => void {
  let inThrottle = false;

  return (...args: Parameters<T>) => {
    if (!inThrottle) {
      func(...args);
      inThrottle = true;
      setTimeout(() => (inThrottle = false), limit);
    }
  };
}

// ============================================
// ERROR HELPERS
// ============================================

export function getErrorMessage(error: unknown): string {
  if (error instanceof Error) return error.message;
  if (typeof error === 'string') return error;
  return 'An unexpected error occurred';
}

// ============================================
// URL HELPERS
// ============================================

export function buildQueryString(params: Record<string, string | number | boolean | undefined>): string {
  const searchParams = new URLSearchParams();

  Object.entries(params).forEach(([key, value]) => {
    if (value !== undefined && value !== null && value !== '') {
      searchParams.append(key, String(value));
    }
  });

  const queryString = searchParams.toString();
  return queryString ? `?${queryString}` : '';
}

export function parseQueryString(queryString: string): Record<string, string> {
  const params = new URLSearchParams(queryString);
  const result: Record<string, string> = {};

  params.forEach((value, key) => {
    result[key] = value;
  });

  return result;
}
