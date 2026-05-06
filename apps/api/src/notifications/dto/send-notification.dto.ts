import {
  IsString,
  IsNotEmpty,
  IsOptional,
  IsObject,
  IsEnum,
} from 'class-validator';
import { ApiProperty, ApiPropertyOptional } from '@nestjs/swagger';
import { NotificationType } from '@prisma/client';

export class SendNotificationDto {
  @ApiProperty({ description: 'User ID to send notification to' })
  @IsString()
  @IsNotEmpty()
  userId: string;

  @ApiProperty({ enum: NotificationType })
  @IsEnum(NotificationType)
  type: NotificationType;

  @ApiProperty({ description: 'Notification title' })
  @IsString()
  @IsNotEmpty()
  title: string;

  @ApiProperty({ description: 'Notification body/message' })
  @IsString()
  @IsNotEmpty()
  body: string;

  @ApiPropertyOptional({ description: 'Additional data payload' })
  @IsObject()
  @IsOptional()
  data?: Record<string, any>;

  // Internal use only: links a per-user notification to its parent Broadcast.
  // Not exposed via Swagger; AdminGuard endpoints accept it but external
  // callers don't need to set it.
  @IsOptional()
  @IsString()
  broadcastId?: string;
}

export class SendBulkNotificationDto {
  @ApiProperty({
    description: 'User IDs to send notification to',
    type: [String],
  })
  @IsString({ each: true })
  @IsNotEmpty({ each: true })
  userIds: string[];

  @ApiProperty({ enum: NotificationType })
  @IsEnum(NotificationType)
  type: NotificationType;

  @ApiProperty({ description: 'Notification title' })
  @IsString()
  @IsNotEmpty()
  title: string;

  @ApiProperty({ description: 'Notification body/message' })
  @IsString()
  @IsNotEmpty()
  body: string;

  @ApiPropertyOptional({ description: 'Additional data payload' })
  @IsObject()
  @IsOptional()
  data?: Record<string, any>;
}
