import {
  IsString,
  IsNotEmpty,
  IsOptional,
  IsEnum,
  ArrayNotEmpty,
  ValidateIf,
} from 'class-validator';
import { ApiProperty, ApiPropertyOptional } from '@nestjs/swagger';
import { UserRole } from '@prisma/client';

export enum BroadcastAudience {
  ALL = 'ALL',
  ROLE = 'ROLE',
  SPECIFIC = 'SPECIFIC',
}

export class BroadcastNotificationDto {
  @ApiProperty({ description: 'Notification title shown to recipients' })
  @IsString()
  @IsNotEmpty()
  title: string;

  @ApiProperty({ description: 'Notification body shown to recipients' })
  @IsString()
  @IsNotEmpty()
  body: string;

  @ApiProperty({ enum: BroadcastAudience })
  @IsEnum(BroadcastAudience)
  audience: BroadcastAudience;

  @ApiPropertyOptional({ enum: UserRole, description: 'Required when audience=ROLE' })
  @ValidateIf((o) => o.audience === BroadcastAudience.ROLE)
  @IsEnum(UserRole)
  role?: UserRole;

  @ApiPropertyOptional({ type: [String], description: 'Required when audience=SPECIFIC' })
  @ValidateIf((o) => o.audience === BroadcastAudience.SPECIFIC)
  @ArrayNotEmpty()
  @IsString({ each: true })
  userIds?: string[];

  @ApiPropertyOptional({ description: 'Listing ID to deep-link to (product-linked broadcast)' })
  @IsOptional()
  @IsString()
  @IsNotEmpty()
  listingId?: string;
}

export class AudienceCountQueryDto {
  @ApiProperty({ enum: BroadcastAudience })
  @IsEnum(BroadcastAudience)
  audience: BroadcastAudience;

  @ApiPropertyOptional({ enum: UserRole })
  @ValidateIf((o) => o.audience === BroadcastAudience.ROLE)
  @IsEnum(UserRole)
  role?: UserRole;
}
