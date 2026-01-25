import {
  IsString,
  IsNotEmpty,
  IsNumber,
  IsPositive,
  IsOptional,
  Min,
} from 'class-validator';
import { ApiProperty, ApiPropertyOptional } from '@nestjs/swagger';

export class CreateOfferDto {
  @ApiProperty({ description: 'ID of the listing' })
  @IsString()
  @IsNotEmpty()
  listingId: string;

  @ApiProperty({ description: 'Offered price', minimum: 0 })
  @IsNumber()
  @IsPositive()
  @Min(0)
  amount: number;

  @ApiPropertyOptional({ description: 'Optional message with the offer' })
  @IsString()
  @IsOptional()
  message?: string;
}
