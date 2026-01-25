import { IsString, IsNotEmpty } from 'class-validator';
import { ApiProperty } from '@nestjs/swagger';

export class UpdateMessageDto {
  @ApiProperty({ description: 'Updated message content' })
  @IsString()
  @IsNotEmpty()
  content: string;
}
