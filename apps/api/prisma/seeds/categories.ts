import { prisma } from './client';

interface CategorySeed {
  name: string;
  slug: string;
  level: number;
  parentSlug?: string;
  iconName?: string;
  sortOrder: number;
}

const categories: CategorySeed[] = [
  // ============================================
  // Level 1: Main Categories
  // ============================================
  { name: 'Women', slug: 'women', level: 1, iconName: 'woman', sortOrder: 1 },
  { name: 'Men', slug: 'men', level: 1, iconName: 'man', sortOrder: 2 },
  { name: 'Kids', slug: 'kids', level: 1, iconName: 'child', sortOrder: 3 },
  { name: 'Home', slug: 'home', level: 1, iconName: 'home', sortOrder: 4 },
  { name: 'Electronics', slug: 'electronics', level: 1, iconName: 'devices', sortOrder: 5 },

  // ============================================
  // Level 2: Women Sub-categories
  // ============================================
  { name: 'Clothing', slug: 'women-clothing', level: 2, parentSlug: 'women', sortOrder: 1 },
  { name: 'Shoes', slug: 'women-shoes', level: 2, parentSlug: 'women', sortOrder: 2 },
  { name: 'Bags', slug: 'women-bags', level: 2, parentSlug: 'women', sortOrder: 3 },
  { name: 'Accessories', slug: 'women-accessories', level: 2, parentSlug: 'women', sortOrder: 4 },

  // ============================================
  // Level 2: Men Sub-categories
  // ============================================
  { name: 'Clothing', slug: 'men-clothing', level: 2, parentSlug: 'men', sortOrder: 1 },
  { name: 'Shoes', slug: 'men-shoes', level: 2, parentSlug: 'men', sortOrder: 2 },
  { name: 'Bags', slug: 'men-bags', level: 2, parentSlug: 'men', sortOrder: 3 },
  { name: 'Accessories', slug: 'men-accessories', level: 2, parentSlug: 'men', sortOrder: 4 },

  // ============================================
  // Level 2: Kids Sub-categories
  // ============================================
  { name: 'Girls', slug: 'kids-girls', level: 2, parentSlug: 'kids', sortOrder: 1 },
  { name: 'Boys', slug: 'kids-boys', level: 2, parentSlug: 'kids', sortOrder: 2 },
  { name: 'Baby', slug: 'kids-baby', level: 2, parentSlug: 'kids', sortOrder: 3 },

  // ============================================
  // Level 2: Home Sub-categories
  // ============================================
  { name: 'Furniture', slug: 'home-furniture', level: 2, parentSlug: 'home', sortOrder: 1 },
  { name: 'Decor', slug: 'home-decor', level: 2, parentSlug: 'home', sortOrder: 2 },
  { name: 'Kitchen', slug: 'home-kitchen', level: 2, parentSlug: 'home', sortOrder: 3 },
  { name: 'Bedding', slug: 'home-bedding', level: 2, parentSlug: 'home', sortOrder: 4 },
  { name: 'Lighting', slug: 'home-lighting', level: 2, parentSlug: 'home', sortOrder: 5 },

  // ============================================
  // Level 2: Electronics Sub-categories
  // ============================================
  { name: 'Phones & Tablets', slug: 'electronics-phones', level: 2, parentSlug: 'electronics', sortOrder: 1 },
  { name: 'Computers', slug: 'electronics-computers', level: 2, parentSlug: 'electronics', sortOrder: 2 },
  { name: 'TV & Audio', slug: 'electronics-tv-audio', level: 2, parentSlug: 'electronics', sortOrder: 3 },
  { name: 'Gaming', slug: 'electronics-gaming', level: 2, parentSlug: 'electronics', sortOrder: 4 },
  { name: 'Cameras', slug: 'electronics-cameras', level: 2, parentSlug: 'electronics', sortOrder: 5 },

  // ============================================
  // Level 3: Women > Clothing
  // ============================================
  { name: 'Dresses', slug: 'women-dresses', level: 3, parentSlug: 'women-clothing', sortOrder: 1 },
  { name: 'Tops & T-shirts', slug: 'women-tops', level: 3, parentSlug: 'women-clothing', sortOrder: 2 },
  { name: 'Skirts', slug: 'women-skirts', level: 3, parentSlug: 'women-clothing', sortOrder: 3 },
  { name: 'Pants & Leggings', slug: 'women-pants', level: 3, parentSlug: 'women-clothing', sortOrder: 4 },
  { name: 'Jeans', slug: 'women-jeans', level: 3, parentSlug: 'women-clothing', sortOrder: 5 },
  { name: 'Lingerie & Nightwear', slug: 'women-lingerie', level: 3, parentSlug: 'women-clothing', sortOrder: 6 },
  { name: 'Outerwear', slug: 'women-outerwear', level: 3, parentSlug: 'women-clothing', sortOrder: 7 },
  { name: 'Other Clothing', slug: 'women-other-clothing', level: 3, parentSlug: 'women-clothing', sortOrder: 8 },

  // ============================================
  // Level 3: Women > Shoes
  // ============================================
  { name: 'Heels', slug: 'women-heels', level: 3, parentSlug: 'women-shoes', sortOrder: 1 },
  { name: 'Flats', slug: 'women-flats', level: 3, parentSlug: 'women-shoes', sortOrder: 2 },
  { name: 'Sandals', slug: 'women-sandals', level: 3, parentSlug: 'women-shoes', sortOrder: 3 },
  { name: 'Boots', slug: 'women-boots', level: 3, parentSlug: 'women-shoes', sortOrder: 4 },
  { name: 'Sneakers', slug: 'women-sneakers', level: 3, parentSlug: 'women-shoes', sortOrder: 5 },
  { name: 'Slippers', slug: 'women-slippers', level: 3, parentSlug: 'women-shoes', sortOrder: 6 },

  // ============================================
  // Level 3: Women > Bags
  // ============================================
  { name: 'Handbags', slug: 'women-handbags', level: 3, parentSlug: 'women-bags', sortOrder: 1 },
  { name: 'Clutches', slug: 'women-clutches', level: 3, parentSlug: 'women-bags', sortOrder: 2 },
  { name: 'Backpacks', slug: 'women-backpacks', level: 3, parentSlug: 'women-bags', sortOrder: 3 },
  { name: 'Totes', slug: 'women-totes', level: 3, parentSlug: 'women-bags', sortOrder: 4 },
  { name: 'Crossbody Bags', slug: 'women-crossbody', level: 3, parentSlug: 'women-bags', sortOrder: 5 },

  // ============================================
  // Level 3: Women > Accessories
  // ============================================
  { name: 'Jewelry', slug: 'women-jewelry', level: 3, parentSlug: 'women-accessories', sortOrder: 1 },
  { name: 'Watches', slug: 'women-watches', level: 3, parentSlug: 'women-accessories', sortOrder: 2 },
  { name: 'Scarves & Wraps', slug: 'women-scarves', level: 3, parentSlug: 'women-accessories', sortOrder: 3 },
  { name: 'Belts', slug: 'women-belts', level: 3, parentSlug: 'women-accessories', sortOrder: 4 },
  { name: 'Sunglasses', slug: 'women-sunglasses', level: 3, parentSlug: 'women-accessories', sortOrder: 5 },
  { name: 'Hair Accessories', slug: 'women-hair-accessories', level: 3, parentSlug: 'women-accessories', sortOrder: 6 },

  // ============================================
  // Level 3: Men > Clothing
  // ============================================
  { name: 'Tops & T-shirts', slug: 'men-tops', level: 3, parentSlug: 'men-clothing', sortOrder: 1 },
  { name: 'Pants', slug: 'men-pants', level: 3, parentSlug: 'men-clothing', sortOrder: 2 },
  { name: 'Jeans', slug: 'men-jeans', level: 3, parentSlug: 'men-clothing', sortOrder: 3 },
  { name: 'Shorts', slug: 'men-shorts', level: 3, parentSlug: 'men-clothing', sortOrder: 4 },
  { name: 'Suits & Blazers', slug: 'men-suits', level: 3, parentSlug: 'men-clothing', sortOrder: 5 },
  { name: 'Traditional Wear', slug: 'men-traditional', level: 3, parentSlug: 'men-clothing', sortOrder: 6 },
  { name: 'Underwear & Socks', slug: 'men-underwear', level: 3, parentSlug: 'men-clothing', sortOrder: 7 },
  { name: 'Other Clothing', slug: 'men-other-clothing', level: 3, parentSlug: 'men-clothing', sortOrder: 8 },

  // ============================================
  // Level 3: Men > Shoes
  // ============================================
  { name: 'Formal Shoes', slug: 'men-formal-shoes', level: 3, parentSlug: 'men-shoes', sortOrder: 1 },
  { name: 'Casual Shoes', slug: 'men-casual-shoes', level: 3, parentSlug: 'men-shoes', sortOrder: 2 },
  { name: 'Sneakers', slug: 'men-sneakers', level: 3, parentSlug: 'men-shoes', sortOrder: 3 },
  { name: 'Sandals', slug: 'men-sandals', level: 3, parentSlug: 'men-shoes', sortOrder: 4 },
  { name: 'Boots', slug: 'men-boots', level: 3, parentSlug: 'men-shoes', sortOrder: 5 },
  { name: 'Slippers', slug: 'men-slippers', level: 3, parentSlug: 'men-shoes', sortOrder: 6 },

  // ============================================
  // Level 3: Men > Bags
  // ============================================
  { name: 'Backpacks', slug: 'men-backpacks', level: 3, parentSlug: 'men-bags', sortOrder: 1 },
  { name: 'Briefcases', slug: 'men-briefcases', level: 3, parentSlug: 'men-bags', sortOrder: 2 },
  { name: 'Messenger Bags', slug: 'men-messenger', level: 3, parentSlug: 'men-bags', sortOrder: 3 },
  { name: 'Duffel Bags', slug: 'men-duffel', level: 3, parentSlug: 'men-bags', sortOrder: 4 },

  // ============================================
  // Level 3: Men > Accessories
  // ============================================
  { name: 'Watches', slug: 'men-watches', level: 3, parentSlug: 'men-accessories', sortOrder: 1 },
  { name: 'Belts', slug: 'men-belts', level: 3, parentSlug: 'men-accessories', sortOrder: 2 },
  { name: 'Ties & Bowties', slug: 'men-ties', level: 3, parentSlug: 'men-accessories', sortOrder: 3 },
  { name: 'Sunglasses', slug: 'men-sunglasses', level: 3, parentSlug: 'men-accessories', sortOrder: 4 },
  { name: 'Hats & Caps', slug: 'men-hats', level: 3, parentSlug: 'men-accessories', sortOrder: 5 },
  { name: 'Wallets', slug: 'men-wallets', level: 3, parentSlug: 'men-accessories', sortOrder: 6 },

  // ============================================
  // Level 3: Kids > Girls
  // ============================================
  { name: 'Dresses', slug: 'girls-dresses', level: 3, parentSlug: 'kids-girls', sortOrder: 1 },
  { name: 'Tops', slug: 'girls-tops', level: 3, parentSlug: 'kids-girls', sortOrder: 2 },
  { name: 'Bottoms', slug: 'girls-bottoms', level: 3, parentSlug: 'kids-girls', sortOrder: 3 },
  { name: 'Shoes', slug: 'girls-shoes', level: 3, parentSlug: 'kids-girls', sortOrder: 4 },
  { name: 'Accessories', slug: 'girls-accessories', level: 3, parentSlug: 'kids-girls', sortOrder: 5 },

  // ============================================
  // Level 3: Kids > Boys
  // ============================================
  { name: 'Shirts & T-Shirts', slug: 'boys-shirts', level: 3, parentSlug: 'kids-boys', sortOrder: 1 },
  { name: 'Pants & Shorts', slug: 'boys-pants', level: 3, parentSlug: 'kids-boys', sortOrder: 2 },
  { name: 'Shoes', slug: 'boys-shoes', level: 3, parentSlug: 'kids-boys', sortOrder: 3 },
  { name: 'Accessories', slug: 'boys-accessories', level: 3, parentSlug: 'kids-boys', sortOrder: 4 },

  // ============================================
  // Level 3: Kids > Baby
  // ============================================
  { name: 'Clothing', slug: 'baby-clothing', level: 3, parentSlug: 'kids-baby', sortOrder: 1 },
  { name: 'Shoes', slug: 'baby-shoes', level: 3, parentSlug: 'kids-baby', sortOrder: 2 },
  { name: 'Accessories', slug: 'baby-accessories', level: 3, parentSlug: 'kids-baby', sortOrder: 3 },

  // ============================================
  // Level 3: Home > Furniture
  // ============================================
  { name: 'Sofas & Chairs', slug: 'home-sofas', level: 3, parentSlug: 'home-furniture', sortOrder: 1 },
  { name: 'Tables', slug: 'home-tables', level: 3, parentSlug: 'home-furniture', sortOrder: 2 },
  { name: 'Beds & Mattresses', slug: 'home-beds', level: 3, parentSlug: 'home-furniture', sortOrder: 3 },
  { name: 'Storage', slug: 'home-storage', level: 3, parentSlug: 'home-furniture', sortOrder: 4 },
  { name: 'Outdoor Furniture', slug: 'home-outdoor-furniture', level: 3, parentSlug: 'home-furniture', sortOrder: 5 },

  // ============================================
  // Level 3: Home > Decor
  // ============================================
  { name: 'Wall Art', slug: 'home-wall-art', level: 3, parentSlug: 'home-decor', sortOrder: 1 },
  { name: 'Mirrors', slug: 'home-mirrors', level: 3, parentSlug: 'home-decor', sortOrder: 2 },
  { name: 'Vases & Plants', slug: 'home-vases', level: 3, parentSlug: 'home-decor', sortOrder: 3 },
  { name: 'Rugs & Carpets', slug: 'home-rugs', level: 3, parentSlug: 'home-decor', sortOrder: 4 },
  { name: 'Curtains', slug: 'home-curtains', level: 3, parentSlug: 'home-decor', sortOrder: 5 },

  // ============================================
  // Level 3: Home > Kitchen
  // ============================================
  { name: 'Cookware', slug: 'home-cookware', level: 3, parentSlug: 'home-kitchen', sortOrder: 1 },
  { name: 'Dinnerware', slug: 'home-dinnerware', level: 3, parentSlug: 'home-kitchen', sortOrder: 2 },
  { name: 'Appliances', slug: 'home-appliances', level: 3, parentSlug: 'home-kitchen', sortOrder: 3 },
  { name: 'Storage & Organization', slug: 'home-kitchen-storage', level: 3, parentSlug: 'home-kitchen', sortOrder: 4 },

  // ============================================
  // Level 3: Home > Bedding
  // ============================================
  { name: 'Bed Sheets', slug: 'home-sheets', level: 3, parentSlug: 'home-bedding', sortOrder: 1 },
  { name: 'Duvets & Covers', slug: 'home-duvets', level: 3, parentSlug: 'home-bedding', sortOrder: 2 },
  { name: 'Pillows', slug: 'home-pillows', level: 3, parentSlug: 'home-bedding', sortOrder: 3 },
  { name: 'Blankets & Throws', slug: 'home-blankets', level: 3, parentSlug: 'home-bedding', sortOrder: 4 },

  // ============================================
  // Level 3: Home > Lighting
  // ============================================
  { name: 'Ceiling Lights', slug: 'home-ceiling-lights', level: 3, parentSlug: 'home-lighting', sortOrder: 1 },
  { name: 'Lamps', slug: 'home-lamps', level: 3, parentSlug: 'home-lighting', sortOrder: 2 },
  { name: 'Wall Lights', slug: 'home-wall-lights', level: 3, parentSlug: 'home-lighting', sortOrder: 3 },
  { name: 'Outdoor Lighting', slug: 'home-outdoor-lighting', level: 3, parentSlug: 'home-lighting', sortOrder: 4 },

  // ============================================
  // Level 3: Electronics > Phones & Tablets
  // ============================================
  { name: 'Smartphones', slug: 'electronics-smartphones', level: 3, parentSlug: 'electronics-phones', sortOrder: 1 },
  { name: 'Tablets', slug: 'electronics-tablets', level: 3, parentSlug: 'electronics-phones', sortOrder: 2 },
  { name: 'Phone Accessories', slug: 'electronics-phone-accessories', level: 3, parentSlug: 'electronics-phones', sortOrder: 3 },
  { name: 'Smartwatches', slug: 'electronics-smartwatches', level: 3, parentSlug: 'electronics-phones', sortOrder: 4 },

  // ============================================
  // Level 3: Electronics > Computers
  // ============================================
  { name: 'Laptops', slug: 'electronics-laptops', level: 3, parentSlug: 'electronics-computers', sortOrder: 1 },
  { name: 'Desktop Computers', slug: 'electronics-desktops', level: 3, parentSlug: 'electronics-computers', sortOrder: 2 },
  { name: 'Monitors', slug: 'electronics-monitors', level: 3, parentSlug: 'electronics-computers', sortOrder: 3 },
  { name: 'Computer Accessories', slug: 'electronics-computer-accessories', level: 3, parentSlug: 'electronics-computers', sortOrder: 4 },

  // ============================================
  // Level 3: Electronics > TV & Audio
  // ============================================
  { name: 'Televisions', slug: 'electronics-tvs', level: 3, parentSlug: 'electronics-tv-audio', sortOrder: 1 },
  { name: 'Speakers', slug: 'electronics-speakers', level: 3, parentSlug: 'electronics-tv-audio', sortOrder: 2 },
  { name: 'Headphones', slug: 'electronics-headphones', level: 3, parentSlug: 'electronics-tv-audio', sortOrder: 3 },
  { name: 'Home Theater', slug: 'electronics-home-theater', level: 3, parentSlug: 'electronics-tv-audio', sortOrder: 4 },

  // ============================================
  // Level 3: Electronics > Gaming
  // ============================================
  { name: 'Consoles', slug: 'electronics-consoles', level: 3, parentSlug: 'electronics-gaming', sortOrder: 1 },
  { name: 'Video Games', slug: 'electronics-games', level: 3, parentSlug: 'electronics-gaming', sortOrder: 2 },
  { name: 'Gaming Accessories', slug: 'electronics-gaming-accessories', level: 3, parentSlug: 'electronics-gaming', sortOrder: 3 },

  // ============================================
  // Level 3: Electronics > Cameras
  // ============================================
  { name: 'Digital Cameras', slug: 'electronics-digital-cameras', level: 3, parentSlug: 'electronics-cameras', sortOrder: 1 },
  { name: 'Camera Lenses', slug: 'electronics-lenses', level: 3, parentSlug: 'electronics-cameras', sortOrder: 2 },
  { name: 'Camera Accessories', slug: 'electronics-camera-accessories', level: 3, parentSlug: 'electronics-cameras', sortOrder: 3 },
];

