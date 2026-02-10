// ============================================
// USER TYPES
// ============================================

export interface User {
  id: string;
  firebaseUid: string;
  phoneNumber?: string;
  email?: string;
  displayName?: string;
  photoUrl?: string;
  bio?: string;
  location?: string;
  isVerified: boolean;
  isOnboardingComplete?: boolean;
  showPhoneNumber?: boolean;
  createdAt: string;
  updatedAt?: string;
}

export interface UserStats {
  totalListings: number;
  activeListings: number;
  soldListings: number;
  totalSales: number;
  averageRating: number;
  totalReviews: number;
  responseRate: number;
  responseTime: string;
}

export interface UserSettings {
  notifications: NotificationSettings;
  privacy: PrivacySettings;
  security: SecuritySettings;
}

export interface NotificationSettings {
  pushEnabled: boolean;
  emailEnabled: boolean;
  smsEnabled: boolean;
  newMessage: boolean;
  newOffer: boolean;
  offerAccepted: boolean;
  offerDeclined: boolean;
  priceDrops: boolean;
  newListingsFromSavedSearches: boolean;
  marketingEmails: boolean;
}

export interface PrivacySettings {
  profileVisibility: 'PUBLIC' | 'REGISTERED_USERS' | 'PRIVATE';
  showLocation: boolean;
  showLastSeen: boolean;
  allowMessagesFrom: 'EVERYONE' | 'VERIFIED_USERS' | 'NO_ONE';
}

export interface SecuritySettings {
  twoFactorEnabled: boolean;
  twoFactorMethod?: 'SMS' | 'AUTHENTICATOR_APP';
  loginAlerts: boolean;
}

export interface UpdateUserDto {
  displayName?: string;
  email?: string;
  bio?: string;
  location?: string;
  photoUrl?: string;
  isOnboardingComplete?: boolean;
}

// ============================================
// LISTING TYPES
// ============================================

