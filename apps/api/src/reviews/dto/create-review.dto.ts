import {
  IsString,
  IsNotEmpty,
  IsNumber,
  IsOptional,
  Min,
  Max,
} from 'class-validator';
import { ApiProperty, ApiPropertyOptional } from '@nestjs/swagger';

export class CreateReviewDto {
  @ApiProperty({ description: 'ID of the user being reviewed' })
  @IsString()
  @IsNotEmpty()
  revieweeId: string;

  @ApiPropertyOptional({ description: 'ID of the listing this review is for (optional - can review sellers without a specific listing)' })
  @IsString()
  @IsOptional()
  listingId?: string;

  @ApiProperty({ description: 'Rating from 1 to 5', minimum: 1, maximum: 5 })
  @IsNumber()
  @Min(1)
  @Max(5)
  rating: number;

  @ApiPropertyOptional({ description: 'Review comment' })
  @IsString()
  @IsOptional()
  comment?: string;
}
