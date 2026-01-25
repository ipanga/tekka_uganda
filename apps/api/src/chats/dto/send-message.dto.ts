import {
  IsString,
  IsNotEmpty,
  IsEnum,
  IsOptional,
  IsObject,
  ValidateNested,
} from 'class-validator';
import { ApiProperty, ApiPropertyOptional } from '@nestjs/swagger';
import { Type } from 'class-transformer';
import { MessageType } from '@prisma/client';

class LocationDto {
  @ApiProperty()
  @IsNotEmpty()
  latitude: number;

  @ApiProperty()
  @IsNotEmpty()
  longitude: number;

  @ApiPropertyOptional()
  @IsString()
  @IsOptional()
  address?: string;
}

export class SendMessageDto {
  @ApiProperty({ description: 'Message content (text or URL)' })
  @IsString()
  @IsNotEmpty()
  content: string;

  @ApiProperty({ enum: MessageType, default: MessageType.TEXT })
  @IsEnum(MessageType)
  @IsOptional()
  type?: MessageType = MessageType.TEXT;

  @ApiPropertyOptional({ description: 'ID of the message being replied to' })
  @IsString()
  @IsOptional()
  replyToId?: string;

  @ApiPropertyOptional({ description: 'Location data for location messages' })
  @ValidateNested()
  @Type(() => LocationDto)
  @IsOptional()
  location?: LocationDto;

  @ApiPropertyOptional({ description: 'Additional metadata' })
  @IsObject()
  @IsOptional()
  metadata?: Record<string, any>;
}
