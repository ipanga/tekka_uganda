import { Controller, Get, Param, NotFoundException } from '@nestjs/common';
import { ApiTags, ApiOperation, ApiResponse, ApiParam } from '@nestjs/swagger';
import { AttributesService } from './attributes.service';

@ApiTags('Attributes')
@Controller('attributes')
export class AttributesController {
  constructor(private readonly attributesService: AttributesService) {}

  @Get()
  @ApiOperation({ summary: 'Get all attribute definitions' })
  @ApiResponse({
    status: 200,
    description: 'List of all attributes with their values',
  })
  findAll() {
    return this.attributesService.findAll();
  }

  @Get(':id')
  @ApiOperation({ summary: 'Get an attribute by ID' })
  @ApiParam({ name: 'id', description: 'Attribute ID' })
  @ApiResponse({
    status: 200,
    description: 'Attribute details with values',
  })
  @ApiResponse({ status: 404, description: 'Attribute not found' })
  async findOne(@Param('id') id: string) {
    const attribute = await this.attributesService.findOne(id);
    if (!attribute) {
      throw new NotFoundException(`Attribute with ID ${id} not found`);
    }
    return attribute;
  }

  @Get('slug/:slug')
  @ApiOperation({ summary: 'Get an attribute by slug' })
  @ApiParam({
    name: 'slug',
    description: 'Attribute slug (e.g., size-clothing, brand-fashion)',
  })
  @ApiResponse({
    status: 200,
    description: 'Attribute details with values',
  })
  @ApiResponse({ status: 404, description: 'Attribute not found' })
  async findBySlug(@Param('slug') slug: string) {
    const attribute = await this.attributesService.findBySlug(slug);
    if (!attribute) {
      throw new NotFoundException(`Attribute with slug "${slug}" not found`);
    }
    return attribute;
  }

  @Get(':id/values')
  @ApiOperation({ summary: 'Get values for an attribute' })
  @ApiParam({ name: 'id', description: 'Attribute ID' })
  @ApiResponse({
    status: 200,
    description: 'List of attribute values',
  })
  getValues(@Param('id') id: string) {
    return this.attributesService.getValues(id);
  }

  @Get('slug/:slug/values')
  @ApiOperation({ summary: 'Get values for an attribute by slug' })
  @ApiParam({
    name: 'slug',
    description: 'Attribute slug (e.g., size-clothing)',
  })
  @ApiResponse({
    status: 200,
    description: 'List of attribute values',
  })
  getValuesBySlug(@Param('slug') slug: string) {
    return this.attributesService.getValuesBySlug(slug);
  }
}
