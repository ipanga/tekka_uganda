// User types
export interface User {
  id: string;
  firebaseUid: string;
  phoneNumber: string;
  email?: string;
  displayName?: string;
  photoUrl?: string;
  bio?: string;
  location?: string;
  isOnboardingComplete: boolean;
  isVerified: boolean;
  isEmailVerified: boolean;
  isIdentityVerified: boolean;
  isSuspended: boolean;
  suspendedReason?: string;
  role: 'USER' | 'ADMIN' | 'MODERATOR';
  createdAt: string;
  updatedAt: string;
  lastActiveAt?: string;
}

// Listing types
export interface Listing {
  id: string;
  sellerId: string;
  title: string;
  description: string;
  price: number;
  originalPrice?: number;
  category: ListingCategory;
  condition: ItemCondition;
  occasion?: ItemOccasion;
  size?: string;
  brand?: string;
  color?: string;
  material?: string;
  location?: string;
  imageUrls: string[];
  status: ListingStatus;
  viewCount: number;
  saveCount: number;
  rejectionReason?: string;
  createdAt: string;
  updatedAt: string;
  soldAt?: string;
  archivedAt?: string;
  seller?: User;
}

export type ListingCategory =
  | 'DRESSES'
  | 'TOPS'
  | 'BOTTOMS'
  | 'TRADITIONAL_WEAR'
  | 'SHOES'
  | 'ACCESSORIES'
  | 'BAGS'
  | 'OTHER';

export type ItemCondition = 'NEW' | 'LIKE_NEW' | 'GOOD' | 'FAIR';

export type ItemOccasion =
  | 'WEDDING'
  | 'KWANJULA'
  | 'CHURCH'
  | 'CORPORATE'
  | 'CASUAL'
  | 'PARTY'
  | 'OTHER';

export type ListingStatus =
  | 'DRAFT'
  | 'PENDING'
  | 'ACTIVE'
  | 'SOLD'
  | 'ARCHIVED'
  | 'REJECTED';

// Report types
export interface Report {
  id: string;
  reporterId: string;
  reportedUserId?: string;
  reportedListingId?: string;
  reason: string;
  description?: string;
  status: ReportStatus;
  resolvedAt?: string;
  resolvedBy?: string;
  resolution?: string;
  createdAt: string;
  updatedAt: string;
  reporter?: User;
  reportedUser?: User;
}

export type ReportStatus = 'PENDING' | 'INVESTIGATING' | 'RESOLVED' | 'DISMISSED';

// Dashboard stats
export interface DashboardStats {
  totalUsers: number;
  activeUsers: number;
  totalListings: number;
  activeListings: number;
  pendingListings: number;
  totalTransactions: number;
  pendingReports: number;
  newUsersToday: number;
  newListingsToday: number;
}

// Pagination
export interface PaginatedResponse<T> {
  data: T[];
  total: number;
  page: number;
  limit: number;
  totalPages: number;
}

// API response
export interface ApiResponse<T> {
  success: boolean;
  data?: T;
  error?: string;
}

// Offer types
export interface Offer {
  id: string;
  buyerId: string;
  sellerId: string;
  listingId: string;
  amount: number;
  status: OfferStatus;
  message?: string;
  counterAmount?: number;
  expiresAt: string;
  createdAt: string;
  updatedAt: string;
  buyer?: User;
  seller?: User;
  listing?: Listing;
}

export type OfferStatus =
  | 'PENDING'
  | 'ACCEPTED'
  | 'REJECTED'
  | 'COUNTERED'
  | 'EXPIRED'
  | 'CANCELLED';

// Transaction types
export interface Transaction {
  id: string;
  offerId: string;
  buyerId: string;
  sellerId: string;
  listingId: string;
  amount: number;
  status: TransactionStatus;
  paymentMethod?: string;
  paymentReference?: string;
  completedAt?: string;
  cancelledAt?: string;
  cancelReason?: string;
  createdAt: string;
  updatedAt: string;
  buyer?: User;
  seller?: User;
  listing?: Listing;
  offer?: Offer;
}

export type TransactionStatus =
  | 'PENDING'
  | 'PAYMENT_PENDING'
  | 'PAID'
  | 'MEETUP_SCHEDULED'
  | 'COMPLETED'
  | 'CANCELLED'
  | 'DISPUTED';

// Verification types
export interface VerificationRequest {
  id: string;
  userId: string;
  type: VerificationType;
  status: VerificationStatus;
  documentType?: string;
  documentUrl?: string;
  selfieUrl?: string;
  notes?: string;
  reviewedBy?: string;
  reviewedAt?: string;
  rejectionReason?: string;
  createdAt: string;
  updatedAt: string;
  user?: User;
}

export type VerificationType = 'PHONE' | 'EMAIL' | 'IDENTITY' | 'ADDRESS';

export type VerificationStatus = 'PENDING' | 'APPROVED' | 'REJECTED' | 'EXPIRED';

