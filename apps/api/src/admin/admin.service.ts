import {
  Injectable,
  NotFoundException,
  BadRequestException,
} from '@nestjs/common';
import { PrismaService } from '../prisma/prisma.service';
import { ListingsService } from '../listings/listings.service';
import {
  ListingStatus,
  UserRole,
  ReportStatus,
  AttributeType,
} from '@prisma/client';
import * as bcrypt from 'bcrypt';

@Injectable()
export class AdminService {
  constructor(
    private prisma: PrismaService,
    private listingsService: ListingsService,
  ) {}

  // ===== DASHBOARD STATS =====
  async getDashboardStats() {
    const [
      totalUsers,
      activeUsers,
      totalListings,
      activeListings,
      pendingListings,
      soldListings,
      pendingReports,
    ] = await Promise.all([
      this.prisma.user.count(),
      this.prisma.user.count({
        where: {
          updatedAt: {
            gte: new Date(Date.now() - 30 * 24 * 60 * 60 * 1000), // Last 30 days
          },
        },
      }),
      this.prisma.listing.count(),
      this.prisma.listing.count({ where: { status: ListingStatus.ACTIVE } }),
      this.prisma.listing.count({ where: { status: ListingStatus.PENDING } }),
      this.prisma.listing.count({ where: { status: ListingStatus.SOLD } }),
      this.prisma.report.count({ where: { status: ReportStatus.PENDING } }),
    ]);

    return {
      totalUsers,
      activeUsers,
      totalListings,
      activeListings,
      pendingListings,
      totalTransactions: soldListings,
      pendingReports,
    };
  }

  // ===== USERS =====
  async getUsers(params: {
    page?: number;
    limit?: number;
    search?: string;
    role?: string;
  }) {
    const page = params.page || 1;
    const limit = params.limit || 10;
    const skip = (page - 1) * limit;

    const where: any = {};

    if (params.search) {
      where.OR = [
        { displayName: { contains: params.search, mode: 'insensitive' } },
        { phoneNumber: { contains: params.search } },
        { email: { contains: params.search, mode: 'insensitive' } },
      ];
    }

    if (params.role) {
      where.role = params.role;
    }

    const [users, total] = await Promise.all([
      this.prisma.user.findMany({
        where,
        skip,
        take: limit,
        orderBy: { createdAt: 'desc' },
        select: {
          id: true,
          phoneNumber: true,
          email: true,
          displayName: true,
          photoUrl: true,
          role: true,
          isVerified: true,
          isSuspended: true,
          createdAt: true,
          _count: {
            select: {
              listings: true,
              reviewsGiven: true,
              reviewsReceived: true,
            },
          },
        },
      }),
      this.prisma.user.count({ where }),
    ]);

    return {
      data: users,
      total,
      page,
      limit,
      totalPages: Math.ceil(total / limit),
    };
  }

  async getUser(id: string) {
    const user = await this.prisma.user.findUnique({
      where: { id },
      include: {
        _count: {
          select: {
            listings: true,
            reviewsGiven: true,
            reviewsReceived: true,
          },
        },
      },
    });

    if (!user) {
      throw new NotFoundException('User not found');
    }

    return user;
  }

  async updateUserRole(id: string, role: string, _adminId: string) {
    const validRoles = Object.values(UserRole);
    if (!validRoles.includes(role as UserRole)) {
      throw new BadRequestException('Invalid role');
    }

    const user = await this.prisma.user.update({
      where: { id },
      data: { role: role as UserRole },
    });

    return user;
  }

  async suspendUser(id: string, reason: string, _adminId: string) {
    const user = await this.prisma.user.update({
      where: { id },
      data: {
        isSuspended: true,
        suspendedReason: reason,
      },
    });

    return user;
  }

  async unsuspendUser(id: string, _adminId: string) {
    const user = await this.prisma.user.update({
      where: { id },
      data: {
        isSuspended: false,
        suspendedReason: null,
      },
    });

    return user;
  }

