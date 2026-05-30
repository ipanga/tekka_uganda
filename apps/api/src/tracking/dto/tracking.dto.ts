import { IsNotEmpty, IsString } from 'class-validator';
import { ApiProperty } from '@nestjs/swagger';

/**
 * Body of POST /api/v1/tracking/category-view. The id is the leaf-level
 * Category.id (cuid). We don't accept slug here on purpose — the table FK
 * is on id and we don't want a slug→id lookup on every beacon.
 */
export class CategoryViewDto {
  @ApiProperty({
    description: 'Category cuid the viewer just navigated to.',
    example: 'cmktcclfy0002owcahgwdiejp',
  })
  @IsString()
  @IsNotEmpty()
  categoryId!: string;
}