export interface Listing {
  id: string;
  sellerId: string;
  title: string;
  description: string;
  price: number;
  originalPrice?: number;
  category?: ListingCategory; // Optional - may be null when using new categoryId system
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
  createdAt: string;
  updatedAt: string;
  seller?: User;
  isSaved?: boolean;
  // New hierarchical category system fields
  categoryId?: string;
  categoryData?: Category;
  attributes?: Record<string, string | string[]>;
  cityId?: string;
  divisionId?: string;
  city?: City;
  division?: Division;
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

export interface CreateListingDto {
  title: string;
  description: string;
  price: number;
  originalPrice?: number;
  category?: ListingCategory; // Legacy - kept for backward compatibility
  condition: ItemCondition;
  occasion?: ItemOccasion;
  size?: string;
  brand?: string;
  color?: string;
  material?: string;
  location?: string;
  imageUrls: string[];
  isDraft?: boolean;
  // New hierarchical category system fields
  categoryId?: string;
  attributes?: Record<string, string | string[]>;
  cityId?: string;
  divisionId?: string;
}

export type UpdateListingDto = Omit<Partial<CreateListingDto>, 'originalPrice' | 'isDraft'>;

export interface ListingQueryParams {
  search?: string;
  categoryId?: string;
  category?: ListingCategory;
  condition?: ItemCondition;
  occasion?: ItemOccasion;
  minPrice?: number;
  maxPrice?: number;
  cityId?: string;
  divisionId?: string;
  location?: string;
  sellerId?: string;
  status?: ListingStatus;
  page?: number;
  limit?: number;
  sortBy?: 'createdAt' | 'price' | 'viewCount';
  sortOrder?: 'asc' | 'desc';
}

// ============================================
// CHAT & MESSAGE TYPES
// ============================================

export interface Chat {
  id: string;
  participants: User[];
  listing?: Listing;
  lastMessage?: Message;
  unreadCount: number;
  isArchived: boolean;
  createdAt: string;
  updatedAt: string;
}

export interface Message {
  id: string;
  chatId: string;
  senderId: string;
  sender?: User;
  content: string;
  type: MessageType;
  status: MessageStatus;
  replyToId?: string;
  replyTo?: Message;
  metadata?: MessageMetadata;
  createdAt: string;
  updatedAt: string;
}

export type MessageType = 'TEXT' | 'IMAGE' | 'SYSTEM' | 'MEETUP';

export type MessageStatus = 'SENDING' | 'SENT' | 'DELIVERED' | 'READ' | 'FAILED';

export interface MessageMetadata {
  meetupId?: string;
  meetup?: Meetup;
  imageUrl?: string;
}

export interface CreateChatDto {
  participantId: string;
  listingId?: string;
}

export interface SendMessageDto {
  content: string;
  type?: MessageType;
  replyToId?: string;
  metadata?: MessageMetadata;
}

// ============================================
// REVIEW TYPES
// ============================================

export interface Review {
  id: string;
  reviewerId: string;
  reviewer?: User;
  revieweeId: string;
  reviewee?: User;
  listingId?: string;
  listing?: Listing;
  rating: number;
  comment?: string;
  createdAt: string;
  updatedAt: string;
}

export interface ReviewStats {
  averageRating: number;
  totalReviews: number;
  ratingBreakdown: {
    1: number;
    2: number;
    3: number;
    4: number;
    5: number;
  };
}

export interface CreateReviewDto {
  revieweeId: string;
  listingId?: string;
  rating: number;
  comment?: string;
}

// ============================================
// NOTIFICATION TYPES
// ============================================

export interface Notification {
  id: string;
  userId: string;
  type: NotificationType;
  title: string;
  body: string;
  data?: NotificationData;
  isRead: boolean;
  createdAt: string;
}

export type NotificationType =
  | 'MESSAGE'
  | 'LISTING_APPROVED'
  | 'LISTING_REJECTED'
  | 'LISTING_SOLD'
  | 'PRICE_DROP'
  | 'NEW_REVIEW'
  | 'MEETUP_PROPOSED'
  | 'MEETUP_ACCEPTED'
  | 'SYSTEM';

export interface NotificationData {
  listingId?: string;
  chatId?: string;
  userId?: string;
  meetupId?: string;
}

// ============================================
// MEETUP TYPES
// ============================================

export interface Meetup {
  id: string;
  chatId: string;
  proposerId: string;
  proposer?: User;
  responderId: string;
  responder?: User;
  locationId?: string;
  location?: SafeLocation;
  locationName: string;
  locationAddress: string;
  latitude?: number;
  longitude?: number;
  scheduledAt: string;
  notes?: string;
  status: MeetupStatus;
  createdAt: string;
  updatedAt: string;
}

export type MeetupStatus =
  | 'PROPOSED'
  | 'ACCEPTED'
  | 'DECLINED'
  | 'COMPLETED'
  | 'CANCELLED';

export interface SafeLocation {
  id: string;
  name: string;
  address: string;
  city: string;
  latitude: number;
  longitude: number;
  type: 'MALL' | 'POLICE_STATION' | 'PUBLIC_SPACE' | 'BANK' | 'OTHER';
  openingHours?: string;
  description?: string;
}

export interface CreateMeetupDto {
  chatId: string;
  locationId?: string;
  locationName: string;
  locationAddress: string;
  latitude?: number;
  longitude?: number;
  scheduledAt: string;
  notes?: string;
}

// ============================================
// REPORT TYPES
// ============================================

export interface Report {
  id: string;
  reporterId: string;
  reportedUserId?: string;
  reportedListingId?: string;
  reason: ReportReason;
  description?: string;
  status: ReportStatus;
  createdAt: string;
}

export type ReportReason =
  | 'SPAM'
  | 'SCAM'
  | 'INAPPROPRIATE_CONTENT'
  | 'HARASSMENT'
  | 'FAKE_PROFILE'
  | 'COUNTERFEIT_ITEMS'
  | 'NO_SHOW'
  | 'OTHER';

export type ReportStatus = 'PENDING' | 'INVESTIGATING' | 'RESOLVED' | 'DISMISSED';

export interface CreateReportDto {
  reportedUserId?: string;
  reportedListingId?: string;
  reason: ReportReason;
  description?: string;
}

// ============================================
// SAVED SEARCH TYPES
// ============================================

export interface SavedSearch {
  id: string;
  userId: string;
  name?: string;
  query?: string;
  category?: ListingCategory;
  minPrice?: number;
  maxPrice?: number;
  location?: string;
  condition?: ItemCondition;
  notificationsEnabled: boolean;
  newMatchesCount: number;
  createdAt: string;
  updatedAt: string;
}

export interface CreateSavedSearchDto {
  name?: string;
  query?: string;
  category?: ListingCategory;
  minPrice?: number;
  maxPrice?: number;
  location?: string;
  condition?: ItemCondition;
}

// ============================================
// PRICE ALERT TYPES
// ============================================

export interface PriceAlert {
  id: string;
  userId: string;
  listingId: string;
  listing?: Listing;
  listingTitle: string;
  listingImageUrl?: string;
  sellerName: string;
  originalPrice: number;
  newPrice: number;
  priceDropAmount: number;
  priceDropPercent: number;
  isRead: boolean;
  isExpired: boolean;
  createdAt: string;
}

// ============================================
// QUICK REPLY TYPES
// ============================================

export interface QuickReply {
  id: string;
  userId: string;
  text: string;
  category?: string;
  usageCount: number;
  createdAt: string;
}

export interface CreateQuickReplyDto {
  text: string;
  category?: string;
}

// ============================================
// BLOCKED USER TYPES
// ============================================

export interface BlockedUser {
  id: string;
  userId: string;
  blockedUserId: string;
  blockedUser?: User;
  createdAt: string;
}

// ============================================
// COMMON TYPES
// ============================================

export interface PaginatedResponse<T> {
  data: T[];
  total: number;
  page: number;
  limit: number;
  totalPages: number;
}

export interface ApiResponse<T> {
  success: boolean;
  data?: T;
  error?: string;
  message?: string;
}

export interface CursorPaginatedResponse<T> {
  data: T[];
  nextCursor?: string;
  hasMore: boolean;
}

// ============================================
// DISPLAY HELPERS
// ============================================

export const CATEGORY_LABELS: Record<ListingCategory, string> = {
  DRESSES: 'Dresses',
  TOPS: 'Tops',
  BOTTOMS: 'Bottoms',
  TRADITIONAL_WEAR: 'Traditional Wear',
  SHOES: 'Shoes',
  ACCESSORIES: 'Accessories',
  BAGS: 'Bags',
  OTHER: 'Other',
};

export const CONDITION_LABELS: Record<ItemCondition, string> = {
  NEW: 'New with tags',
  LIKE_NEW: 'Like New',
  GOOD: 'Good',
  FAIR: 'Fair',
};

export const OCCASION_LABELS: Record<ItemOccasion, string> = {
  WEDDING: 'Wedding',
  KWANJULA: 'Kwanjula',
  CHURCH: 'Church',
  CORPORATE: 'Corporate',
  CASUAL: 'Casual',
  PARTY: 'Party',
  OTHER: 'Other',
};

export const STATUS_LABELS: Record<ListingStatus, string> = {
  DRAFT: 'Draft',
  PENDING: 'Pending Review',
  ACTIVE: 'Active',
  SOLD: 'Sold',
  ARCHIVED: 'Archived',
  REJECTED: 'Rejected',
};

export const MEETUP_STATUS_LABELS: Record<MeetupStatus, string> = {
  PROPOSED: 'Proposed',
  ACCEPTED: 'Accepted',
  DECLINED: 'Declined',
  COMPLETED: 'Completed',
  CANCELLED: 'Cancelled',
};

// ============================================
// CATEGORY & ATTRIBUTE TYPES (New Hierarchical System)
// ============================================

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

// ============================================
// LOCATION TYPES (City/Division System)
// ============================================

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
