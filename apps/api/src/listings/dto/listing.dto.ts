import {
  IsString,
  IsInt,
  IsEnum,
  IsOptional,
  IsArray,
  Min,
  MaxLength,
  IsBoolean,
  IsObject,
} from 'class-validator';
import { ListingCategory, ItemCondition, ListingStatus } from '@prisma/client';
import { Type } from 'class-transformer';
import { ApiProperty, ApiPropertyOptional } from '@nestjs/swagger';

export class CreateListingDto {
  @ApiProperty({ description: 'Listing title', maxLength: 150 })
  @IsString()
  @MaxLength(150)
  title: string;

  @ApiProperty({ description: 'Listing description', maxLength: 2000 })
  @IsString()
  @MaxLength(2000)
  description: string;

  @ApiProperty({ description: 'Price in smallest currency unit', minimum: 0 })
  @IsInt()
  @Min(0)
  price: number;

  // NEW: Category ID (new system)
  @ApiPropertyOptional({
    description: 'Category ID from the new hierarchical category system',
  })
  @IsOptional()
  @IsString()
  categoryId?: string;

  // LEGACY: Keep for backward compatibility
  @ApiPropertyOptional({
    description: 'Legacy category enum (deprecated, use categoryId instead)',
    enum: ListingCategory,
  })
  @IsOptional()
  @IsEnum(ListingCategory)
  category?: ListingCategory;

  @ApiProperty({ description: 'Item condition', enum: ItemCondition })
  @IsEnum(ItemCondition)
  condition: ItemCondition;

  // NEW: Dynamic attributes as JSON object
  @ApiPropertyOptional({
    description:
      'Dynamic attributes based on category (e.g., { "size": "M", "brand": "Nike", "color": ["Red"] })',
  })
  @IsOptional()
  @IsObject()
  attributes?: Record<string, string | string[]>;

  // LEGACY: Keep individual fields for backward compatibility
  @ApiPropertyOptional({
    description: 'Legacy size field (deprecated)',
    maxLength: 50,
  })
  @IsOptional()
  @IsString()
  @MaxLength(50)
  size?: string;

  @ApiPropertyOptional({
    description: 'Legacy brand field (deprecated)',
    maxLength: 50,
  })
  @IsOptional()
  @IsString()
  @MaxLength(50)
  brand?: string;

  @ApiPropertyOptional({
    description: 'Legacy color field (deprecated)',
    maxLength: 50,
  })
  @IsOptional()
  @IsString()
  @MaxLength(50)
  color?: string;

  @ApiPropertyOptional({
    description: 'Legacy material field (deprecated)',
    maxLength: 50,
  })
  @IsOptional()
  @IsString()
  @MaxLength(50)
  material?: string;

  // NEW: Structured location
  @ApiPropertyOptional({ description: 'City ID from locations system' })
  @IsOptional()
  @IsString()
  cityId?: string;

  @ApiPropertyOptional({ description: 'Division ID from locations system' })
  @IsOptional()
  @IsString()
  divisionId?: string;

  // LEGACY: Keep for backward compatibility
  @ApiPropertyOptional({
    description: 'Legacy location string (deprecated)',
    maxLength: 100,
  })
  @IsOptional()
  @IsString()
  @MaxLength(100)
  location?: string;

  @ApiPropertyOptional({
    description: 'Original price before discount',
    minimum: 0,
  })
  @IsOptional()
  @IsInt()
  @Min(0)
  originalPrice?: number;

  @ApiProperty({ description: 'Array of image URLs', type: [String] })
  @IsArray()
  @IsString({ each: true })
  imageUrls: string[];

  @ApiPropertyOptional({ description: 'Save as draft' })
  @IsOptional()
  @IsBoolean()
  isDraft?: boolean;
}

export class UpdateListingDto {
  @ApiPropertyOptional({ description: 'Listing title', maxLength: 150 })
  @IsOptional()
  @IsString()
  @MaxLength(150)
  title?: string;

  @ApiPropertyOptional({ description: 'Listing description', maxLength: 2000 })
  @IsOptional()
  @IsString()
  @MaxLength(2000)
  description?: string;

  @ApiPropertyOptional({
    description: 'Price in smallest currency unit',
    minimum: 0,
  })
  @IsOptional()
  @IsInt()
  @Min(0)
  price?: number;

  // NEW: Category ID
  @ApiPropertyOptional({
    description: 'Category ID from the new hierarchical category system',
  })
  @IsOptional()
  @IsString()
  categoryId?: string;

  // LEGACY: Keep for backward compatibility
  @ApiPropertyOptional({
    description: 'Legacy category enum (deprecated)',
    enum: ListingCategory,
  })
  @IsOptional()
  @IsEnum(ListingCategory)
  category?: ListingCategory;

  @ApiPropertyOptional({ description: 'Item condition', enum: ItemCondition })
  @IsOptional()
  @IsEnum(ItemCondition)
  condition?: ItemCondition;

