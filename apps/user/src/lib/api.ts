import {
  User,
  UserStats,
  UserSettings,
  UpdateUserDto,
  Listing,
  CreateListingDto,
  UpdateListingDto,
  ListingQueryParams,
  Chat,
  Message,
  CreateChatDto,
  SendMessageDto,
  Review,
  ReviewStats,
  CreateReviewDto,
  Notification,
  Meetup,
  SafeLocation,
  CreateMeetupDto,
  Report,
  CreateReportDto,
  SavedSearch,
  CreateSavedSearchDto,
  PriceAlert,
  QuickReply,
  CreateQuickReplyDto,
  BlockedUser,
  PaginatedResponse,
  CursorPaginatedResponse,
  Category,
  AttributeDefinition,
  City,
  Division,
} from '@/types';

const API_URL = process.env.NEXT_PUBLIC_API_URL || 'http://localhost:4000/api/v1';

class ApiClient {
  private token: string | null = null;

  setToken(token: string) {
    this.token = token;
  }

  clearToken() {
    this.token = null;
  }

  hasToken(): boolean {
    return !!this.token;
  }

  private async request<T>(
    endpoint: string,
    options: RequestInit = {}
  ): Promise<T> {
    const headers: HeadersInit = {
      'Content-Type': 'application/json',
      ...options.headers,
    };

    if (this.token) {
      (headers as Record<string, string>)['Authorization'] = `Bearer ${this.token}`;
    }

    const response = await fetch(`${API_URL}${endpoint}`, {
      ...options,
      headers,
    });

    if (!response.ok) {
      const error = await response.json().catch(() => ({}));
      throw new Error(error.message || 'API request failed');
    }

    // Handle 204 No Content
    if (response.status === 204) {
      return {} as T;
    }

    return response.json();
  }

  private buildQueryString(params: object): string {
    const searchParams = new URLSearchParams();
    Object.entries(params).forEach(([key, value]) => {
      if (value !== undefined && value !== null && value !== '') {
        searchParams.append(key, String(value));
      }
    });
    const queryString = searchParams.toString();
    return queryString ? `?${queryString}` : '';
  }

  get<T>(endpoint: string): Promise<T> {
    return this.request<T>(endpoint, { method: 'GET' });
  }

  post<T>(endpoint: string, data?: unknown): Promise<T> {
    return this.request<T>(endpoint, {
      method: 'POST',
      body: data ? JSON.stringify(data) : undefined,
    });
  }

  put<T>(endpoint: string, data?: unknown): Promise<T> {
    return this.request<T>(endpoint, {
      method: 'PUT',
      body: data ? JSON.stringify(data) : undefined,
    });
  }

  delete<T>(endpoint: string): Promise<T> {
    return this.request<T>(endpoint, { method: 'DELETE' });
  }

  // ============================================
  // USER ENDPOINTS
  // ============================================

  getMe(): Promise<User> {
    return this.get<User>('/users/me');
  }

  updateMe(data: UpdateUserDto): Promise<User> {
    return this.put<User>('/users/me', data);
  }

  deleteAccount(): Promise<void> {
    return this.delete<void>('/users/me');
  }

  getUser(userId: string): Promise<User> {
    return this.get<User>(`/users/${userId}`);
  }

  getUserStats(userId: string): Promise<UserStats> {
    return this.get<UserStats>(`/users/${userId}/stats`);
  }

  getMyStats(): Promise<UserStats> {
    return this.get<UserStats>('/users/me/stats');
  }

  getMySettings(): Promise<UserSettings> {
    return this.get<UserSettings>('/users/me/settings');
  }

  updateMySettings(data: Partial<UserSettings>): Promise<UserSettings> {
    return this.put<UserSettings>('/users/me/settings', data);
  }

  // FCM Token management
  registerFcmToken(token: string, platform: string): Promise<void> {
    return this.post<void>('/users/me/fcm-token', { token, platform });
  }

  removeFcmToken(token: string): Promise<void> {
    return this.delete<void>(`/users/me/fcm-token/${token}`);
  }

