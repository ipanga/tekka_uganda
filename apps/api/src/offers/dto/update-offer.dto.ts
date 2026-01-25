import {
  IsNumber,
  IsPositive,
  IsOptional,
  IsString,
  Min,
} from 'class-validator';
import { ApiPropertyOptional } from '@nestjs/swagger';

export class UpdateOfferDto {
  @ApiPropertyOptional({ description: 'Updated offered price', minimum: 0 })
  @IsNumber()
  @IsPositive()
  @Min(0)
  @IsOptional()
  amount?: number;

  @ApiPropertyOptional({ description: 'Updated message' })
  @IsString()
  @IsOptional()
  message?: string;
}