  // NEW: Dynamic attributes
  @ApiPropertyOptional({ description: 'Dynamic attributes based on category' })
  @IsOptional()
  @IsObject()
  attributes?: Record<string, string | string[]>;

  // LEGACY fields
  @ApiPropertyOptional({
    description: 'Legacy size field (deprecated)',
    maxLength: 50,
  })
  @IsOptional()
  @IsString()
  @MaxLength(50)
  size?: string;

  @ApiPropertyOptional({
    description: 'Legacy brand field (deprecated)',
    maxLength: 50,
  })
  @IsOptional()
  @IsString()
  @MaxLength(50)
  brand?: string;

  @ApiPropertyOptional({
    description: 'Legacy color field (deprecated)',
    maxLength: 50,
  })
  @IsOptional()
  @IsString()
  @MaxLength(50)
  color?: string;

  @ApiPropertyOptional({
    description: 'Legacy material field (deprecated)',
    maxLength: 50,
  })
  @IsOptional()
  @IsString()
  @MaxLength(50)
  material?: string;

  // NEW: Structured location
  @ApiPropertyOptional({ description: 'City ID from locations system' })
  @IsOptional()
  @IsString()
  cityId?: string;

  @ApiPropertyOptional({ description: 'Division ID from locations system' })
  @IsOptional()
  @IsString()
  divisionId?: string;

  // LEGACY
  @ApiPropertyOptional({
    description: 'Legacy location string (deprecated)',
    maxLength: 100,
  })
  @IsOptional()
  @IsString()
  @MaxLength(100)
  location?: string;

  @ApiPropertyOptional({ description: 'Array of image URLs', type: [String] })
  @IsOptional()
  @IsArray()
  @IsString({ each: true })
  imageUrls?: string[];
}

export class ListingQueryDto {
  @ApiPropertyOptional({ description: 'Search term for title/description' })
  @IsOptional()
  @IsString()
  search?: string;

  // NEW: Category ID for filtering
  @ApiPropertyOptional({
    description: 'Category ID to filter by (includes children)',
  })
  @IsOptional()
  @IsString()
  categoryId?: string;

  // LEGACY
  @ApiPropertyOptional({
    description: 'Legacy category enum filter (deprecated)',
    enum: ListingCategory,
  })
  @IsOptional()
  @IsEnum(ListingCategory)
  category?: ListingCategory;

  @ApiPropertyOptional({
    description: 'Item condition filter',
    enum: ItemCondition,
  })
  @IsOptional()
  @IsEnum(ItemCondition)
  condition?: ItemCondition;

  @ApiPropertyOptional({ description: 'Minimum price filter', minimum: 0 })
  @IsOptional()
  @Type(() => Number)
  @IsInt()
  @Min(0)
  minPrice?: number;

  @ApiPropertyOptional({ description: 'Maximum price filter', minimum: 0 })
  @IsOptional()
  @Type(() => Number)
  @IsInt()
  @Min(0)
  maxPrice?: number;

  // NEW: Structured location filters
  @ApiPropertyOptional({ description: 'City ID to filter by' })
  @IsOptional()
  @IsString()
  cityId?: string;

  @ApiPropertyOptional({ description: 'Division ID to filter by' })
  @IsOptional()
  @IsString()
  divisionId?: string;

  // LEGACY
  @ApiPropertyOptional({
    description: 'Legacy location string filter (deprecated)',
  })
  @IsOptional()
  @IsString()
  location?: string;

  @ApiPropertyOptional({ description: 'Seller ID to filter by' })
  @IsOptional()
  @IsString()
  sellerId?: string;

  @ApiPropertyOptional({
    description: 'Listing status filter',
    enum: ListingStatus,
  })
  @IsOptional()
  @IsEnum(ListingStatus)
  status?: ListingStatus;

  @ApiPropertyOptional({ description: 'Page number', default: 1, minimum: 1 })
  @IsOptional()
  @Type(() => Number)
  @IsInt()
  @Min(1)
  page?: number = 1;

  @ApiPropertyOptional({
    description: 'Items per page',
    default: 20,
    minimum: 1,
  })
  @IsOptional()
  @Type(() => Number)
  @IsInt()
  @Min(1)
  limit?: number = 20;

  @ApiPropertyOptional({
    description: 'Sort field',
    enum: ['createdAt', 'price', 'viewCount'],
  })
  @IsOptional()
  @IsString()
  sortBy?: 'createdAt' | 'price' | 'viewCount';

  @ApiPropertyOptional({ description: 'Sort order', enum: ['asc', 'desc'] })
  @IsOptional()
  @IsString()
  sortOrder?: 'asc' | 'desc';
}

export class AdminListingActionDto {
  @IsOptional()
  @IsString()
  @MaxLength(500)
  reason?: string;
}
