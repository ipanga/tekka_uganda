import { prisma, pool } from './client';
import { seedCategories } from './categories';
import { seedAttributes, seedCategoryAttributeMappings } from './attributes';
import { seedLocations } from './locations';

async function main() {
  console.log('========================================');
  console.log('Starting database seed...');
  console.log('========================================\n');

  try {
    // 1. Seed locations (cities and divisions)
    await seedLocations();
    console.log('');

    // 2. Seed categories (hierarchical)
    const categoryMap = await seedCategories();
    console.log('');

    // 3. Seed attributes (definitions and values)
    const attributeMap = await seedAttributes();
    console.log('');

    // 4. Seed category-attribute mappings
    await seedCategoryAttributeMappings(categoryMap, attributeMap);
    console.log('');

    console.log('========================================');
    console.log('Database seed completed successfully!');
    console.log('========================================');
  } catch (error) {
    console.error('Seed failed:', error);
    throw error;
  }
}

main()
  .catch((e) => {
    console.error(e);
    process.exit(1);
  })
  .finally(async () => {
    await prisma.$disconnect();
    await pool.end();
  });
