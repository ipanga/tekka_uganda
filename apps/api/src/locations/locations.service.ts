import { Injectable } from '@nestjs/common';
import { PrismaService } from '../prisma/prisma.service';

@Injectable()
export class LocationsService {
  constructor(private prisma: PrismaService) {}

  /**
   * Get all cities
   */
  async getCities() {
    return this.prisma.city.findMany({
      where: { isActive: true },
      orderBy: { sortOrder: 'asc' },
      select: {
        id: true,
        name: true,
      },
    });
  }

  /**
   * Get all cities with their divisions
   */
  async getCitiesWithDivisions() {
    return this.prisma.city.findMany({
      where: { isActive: true },
      orderBy: { sortOrder: 'asc' },
      include: {
        divisions: {
          where: { isActive: true },
          orderBy: { sortOrder: 'asc' },
          select: {
            id: true,
            name: true,
          },
        },
      },
    });
  }

  /**
   * Get a city by ID
   */
  async getCity(id: string) {
    return this.prisma.city.findUnique({
      where: { id },
      include: {
        divisions: {
          where: { isActive: true },
          orderBy: { sortOrder: 'asc' },
        },
      },
    });
  }

  /**
   * Get divisions for a city
   */
  async getDivisions(cityId: string) {
    return this.prisma.division.findMany({
      where: {
        cityId,
        isActive: true,
      },
      orderBy: { sortOrder: 'asc' },
      select: {
        id: true,
        name: true,
      },
    });
  }

  /**
   * Get a division by ID
   */
  async getDivision(id: string) {
    return this.prisma.division.findUnique({
      where: { id },
      include: {
        city: true,
      },
    });
  }
}
