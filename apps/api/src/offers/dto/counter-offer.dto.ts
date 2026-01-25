import {
  IsNumber,
  IsPositive,
  IsOptional,
  IsString,
  Min,
} from 'class-validator';
import { ApiProperty, ApiPropertyOptional } from '@nestjs/swagger';

export class CounterOfferDto {
  @ApiProperty({ description: 'Counter offer price', minimum: 0 })
  @IsNumber()
  @IsPositive()
  @Min(0)
  amount: number;

  @ApiPropertyOptional({ description: 'Optional message with counter offer' })
  @IsString()
  @IsOptional()
  message?: string;
}
