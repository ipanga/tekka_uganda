import { IsOptional, IsBoolean } from 'class-validator';
import { ApiPropertyOptional } from '@nestjs/swagger';

export class UpdatePriceAlertDto {
  @ApiPropertyOptional({ description: 'Mark as read' })
  @IsBoolean()
  @IsOptional()
  isRead?: boolean;
}