  // ===== LISTINGS =====
  async getListings(params: {
    page?: number;
    limit?: number;
    status?: string;
    category?: string;
  }) {
    const page = params.page || 1;
    const limit = params.limit || 10;
    const skip = (page - 1) * limit;

    const where: any = {};

    if (params.status) {
      where.status = params.status;
    }

    if (params.category) {
      where.category = params.category;
    }

    const [listings, total] = await Promise.all([
      this.prisma.listing.findMany({
        where,
        skip,
        take: limit,
        orderBy: { createdAt: 'desc' },
        include: {
          seller: {
            select: {
              id: true,
              displayName: true,
              phoneNumber: true,
              photoUrl: true,
            },
          },
          // Include category hierarchy for new category system
          categoryRef: {
            include: {
              parent: {
                include: {
                  parent: true, // Include grandparent (main category)
                },
              },
            },
          },
          // Include location references
          cityRef: true,
          divisionRef: true,
        },
      }),
      this.prisma.listing.count({ where }),
    ]);

    // Transform listings to include properly named category/location data
    const transformedListings = listings.map((listing) => {
      const { categoryRef, cityRef, divisionRef, ...rest } = listing as any;
      return {
        ...rest,
        // Map Prisma relations to frontend expected names
        categoryData: categoryRef,
        city: cityRef,
        division: divisionRef,
      };
    });

    return {
      data: transformedListings,
      total,
      page,
      limit,
      totalPages: Math.ceil(total / limit),
    };
  }

  async deleteListing(id: string, adminId: string) {
    await this.listingsService.adminDelete(id, adminId);
    return { success: true };
  }

  // ===== REPORTS =====
  async getReports(params: { page?: number; limit?: number; status?: string }) {
    const page = params.page || 1;
    const limit = params.limit || 10;
    const skip = (page - 1) * limit;

    const where: any = {};

    if (params.status) {
      where.status = params.status;
    }

    const [reports, total] = await Promise.all([
      this.prisma.report.findMany({
        where,
        skip,
        take: limit,
        orderBy: { createdAt: 'desc' },
        include: {
          reporter: {
            select: {
              id: true,
              displayName: true,
              phoneNumber: true,
            },
          },
          reportedUser: {
            select: {
              id: true,
              displayName: true,
              phoneNumber: true,
            },
          },
        },
      }),
      this.prisma.report.count({ where }),
    ]);

    return {
      data: reports,
      total,
      page,
      limit,
      totalPages: Math.ceil(total / limit),
    };
  }

  async resolveReport(id: string, resolution: string, adminId: string) {
    const report = await this.prisma.report.update({
      where: { id },
      data: {
        status: ReportStatus.RESOLVED,
        resolvedAt: new Date(),
        resolution,
        resolvedBy: adminId,
      },
    });

    return report;
  }

  async dismissReport(id: string, adminId: string) {
    const report = await this.prisma.report.update({
      where: { id },
      data: {
        status: ReportStatus.DISMISSED,
        resolvedAt: new Date(),
        resolvedBy: adminId,
      },
    });

    return report;
  }

  // ===== ANALYTICS =====
  async getAnalyticsOverview(period?: string) {
    const days = period === 'week' ? 7 : period === 'year' ? 365 : 30;
    const startDate = new Date(Date.now() - days * 24 * 60 * 60 * 1000);

    const [newUsers, newListings, soldListings] = await Promise.all([
      this.prisma.user.count({
        where: { createdAt: { gte: startDate } },
      }),
      this.prisma.listing.count({
        where: { createdAt: { gte: startDate } },
      }),
      this.prisma.listing.count({
        where: {
          status: ListingStatus.SOLD,
          updatedAt: { gte: startDate },
        },
      }),
    ]);

    return {
      period: period || 'month',
      newUsers,
      newListings,
      completedTransactions: soldListings,
    };
  }

  async getUserGrowth(period?: string) {
    const days = period === 'week' ? 7 : period === 'year' ? 365 : 30;
    const startDate = new Date(Date.now() - days * 24 * 60 * 60 * 1000);

    const users = await this.prisma.user.groupBy({
      by: ['createdAt'],
      where: { createdAt: { gte: startDate } },
      _count: true,
    });

    return {
      period: period || 'month',
      data: users,
    };
  }

