import {
  Injectable,
  NotFoundException,
  ForbiddenException,
  BadRequestException,
  Logger,
} from '@nestjs/common';
import { PrismaService } from '../prisma/prisma.service';
import { NotificationsService } from '../notifications/notifications.service';
import { UploadService } from '../upload/upload.service';
import { Listing, ListingStatus, Prisma } from '@prisma/client';
import {
  CreateListingDto,
  UpdateListingDto,
  ListingQueryDto,
} from './dto/listing.dto';

@Injectable()
export class ListingsService {
  private readonly logger = new Logger(ListingsService.name);

  constructor(
    private prisma: PrismaService,
    private notificationsService: NotificationsService,
    private uploadService: UploadService,
  ) {}

  async create(sellerId: string, dto: CreateListingDto): Promise<Listing> {
    const status = dto.isDraft ? ListingStatus.DRAFT : ListingStatus.PENDING;

    const listing = await this.prisma.listing.create({
      data: {
        sellerId,
        title: dto.title,
        description: dto.description,
        price: dto.price,
        originalPrice: dto.originalPrice ?? dto.price,
        // NEW: Category ID (new hierarchical system)
        categoryId: dto.categoryId,
        // LEGACY: Keep for backward compatibility
        category: dto.category,
        condition: dto.condition,
        // NEW: Dynamic attributes JSON
        attributes: dto.attributes,
        // NEW: Structured location
        cityId: dto.cityId,
        divisionId: dto.divisionId,
        // LEGACY: Keep individual fields
        size: dto.size,
        brand: dto.brand,
        color: dto.color,
        material: dto.material,
        location: dto.location,
        imageUrls: dto.imageUrls,
        status,
      },
    });

    // Mark uploaded images as permanent in Cloudinary
    if (dto.imageUrls?.length > 0) {
      this.uploadService.markImagesPermanent(dto.imageUrls).catch((error) => {
        this.logger.warn(
          `Failed to mark images permanent for listing ${listing.id}: ${error.message}`,
        );
      });
    }

    return listing;
  }

