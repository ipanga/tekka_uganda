import { Controller, Get, Param, NotFoundException } from '@nestjs/common';
import { ApiTags, ApiOperation, ApiResponse, ApiParam } from '@nestjs/swagger';
import { CategoriesService } from './categories.service';

@ApiTags('Categories')
@Controller('categories')
export class CategoriesController {
  constructor(private readonly categoriesService: CategoriesService) {}

  @Get()
  @ApiOperation({ summary: 'Get all categories in hierarchical structure' })
  @ApiResponse({
    status: 200,
    description: 'List of top-level categories with nested children',
  })
  findAll() {
    return this.categoriesService.findAll();
  }

  @Get('flat')
  @ApiOperation({ summary: 'Get all categories as flat list' })
  @ApiResponse({
    status: 200,
    description: 'Flat list of all categories',
  })
  findAllFlat() {
    return this.categoriesService.findAllFlat();
  }

  @Get(':id')
  @ApiOperation({ summary: 'Get a category by ID' })
  @ApiParam({ name: 'id', description: 'Category ID' })
  @ApiResponse({
    status: 200,
    description: 'Category details with children and attributes',
  })
  @ApiResponse({ status: 404, description: 'Category not found' })
  async findOne(@Param('id') id: string) {
    const category = await this.categoriesService.findOne(id);
    if (!category) {
      throw new NotFoundException(`Category with ID ${id} not found`);
    }
    return category;
  }

  @Get('slug/:slug')
  @ApiOperation({ summary: 'Get a category by slug' })
  @ApiParam({
    name: 'slug',
    description: 'Category slug (e.g., women-dresses)',
  })
  @ApiResponse({
    status: 200,
    description: 'Category details with children and attributes',
  })
  @ApiResponse({ status: 404, description: 'Category not found' })
  async findBySlug(@Param('slug') slug: string) {
    const category = await this.categoriesService.findBySlug(slug);
    if (!category) {
      throw new NotFoundException(`Category with slug "${slug}" not found`);
    }
    return category;
  }

  @Get(':id/attributes')
  @ApiOperation({
    summary: 'Get attributes for a category',
    description:
      'Returns all attributes applicable to this category, including inherited attributes from parent categories',
  })
  @ApiParam({ name: 'id', description: 'Category ID' })
  @ApiResponse({
    status: 200,
    description: 'List of attributes with their values',
  })
  getAttributes(@Param('id') id: string) {
    return this.categoriesService.getAttributesForCategory(id);
  }

  @Get(':id/children')
  @ApiOperation({ summary: 'Get child categories' })
  @ApiParam({ name: 'id', description: 'Parent category ID' })
  @ApiResponse({
    status: 200,
    description: 'List of child categories',
  })
  getChildren(@Param('id') id: string) {
    return this.categoriesService.getChildren(id);
  }

  @Get(':id/breadcrumb')
  @ApiOperation({ summary: 'Get breadcrumb path for a category' })
  @ApiParam({ name: 'id', description: 'Category ID' })
  @ApiResponse({
    status: 200,
    description: 'Breadcrumb path from root to category',
  })
  getBreadcrumb(@Param('id') id: string) {
    return this.categoriesService.getBreadcrumb(id);
  }
}
