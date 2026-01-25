import { IsString, IsOptional, IsBoolean } from 'class-validator';

export class CreateQuickReplyDto {
  @IsString()
  text: string;

  @IsOptional()
  @IsString()
  category?: string;

  @IsOptional()
  @IsBoolean()
  isDefault?: boolean;
}

export class UpdateQuickReplyDto {
  @IsOptional()
  @IsString()
  text?: string;

  @IsOptional()
  @IsString()
  category?: string;
}
