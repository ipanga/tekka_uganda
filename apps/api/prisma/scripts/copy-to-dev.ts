/**
 * Script to copy data from production to development database
 * and create an admin user for development.
 *
 * Usage:
 *   PROD_DATABASE_URL="postgresql://..." DEV_DATABASE_URL="postgresql://..." npx ts-node prisma/scripts/copy-to-dev.ts
 *
 * Or set these in your .env file and run:
 *   npx ts-node prisma/scripts/copy-to-dev.ts
 */
import { PrismaClient } from '@prisma/client';
import * as bcrypt from 'bcrypt';

const PROD_DATABASE_URL = process.env.PROD_DATABASE_URL;
const DEV_DATABASE_URL = process.env.DEV_DATABASE_URL;

if (!PROD_DATABASE_URL || !DEV_DATABASE_URL) {
  console.error('Error: PROD_DATABASE_URL and DEV_DATABASE_URL environment variables are required.');
  console.error('Set them in your .env file or pass them directly:');
  console.error('  PROD_DATABASE_URL="postgresql://..." DEV_DATABASE_URL="postgresql://..." npx ts-node prisma/scripts/copy-to-dev.ts');
  process.exit(1);
}

const prodClient = new PrismaClient({
  datasources: { db: { url: PROD_DATABASE_URL } },
});

const devClient = new PrismaClient({
  datasources: { db: { url: DEV_DATABASE_URL } },
});

async function copyData() {
  console.log('Starting data copy from production to development...\n');

  try {
    // 1. Copy Cities
    console.log('Copying cities...');
    const cities = await prodClient.city.findMany();
    for (const city of cities) {
      await devClient.city.upsert({
        where: { id: city.id },
        update: city,
        create: city,
      });
    }
    console.log(`  ✓ Copied ${cities.length} cities`);

    // 2. Copy Divisions
    console.log('Copying divisions...');
    const divisions = await prodClient.division.findMany();
    for (const division of divisions) {
      await devClient.division.upsert({
        where: { id: division.id },
        update: division,
        create: division,
      });
    }
    console.log(`  ✓ Copied ${divisions.length} divisions`);

    // 3. Copy Categories
    console.log('Copying categories...');
    const categories = await prodClient.category.findMany({
      orderBy: { level: 'asc' }, // Parents first
    });
    for (const category of categories) {
      await devClient.category.upsert({
        where: { id: category.id },
        update: category,
        create: category,
      });
    }
    console.log(`  ✓ Copied ${categories.length} categories`);

    // 4. Copy Attribute Definitions
    console.log('Copying attribute definitions...');
    const attributeDefs = await prodClient.attributeDefinition.findMany();
    for (const attr of attributeDefs) {
      await devClient.attributeDefinition.upsert({
        where: { id: attr.id },
        update: attr,
        create: attr,
      });
    }
    console.log(`  ✓ Copied ${attributeDefs.length} attribute definitions`);

    // 5. Copy Attribute Values
    console.log('Copying attribute values...');
    const attributeValues = await prodClient.attributeValue.findMany();
    for (const val of attributeValues) {
      await devClient.attributeValue.upsert({
        where: { id: val.id },
        update: val,
        create: val,
      });
    }
    console.log(`  ✓ Copied ${attributeValues.length} attribute values`);

    // 6. Copy Category Attributes
    console.log('Copying category attributes...');
    const categoryAttrs = await prodClient.categoryAttribute.findMany();
    for (const catAttr of categoryAttrs) {
      await devClient.categoryAttribute.upsert({
        where: { id: catAttr.id },
        update: catAttr,
        create: catAttr,
      });
    }
    console.log(`  ✓ Copied ${categoryAttrs.length} category attributes`);

    // 7. Copy Safe Locations
    console.log('Copying safe locations...');
    const safeLocations = await prodClient.safeLocation.findMany();
    for (const loc of safeLocations) {
      await devClient.safeLocation.upsert({
        where: { id: loc.id },
        update: loc,
        create: loc,
      });
    }
    console.log(`  ✓ Copied ${safeLocations.length} safe locations`);

    // 8. Copy Users (excluding sensitive data like passwords)
    console.log('Copying users...');
    const users = await prodClient.user.findMany();
    for (const user of users) {
      await devClient.user.upsert({
        where: { id: user.id },
        update: user,
        create: user,
      });
    }
    console.log(`  ✓ Copied ${users.length} users`);

    // 9. Copy Listings
    console.log('Copying listings...');
    const listings = await prodClient.listing.findMany();
    for (const listing of listings) {
      await devClient.listing.upsert({
        where: { id: listing.id },
        update: listing,
        create: listing,
      });
    }
    console.log(`  ✓ Copied ${listings.length} listings`);

    console.log('\n✅ Data copy completed successfully!');

  } catch (error) {
    console.error('Error copying data:', error);
    throw error;
  }
}

async function createAdminUser() {
  console.log('\nCreating admin user for development...');

  const adminEmail = 'admin@tekka.ug';
  const adminPassword = 'admin123';
  const adminPhone = '+256700000001'; // Placeholder admin phone

  try {
    // Hash the password
    const passwordHash = await bcrypt.hash(adminPassword, 10);

    // Check if admin already exists
    const existingAdmin = await devClient.user.findFirst({
      where: {
        OR: [
          { email: adminEmail },
          { phoneNumber: adminPhone },
        ],
      },
    });

    if (existingAdmin) {
      // Update existing admin
      await devClient.user.update({
        where: { id: existingAdmin.id },
        data: {
          email: adminEmail,
          passwordHash: passwordHash,
          role: 'ADMIN',
          displayName: 'Admin',
          isPhoneVerified: true,
          isEmailVerified: true,
          isOnboardingComplete: true,
        },
      });
      console.log('  ✓ Updated existing admin user');
    } else {
      // Create new admin
      await devClient.user.create({
        data: {
          phoneNumber: adminPhone,
          email: adminEmail,
          passwordHash: passwordHash,
          displayName: 'Admin',
          role: 'ADMIN',
          isPhoneVerified: true,
          isEmailVerified: true,
          isOnboardingComplete: true,
        },
      });
      console.log('  ✓ Created new admin user');
    }

    console.log(`\n✅ Admin user ready:`);
    console.log(`   Email: ${adminEmail}`);
    console.log(`   Password: ${adminPassword}`);
    console.log(`   Phone: ${adminPhone}`);

  } catch (error) {
    console.error('Error creating admin user:', error);
    throw error;
  }
}

async function main() {
  try {
    // First, ensure dev database schema is up to date
    console.log('Note: Make sure to run "npx prisma db push" on dev database first.\n');

    await copyData();
    await createAdminUser();

    console.log('\n🎉 All done! Development database is ready.');

  } catch (error) {
    console.error('Script failed:', error);
    process.exit(1);
  } finally {
    await prodClient.$disconnect();
    await devClient.$disconnect();
  }
}

main();
