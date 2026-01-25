import { Injectable } from '@nestjs/common';
import { PrismaService } from '../prisma/prisma.service';

@Injectable()
export class CategoriesService {
  constructor(private prisma: PrismaService) {}

  /**
   * Get all categories with hierarchical structure
   */
  async findAll() {
    const categories = await this.prisma.category.findMany({
      where: { isActive: true },
      orderBy: [{ level: 'asc' }, { sortOrder: 'asc' }],
      include: {
        children: {
          where: { isActive: true },
          orderBy: { sortOrder: 'asc' },
          include: {
            children: {
              where: { isActive: true },
              orderBy: { sortOrder: 'asc' },
            },
          },
        },
      },
    });

    // Return only top-level categories (level 1)
    return categories.filter((cat) => cat.level === 1);
  }

  /**
   * Get all categories as flat list
   */
  async findAllFlat() {
    return this.prisma.category.findMany({
      where: { isActive: true },
      orderBy: [{ level: 'asc' }, { sortOrder: 'asc' }],
      select: {
        id: true,
        name: true,
        slug: true,
        level: true,
        parentId: true,
        iconName: true,
        imageUrl: true,
        sortOrder: true,
      },
    });
  }

  /**
   * Get a single category by ID with its attributes
   */
  async findOne(id: string) {
    return this.prisma.category.findUnique({
      where: { id },
      include: {
        parent: true,
        children: {
          where: { isActive: true },
          orderBy: { sortOrder: 'asc' },
        },
        attributes: {
          orderBy: { sortOrder: 'asc' },
          include: {
            attribute: {
              include: {
                values: {
                  where: { isActive: true },
                  orderBy: { sortOrder: 'asc' },
                },
              },
            },
          },
        },
      },
    });
  }

  /**
   * Get a category by slug
   */
  async findBySlug(slug: string) {
    return this.prisma.category.findUnique({
      where: { slug },
      include: {
        parent: true,
        children: {
          where: { isActive: true },
          orderBy: { sortOrder: 'asc' },
        },
        attributes: {
          orderBy: { sortOrder: 'asc' },
          include: {
            attribute: {
              include: {
                values: {
                  where: { isActive: true },
                  orderBy: { sortOrder: 'asc' },
                },
              },
            },
          },
        },
      },
    });
  }

  /**
   * Get attributes for a specific category
   * This includes inherited attributes from parent categories
   */
  async getAttributesForCategory(categoryId: string) {
    // First, get the category and its ancestors
    const category = await this.prisma.category.findUnique({
      where: { id: categoryId },
      include: {
        parent: {
          include: {
            parent: true,
          },
        },
      },
    });

    if (!category) {
      return [];
    }

    // Collect all category IDs (self + ancestors)
    const categoryIds: string[] = [categoryId];
    if (category.parentId) {
      categoryIds.push(category.parentId);
      if (category.parent?.parentId) {
        categoryIds.push(category.parent.parentId);
      }
    }

    // Get all attributes for these categories (excluding inactive attributes)
    const categoryAttributes = await this.prisma.categoryAttribute.findMany({
      where: {
        categoryId: { in: categoryIds },
        attribute: {
          isActive: true, // Filter out deprecated attributes like pattern/style
        },
      },
      orderBy: { sortOrder: 'asc' },
      include: {
        attribute: {
          include: {
            values: {
              where: { isActive: true },
              orderBy: { sortOrder: 'asc' },
            },
          },
        },
      },
    });

    // Deduplicate by attribute ID (closest category wins)
    const attributeMap = new Map<string, (typeof categoryAttributes)[0]>();

    // Process in order: L3 -> L2 -> L1 (closest takes precedence)
    for (const catAttr of categoryAttributes) {
      const existingAttr = attributeMap.get(catAttr.attributeId);
      if (!existingAttr) {
        attributeMap.set(catAttr.attributeId, catAttr);
      }
    }

    return Array.from(attributeMap.values()).map((ca) => ({
      id: ca.attribute.id,
      name: ca.attribute.name,
      slug: ca.attribute.slug,
      type: ca.attribute.type,
      isRequired: ca.isRequired,
      values: ca.attribute.values.map((v) => ({
        value: v.value,
        displayValue: v.displayValue || v.value,
        metadata: v.metadata,
      })),
    }));
  }

  /**
   * Get child categories by parent ID
   */
  async getChildren(parentId: string) {
    return this.prisma.category.findMany({
      where: {
        parentId,
        isActive: true,
      },
      orderBy: { sortOrder: 'asc' },
      select: {
        id: true,
        name: true,
        slug: true,
        level: true,
        iconName: true,
        imageUrl: true,
      },
    });
  }

  /**
   * Get breadcrumb path for a category
   */
  async getBreadcrumb(categoryId: string) {
    const category = await this.prisma.category.findUnique({
      where: { id: categoryId },
      include: {
        parent: {
          include: {
            parent: true,
          },
        },
      },
    });

    if (!category) {
      return [];
    }

    const breadcrumb = [
      { id: category.id, name: category.name, slug: category.slug },
    ];

    if (category.parent) {
      breadcrumb.unshift({
        id: category.parent.id,
        name: category.parent.name,
        slug: category.parent.slug,
      });

      if (category.parent.parent) {
        breadcrumb.unshift({
          id: category.parent.parent.id,
          name: category.parent.parent.name,
          slug: category.parent.parent.slug,
        });
      }
    }

    return breadcrumb;
  }
}