  async findById(id: string): Promise<Listing> {
    const listing = await this.prisma.listing.findUnique({
      where: { id },
      include: {
        seller: {
          select: {
            id: true,
            displayName: true,
            photoUrl: true,
            location: true,
            createdAt: true,
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
    });

    if (!listing) {
      throw new NotFoundException('Listing not found');
    }

    return listing;
  }

  async findByIdWithStats(id: string, viewerId?: string) {
    const listing = await this.findById(id);

    // Increment view count
    await this.prisma.listing.update({
      where: { id },
      data: { viewCount: { increment: 1 } },
    });

    // Check if viewer has saved this listing
    let isSaved = false;
    if (viewerId) {
      const saved = await this.prisma.savedItem.findUnique({
        where: {
          userId_listingId: { userId: viewerId, listingId: id },
        },
      });
      isSaved = !!saved;
    }

    // Get seller stats
    const sellerStats = await this.prisma.review.aggregate({
      where: { revieweeId: listing.sellerId },
      _avg: { rating: true },
      _count: { rating: true },
    });

    // Transform response to include properly named category/location data
    const listingData = listing as any;
    const { categoryRef, cityRef, divisionRef, ...rest } = listingData;

    return {
      ...rest,
      isSaved,
      // Map Prisma relations to frontend expected names
      categoryData: categoryRef,
      city: cityRef,
      division: divisionRef,
      seller: {
        ...listingData.seller,
        rating: sellerStats._avg.rating || 0,
        reviewCount: sellerStats._count.rating,
      },
    };
  }

  async update(
    id: string,
    sellerId: string,
    dto: UpdateListingDto,
  ): Promise<Listing> {
    const listing = await this.findById(id);

    if (listing.sellerId !== sellerId) {
      throw new ForbiddenException('You can only edit your own listings');
    }

    if (listing.status === ListingStatus.SOLD) {
      throw new BadRequestException('Cannot edit a sold listing');
    }

    // Clean up replaced images and mark new ones in Cloudinary
    if (dto.imageUrls) {
      const newUrls = dto.imageUrls;
      const oldUrls = listing.imageUrls || [];
      const removedUrls = oldUrls.filter(
        (url) => !newUrls.includes(url),
      );
      const addedUrls = newUrls.filter(
        (url) => !oldUrls.includes(url),
      );

      if (removedUrls.length > 0) {
        this.uploadService.deleteImagesByUrls(removedUrls).catch((error) => {
          this.logger.warn(
            `Failed to cleanup replaced images for listing ${id}: ${error.message}`,
          );
        });
      }
      if (addedUrls.length > 0) {
        this.uploadService.markImagesPermanent(addedUrls).catch((error) => {
          this.logger.warn(
            `Failed to mark new images permanent for listing ${id}: ${error.message}`,
          );
        });
      }
    }

    // Track price changes for alerts
    const priceChanged = dto.price !== undefined && dto.price !== listing.price;
    const newPrice = dto.price ?? listing.price;

    const updated = await this.prisma.listing.update({
      where: { id },
      data: {
        ...dto,
        // If price decreased, keep original for comparison
        originalPrice:
          priceChanged && newPrice < listing.price
            ? listing.originalPrice || listing.price
            : undefined,
        // Reset to pending if it was active and significant changes made
        status:
          listing.status === ListingStatus.ACTIVE &&
          (dto.title || dto.description)
            ? ListingStatus.PENDING
            : undefined,
      },
    });

    // Trigger price alerts if price dropped
    if (priceChanged && newPrice < listing.price) {
      await this.triggerPriceAlerts(listing, newPrice);
    }

    return updated;
  }

  /**
   * Delete a listing and all related data including Cloudinary images.
   * Uses database cascade deletes for related records (chats, messages, offers, etc.)
   * Then deletes images from Cloudinary storage.
   */
  async delete(id: string, sellerId: string): Promise<void> {
    const listing = await this.findById(id);

    if (listing.sellerId !== sellerId) {
      throw new ForbiddenException('You can only delete your own listings');
    }

    await this.deleteListingWithCleanup(listing);
  }

  /**
   * Admin delete - bypasses seller check
   */
  async adminDelete(id: string, adminId: string): Promise<void> {
    const listing = await this.findById(id);

    this.logger.log(`Admin ${adminId} deleting listing ${id}`);
    await this.deleteListingWithCleanup(listing);

    // Log admin action
    await this.prisma.adminAction.create({
      data: {
        adminId,
        action: 'DELETE_LISTING',
        targetType: 'listing',
        targetId: id,
        details: { title: listing.title, sellerId: listing.sellerId },
      },
    });
  }

  /**
   * Internal method to delete listing with full cleanup
   * 1. Collects image URLs before deletion
   * 2. Deletes database record (cascades to related records)
   * 3. Deletes images from Cloudinary (non-blocking on failure)
   */
  private async deleteListingWithCleanup(listing: Listing): Promise<void> {
    const imageUrls = listing.imageUrls || [];
    const listingId = listing.id;

    this.logger.log(
      `Deleting listing ${listingId} with ${imageUrls.length} images`,
    );

    // Delete from database first (cascades to related records)
    await this.prisma.listing.delete({ where: { id: listingId } });

    this.logger.log(`Database records deleted for listing ${listingId}`);

    // Delete images from Cloudinary (don't block on failures)
    if (imageUrls.length > 0) {
      try {
        const result = await this.uploadService.deleteImagesByUrls(imageUrls);
        this.logger.log(
          `Cloudinary cleanup for listing ${listingId}: ` +
            `${result.deleted} deleted, ${result.failed} failed`,
        );
        if (result.errors.length > 0) {
          this.logger.warn(
            `Cloudinary errors: ${result.errors.join(', ')}`,
          );
        }
      } catch (error) {
        // Log but don't fail the deletion - images can be cleaned up later
        this.logger.error(
          `Cloudinary cleanup failed for listing ${listingId}: ${error.message}`,
        );
      }
    }
  }

  async publishDraft(id: string, sellerId: string): Promise<Listing> {
    const listing = await this.findById(id);

    if (listing.sellerId !== sellerId) {
      throw new ForbiddenException('You can only publish your own listings');
    }

    if (listing.status !== ListingStatus.DRAFT) {
      throw new BadRequestException('Only draft listings can be published');
    }

    if (
      !listing.title ||
      !listing.description ||
      !listing.price ||
      !listing.imageUrls?.length
    ) {
      throw new BadRequestException(
        'Listing must have title, description, price, and at least one image to publish',
      );
    }

    return this.prisma.listing.update({
      where: { id },
      data: { status: ListingStatus.PENDING },
    });
  }

  async archive(id: string, sellerId: string): Promise<Listing> {
    const listing = await this.findById(id);

    if (listing.sellerId !== sellerId) {
      throw new ForbiddenException('You can only archive your own listings');
    }

    return this.prisma.listing.update({
      where: { id },
      data: {
        status: ListingStatus.ARCHIVED,
        archivedAt: new Date(),
      },
    });
  }

  async markAsSold(id: string, sellerId: string): Promise<Listing> {
    const listing = await this.findById(id);

    if (listing.sellerId !== sellerId) {
      throw new ForbiddenException(
        'You can only mark your own listings as sold',
      );
    }

    if (listing.status !== ListingStatus.ACTIVE) {
      throw new BadRequestException(
        'Only active listings can be marked as sold',
      );
    }

    return this.prisma.listing.update({
      where: { id },
      data: {
        status: ListingStatus.SOLD,
        soldAt: new Date(),
      },
    });
  }

  async search(query: ListingQueryDto, viewerId?: string) {
    const {
      search,
      categoryId,
      category,
      condition,
      minPrice,
      maxPrice,
      cityId,
      divisionId,
      location,
      sellerId,
      status,
      page = 1,
      limit = 20,
      sortBy = 'createdAt',
      sortOrder = 'desc',
    } = query;

    // If search term provided, use PostgreSQL full-text search for relevance ranking
    if (search && search.trim()) {
      return this.fullTextSearch(query, viewerId);
    }

    const where: Prisma.ListingWhereInput = {
      status: status || ListingStatus.ACTIVE,
    };

    // NEW: Category ID filter (includes children)
    if (categoryId) {
      const childCategories = await this.prisma.category.findMany({
        where: {
          OR: [
            { id: categoryId },
            { parentId: categoryId },
            { parent: { parentId: categoryId } },
          ],
        },
        select: { id: true },
      });
      where.categoryId = { in: childCategories.map((c) => c.id) };
    }
    // LEGACY: Fallback to enum filter
    if (category) where.category = category;
    if (condition) where.condition = condition;
    // NEW: Structured location filters
    if (cityId) where.cityId = cityId;
    if (divisionId) where.divisionId = divisionId;
    // LEGACY: Text location filter
    if (sellerId) where.sellerId = sellerId;
    if (location) where.location = { contains: location, mode: 'insensitive' };

    if (minPrice !== undefined || maxPrice !== undefined) {
      where.price = {};
      if (minPrice !== undefined) where.price.gte = minPrice;
      if (maxPrice !== undefined) where.price.lte = maxPrice;
    }

    const [listings, total] = await Promise.all([
      this.prisma.listing.findMany({
        where,
        include: {
          seller: {
            select: {
              id: true,
              displayName: true,
              photoUrl: true,
              location: true,
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
        orderBy: { [sortBy]: sortOrder },
        skip: (page - 1) * limit,
        take: limit,
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

    // Add isSaved status for each listing if viewer is logged in
    const listingsWithSaved = await this.addSavedStatus(
      transformedListings,
      viewerId,
    );

    return {
      listings: listingsWithSaved,
      pagination: {
        page,
        limit,
        total,
        totalPages: Math.ceil(total / limit),
      },
    };
  }

  /**
   * PostgreSQL full-text search with relevance ranking.
   * Uses to_tsvector/to_tsquery for proper tokenization and ranking.
   * Falls back to ILIKE for short or special-character queries.
   */
  private async fullTextSearch(query: ListingQueryDto, viewerId?: string) {
    const {
      search,
      categoryId,
      category,
      condition,
      minPrice,
      maxPrice,
      cityId,
      divisionId,
      location,
      sellerId,
      status,
      page = 1,
      limit = 20,
      sortBy = 'createdAt',
      sortOrder = 'desc',
    } = query;

    const searchTerm = search?.trim() || '';
    const filterStatus = status || 'ACTIVE';

    // Build WHERE conditions for filters
    const conditions: string[] = [`l.status = $1`];
    const params: any[] = [filterStatus];
    let paramIndex = 2;

    // Category filter
    if (categoryId) {
      const childCategories = await this.prisma.category.findMany({
        where: {
          OR: [
            { id: categoryId },
            { parentId: categoryId },
            { parent: { parentId: categoryId } },
          ],
        },
        select: { id: true },
      });
      const categoryIds = childCategories.map((c) => c.id);
      conditions.push(`l.category_id = ANY($${paramIndex})`);
      params.push(categoryIds);
      paramIndex++;
    }

    if (category) {
      conditions.push(`l.category = $${paramIndex}::"ListingCategory"`);
      params.push(category);
      paramIndex++;
    }

    if (condition) {
      conditions.push(`l.condition = $${paramIndex}::"ItemCondition"`);
      params.push(condition);
      paramIndex++;
    }

    if (minPrice !== undefined) {
      conditions.push(`l.price >= $${paramIndex}`);
      params.push(minPrice);
      paramIndex++;
    }

    if (maxPrice !== undefined) {
      conditions.push(`l.price <= $${paramIndex}`);
      params.push(maxPrice);
      paramIndex++;
    }

    if (cityId) {
      conditions.push(`l.city_id = $${paramIndex}`);
      params.push(cityId);
      paramIndex++;
    }

    if (divisionId) {
      conditions.push(`l.division_id = $${paramIndex}`);
      params.push(divisionId);
      paramIndex++;
    }

    if (sellerId) {
      conditions.push(`l.seller_id = $${paramIndex}`);
      params.push(sellerId);
      paramIndex++;
    }

    if (location) {
      conditions.push(`l.location ILIKE $${paramIndex}`);
      params.push(`%${location}%`);
      paramIndex++;
    }

    // Convert search term to tsquery format: split words and join with &
    const tsQueryWords = searchTerm
      .split(/\s+/)
      .filter((w) => w.length > 0)
      .map((w) => w.replace(/[^a-zA-Z0-9]/g, ''))
      .filter((w) => w.length > 0);

    // Use prefix matching (:*) for the last word to support partial typing
    const tsQueryTerms = tsQueryWords.map((w, i) =>
      i === tsQueryWords.length - 1 ? `${w}:*` : w,
    );
    const tsQueryStr = tsQueryTerms.join(' & ');

    // Add full-text search condition with fallback to ILIKE
    const searchParamIdx = paramIndex;
    const ilikeParamIdx = paramIndex + 1;
    params.push(tsQueryStr);
    params.push(`%${searchTerm}%`);

    // Full-text search on title (weighted A) + description (weighted B) + brand (weighted C)
    // Falls back to ILIKE if tsquery doesn't match (handles special characters, very short terms)
    conditions.push(`(
      to_tsvector('english', COALESCE(l.title, '') || ' ' || COALESCE(l.description, '') || ' ' || COALESCE(l.brand, ''))
      @@ to_tsquery('english', $${searchParamIdx})
      OR l.title ILIKE $${ilikeParamIdx}
      OR l.description ILIKE $${ilikeParamIdx}
      OR l.brand ILIKE $${ilikeParamIdx}
    )`);

    const whereClause = conditions.join(' AND ');
    const offset = (page - 1) * limit;

    // Determine sort: use relevance ranking when searching, otherwise use specified sort
    let orderClause: string;
    if (sortBy === 'createdAt' || !sortBy) {
      // Default: sort by relevance rank when searching
      orderClause = `ts_rank(
        setweight(to_tsvector('english', COALESCE(l.title, '')), 'A') ||
        setweight(to_tsvector('english', COALESCE(l.description, '')), 'B') ||
        setweight(to_tsvector('english', COALESCE(l.brand, '')), 'C'),
        to_tsquery('english', $${searchParamIdx})
      ) DESC, l.created_at DESC`;
    } else {
      const sortColumn =
        sortBy === 'price'
          ? 'l.price'
          : `l.${sortBy === 'viewCount' ? 'view_count' : sortBy}`;
      orderClause = `${sortColumn} ${sortOrder === 'asc' ? 'ASC' : 'DESC'}`;
    }

    // Execute search query with seller, category, and location joins
    const searchQuery = `
      SELECT l.*,
        json_build_object(
          'id', u.id,
          'displayName', u.display_name,
          'photoUrl', u.photo_url,
          'location', u.location
        ) as seller,
        CASE WHEN c.id IS NOT NULL THEN
          json_build_object(
            'id', c.id,
            'name', c.name,
            'slug', c.slug,
            'level', c.level,
            'parentId', c.parent_id,
            'parent', CASE WHEN cp.id IS NOT NULL THEN
              json_build_object(
                'id', cp.id,
                'name', cp.name,
                'slug', cp.slug,
                'level', cp.level,
                'parentId', cp.parent_id,
                'parent', CASE WHEN cpp.id IS NOT NULL THEN
                  json_build_object(
                    'id', cpp.id,
                    'name', cpp.name,
                    'slug', cpp.slug,
                    'level', cpp.level
                  )
                ELSE NULL END
              )
            ELSE NULL END
          )
        ELSE NULL END as category_data,
        CASE WHEN city.id IS NOT NULL THEN
          json_build_object(
            'id', city.id,
            'name', city.name,
            'isActive', city.is_active,
            'sortOrder', city.sort_order
          )
        ELSE NULL END as city_data,
        CASE WHEN div.id IS NOT NULL THEN
          json_build_object(
            'id', div.id,
            'cityId', div.city_id,
            'name', div.name,
            'isActive', div.is_active,
            'sortOrder', div.sort_order
          )
        ELSE NULL END as division_data
      FROM listings l
      LEFT JOIN users u ON l.seller_id = u.id
      LEFT JOIN categories c ON l.category_id = c.id
      LEFT JOIN categories cp ON c.parent_id = cp.id
      LEFT JOIN categories cpp ON cp.parent_id = cpp.id
      LEFT JOIN cities city ON l.city_id = city.id
      LEFT JOIN divisions div ON l.division_id = div.id
      WHERE ${whereClause}
      ORDER BY ${orderClause}
      LIMIT ${limit} OFFSET ${offset}
    `;

    const countQuery = `
      SELECT COUNT(*)::int as total
      FROM listings l
      WHERE ${whereClause}
    `;

    const [listings, countResult] = await Promise.all([
      this.prisma.$queryRawUnsafe<any[]>(searchQuery, ...params),
      this.prisma.$queryRawUnsafe<[{ total: number }]>(countQuery, ...params),
    ]);

    const total = countResult[0]?.total || 0;

    // Normalize raw results to match Prisma's format
    const normalizedListings = listings.map((row) => ({
      id: row.id,
      sellerId: row.seller_id,
      title: row.title,
      description: row.description,
      price: row.price,
      originalPrice: row.original_price,
      categoryId: row.category_id,
      attributes: row.attributes,
      cityId: row.city_id,
      divisionId: row.division_id,
      category: row.category,
      size: row.size,
      brand: row.brand,
      color: row.color,
      material: row.material,
      location: row.location,
      condition: row.condition,
      imageUrls: row.image_urls,
      status: row.status,
      viewCount: row.view_count,
      saveCount: row.save_count,
      rejectionReason: row.rejection_reason,
      createdAt: row.created_at,
      updatedAt: row.updated_at,
      soldAt: row.sold_at,
      archivedAt: row.archived_at,
      seller: row.seller,
      // Map category/location data to frontend expected names
      categoryData: row.category_data,
      city: row.city_data,
      division: row.division_data,
    }));

    // Add isSaved status
    const listingsWithSaved = await this.addSavedStatus(
      normalizedListings,
      viewerId,
    );

    return {
      listings: listingsWithSaved,
      pagination: {
        page,
        limit,
        total,
        totalPages: Math.ceil(total / limit),
      },
    };
  }

  /**
   * Add isSaved status to listings for the current viewer.
   */
  private async addSavedStatus(listings: any[], viewerId?: string) {
    if (viewerId && listings.length > 0) {
      const savedListingIds = await this.prisma.savedItem.findMany({
        where: {
          userId: viewerId,
          listingId: { in: listings.map((l) => l.id) },
        },
        select: { listingId: true },
      });
      const savedSet = new Set(savedListingIds.map((s) => s.listingId));
      return listings.map((listing) => ({
        ...listing,
        isSaved: savedSet.has(listing.id),
      }));
    }
    return listings.map((listing) => ({
      ...listing,
      isSaved: false,
    }));
  }

  async getMyListings(sellerId: string, status?: string) {
    const where: Prisma.ListingWhereInput = { sellerId };

    // Validate and apply status filter if provided
    if (status) {
      const validStatuses = Object.values(ListingStatus);
      const upperStatus = status.toUpperCase();
      if (validStatuses.includes(upperStatus as ListingStatus)) {
        where.status = upperStatus as ListingStatus;
      }
    }

    const [listings, total] = await Promise.all([
      this.prisma.listing.findMany({
        where,
        orderBy: { createdAt: 'desc' },
        include: {
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
      page: 1,
      limit: total,
      totalPages: 1,
    };
  }

  // Saved items
  async saveListing(userId: string, listingId: string) {
    await this.findById(listingId); // Verify listing exists

    await this.prisma.savedItem.upsert({
      where: {
        userId_listingId: { userId, listingId },
      },
      create: { userId, listingId },
      update: {},
    });

    await this.prisma.listing.update({
      where: { id: listingId },
      data: { saveCount: { increment: 1 } },
    });
  }

  async unsaveListing(userId: string, listingId: string) {
    const deleted = await this.prisma.savedItem.deleteMany({
      where: { userId, listingId },
    });

    if (deleted.count > 0) {
      await this.prisma.listing.update({
        where: { id: listingId },
        data: { saveCount: { decrement: 1 } },
      });
    }
  }

  async getSavedListings(userId: string) {
    const saved = await this.prisma.savedItem.findMany({
      where: { userId },
      include: {
        listing: {
          include: {
            seller: {
              select: {
                id: true,
                displayName: true,
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
        },
      },
      orderBy: { createdAt: 'desc' },
    });

    // Transform listings to include properly named category/location data
    return saved.map((s) => {
      const listing = s.listing as any;
      const { categoryRef, cityRef, divisionRef, ...rest } = listing;
      return {
        ...rest,
        // Map Prisma relations to frontend expected names
        categoryData: categoryRef,
        city: cityRef,
        division: divisionRef,
        isSaved: true,
      };
    });
  }

  async isListingSaved(userId: string, listingId: string): Promise<boolean> {
    const saved = await this.prisma.savedItem.findUnique({
      where: {
        userId_listingId: { userId, listingId },
      },
    });
    return !!saved;
  }

  async getListingsBySeller(sellerId: string, viewerId?: string) {
    const [listings, total] = await Promise.all([
      this.prisma.listing.findMany({
        where: {
          sellerId,
          status: ListingStatus.ACTIVE,
        },
        include: {
          seller: {
            select: {
              id: true,
              displayName: true,
              photoUrl: true,
              location: true,
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
        orderBy: { createdAt: 'desc' },
      }),
      this.prisma.listing.count({
        where: {
          sellerId,
          status: ListingStatus.ACTIVE,
        },
      }),
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

    // If viewer is logged in, check which listings they've saved
    let data;
    if (viewerId) {
      const savedListingIds = await this.prisma.savedItem.findMany({
        where: {
          userId: viewerId,
          listingId: { in: transformedListings.map((l) => l.id) },
        },
        select: { listingId: true },
      });
      const savedSet = new Set(savedListingIds.map((s) => s.listingId));
      data = transformedListings.map((listing) => ({
        ...listing,
        isSaved: savedSet.has(listing.id),
      }));
    } else {
      data = transformedListings.map((listing) => ({ ...listing, isSaved: false }));
    }

    return {
      data,
      total,
      page: 1,
      limit: total,
      totalPages: 1,
    };
  }

  async getPurchaseHistory(buyerId: string) {
    // Get purchases from the Purchase model
    const purchases = await this.prisma.purchase.findMany({
      where: {
        buyerId,
      },
      include: {
        listing: {
          include: {
            seller: {
              select: {
                id: true,
                displayName: true,
                photoUrl: true,
              },
            },
          },
        },
      },
      orderBy: { createdAt: 'desc' },
    });

    return purchases.map((purchase) => ({
      ...purchase.listing,
      purchasedAt: purchase.createdAt,
      purchasePrice: purchase.finalPrice,
    }));
  }

  // Admin actions
  async approveListing(id: string, adminId: string): Promise<Listing> {
    const listing = await this.findById(id);

    if (listing.status !== ListingStatus.PENDING) {
      throw new BadRequestException('Only pending listings can be approved');
    }

    const updated = await this.prisma.listing.update({
      where: { id },
      data: { status: ListingStatus.ACTIVE },
    });

    // Log admin action
    await this.prisma.adminAction.create({
      data: {
        adminId,
        action: 'APPROVE_LISTING',
        targetType: 'listing',
        targetId: id,
      },
    });

    // Send notification to seller
    await this.notificationsService.sendListingApproved(
      listing.sellerId,
      listing.title,
      listing.id,
    );

    return updated;
  }

  async rejectListing(
    id: string,
    adminId: string,
    reason?: string,
  ): Promise<Listing> {
    const listing = await this.findById(id);

    if (listing.status !== ListingStatus.PENDING) {
      throw new BadRequestException('Only pending listings can be rejected');
    }

    const updated = await this.prisma.listing.update({
      where: { id },
      data: {
        status: ListingStatus.REJECTED,
        rejectionReason: reason,
      },
    });

    // Log admin action
    await this.prisma.adminAction.create({
      data: {
        adminId,
        action: 'REJECT_LISTING',
        targetType: 'listing',
        targetId: id,
        details: reason ? { reason } : undefined,
      },
    });

    // Send notification to seller
    await this.notificationsService.sendListingRejected(
      listing.sellerId,
      listing.title,
      reason || 'Does not meet community guidelines',
      listing.id,
    );

    return updated;
  }

  /**
   * Suspend an active listing - sets it back to PENDING for review
   */
  async suspendListing(
    id: string,
    adminId: string,
    reason?: string,
  ): Promise<Listing> {
    const listing = await this.findById(id);

    if (listing.status === ListingStatus.PENDING) {
      throw new BadRequestException('Listing is already pending review');
    }

    if (listing.status === ListingStatus.SOLD) {
      throw new BadRequestException('Cannot suspend a sold listing');
    }

    const updated = await this.prisma.listing.update({
      where: { id },
      data: {
        status: ListingStatus.PENDING,
        rejectionReason: reason ? `Suspended: ${reason}` : 'Suspended by admin',
      },
    });

    // Log admin action
    await this.prisma.adminAction.create({
      data: {
        adminId,
        action: 'SUSPEND_LISTING',
        targetType: 'listing',
        targetId: id,
        details: reason ? { reason } : undefined,
      },
    });

    // Send notification to seller
    await this.notificationsService.sendListingSuspended(
      listing.sellerId,
      listing.title,
      reason,
      listing.id,
    );

    return updated;
  }

  async getPendingListings(page = 1, limit = 20) {
    const [listings, total] = await Promise.all([
      this.prisma.listing.findMany({
        where: { status: ListingStatus.PENDING },
        include: {
          seller: {
            select: {
              id: true,
              displayName: true,
              photoUrl: true,
              createdAt: true,
            },
          },
        },
        orderBy: { createdAt: 'asc' },
        skip: (page - 1) * limit,
        take: limit,
      }),
      this.prisma.listing.count({
        where: { status: ListingStatus.PENDING },
      }),
    ]);

    return {
      listings,
      pagination: {
        page,
        limit,
        total,
        totalPages: Math.ceil(total / limit),
      },
    };
  }

  // Price alerts
  private async triggerPriceAlerts(listing: Listing, newPrice: number) {
    const originalPrice = listing.originalPrice || listing.price;
    const priceDropAmount = originalPrice - newPrice;
    const priceDropPercent = (priceDropAmount / originalPrice) * 100;

    // Only alert for drops >= 5%
    if (priceDropPercent < 5) return;

    // Find users who saved this listing and have price alerts enabled
    const savedBy = await this.prisma.savedItem.findMany({
      where: { listingId: listing.id },
      include: {
        user: {
          select: {
            id: true,
            priceAlertsEnabled: true,
          },
        },
      },
    });

    const seller = await this.prisma.user.findUnique({
      where: { id: listing.sellerId },
      select: { displayName: true },
    });

    for (const save of savedBy) {
      if (!save.user.priceAlertsEnabled) continue;

      await this.prisma.priceAlert.create({
        data: {
          userId: save.user.id,
          listingId: listing.id,
          listingTitle: listing.title,
          listingImageUrl: listing.imageUrls[0],
          sellerName: seller?.displayName || 'Unknown',
          originalPrice,
          newPrice,
          priceDropAmount,
          priceDropPercent,
        },
      });
    }
  }
}
