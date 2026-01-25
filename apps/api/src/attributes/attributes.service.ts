import { Injectable } from '@nestjs/common';
import { PrismaService } from '../prisma/prisma.service';

@Injectable()
export class AttributesService {
  constructor(private prisma: PrismaService) {}

  /**
   * Get all attribute definitions
   */
  async findAll() {
    return this.prisma.attributeDefinition.findMany({
      where: { isActive: true },
      orderBy: { sortOrder: 'asc' },
      include: {
        values: {
          where: { isActive: true },
          orderBy: { sortOrder: 'asc' },
        },
      },
    });
  }

  /**
   * Get a single attribute by ID
   */
  async findOne(id: string) {
    return this.prisma.attributeDefinition.findUnique({
      where: { id },
      include: {
        values: {
          where: { isActive: true },
          orderBy: { sortOrder: 'asc' },
        },
      },
    });
  }

  /**
   * Get an attribute by slug with its values
   */
  async findBySlug(slug: string) {
    return this.prisma.attributeDefinition.findUnique({
      where: { slug },
      include: {
        values: {
          where: { isActive: true },
          orderBy: { sortOrder: 'asc' },
        },
      },
    });
  }

  /**
   * Get values for a specific attribute
   */
  async getValues(attributeId: string) {
    return this.prisma.attributeValue.findMany({
      where: {
        attributeId,
        isActive: true,
      },
      orderBy: { sortOrder: 'asc' },
      select: {
        id: true,
        value: true,
        displayValue: true,
        metadata: true,
        sortOrder: true,
      },
    });
  }

  /**
   * Get values for an attribute by slug
   */
  async getValuesBySlug(slug: string) {
    const attribute = await this.prisma.attributeDefinition.findUnique({
      where: { slug },
      include: {
        values: {
          where: { isActive: true },
          orderBy: { sortOrder: 'asc' },
        },
      },
    });

    return attribute?.values || [];
  }
}
