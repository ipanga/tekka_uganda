const API_URL = process.env.NEXT_PUBLIC_API_URL || 'http://localhost:4000/api/v1';

export interface AdminUser {
  id: string;
  email: string;
  displayName: string | null;
  role: 'ADMIN' | 'MODERATOR';
  photoUrl?: string | null;
}

export interface AuthTokens {
  accessToken: string;
  refreshToken: string;
  user: AdminUser;
}

class ApiClient {
  private token: string | null = null;
  private refreshToken: string | null = null;

  constructor() {
    // Restore tokens from localStorage on init
    if (typeof window !== 'undefined') {
      this.token = localStorage.getItem('admin_access_token');
      this.refreshToken = localStorage.getItem('admin_refresh_token');
    }
  }

  setTokens(accessToken: string, refreshToken: string) {
    this.token = accessToken;
    this.refreshToken = refreshToken;
    if (typeof window !== 'undefined') {
      localStorage.setItem('admin_access_token', accessToken);
      localStorage.setItem('admin_refresh_token', refreshToken);
    }
  }

  setToken(token: string) {
    this.token = token;
  }

  clearToken() {
    this.token = null;
    this.refreshToken = null;
    if (typeof window !== 'undefined') {
      localStorage.removeItem('admin_access_token');
      localStorage.removeItem('admin_refresh_token');
      localStorage.removeItem('admin_user');
    }
  }

  getStoredUser(): AdminUser | null {
    if (typeof window !== 'undefined') {
      const userStr = localStorage.getItem('admin_user');
      if (userStr) {
        try {
          return JSON.parse(userStr);
        } catch {
          return null;
        }
      }
    }
    return null;
  }

  setStoredUser(user: AdminUser) {
    if (typeof window !== 'undefined') {
      localStorage.setItem('admin_user', JSON.stringify(user));
    }
  }

  isAuthenticated(): boolean {
    return !!this.token;
  }

  // Admin authentication
  async adminLogin(email: string, password: string): Promise<AuthTokens> {
    const response = await fetch(`${API_URL}/auth/admin/login`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({ email, password }),
    });

    if (!response.ok) {
      const error = await response.json().catch(() => ({ message: 'Login failed' }));
      throw new Error(error.message || 'Invalid credentials');
    }

