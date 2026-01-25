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
import { ListingsService } from './listings.service';
import { JwtAuthGuard } from '../auth/guards/jwt-auth.guard';
import { AdminGuard } from '../auth/guards/admin.guard';
import { CurrentUser } from '../auth/decorators/current-user.decorator';
import * as Prisma from '@prisma/client';
import {
  CreateListingDto,
  UpdateListingDto,
  ListingQueryDto,
  AdminListingActionDto,
} from './dto/listing.dto';

@Controller('listings')
export class ListingsController {
  constructor(private readonly listingsService: ListingsService) {}

  // Create a new listing
  @Post()
  @UseGuards(JwtAuthGuard)
  async create(
    @CurrentUser() user: Prisma.User,
    @Body() dto: CreateListingDto,
  ) {
    return this.listingsService.create(user.id, dto);
  }

  // Search/browse listings (public, but includes isSaved if authenticated)
  @Get()
  async search(
    @Query() query: ListingQueryDto,
    @CurrentUser() user: Prisma.User | null,
  ) {
    return this.listingsService.search(query, user?.id);
  }

  // Get current user's listings
  @Get('my')
  @UseGuards(JwtAuthGuard)
  async getMyListings(
    @CurrentUser() user: Prisma.User,
    @Query('status') status?: string,
  ) {
    return this.listingsService.getMyListings(user.id, status as any);
  }

  // Get saved listings
  @Get('saved')
  @UseGuards(JwtAuthGuard)
  async getSavedListings(@CurrentUser() user: Prisma.User) {
    return this.listingsService.getSavedListings(user.id);
  }

  // Get purchase history
  @Get('purchases')
  @UseGuards(JwtAuthGuard)
  async getPurchaseHistory(@CurrentUser() user: Prisma.User) {
    return this.listingsService.getPurchaseHistory(user.id);
  }

  // Get listings by a specific seller
  @Get('seller/:sellerId')
  async getListingsBySeller(
    @Param('sellerId') sellerId: string,
    @CurrentUser() user: Prisma.User | null,
  ) {
    return this.listingsService.getListingsBySeller(sellerId, user?.id);
  }

  // Check if listing is saved
  @Get(':id/saved')
  @UseGuards(JwtAuthGuard)
  async isListingSaved(
    @Param('id') id: string,
    @CurrentUser() user: Prisma.User,
  ) {
    const isSaved = await this.listingsService.isListingSaved(user.id, id);
    return { isSaved };
  }

  // Get a specific listing
  @Get(':id')
  async findOne(
    @Param('id') id: string,
    @CurrentUser() user: Prisma.User | null,
  ) {
    return this.listingsService.findByIdWithStats(id, user?.id);
  }

  // Update a listing
  @Put(':id')
  @UseGuards(JwtAuthGuard)
  async update(
    @Param('id') id: string,
    @CurrentUser() user: Prisma.User,
    @Body() dto: UpdateListingDto,
  ) {
    return this.listingsService.update(id, user.id, dto);
  }

  // Delete a listing
  @Delete(':id')
  @UseGuards(JwtAuthGuard)
  async delete(@Param('id') id: string, @CurrentUser() user: Prisma.User) {
    await this.listingsService.delete(id, user.id);
    return { success: true };
  }

  // Archive a listing
  @Post(':id/archive')
  @UseGuards(JwtAuthGuard)
  async archive(@Param('id') id: string, @CurrentUser() user: Prisma.User) {
    return this.listingsService.archive(id, user.id);
  }

  // Mark as sold
  @Post(':id/sold')
  @UseGuards(JwtAuthGuard)
  async markAsSold(@Param('id') id: string, @CurrentUser() user: Prisma.User) {
    return this.listingsService.markAsSold(id, user.id);
  }

  // Save a listing
  @Post(':id/save')
  @UseGuards(JwtAuthGuard)
  async saveListing(@Param('id') id: string, @CurrentUser() user: Prisma.User) {
    await this.listingsService.saveListing(user.id, id);
    return { success: true };
  }

  // Unsave a listing
  @Delete(':id/save')
  @UseGuards(JwtAuthGuard)
  async unsaveListing(
    @Param('id') id: string,
    @CurrentUser() user: Prisma.User,
  ) {
    await this.listingsService.unsaveListing(user.id, id);
    return { success: true };
  }

  // ===== ADMIN ENDPOINTS =====

  // Get pending listings for moderation
  @Get('admin/pending')
  @UseGuards(JwtAuthGuard, AdminGuard)
  async getPendingListings(
    @Query('page') page?: number,
    @Query('limit') limit?: number,
  ) {
    return this.listingsService.getPendingListings(page, limit);
  }

  // Approve a listing
  @Post('admin/:id/approve')
  @UseGuards(JwtAuthGuard, AdminGuard)
  async approveListing(
    @Param('id') id: string,
    @CurrentUser() admin: Prisma.User,
  ) {
    return this.listingsService.approveListing(id, admin.id);
  }

  // Reject a listing
  @Post('admin/:id/reject')
  @UseGuards(JwtAuthGuard, AdminGuard)
  async rejectListing(
    @Param('id') id: string,
    @CurrentUser() admin: Prisma.User,
    @Body() dto: AdminListingActionDto,
  ) {
    return this.listingsService.rejectListing(id, admin.id, dto.reason);
  }
}
