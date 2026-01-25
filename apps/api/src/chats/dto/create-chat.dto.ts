import { IsString, IsNotEmpty, IsOptional } from 'class-validator';
import { ApiProperty, ApiPropertyOptional } from '@nestjs/swagger';

export class CreateChatDto {
  @ApiPropertyOptional({ description: 'ID of the seller (other participant)' })
  @IsString()
  @IsOptional()
  sellerId?: string;

  @ApiPropertyOptional({
    description: 'ID of the other participant (alias for sellerId)',
  })
  @IsString()
  @IsOptional()
  participantId?: string;

  @ApiProperty({ description: 'ID of the listing this chat is about' })
  @IsString()
  @IsNotEmpty()
  listingId: string;
}