  async getListingGrowth(period?: string) {
    const days = period === 'week' ? 7 : period === 'year' ? 365 : 30;
    const startDate = new Date(Date.now() - days * 24 * 60 * 60 * 1000);

    const listings = await this.prisma.listing.groupBy({
      by: ['createdAt'],
      where: { createdAt: { gte: startDate } },
      _count: true,
    });

    return {
      period: period || 'month',
      data: listings,
    };
  }

  async getRevenueByCategory() {
    // Get listings that have been sold with their categories
    const soldListings = await this.prisma.listing.findMany({
      where: { status: ListingStatus.SOLD },
      select: {
        price: true,
        categoryRef: {
          select: { name: true, slug: true },
        },
      },
    });

    // Aggregate by category
    const revenueMap = new Map<
      string,
      { name: string; revenue: number; count: number }
    >();
    for (const listing of soldListings) {
      const catName = listing.categoryRef?.name || 'Uncategorized';
      const existing = revenueMap.get(catName) || {
        name: catName,
        revenue: 0,
        count: 0,
      };
      existing.revenue += listing.price;
      existing.count += 1;
      revenueMap.set(catName, existing);
    }

    return Array.from(revenueMap.values()).sort(
      (a, b) => b.revenue - a.revenue,
    );
  }

  async getTopSellers(limit?: number) {
    const take = limit || 10;

    const sellers = await this.prisma.user.findMany({
      where: {
        listings: {
          some: { status: ListingStatus.SOLD },
        },
      },
      select: {
        id: true,
        displayName: true,
        photoUrl: true,
        _count: {
          select: {
            listings: { where: { status: ListingStatus.SOLD } },
          },
        },
      },
      orderBy: {
        listings: { _count: 'desc' },
      },
      take,
    });

    return sellers;
  }

  // ===== CATEGORIES =====
  async getCategories() {
    return this.prisma.category.findMany({
      include: {
        parent: { select: { id: true, name: true, slug: true } },
        children: { select: { id: true, name: true, slug: true, level: true } },
        _count: { select: { listings: true } },
      },
      orderBy: [{ level: 'asc' }, { sortOrder: 'asc' }],
    });
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
    return this.prisma.category.create({
      data: {
        name: data.name,
        slug: data.slug,
        level: data.level,
        parentId: data.parentId,
        imageUrl: data.imageUrl,
        iconName: data.iconName,
        sortOrder: data.sortOrder || 0,
      },
    });
  }

  async updateCategory(
    id: string,
    data: {
      name?: string;
      imageUrl?: string;
      iconName?: string;
      sortOrder?: number;
      isActive?: boolean;
    },
  ) {
    return this.prisma.category.update({
      where: { id },
      data,
    });
  }

  async deleteCategory(id: string) {
    // Check if category has children or listings
    const category = await this.prisma.category.findUnique({
      where: { id },
      include: { _count: { select: { children: true, listings: true } } },
    });

    if (!category) {
      throw new NotFoundException('Category not found');
    }

    if (category._count.children > 0) {
      throw new BadRequestException(
        'Cannot delete category with subcategories',
      );
    }

    if (category._count.listings > 0) {
      throw new BadRequestException('Cannot delete category with listings');
    }

    await this.prisma.category.delete({ where: { id } });
    return { success: true };
  }

  // ===== ATTRIBUTES =====
  async getAttributes() {
    return this.prisma.attributeDefinition.findMany({
      include: {
        values: { orderBy: { sortOrder: 'asc' } },
        _count: { select: { categories: true } },
      },
      orderBy: { sortOrder: 'asc' },
    });
  }

  async createAttribute(data: {
    name: string;
    slug: string;
    type: string;
    isRequired?: boolean;
    sortOrder?: number;
    values?: { value: string; displayValue?: string; sortOrder?: number }[];
  }) {
    const validTypes = Object.values(AttributeType);
    if (!validTypes.includes(data.type as AttributeType)) {
      throw new BadRequestException('Invalid attribute type');
    }

    return this.prisma.attributeDefinition.create({
      data: {
        name: data.name,
        slug: data.slug,
        type: data.type as AttributeType,
        isRequired: data.isRequired || false,
        sortOrder: data.sortOrder || 0,
        values: data.values
          ? {
              create: data.values.map((v, i) => ({
                value: v.value,
                displayValue: v.displayValue,
                sortOrder: v.sortOrder || i,
              })),
            }
          : undefined,
      },
      include: { values: true },
    });
  }

