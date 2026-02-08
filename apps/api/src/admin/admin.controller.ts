import {
  Controller,
  Get,
  Post,
  Put,
  Delete,
  Body,
  Param,
  Query,
  UseGuards,
} from '@nestjs/common';
import { AdminService } from './admin.service';
import { JwtAuthGuard } from '../auth/guards/jwt-auth.guard';
import { AdminGuard } from '../auth/guards/admin.guard';
import { CurrentUser } from '../auth/decorators/current-user.decorator';
import * as Prisma from '@prisma/client';

@Controller('admin')
@UseGuards(JwtAuthGuard, AdminGuard)
export class AdminController {
  constructor(private readonly adminService: AdminService) {}

  // ===== DASHBOARD STATS =====
  @Get('stats')
  async getDashboardStats() {
    return this.adminService.getDashboardStats();
  }

  // ===== USERS =====
  @Get('users')
  async getUsers(
    @Query('page') page?: number,
    @Query('limit') limit?: number,
    @Query('search') search?: string,
    @Query('role') role?: string,
  ) {
    return this.adminService.getUsers({ page, limit, search, role });
  }

  @Get('users/:id')
  async getUser(@Param('id') id: string) {
    return this.adminService.getUser(id);
  }

  @Put('users/:id/role')
  async updateUserRole(
    @Param('id') id: string,
    @Body('role') role: string,
    @CurrentUser() admin: Prisma.User,
  ) {
    return this.adminService.updateUserRole(id, role, admin.id);
  }

  @Post('users/:id/suspend')
  async suspendUser(
    @Param('id') id: string,
    @Body('reason') reason: string,
    @CurrentUser() admin: Prisma.User,
  ) {
    return this.adminService.suspendUser(id, reason, admin.id);
  }

  @Post('users/:id/unsuspend')
  async unsuspendUser(
    @Param('id') id: string,
    @CurrentUser() admin: Prisma.User,
  ) {
    return this.adminService.unsuspendUser(id, admin.id);
  }

  // ===== LISTINGS =====
  @Get('listings')
  async getListings(
    @Query('page') page?: number,
    @Query('limit') limit?: number,
    @Query('status') status?: string,
    @Query('category') category?: string,
  ) {
    return this.adminService.getListings({ page, limit, status, category });
  }

  @Delete('listings/:id')
  async deleteListing(
    @Param('id') id: string,
    @CurrentUser() admin: Prisma.User,
  ) {
    return this.adminService.deleteListing(id, admin.id);
  }

  // ===== REPORTS =====
  @Get('reports')
  async getReports(
    @Query('page') page?: number,
    @Query('limit') limit?: number,
    @Query('status') status?: string,
  ) {
    return this.adminService.getReports({ page, limit, status });
  }

  @Post('reports/:id/resolve')
  async resolveReport(
    @Param('id') id: string,
    @Body('resolution') resolution: string,
    @CurrentUser() admin: Prisma.User,
  ) {
    return this.adminService.resolveReport(id, resolution, admin.id);
  }

  @Post('reports/:id/dismiss')
  async dismissReport(
    @Param('id') id: string,
    @CurrentUser() admin: Prisma.User,
  ) {
    return this.adminService.dismissReport(id, admin.id);
  }

  // ===== ANALYTICS =====
  @Get('analytics/overview')
  async getAnalyticsOverview(@Query('period') period?: string) {
    return this.adminService.getAnalyticsOverview(period);
  }

  @Get('analytics/users')
  async getUserGrowth(@Query('period') period?: string) {
    return this.adminService.getUserGrowth(period);
  }

  @Get('analytics/listings')
  async getListingGrowth(@Query('period') period?: string) {
    return this.adminService.getListingGrowth(period);
  }

  @Get('analytics/revenue-by-category')
  async getRevenueByCategory() {
    return this.adminService.getRevenueByCategory();
  }

  @Get('analytics/top-sellers')
  async getTopSellers(@Query('limit') limit?: number) {
    return this.adminService.getTopSellers(limit);
  }

  // ===== CATEGORIES =====
  @Get('categories')
  async getCategories() {
    return this.adminService.getCategories();
  }

  @Post('categories')
  async createCategory(
    @Body()
    data: {
      name: string;
      slug: string;
      level: number;
      parentId?: string;
      imageUrl?: string;
      iconName?: string;
      sortOrder?: number;
    },
  ) {
    return this.adminService.createCategory(data);
  }

  @Put('categories/:id')
  async updateCategory(
    @Param('id') id: string,
    @Body()
    data: {
      name?: string;
      imageUrl?: string;
      iconName?: string;
      sortOrder?: number;
      isActive?: boolean;
    },
  ) {
    return this.adminService.updateCategory(id, data);
  }

  @Delete('categories/:id')
  async deleteCategory(@Param('id') id: string) {
    return this.adminService.deleteCategory(id);
  }

