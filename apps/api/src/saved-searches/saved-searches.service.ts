import { Injectable, NotFoundException } from '@nestjs/common';
import { PrismaService } from '../prisma/prisma.service';
import {
  CreateSavedSearchDto,
  UpdateSavedSearchDto,
} from './dto/create-saved-search.dto';

@Injectable()
export class SavedSearchesService {
  constructor(private prisma: PrismaService) {}

  async create(userId: string, dto: CreateSavedSearchDto) {
    return this.prisma.savedSearch.create({
      data: {
        userId,
        query: dto.query,
        categoryId: dto.categoryId,
        categoryName: dto.categoryName,
        minPrice: dto.minPrice,
        maxPrice: dto.maxPrice,
        location: dto.location,
        condition: dto.condition,
        notificationsEnabled: dto.notificationsEnabled ?? true,
        newMatchCount: 0,
      },
    });
  }

  async findAll(userId: string) {
    return this.prisma.savedSearch.findMany({
      where: { userId },
      orderBy: { createdAt: 'desc' },
    });
  }

  async findOne(userId: string, id: string) {
    const savedSearch = await this.prisma.savedSearch.findFirst({
      where: { id, userId },
    });

    if (!savedSearch) {
      throw new NotFoundException('Saved search not found');
    }

    return savedSearch;
  }

  async update(userId: string, id: string, dto: UpdateSavedSearchDto) {
    // First verify ownership
    await this.findOne(userId, id);

    return this.prisma.savedSearch.update({
      where: { id },
      data: dto,
    });
  }

  async toggleNotifications(userId: string, id: string, enabled: boolean) {
    await this.findOne(userId, id);

    return this.prisma.savedSearch.update({
      where: { id },
      data: { notificationsEnabled: enabled },
    });
  }

  async clearNewMatches(userId: string, id: string) {
    await this.findOne(userId, id);

    return this.prisma.savedSearch.update({
      where: { id },
      data: { newMatchCount: 0 },
    });
  }

  async remove(userId: string, id: string) {
    await this.findOne(userId, id);

    return this.prisma.savedSearch.delete({
      where: { id },
    });
  }

  async removeAll(userId: string) {
    return this.prisma.savedSearch.deleteMany({
      where: { userId },
    });
  }

  async isSearchSaved(userId: string, query: string) {
    const count = await this.prisma.savedSearch.count({
      where: { userId, query },
    });
    return count > 0;
  }

  async getSearchesWithMatches(userId: string) {
    return this.prisma.savedSearch.count({
      where: {
        userId,
        newMatchCount: { gt: 0 },
      },
    });
  }
}