    const data: AuthTokens = await response.json();
    this.setTokens(data.accessToken, data.refreshToken);
    this.setStoredUser(data.user);
    return data;
  }

  async refreshTokens(): Promise<AuthTokens | null> {
    if (!this.refreshToken) return null;

    try {
      const response = await fetch(`${API_URL}/auth/refresh`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ refreshToken: this.refreshToken }),
      });

      if (!response.ok) {
        this.clearToken();
        return null;
      }

      const data: AuthTokens = await response.json();
      this.setTokens(data.accessToken, data.refreshToken);
      this.setStoredUser(data.user);
      return data;
    } catch {
      this.clearToken();
      return null;
    }
  }

  private async request<T>(
    endpoint: string,
    options: RequestInit = {}
  ): Promise<T> {
    const headers: HeadersInit = {
      'Content-Type': 'application/json',
      ...(options.headers || {}),
    };

    if (this.token) {
      (headers as Record<string, string>)['Authorization'] = `Bearer ${this.token}`;
    }

    const response = await fetch(`${API_URL}${endpoint}`, {
      ...options,
      headers,
    });

    if (!response.ok) {
      const error = await response.json().catch(() => ({ message: 'Request failed' }));
      throw new Error(error.message || `HTTP error ${response.status}`);
    }

    return response.json();
  }

  // Dashboard
  async getDashboardStats() {
    return this.request<{
      totalUsers: number;
      activeUsers: number;
      totalListings: number;
      activeListings: number;
      pendingListings: number;
      totalTransactions: number;
      pendingReports: number;
    }>('/admin/stats');
  }

  // Users
  async getUsers(params?: { page?: number; limit?: number; search?: string; role?: string }): Promise<{ data?: any[]; totalPages?: number } | any[]> {
    const query = new URLSearchParams();
    if (params?.page) query.set('page', params.page.toString());
    if (params?.limit) query.set('limit', params.limit.toString());
    if (params?.search) query.set('search', params.search);
    if (params?.role) query.set('role', params.role);
    return this.request(`/admin/users?${query.toString()}`);
  }

  async getUser(id: string) {
    return this.request(`/admin/users/${id}`);
  }

  async updateUserRole(id: string, role: string) {
    return this.request(`/admin/users/${id}/role`, {
      method: 'PUT',
      body: JSON.stringify({ role }),
    });
  }

  async suspendUser(id: string, reason: string) {
    return this.request(`/admin/users/${id}/suspend`, {
      method: 'POST',
      body: JSON.stringify({ reason }),
    });
  }

  async unsuspendUser(id: string) {
    return this.request(`/admin/users/${id}/unsuspend`, {
      method: 'POST',
    });
  }

  // Listings
  async getListings(params?: {
    page?: number;
    limit?: number;
    status?: string;
    category?: string;
  }): Promise<{ data?: any[]; totalPages?: number } | any[]> {
    const query = new URLSearchParams();
    if (params?.page) query.set('page', params.page.toString());
    if (params?.limit) query.set('limit', params.limit.toString());
    if (params?.status) query.set('status', params.status);
    if (params?.category) query.set('category', params.category);
    return this.request(`/admin/listings?${query.toString()}`);
  }

  async getPendingListings(params?: { page?: number; limit?: number }) {
    const query = new URLSearchParams();
    if (params?.page) query.set('page', params.page.toString());
    if (params?.limit) query.set('limit', params.limit.toString());
    return this.request(`/listings/admin/pending?${query.toString()}`);
  }

  async approveListing(id: string) {
    return this.request(`/listings/admin/${id}/approve`, {
      method: 'POST',
    });
  }

  async rejectListing(id: string, reason: string) {
    return this.request(`/listings/admin/${id}/reject`, {
      method: 'POST',
      body: JSON.stringify({ reason }),
    });
  }

  async suspendListing(id: string, reason?: string) {
    return this.request(`/listings/admin/${id}/suspend`, {
      method: 'POST',
      body: JSON.stringify({ reason }),
    });
  }

  async getListing(id: string) {
    return this.request<any>(`/listings/${id}`);
  }

  async deleteListing(id: string) {
    return this.request(`/admin/listings/${id}`, {
      method: 'DELETE',
    });
  }

  // Reports
  async getReports(params?: { page?: number; limit?: number; status?: string }): Promise<{ data?: any[]; totalPages?: number } | any[]> {
    const query = new URLSearchParams();
    if (params?.page) query.set('page', params.page.toString());
    if (params?.limit) query.set('limit', params.limit.toString());
    if (params?.status) query.set('status', params.status);
    return this.request(`/admin/reports?${query.toString()}`);
  }

  async resolveReport(id: string, resolution: string) {
    return this.request(`/admin/reports/${id}/resolve`, {
      method: 'POST',
      body: JSON.stringify({ resolution }),
    });
  }

  async dismissReport(id: string) {
    return this.request(`/admin/reports/${id}/dismiss`, {
      method: 'POST',
    });
  }

  // Notifications
  async sendNotification(userId: string, title: string, body: string) {
    return this.request('/notifications/admin/send', {
      method: 'POST',
      body: JSON.stringify({ userId, title, body, type: 'SYSTEM' }),
    });
  }

  async sendBulkNotification(userIds: string[], title: string, body: string) {
    return this.request('/notifications/admin/send-bulk', {
      method: 'POST',
      body: JSON.stringify({ userIds, title, body, type: 'SYSTEM' }),
    });
  }

  // Transactions
  async getTransactions(params?: {
    page?: number;
    limit?: number;
    status?: string;
    search?: string;
  }): Promise<{ data?: any[]; totalPages?: number } | any[]> {
    const query = new URLSearchParams();
    if (params?.page) query.set('page', params.page.toString());
    if (params?.limit) query.set('limit', params.limit.toString());
    if (params?.status) query.set('status', params.status);
    if (params?.search) query.set('search', params.search);
    return this.request(`/admin/transactions?${query.toString()}`);
  }

  async getTransaction(id: string) {
    return this.request(`/admin/transactions/${id}`);
  }

  async cancelTransaction(id: string, reason: string) {
    return this.request(`/admin/transactions/${id}/cancel`, {
      method: 'POST',
      body: JSON.stringify({ reason }),
    });
  }

  async resolveDispute(id: string, resolution: string, refundAmount?: number) {
    return this.request(`/admin/transactions/${id}/resolve-dispute`, {
      method: 'POST',
      body: JSON.stringify({ resolution, refundAmount }),
    });
  }

  // Verifications
  async getVerificationRequests(params?: {
    page?: number;
    limit?: number;
    status?: string;
    type?: string;
  }): Promise<{ data?: any[]; totalPages?: number } | any[]> {
    const query = new URLSearchParams();
    if (params?.page) query.set('page', params.page.toString());
    if (params?.limit) query.set('limit', params.limit.toString());
    if (params?.status) query.set('status', params.status);
    if (params?.type) query.set('type', params.type);
    return this.request(`/admin/verifications?${query.toString()}`);
  }

  async approveVerification(id: string, notes?: string) {
    return this.request(`/admin/verifications/${id}/approve`, {
      method: 'POST',
      body: JSON.stringify({ notes }),
    });
  }

  async rejectVerification(id: string, reason: string) {
    return this.request(`/admin/verifications/${id}/reject`, {
      method: 'POST',
      body: JSON.stringify({ reason }),
    });
  }

  // Analytics
  async getAnalyticsOverview(period: 'day' | 'week' | 'month' | 'year' = 'month') {
    return this.request(`/admin/analytics/overview?period=${period}`);
  }

  async getUserGrowth(period: 'day' | 'week' | 'month' | 'year' = 'month') {
    return this.request(`/admin/analytics/users?period=${period}`);
  }

  async getListingGrowth(period: 'day' | 'week' | 'month' | 'year' = 'month') {
    return this.request(`/admin/analytics/listings?period=${period}`);
  }

  async getTransactionAnalytics(period: 'day' | 'week' | 'month' | 'year' = 'month') {
    return this.request(`/admin/analytics/transactions?period=${period}`);
  }

  async getRevenueByCategory() {
    return this.request('/admin/analytics/revenue-by-category');
  }

  async getTopSellers(limit: number = 10) {
    return this.request(`/admin/analytics/top-sellers?limit=${limit}`);
  }

  // Admin Notifications Management
  async getAdminNotifications(params?: {
    page?: number;
    limit?: number;
    status?: string;
  }): Promise<{ data?: any[]; totalPages?: number } | any[]> {
    const query = new URLSearchParams();
    if (params?.page) query.set('page', params.page.toString());
    if (params?.limit) query.set('limit', params.limit.toString());
    if (params?.status) query.set('status', params.status);
    return this.request(`/admin/notifications?${query.toString()}`);
  }

  async createNotificationCampaign(data: {
    type: string;
    title: string;
    body: string;
    targetType: string;
    targetRole?: string;
    targetUserIds?: string[];
    scheduledAt?: string;
  }) {
    return this.request('/admin/notifications/campaign', {
      method: 'POST',
      body: JSON.stringify(data),
    });
  }

  async sendNotificationCampaign(id: string) {
    return this.request(`/admin/notifications/campaign/${id}/send`, {
      method: 'POST',
    });
  }

  // Admin Users
  async getAdminUsers(params?: {
    page?: number;
    limit?: number;
  }): Promise<{ data?: any[]; totalPages?: number } | any[]> {
    const query = new URLSearchParams();
    if (params?.page) query.set('page', params.page.toString());
    if (params?.limit) query.set('limit', params.limit.toString());
    return this.request(`/admin/admins?${query.toString()}`);
  }

  async createAdminUser(data: {
    email: string;
    displayName: string;
    role: 'ADMIN' | 'MODERATOR';
    permissions: string[];
  }) {
    return this.request('/admin/admins', {
      method: 'POST',
      body: JSON.stringify(data),
    });
  }

  async updateAdminPermissions(id: string, permissions: string[]) {
    return this.request(`/admin/admins/${id}/permissions`, {
      method: 'PUT',
      body: JSON.stringify({ permissions }),
    });
  }

  async removeAdmin(id: string) {
    return this.request(`/admin/admins/${id}`, {
      method: 'DELETE',
    });
  }

  // Reviews
  async getReviews(params?: {
    page?: number;
    limit?: number;
    search?: string;
  }): Promise<{ data?: any[]; totalPages?: number; total?: number } | any[]> {
    const query = new URLSearchParams();
    if (params?.page) query.set('page', params.page.toString());
    if (params?.limit) query.set('limit', params.limit.toString());
    if (params?.search) query.set('search', params.search);
    return this.request(`/reviews/admin/list?${query.toString()}`);
  }

  async deleteReview(id: string) {
    return this.request(`/reviews/admin/${id}`, {
      method: 'DELETE',
    });
  }

  // Audit Logs
  async getAuditLogs(params?: {
    page?: number;
    limit?: number;
    adminId?: string;
    targetType?: string;
  }): Promise<{ data?: any[]; totalPages?: number } | any[]> {
    const query = new URLSearchParams();
    if (params?.page) query.set('page', params.page.toString());
    if (params?.limit) query.set('limit', params.limit.toString());
    if (params?.adminId) query.set('adminId', params.adminId);
    if (params?.targetType) query.set('targetType', params.targetType);
    return this.request(`/admin/audit-logs?${query.toString()}`);
  }

  // Categories
  async getCategories(): Promise<any[]> {
    return this.request('/admin/categories');
  }

  async createCategory(data: {
    name: string;
    slug: string;
    level: number;
    parentId?: string;
    imageUrl?: string;
    iconName?: string;
    sortOrder?: number;
  }) {
    return this.request('/admin/categories', {
      method: 'POST',
      body: JSON.stringify(data),
    });
  }

  async updateCategory(id: string, data: {
    name?: string;
    imageUrl?: string;
    iconName?: string;
    isActive?: boolean;
    sortOrder?: number;
  }) {
    return this.request(`/admin/categories/${id}`, {
      method: 'PUT',
      body: JSON.stringify(data),
    });
  }

  async deleteCategory(id: string) {
    return this.request(`/admin/categories/${id}`, {
      method: 'DELETE',
    });
  }

  // Attributes
  async getAttributes(): Promise<any[]> {
    return this.request('/admin/attributes');
  }

  async createAttribute(data: {
    name: string;
    slug: string;
    type: string;
    isRequired?: boolean;
    sortOrder?: number;
    values?: { value: string; displayValue?: string; sortOrder?: number }[];
  }) {
    return this.request('/admin/attributes', {
      method: 'POST',
      body: JSON.stringify(data),
    });
  }

  async updateAttribute(id: string, data: {
    name?: string;
    isRequired?: boolean;
    sortOrder?: number;
    isActive?: boolean;
  }) {
    return this.request(`/admin/attributes/${id}`, {
      method: 'PUT',
      body: JSON.stringify(data),
    });
  }

  async deleteAttribute(id: string) {
    return this.request(`/admin/attributes/${id}`, {
      method: 'DELETE',
    });
  }

  // Locations
  async getLocations(): Promise<any[]> {
    return this.request('/admin/locations');
  }

  async createCity(data: { name: string; sortOrder?: number }) {
    return this.request('/admin/locations/cities', {
      method: 'POST',
      body: JSON.stringify(data),
    });
  }

  async updateCity(id: string, data: { name?: string; sortOrder?: number; isActive?: boolean }) {
    return this.request(`/admin/locations/cities/${id}`, {
      method: 'PUT',
      body: JSON.stringify(data),
    });
  }

  async deleteCity(id: string) {
    return this.request(`/admin/locations/cities/${id}`, {
      method: 'DELETE',
    });
  }

  async createDivision(data: { cityId: string; name: string; sortOrder?: number }) {
    return this.request('/admin/locations/divisions', {
      method: 'POST',
      body: JSON.stringify(data),
    });
  }

  async updateDivision(id: string, data: { name?: string; sortOrder?: number; isActive?: boolean }) {
    return this.request(`/admin/locations/divisions/${id}`, {
      method: 'PUT',
      body: JSON.stringify(data),
    });
  }

  async deleteDivision(id: string) {
    return this.request(`/admin/locations/divisions/${id}`, {
      method: 'DELETE',
    });
  }
}

export const api = new ApiClient();