  // Blocked users
  getBlockedUsers(): Promise<BlockedUser[]> {
    return this.get<BlockedUser[]>('/users/me/blocked');
  }

  blockUser(userId: string): Promise<void> {
    return this.post<void>(`/users/me/blocked/${userId}`);
  }

  unblockUser(userId: string): Promise<void> {
    return this.delete<void>(`/users/me/blocked/${userId}`);
  }

  // Email verification
  sendEmailVerification(email: string): Promise<void> {
    return this.post<void>('/users/me/email-verification/send', { email });
  }

  verifyEmailCode(code: string): Promise<void> {
    return this.post<void>('/users/me/email-verification/verify', { code });
  }

  // ============================================
  // LISTING ENDPOINTS
  // ============================================

  getListings(params: ListingQueryParams = {}): Promise<PaginatedResponse<Listing>> {
    return this.get<PaginatedResponse<Listing>>(`/listings${this.buildQueryString(params)}`);
  }

  getListing(id: string): Promise<Listing> {
    return this.get<Listing>(`/listings/${id}`);
  }

  createListing(data: CreateListingDto): Promise<Listing> {
    return this.post<Listing>('/listings', data);
  }

  updateListing(id: string, data: UpdateListingDto): Promise<Listing> {
    return this.put<Listing>(`/listings/${id}`, data);
  }

  deleteListing(id: string): Promise<void> {
    return this.delete<void>(`/listings/${id}`);
  }

  getMyListings(params: ListingQueryParams = {}): Promise<PaginatedResponse<Listing>> {
    return this.get<PaginatedResponse<Listing>>(`/listings/my${this.buildQueryString(params)}`);
  }

  getSellerListings(sellerId: string, params: ListingQueryParams = {}): Promise<PaginatedResponse<Listing>> {
    return this.get<PaginatedResponse<Listing>>(`/listings/seller/${sellerId}${this.buildQueryString(params)}`);
  }

  publishListing(id: string): Promise<Listing> {
    return this.post<Listing>(`/listings/${id}/publish`);
  }

  archiveListing(id: string): Promise<Listing> {
    return this.post<Listing>(`/listings/${id}/archive`);
  }

  markListingAsSold(id: string): Promise<Listing> {
    return this.post<Listing>(`/listings/${id}/sold`);
  }

  // Saved listings
  getSavedListings(): Promise<Listing[]> {
    return this.get<Listing[]>('/listings/saved');
  }

  saveListing(id: string): Promise<void> {
    return this.post<void>(`/listings/${id}/save`);
  }

  unsaveListing(id: string): Promise<void> {
    return this.delete<void>(`/listings/${id}/save`);
  }

  isListingSaved(id: string): Promise<{ saved: boolean }> {
    return this.get<{ saved: boolean }>(`/listings/${id}/saved`);
  }

  // ============================================
  // CHAT ENDPOINTS
  // ============================================

  getChats(): Promise<Chat[]> {
    return this.get<Chat[]>('/chats');
  }

  createChat(data: CreateChatDto): Promise<Chat> {
    return this.post<Chat>('/chats', data);
  }

  getUnreadChatCount(): Promise<{ count: number }> {
    return this.get<{ count: number }>('/chats/unread-count');
  }

  getChat(id: string): Promise<Chat> {
    return this.get<Chat>(`/chats/${id}`);
  }

  markChatAsRead(id: string): Promise<void> {
    return this.put<void>(`/chats/${id}/read`);
  }

  archiveChat(id: string): Promise<void> {
    return this.put<void>(`/chats/${id}/archive`);
  }

  unarchiveChat(id: string): Promise<void> {
    return this.put<void>(`/chats/${id}/unarchive`);
  }

  deleteChat(id: string): Promise<void> {
    return this.delete<void>(`/chats/${id}`);
  }

  // Messages
  getMessages(chatId: string, cursor?: string, limit: number = 50): Promise<CursorPaginatedResponse<Message>> {
    const params: Record<string, unknown> = { limit };
    if (cursor) params.cursor = cursor;
    return this.get<CursorPaginatedResponse<Message>>(`/chats/${chatId}/messages${this.buildQueryString(params)}`);
  }