// Notification types for admin
export interface AdminNotification {
  id: string;
  type: AdminNotificationType;
  title: string;
  body: string;
  targetType: 'ALL' | 'ROLE' | 'USER' | 'SEGMENT';
  targetRole?: 'USER' | 'ADMIN' | 'MODERATOR';
  targetUserIds?: string[];
  sentAt?: string;
  sentBy: string;
  status: NotificationStatus;
  recipientCount: number;
  readCount: number;
  createdAt: string;
  sentByUser?: User;
}

export type AdminNotificationType = 'ANNOUNCEMENT' | 'PROMOTION' | 'SYSTEM' | 'ALERT';

export type NotificationStatus = 'DRAFT' | 'SCHEDULED' | 'SENT' | 'FAILED';

// Analytics types
export interface AnalyticsData {
  period: string;
  users: {
    total: number;
    new: number;
    active: number;
  };
  listings: {
    total: number;
    new: number;
    sold: number;
    pending: number;
  };
  transactions: {
    total: number;
    completed: number;
    cancelled: number;
    totalValue: number;
  };
  reports: {
    total: number;
    resolved: number;
    pending: number;
  };
}

export interface TimeSeriesData {
  date: string;
  value: number;
}

export interface AnalyticsOverview {
  summary: AnalyticsData;
  userGrowth: TimeSeriesData[];
  listingGrowth: TimeSeriesData[];
  transactionVolume: TimeSeriesData[];
  revenueByCategory: { category: string; amount: number }[];
  topSellers: { user: User; sales: number; revenue: number }[];
}

// Admin user types
export interface AdminUser extends User {
  permissions: AdminPermission[];
  lastLoginAt?: string;
  createdBy?: string;
}

export type AdminPermission =
  | 'MANAGE_USERS'
  | 'MANAGE_LISTINGS'
  | 'MANAGE_REPORTS'
  | 'MANAGE_TRANSACTIONS'
  | 'MANAGE_SETTINGS'
  | 'MANAGE_ADMINS'
  | 'VIEW_ANALYTICS'
  | 'SEND_NOTIFICATIONS';

// Audit log
export interface AuditLog {
  id: string;
  adminId: string;
  action: string;
  targetType: 'USER' | 'LISTING' | 'REPORT' | 'TRANSACTION' | 'SETTING';
  targetId: string;
  details?: Record<string, unknown>;
  ipAddress?: string;
  createdAt: string;
  admin?: User;
}

// Category management (New hierarchical system)
export interface Category {
  id: string;
  name: string;
  slug: string;
  level: number; // 1 = Main, 2 = Sub, 3 = ProductType
  parentId?: string;
  imageUrl?: string;
  iconName?: string;
  sortOrder: number;
  isActive: boolean;
  createdAt: string;
  updatedAt: string;
  parent?: Category;
  children?: Category[];
  attributes?: CategoryAttribute[];
}

export interface AttributeDefinition {
  id: string;
  name: string;
  slug: string;
  type: AttributeType;
  isRequired: boolean;
  sortOrder: number;
  isActive: boolean;
  createdAt: string;
  updatedAt: string;
  values?: AttributeValue[];
}

export type AttributeType = 'SINGLE_SELECT' | 'MULTI_SELECT' | 'TEXT' | 'NUMBER';

export interface AttributeValue {
  id: string;
  attributeId: string;
  value: string;
  displayValue?: string;
  sortOrder: number;
  isActive: boolean;
  metadata?: Record<string, unknown>;
}

export interface CategoryAttribute {
  id: string;
  categoryId: string;
  attributeId: string;
  isRequired: boolean;
  sortOrder: number;
  attribute?: AttributeDefinition;
}

// Location management
export interface City {
  id: string;
  name: string;
  isActive: boolean;
  sortOrder: number;
  divisions?: Division[];
}

export interface Division {
  id: string;
  cityId: string;
  name: string;
  isActive: boolean;
  sortOrder: number;
  city?: City;
}

// Label constants
export const OFFER_STATUS_LABELS: Record<OfferStatus, string> = {
  PENDING: 'Pending',
  ACCEPTED: 'Accepted',
  REJECTED: 'Rejected',
  COUNTERED: 'Countered',
  EXPIRED: 'Expired',
  CANCELLED: 'Cancelled',
};

export const TRANSACTION_STATUS_LABELS: Record<TransactionStatus, string> = {
  PENDING: 'Pending',
  PAYMENT_PENDING: 'Payment Pending',
  PAID: 'Paid',
  MEETUP_SCHEDULED: 'Meetup Scheduled',
  COMPLETED: 'Completed',
  CANCELLED: 'Cancelled',
  DISPUTED: 'Disputed',
};

export const VERIFICATION_STATUS_LABELS: Record<VerificationStatus, string> = {
  PENDING: 'Pending',
  APPROVED: 'Approved',
  REJECTED: 'Rejected',
  EXPIRED: 'Expired',
};

export const VERIFICATION_TYPE_LABELS: Record<VerificationType, string> = {
  PHONE: 'Phone',
  EMAIL: 'Email',
  IDENTITY: 'Identity',
  ADDRESS: 'Address',
};
