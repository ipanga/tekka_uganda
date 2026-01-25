import { IsString, IsNotEmpty, IsOptional } from 'class-validator';
import { ApiProperty, ApiPropertyOptional } from '@nestjs/swagger';

export enum ReportReason {
  SPAM = 'SPAM',
  SCAM = 'SCAM',
  INAPPROPRIATE_CONTENT = 'INAPPROPRIATE_CONTENT',
  HARASSMENT = 'HARASSMENT',
  FAKE_PROFILE = 'FAKE_PROFILE',
  COUNTERFEIT_ITEMS = 'COUNTERFEIT_ITEMS',
  NO_SHOW = 'NO_SHOW',
  OTHER = 'OTHER',
}

export class CreateReportDto {
  @ApiPropertyOptional({ description: 'ID of the user being reported' })
  @IsString()
  @IsOptional()
  reportedUserId?: string;

  @ApiPropertyOptional({ description: 'ID of the listing being reported' })
  @IsString()
  @IsOptional()
  reportedListingId?: string;

  @ApiProperty({ description: 'Reason for the report', enum: ReportReason })
  @IsString()
  @IsNotEmpty()
  reason: string;

  @ApiPropertyOptional({ description: 'Additional details about the report' })
  @IsString()
  @IsOptional()
  description?: string;
}