  sendMessage(chatId: string, data: SendMessageDto): Promise<Message> {
    return this.post<Message>(`/chats/${chatId}/messages`, data);
  }

  editMessage(messageId: string, content: string): Promise<Message> {
    return this.put<Message>(`/chats/messages/${messageId}`, { content });
  }

  deleteMessage(messageId: string): Promise<void> {
    return this.delete<void>(`/chats/messages/${messageId}`);
  }

  searchMessages(query: string): Promise<Message[]> {
    return this.get<Message[]>(`/chats/search${this.buildQueryString({ query })}`);
  }

  // ============================================
  // REVIEW ENDPOINTS
  // ============================================

  createReview(data: CreateReviewDto): Promise<Review> {
    return this.post<Review>('/reviews', data);
  }

  getUserReviews(userId: string, type: 'received' | 'given' = 'received'): Promise<{ reviews: Review[]; nextCursor: string | null }> {
    return this.get<{ reviews: Review[]; nextCursor: string | null }>(`/reviews/user/${userId}${this.buildQueryString({ type })}`);
  }

  getUserReviewStats(userId: string): Promise<ReviewStats> {
    return this.get<ReviewStats>(`/reviews/user/${userId}/stats`);
  }

  getReview(id: string): Promise<Review> {
    return this.get<Review>(`/reviews/${id}`);
  }

  updateReview(id: string, data: { rating?: number; comment?: string }): Promise<Review> {
    return this.put<Review>(`/reviews/${id}`, data);
  }

  deleteReview(id: string): Promise<void> {
    return this.delete<void>(`/reviews/${id}`);
  }

  reportReview(id: string): Promise<void> {
    return this.post<void>(`/reviews/${id}/report`);
  }

  // ============================================
  // NOTIFICATION ENDPOINTS
  // ============================================

  getNotifications(cursor?: string, limit: number = 20): Promise<CursorPaginatedResponse<Notification>> {
    const params: Record<string, unknown> = { limit };
    if (cursor) params.cursor = cursor;
    return this.get<CursorPaginatedResponse<Notification>>(`/notifications${this.buildQueryString(params)}`);
  }

  getUnreadNotificationCount(): Promise<{ count: number }> {
    return this.get<{ count: number }>('/notifications/unread-count');
  }

  getNotification(id: string): Promise<Notification> {
    return this.get<Notification>(`/notifications/${id}`);
  }

  markNotificationAsRead(id: string): Promise<void> {
    return this.post<void>(`/notifications/${id}/read`);
  }

  markAllNotificationsAsRead(): Promise<void> {
    return this.post<void>('/notifications/read-all');
  }

  deleteNotification(id: string): Promise<void> {
    return this.delete<void>(`/notifications/${id}`);
  }

  deleteAllNotifications(): Promise<void> {
    return this.delete<void>('/notifications');
  }

  // ============================================
  // MEETUP ENDPOINTS
  // ============================================

  getSafeLocations(city?: string): Promise<SafeLocation[]> {
    return this.get<SafeLocation[]>(`/meetups/locations${this.buildQueryString({ city })}`);
  }

  // Alias for getSafeLocations
  getMeetupLocations(city?: string): Promise<SafeLocation[]> {
    return this.getSafeLocations(city);
  }

  getSafeLocation(id: string): Promise<SafeLocation> {
    return this.get<SafeLocation>(`/meetups/locations/${id}`);
  }

  scheduleMeetup(data: CreateMeetupDto): Promise<Meetup> {
    return this.post<Meetup>('/meetups', data);
  }

  getUpcomingMeetups(): Promise<Meetup[]> {
    return this.get<Meetup[]>('/meetups/upcoming');
  }

  getChatMeetups(chatId: string): Promise<Meetup[]> {
    return this.get<Meetup[]>(`/meetups/chat/${chatId}`);
  }

  getMeetup(id: string): Promise<Meetup> {
    return this.get<Meetup>(`/meetups/${id}`);
  }