  async updateAttribute(
    id: string,
    data: {
      name?: string;
      isRequired?: boolean;
      sortOrder?: number;
      isActive?: boolean;
    },
  ) {
    return this.prisma.attributeDefinition.update({
      where: { id },
      data,
    });
  }

  async deleteAttribute(id: string) {
    await this.prisma.attributeDefinition.delete({ where: { id } });
    return { success: true };
  }

  // ===== LOCATIONS =====
  async getLocations() {
    return this.prisma.city.findMany({
      include: {
        divisions: { orderBy: { sortOrder: 'asc' } },
        _count: { select: { listings: true } },
      },
      orderBy: { sortOrder: 'asc' },
    });
  }

  async createCity(data: { name: string; sortOrder?: number }) {
    return this.prisma.city.create({
      data: {
        name: data.name,
        sortOrder: data.sortOrder || 0,
      },
    });
  }

  async updateCity(
    id: string,
    data: { name?: string; sortOrder?: number; isActive?: boolean },
  ) {
    return this.prisma.city.update({
      where: { id },
      data,
    });
  }

  async deleteCity(id: string) {
    const city = await this.prisma.city.findUnique({
      where: { id },
      include: { _count: { select: { listings: true } } },
    });

    if (!city) {
      throw new NotFoundException('City not found');
    }

    if (city._count.listings > 0) {
      throw new BadRequestException('Cannot delete city with listings');
    }

    await this.prisma.city.delete({ where: { id } });
    return { success: true };
  }

  async createDivision(data: {
    cityId: string;
    name: string;
    sortOrder?: number;
  }) {
    return this.prisma.division.create({
      data: {
        cityId: data.cityId,
        name: data.name,
        sortOrder: data.sortOrder || 0,
      },
    });
  }

  async updateDivision(
    id: string,
    data: { name?: string; sortOrder?: number; isActive?: boolean },
  ) {
    return this.prisma.division.update({
      where: { id },
      data,
    });
  }

  async deleteDivision(id: string) {
    const division = await this.prisma.division.findUnique({
      where: { id },
      include: { _count: { select: { listings: true } } },
    });

    if (!division) {
      throw new NotFoundException('Division not found');
    }

    if (division._count.listings > 0) {
      throw new BadRequestException('Cannot delete division with listings');
    }

    await this.prisma.division.delete({ where: { id } });
    return { success: true };
  }

  // ===== VERIFICATIONS =====
  async getVerifications(params: {
    page?: number;
    limit?: number;
    status?: string;
    type?: string;
  }) {
    const page = params.page || 1;
    const limit = params.limit || 10;
    const skip = (page - 1) * limit;

    // For now, return users with verification pending status
    const where: any = {};

    if (params.status === 'PENDING') {
      where.identityVerificationPending = true;
    } else if (params.status === 'APPROVED') {
      where.isIdentityVerified = true;
    }

    const [users, total] = await Promise.all([
      this.prisma.user.findMany({
        where,
        skip,
        take: limit,
        orderBy: { createdAt: 'desc' },
        select: {
          id: true,
          displayName: true,
          phoneNumber: true,
          email: true,
          photoUrl: true,
          isIdentityVerified: true,
          identityVerificationPending: true,
          identityVerifiedAt: true,
          createdAt: true,
        },
      }),
      this.prisma.user.count({ where }),
    ]);

    // Map to verification request format
    const data = users.map((u) => ({
      id: u.id,
      userId: u.id,
      user: u,
      type: 'IDENTITY',
      status: u.isIdentityVerified
        ? 'APPROVED'
        : u.identityVerificationPending
          ? 'PENDING'
          : 'NONE',
      createdAt: u.createdAt,
      verifiedAt: u.identityVerifiedAt,
    }));

    return {
      data,
      total,
      page,
      limit,
      totalPages: Math.ceil(total / limit),
    };
  }

  async approveVerification(id: string, _notes: string, _adminId: string) {
    const user = await this.prisma.user.update({
      where: { id },
      data: {
        isIdentityVerified: true,
        identityVerificationPending: false,
        identityVerifiedAt: new Date(),
      },
    });

    return { success: true, user };
  }

