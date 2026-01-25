import {
  IsString,
  IsNotEmpty,
  IsOptional,
  IsDateString,
  IsNumber,
} from 'class-validator';
import { ApiProperty, ApiPropertyOptional } from '@nestjs/swagger';

export class CreateMeetupDto {
  @ApiProperty({ description: 'Chat ID' })
  @IsString()
  @IsNotEmpty()
  chatId: string;

  @ApiPropertyOptional({
    description: 'Safe location ID (if using a predefined location)',
  })
  @IsString()
  @IsOptional()
  locationId?: string;

  @ApiProperty({ description: 'Location name' })
  @IsString()
  @IsNotEmpty()
  locationName: string;

  @ApiPropertyOptional({ description: 'Location address' })
  @IsString()
  @IsOptional()
  locationAddress?: string;

  @ApiPropertyOptional({ description: 'Latitude' })
  @IsNumber()
  @IsOptional()
  latitude?: number;

  @ApiPropertyOptional({ description: 'Longitude' })
  @IsNumber()
  @IsOptional()
  longitude?: number;

  @ApiProperty({ description: 'Scheduled date and time' })
  @IsDateString()
  scheduledAt: string;

  @ApiPropertyOptional({ description: 'Additional notes' })
  @IsString()
  @IsOptional()
  notes?: string;
}

export class UpdateMeetupStatusDto {
  @ApiProperty({ description: 'Reason for cancellation', required: false })
  @IsString()
  @IsOptional()
  reason?: string;
}