  acceptMeetup(id: string): Promise<Meetup> {
    return this.put<Meetup>(`/meetups/${id}/accept`);
  }

  declineMeetup(id: string): Promise<Meetup> {
    return this.put<Meetup>(`/meetups/${id}/decline`);
  }

  cancelMeetup(id: string): Promise<Meetup> {
    return this.put<Meetup>(`/meetups/${id}/cancel`);
  }

  completeMeetup(id: string): Promise<Meetup> {
    return this.put<Meetup>(`/meetups/${id}/complete`);
  }

  noShowMeetup(id: string): Promise<Meetup> {
    return this.put<Meetup>(`/meetups/${id}/no-show`);
  }

  // ============================================
  // REPORT ENDPOINTS
  // ============================================

  createReport(data: CreateReportDto): Promise<Report> {
    return this.post<Report>('/reports', data);
  }

  checkIfReported(userId: string): Promise<{ reported: boolean }> {
    return this.get<{ reported: boolean }>(`/reports/check${this.buildQueryString({ userId })}`);
  }

  getMyReports(): Promise<Report[]> {
    return this.get<Report[]>('/reports/my-reports');
  }

  // ============================================
  // SAVED SEARCH ENDPOINTS
  // ============================================

  createSavedSearch(data: CreateSavedSearchDto): Promise<SavedSearch> {
    return this.post<SavedSearch>('/saved-searches', data);
  }

  getSavedSearches(): Promise<SavedSearch[]> {
    return this.get<SavedSearch[]>('/saved-searches');
  }

  checkSavedSearch(params: CreateSavedSearchDto): Promise<{ exists: boolean; id?: string }> {
    return this.get(`/saved-searches/check${this.buildQueryString(params)}`);
  }

  getSavedSearchesWithMatchesCount(): Promise<{ count: number }> {
    return this.get<{ count: number }>('/saved-searches/with-matches/count');
  }

  getSavedSearch(id: string): Promise<SavedSearch> {
    return this.get<SavedSearch>(`/saved-searches/${id}`);
  }

  updateSavedSearch(id: string, data: Partial<CreateSavedSearchDto>): Promise<SavedSearch> {
    return this.put<SavedSearch>(`/saved-searches/${id}`, data);
  }

  toggleSavedSearchNotifications(id: string, enabled: boolean): Promise<SavedSearch> {
    return this.put<SavedSearch>(`/saved-searches/${id}/notifications`, { enabled });
  }

  clearSavedSearchMatches(id: string): Promise<SavedSearch> {
    return this.put<SavedSearch>(`/saved-searches/${id}/clear-matches`);
  }

  deleteSavedSearch(id: string): Promise<void> {
    return this.delete<void>(`/saved-searches/${id}`);
  }

  deleteAllSavedSearches(): Promise<void> {
    return this.delete<void>('/saved-searches');
  }

  // ============================================
  // PRICE ALERT ENDPOINTS
  // ============================================

  getPriceAlerts(limit?: number): Promise<PriceAlert[]> {
    return this.get<PriceAlert[]>(`/price-alerts${this.buildQueryString({ limit })}`);
  }

  getUnreadPriceAlertsCount(): Promise<{ count: number }> {
    return this.get<{ count: number }>('/price-alerts/unread-count');
  }

  markPriceAlertAsRead(id: string): Promise<void> {
    return this.put<void>(`/price-alerts/${id}/read`);
  }

  markAllPriceAlertsAsRead(): Promise<void> {
    return this.put<void>('/price-alerts/read-all');
  }

  deletePriceAlert(id: string): Promise<void> {
    return this.delete<void>(`/price-alerts/${id}`);
  }

  deleteAllPriceAlerts(): Promise<void> {
    return this.delete<void>('/price-alerts');
  }

  // ============================================
  // QUICK REPLY ENDPOINTS
  // ============================================

  createQuickReply(data: CreateQuickReplyDto): Promise<QuickReply> {
    return this.post<QuickReply>('/quick-replies', data);
  }

  getQuickReplies(): Promise<QuickReply[]> {
    return this.get<QuickReply[]>('/quick-replies');
  }

