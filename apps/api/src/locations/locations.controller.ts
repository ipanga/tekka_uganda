import { Controller, Get, Param, NotFoundException } from '@nestjs/common';
import { ApiTags, ApiOperation, ApiResponse, ApiParam } from '@nestjs/swagger';
import { LocationsService } from './locations.service';

@ApiTags('Locations')
@Controller('locations')
export class LocationsController {
  constructor(private readonly locationsService: LocationsService) {}

  @Get('cities')
  @ApiOperation({ summary: 'Get all cities' })
  @ApiResponse({
    status: 200,
    description: 'List of all active cities',
  })
  getCities() {
    return this.locationsService.getCities();
  }

  @Get('cities/with-divisions')
  @ApiOperation({ summary: 'Get all cities with their divisions' })
  @ApiResponse({
    status: 200,
    description: 'List of all cities with nested divisions',
  })
  getCitiesWithDivisions() {
    return this.locationsService.getCitiesWithDivisions();
  }

  @Get('cities/:id')
  @ApiOperation({ summary: 'Get a city by ID' })
  @ApiParam({ name: 'id', description: 'City ID' })
  @ApiResponse({
    status: 200,
    description: 'City details with divisions',
  })
  @ApiResponse({ status: 404, description: 'City not found' })
  async getCity(@Param('id') id: string) {
    const city = await this.locationsService.getCity(id);
    if (!city) {
      throw new NotFoundException(`City with ID ${id} not found`);
    }
    return city;
  }

  @Get('cities/:id/divisions')
  @ApiOperation({ summary: 'Get divisions for a city' })
  @ApiParam({ name: 'id', description: 'City ID' })
  @ApiResponse({
    status: 200,
    description: 'List of divisions for the city',
  })
  getDivisions(@Param('id') id: string) {
    return this.locationsService.getDivisions(id);
  }

  @Get('divisions/:id')
  @ApiOperation({ summary: 'Get a division by ID' })
  @ApiParam({ name: 'id', description: 'Division ID' })
  @ApiResponse({
    status: 200,
    description: 'Division details with city',
  })
  @ApiResponse({ status: 404, description: 'Division not found' })
  async getDivision(@Param('id') id: string) {
    const division = await this.locationsService.getDivision(id);
    if (!division) {
      throw new NotFoundException(`Division with ID ${id} not found`);
    }
    return division;
  }
}