  // ===== ATTRIBUTES =====
  @Get('attributes')
  async getAttributes() {
    return this.adminService.getAttributes();
  }

  @Post('attributes')
  async createAttribute(
    @Body()
    data: {
      name: string;
      slug: string;
      type: string;
      isRequired?: boolean;
      sortOrder?: number;
      values?: { value: string; displayValue?: string; sortOrder?: number }[];
    },
  ) {
    return this.adminService.createAttribute(data);
  }

  @Put('attributes/:id')
  async updateAttribute(
    @Param('id') id: string,
    @Body()
    data: {
      name?: string;
      isRequired?: boolean;
      sortOrder?: number;
      isActive?: boolean;
    },
  ) {
    return this.adminService.updateAttribute(id, data);
  }

  @Delete('attributes/:id')
  async deleteAttribute(@Param('id') id: string) {
    return this.adminService.deleteAttribute(id);
  }

  // ===== LOCATIONS =====
  @Get('locations')
  async getLocations() {
    return this.adminService.getLocations();
  }

  @Post('locations/cities')
  async createCity(@Body() data: { name: string; sortOrder?: number }) {
    return this.adminService.createCity(data);
  }

  @Put('locations/cities/:id')
  async updateCity(
    @Param('id') id: string,
    @Body()
    data: {
      name?: string;
      sortOrder?: number;
      isActive?: boolean;
    },
  ) {
    return this.adminService.updateCity(id, data);
  }

  @Delete('locations/cities/:id')
  async deleteCity(@Param('id') id: string) {
    return this.adminService.deleteCity(id);
  }

  @Post('locations/divisions')
  async createDivision(
    @Body() data: { cityId: string; name: string; sortOrder?: number },
  ) {
    return this.adminService.createDivision(data);
  }

  @Put('locations/divisions/:id')
  async updateDivision(
    @Param('id') id: string,
    @Body()
    data: {
      name?: string;
      sortOrder?: number;
      isActive?: boolean;
    },
  ) {
    return this.adminService.updateDivision(id, data);
  }

  @Delete('locations/divisions/:id')
  async deleteDivision(@Param('id') id: string) {
    return this.adminService.deleteDivision(id);
  }

  // ===== VERIFICATIONS =====
  @Get('verifications')
  async getVerifications(
    @Query('page') page?: number,
    @Query('limit') limit?: number,
    @Query('status') status?: string,
    @Query('type') type?: string,
  ) {
    return this.adminService.getVerifications({ page, limit, status, type });
  }

  @Post('verifications/:id/approve')
  async approveVerification(
    @Param('id') id: string,
    @Body('notes') notes: string,
    @CurrentUser() admin: Prisma.User,
  ) {
    return this.adminService.approveVerification(id, notes, admin.id);
  }

  @Post('verifications/:id/reject')
  async rejectVerification(
    @Param('id') id: string,
    @Body('reason') reason: string,
    @CurrentUser() admin: Prisma.User,
  ) {
    return this.adminService.rejectVerification(id, reason, admin.id);
  }

  // ===== NOTIFICATIONS =====
  @Get('notifications')
  async getNotifications(
    @Query('page') page?: number,
    @Query('limit') limit?: number,
    @Query('status') status?: string,
  ) {
    return this.adminService.getAdminNotifications({ page, limit, status });
  }

  @Post('notifications/campaign')
  async createNotificationCampaign(
    @Body()
    data: {
      type: string;
      title: string;
      body: string;
      targetType: string;
      targetRole?: string;
      targetUserIds?: string[];
      scheduledAt?: string;
    },
    @CurrentUser() admin: Prisma.User,
  ) {
    return this.adminService.createNotificationCampaign(data, admin.id);
  }

  @Post('notifications/campaign/:id/send')
  sendNotificationCampaign(
    @Param('id') id: string,
    @CurrentUser() admin: Prisma.User,
  ) {
    return this.adminService.sendNotificationCampaign(id, admin.id);
  }

  // ===== ADMIN USERS =====
  @Get('admins')
  async getAdmins(
    @Query('page') page?: number,
    @Query('limit') limit?: number,
  ) {
    return this.adminService.getAdmins({ page, limit });
  }

  @Post('admins')
  async createAdmin(
    @Body()
    data: {
      email: string;
      displayName: string;
      role: 'ADMIN' | 'MODERATOR';
      permissions?: string[];
    },
    @CurrentUser() admin: Prisma.User,
  ) {
    return this.adminService.createAdmin(data, admin.id);
  }

  @Put('admins/:id/permissions')
  updateAdminPermissions(
    @Param('id') id: string,
    @Body('permissions') permissions: string[],
    @CurrentUser() admin: Prisma.User,
  ) {
    return this.adminService.updateAdminPermissions(id, permissions, admin.id);
  }

  @Delete('admins/:id')
  async removeAdmin(
    @Param('id') id: string,
    @CurrentUser() admin: Prisma.User,
  ) {
    return this.adminService.removeAdmin(id, admin.id);
  }
}
