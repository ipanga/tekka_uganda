import { IsString, IsOptional, IsNumber, IsBoolean } from 'class-validator';

export class CreateSavedSearchDto {
  @IsString()
  query: string;

  @IsOptional()
  @IsString()
  categoryId?: string;

  @IsOptional()
  @IsString()
  categoryName?: string;

  @IsOptional()
  @IsNumber()
  minPrice?: number;

  @IsOptional()
  @IsNumber()
  maxPrice?: number;

  @IsOptional()
  @IsString()
  location?: string;

  @IsOptional()
  @IsString()
  condition?: string;

  @IsOptional()
  @IsBoolean()
  notificationsEnabled?: boolean;
}

export class UpdateSavedSearchDto {
  @IsOptional()
  @IsBoolean()
  notificationsEnabled?: boolean;

  @IsOptional()
  @IsNumber()
  newMatchCount?: number;
}
