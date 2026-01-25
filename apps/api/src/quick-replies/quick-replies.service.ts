import { Injectable, NotFoundException } from '@nestjs/common';
import { PrismaService } from '../prisma/prisma.service';
import {
  CreateQuickReplyDto,
  UpdateQuickReplyDto,
} from './dto/create-quick-reply.dto';

@Injectable()
export class QuickRepliesService {
  constructor(private prisma: PrismaService) {}

  private getDefaultTemplates() {
    const now = new Date();
    return [
      {
        id: 'default_1',
        text: 'Is this still available?',
        category: 'availability',
        isDefault: true,
        usageCount: 0,
        createdAt: now,
        lastUsedAt: null,
      },
      {
        id: 'default_2',
        text: "What's your lowest price?",
        category: 'pricing',
        isDefault: true,
        usageCount: 0,
        createdAt: now,
        lastUsedAt: null,
      },
      {
        id: 'default_3',
        text: 'Can we arrange a meetup?',
        category: 'meetup',
        isDefault: true,
        usageCount: 0,
        createdAt: now,
        lastUsedAt: null,
      },
      {
        id: 'default_4',
        text: 'Can you send more photos?',
        category: 'availability',
        isDefault: true,
        usageCount: 0,
        createdAt: now,
        lastUsedAt: null,
      },
      {
        id: 'default_5',
        text: 'Is the price negotiable?',
        category: 'pricing',
        isDefault: true,
        usageCount: 0,
        createdAt: now,
        lastUsedAt: null,
      },
      {
        id: 'default_6',
        text: 'Yes, it is still available!',
        category: 'availability',
        isDefault: true,
        usageCount: 0,
        createdAt: now,
        lastUsedAt: null,
      },
      {
        id: 'default_7',
        text: 'The price is fixed, sorry.',
        category: 'pricing',
        isDefault: true,
        usageCount: 0,
        createdAt: now,
        lastUsedAt: null,
      },
      {
        id: 'default_8',
        text: "I can do a small discount if you're buying today.",
        category: 'pricing',
        isDefault: true,
        usageCount: 0,
        createdAt: now,
        lastUsedAt: null,
      },
      {
        id: 'default_9',
        text: 'When would you like to meet?',
        category: 'meetup',
        isDefault: true,
        usageCount: 0,
        createdAt: now,
        lastUsedAt: null,
      },
      {
        id: 'default_10',
        text: 'Thank you for your interest!',
        category: 'thanks',
        isDefault: true,
        usageCount: 0,
        createdAt: now,
        lastUsedAt: null,
      },
    ];
  }

  async create(userId: string, dto: CreateQuickReplyDto) {
    return this.prisma.quickReplyTemplate.create({
      data: {
        userId,
        text: dto.text,
        category: dto.category ?? 'custom',
        isDefault: dto.isDefault ?? false,
        usageCount: 0,
      },
    });
  }

  async findAll(userId: string) {
    const templates = await this.prisma.quickReplyTemplate.findMany({
      where: { userId },
      orderBy: { usageCount: 'desc' },
    });

    // If user has no templates, return defaults
    if (templates.length === 0) {
      return this.getDefaultTemplates();
    }

    return templates;
  }

  async findOne(userId: string, id: string) {
    const template = await this.prisma.quickReplyTemplate.findFirst({
      where: { id, userId },
    });

    if (!template) {
      throw new NotFoundException('Quick reply template not found');
    }

    return template;
  }

  async update(userId: string, id: string, dto: UpdateQuickReplyDto) {
    await this.findOne(userId, id);

    return this.prisma.quickReplyTemplate.update({
      where: { id },
      data: {
        ...(dto.text && { text: dto.text }),
        ...(dto.category && { category: dto.category }),
      },
    });
  }

  async recordUsage(userId: string, id: string) {
    // Check if it's a default template ID and user doesn't have it yet
    if (id.startsWith('default_')) {
      const existing = await this.prisma.quickReplyTemplate.findFirst({
        where: { id, userId },
      });

      if (!existing) {
        // This is a default template being used for the first time
        // We don't track usage for default templates that aren't saved
        return;
      }
    }

    try {
      await this.prisma.quickReplyTemplate.update({
        where: { id },
        data: {
          usageCount: { increment: 1 },
          lastUsedAt: new Date(),
        },
      });
    } catch {
      // Silently fail if template doesn't exist
    }
  }

  async remove(userId: string, id: string) {
    await this.findOne(userId, id);

    return this.prisma.quickReplyTemplate.delete({
      where: { id },
    });
  }

  async initializeDefaults(userId: string) {
    const existing = await this.prisma.quickReplyTemplate.count({
      where: { userId },
    });

    if (existing > 0) {
      return { initialized: false, message: 'User already has templates' };
    }

    const defaults = this.getDefaultTemplates();
    await this.prisma.quickReplyTemplate.createMany({
      data: defaults.map((t) => ({
        id: t.id,
        userId,
        text: t.text,
        category: t.category,
        isDefault: t.isDefault,
        usageCount: 0,
      })),
    });

    return { initialized: true, count: defaults.length };
  }

  async resetToDefaults(userId: string) {
    // Delete all user templates
    await this.prisma.quickReplyTemplate.deleteMany({
      where: { userId },
    });

    // Add default templates
    const defaults = this.getDefaultTemplates();
    await this.prisma.quickReplyTemplate.createMany({
      data: defaults.map((t) => ({
        id: t.id,
        userId,
        text: t.text,
        category: t.category,
        isDefault: t.isDefault,
        usageCount: 0,
      })),
    });

    return { reset: true, count: defaults.length };
  }
}