  getQuickReply(id: string): Promise<QuickReply> {
    return this.get<QuickReply>(`/quick-replies/${id}`);
  }

  updateQuickReply(id: string, data: Partial<CreateQuickReplyDto>): Promise<QuickReply> {
    return this.put<QuickReply>(`/quick-replies/${id}`, data);
  }

  recordQuickReplyUsage(id: string): Promise<void> {
    return this.put<void>(`/quick-replies/${id}/usage`);
  }

  deleteQuickReply(id: string): Promise<void> {
    return this.delete<void>(`/quick-replies/${id}`);
  }

  initializeDefaultQuickReplies(): Promise<QuickReply[]> {
    return this.post<QuickReply[]>('/quick-replies/initialize');
  }

  resetQuickReplies(): Promise<QuickReply[]> {
    return this.post<QuickReply[]>('/quick-replies/reset');
  }

  // ============================================
  // UPLOAD ENDPOINTS
  // ============================================

  async uploadImage(file: File): Promise<{ url: string }> {
    const formData = new FormData();
    formData.append('file', file);

    const headers: HeadersInit = {};
    if (this.token) {
      headers['Authorization'] = `Bearer ${this.token}`;
    }

    const response = await fetch(`${API_URL}/upload/image`, {
      method: 'POST',
      headers,
      body: formData,
    });

    if (!response.ok) {
      const error = await response.json().catch(() => ({}));
      throw new Error(error.message || 'Failed to upload image');
    }

    return response.json();
  }

  async uploadImages(files: File[]): Promise<{ urls: string[] }> {
    const formData = new FormData();
    files.forEach((file) => {
      formData.append('files', file);
    });

    const headers: HeadersInit = {};
    if (this.token) {
      headers['Authorization'] = `Bearer ${this.token}`;
    }

    const response = await fetch(`${API_URL}/upload/images`, {
      method: 'POST',
      headers,
      body: formData,
    });

    if (!response.ok) {
      const error = await response.json().catch(() => ({}));
      throw new Error(error.message || 'Failed to upload images');
    }

    return response.json();
  }

  // ============================================
  // CATEGORY ENDPOINTS (New Hierarchical System)
  // ============================================

  getCategories(): Promise<Category[]> {
    return this.get<Category[]>('/categories');
  }

  getCategory(id: string): Promise<Category> {
    return this.get<Category>(`/categories/${id}`);
  }

  getCategoryBySlug(slug: string): Promise<Category> {
    return this.get<Category>(`/categories/slug/${slug}`);
  }

  getCategoryChildren(id: string): Promise<Category[]> {
    return this.get<Category[]>(`/categories/${id}/children`);
  }

  getCategoryAttributes(id: string): Promise<AttributeDefinition[]> {
    return this.get<AttributeDefinition[]>(`/categories/${id}/attributes`);
  }

  getCategoryBreadcrumb(id: string): Promise<Category[]> {
    return this.get<Category[]>(`/categories/${id}/breadcrumb`);
  }

  // ============================================
  // ATTRIBUTE ENDPOINTS
  // ============================================

  getAttributes(): Promise<AttributeDefinition[]> {
    return this.get<AttributeDefinition[]>('/attributes');
  }

  getAttributeBySlug(slug: string): Promise<AttributeDefinition> {
    return this.get<AttributeDefinition>(`/attributes/${slug}`);
  }

  getAttributeValues(slug: string): Promise<AttributeDefinition> {
    return this.get<AttributeDefinition>(`/attributes/${slug}/values`);
  }

  // ============================================
  // LOCATION ENDPOINTS (City/Division System)
  // ============================================

  getCities(): Promise<City[]> {
    return this.get<City[]>('/locations/cities');
  }

  getCitiesWithDivisions(): Promise<City[]> {
    return this.get<City[]>('/locations/cities/with-divisions');
  }

  getDivisions(cityId: string): Promise<Division[]> {
    return this.get<Division[]>(`/locations/cities/${cityId}/divisions`);
  }
}

export const api = new ApiClient();