// Slugs of L3 clothing subcategories that are obsolete and should be removed
const obsoleteClothingSubcategories = [
  // Old Women Clothing subcategories (replaced)
  'women-bottoms',
  'women-traditional',
  'women-swimwear',
  'women-activewear',
  'women-underwear',
  // Old Men Clothing subcategories (replaced)
  'men-shirts',
  'men-tshirts',
  'men-outerwear',
  'men-activewear',
];

export async function seedCategories() {
  console.log('Seeding categories...');

  // Clean up obsolete clothing subcategories
  console.log('Removing obsolete clothing subcategories...');
  for (const slug of obsoleteClothingSubcategories) {
    try {
      await prisma.category.delete({
        where: { slug },
      });
      console.log(`  Deleted obsolete category: ${slug}`);
    } catch {
      // Category doesn't exist, skip
    }
  }

  // Create a map to store created categories by slug
  const categoryMap = new Map<string, string>();

  // First pass: Create Level 1 categories
  for (const cat of categories.filter((c) => c.level === 1)) {
    const created = await prisma.category.upsert({
      where: { slug: cat.slug },
      update: {
        name: cat.name,
        iconName: cat.iconName,
        sortOrder: cat.sortOrder,
      },
      create: {
        name: cat.name,
        slug: cat.slug,
        level: cat.level,
        iconName: cat.iconName,
        sortOrder: cat.sortOrder,
      },
    });
    categoryMap.set(cat.slug, created.id);
    console.log(`  Created L1: ${cat.name}`);
  }

  // Second pass: Create Level 2 categories
  for (const cat of categories.filter((c) => c.level === 2)) {
    const parentId = categoryMap.get(cat.parentSlug!);
    if (!parentId) {
      console.error(`  Parent not found for ${cat.slug}: ${cat.parentSlug}`);
      continue;
    }

    const created = await prisma.category.upsert({
      where: { slug: cat.slug },
      update: {
        name: cat.name,
        parentId,
        iconName: cat.iconName,
        sortOrder: cat.sortOrder,
      },
      create: {
        name: cat.name,
        slug: cat.slug,
        level: cat.level,
        parentId,
        iconName: cat.iconName,
        sortOrder: cat.sortOrder,
      },
    });
    categoryMap.set(cat.slug, created.id);
    console.log(`  Created L2: ${cat.name} (parent: ${cat.parentSlug})`);
  }

  // Third pass: Create Level 3 categories
  for (const cat of categories.filter((c) => c.level === 3)) {
    const parentId = categoryMap.get(cat.parentSlug!);
    if (!parentId) {
      console.error(`  Parent not found for ${cat.slug}: ${cat.parentSlug}`);
      continue;
    }

    const created = await prisma.category.upsert({
      where: { slug: cat.slug },
      update: {
        name: cat.name,
        parentId,
        iconName: cat.iconName,
        sortOrder: cat.sortOrder,
      },
      create: {
        name: cat.name,
        slug: cat.slug,
        level: cat.level,
        parentId,
        iconName: cat.iconName,
        sortOrder: cat.sortOrder,
      },
    });
    categoryMap.set(cat.slug, created.id);
    console.log(`  Created L3: ${cat.name} (parent: ${cat.parentSlug})`);
  }

  console.log(`Seeded ${categories.length} categories.`);
  return categoryMap;
}

export { categories };