  async rejectVerification(id: string, _reason: string, _adminId: string) {
    const user = await this.prisma.user.update({
      where: { id },
      data: {
        identityVerificationPending: false,
      },
    });

    return { success: true, user };
  }

  // ===== NOTIFICATIONS =====
  async getAdminNotifications(params: {
    page?: number;
    limit?: number;
    status?: string;
  }) {
    const page = params.page || 1;
    const limit = params.limit || 10;
    const skip = (page - 1) * limit;

    const where: any = {
      type: 'SYSTEM',
    };

    const [notifications, total] = await Promise.all([
      this.prisma.notification.findMany({
        where,
        skip,
        take: limit,
        orderBy: { createdAt: 'desc' },
        include: {
          user: {
            select: { id: true, displayName: true, phoneNumber: true },
          },
        },
      }),
      this.prisma.notification.count({ where }),
    ]);

    return {
      data: notifications,
      total,
      page,
      limit,
      totalPages: Math.ceil(total / limit),
    };
  }

  async createNotificationCampaign(
    data: {
      type: string;
      title: string;
      body: string;
      targetType: string;
      targetRole?: string;
      targetUserIds?: string[];
      scheduledAt?: string;
    },
    adminId: string,
  ) {
    // Get target users
    let targetUsers: { id: string }[] = [];

    if (data.targetType === 'ALL') {
      targetUsers = await this.prisma.user.findMany({ select: { id: true } });
    } else if (data.targetType === 'ROLE' && data.targetRole) {
      targetUsers = await this.prisma.user.findMany({
        where: { role: data.targetRole as UserRole },
        select: { id: true },
      });
    } else if (data.targetType === 'SPECIFIC' && data.targetUserIds) {
      targetUsers = data.targetUserIds.map((id) => ({ id }));
    }

    return {
      id: `campaign_${Date.now()}`,
      ...data,
      targetCount: targetUsers.length,
      status: 'DRAFT',
      createdBy: adminId,
      createdAt: new Date(),
    };
  }

  sendNotificationCampaign(campaignId: string, _adminId: string) {
    // In a real implementation, this would send notifications
    return {
      success: true,
      campaignId,
      sentAt: new Date(),
    };
  }

  // ===== ADMIN USERS =====
  async getAdmins(params: { page?: number; limit?: number }) {
    const page = params.page || 1;
    const limit = params.limit || 10;
    const skip = (page - 1) * limit;

    const where = {
      role: { in: [UserRole.ADMIN, UserRole.MODERATOR] },
    };

    const [admins, total] = await Promise.all([
      this.prisma.user.findMany({
        where,
        skip,
        take: limit,
        orderBy: { createdAt: 'desc' },
        select: {
          id: true,
          email: true,
          displayName: true,
          photoUrl: true,
          role: true,
          createdAt: true,
          lastLoginAt: true,
        },
      }),
      this.prisma.user.count({ where }),
    ]);

    return {
      data: admins,
      total,
      page,
      limit,
      totalPages: Math.ceil(total / limit),
    };
  }

  async createAdmin(
    data: {
      email: string;
      displayName: string;
      role: 'ADMIN' | 'MODERATOR';
      permissions?: string[];
    },
    _createdById: string,
  ) {
    // Generate a temporary password
    const tempPassword = Math.random().toString(36).slice(-8);
    const hashedPassword = await bcrypt.hash(tempPassword, 10);

    const admin = await this.prisma.user.create({
      data: {
        email: data.email,
        displayName: data.displayName,
        role: data.role as UserRole,
        phoneNumber: `admin_${Date.now()}`, // Placeholder phone for admin users
        passwordHash: hashedPassword,
      },
    });

    return {
      ...admin,
      tempPassword, // Return temp password so it can be shared with the new admin
    };
  }

  updateAdminPermissions(id: string, permissions: string[], _adminId: string) {
    // For now, just return success since we don't have a permissions model yet
    return { success: true, id, permissions };
  }

  async removeAdmin(id: string, adminId: string) {
    if (id === adminId) {
      throw new BadRequestException('Cannot remove yourself');
    }

    await this.prisma.user.update({
      where: { id },
      data: { role: UserRole.USER },
    });

    return { success: true };
  }
}
