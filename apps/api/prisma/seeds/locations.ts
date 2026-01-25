import { prisma } from './client';

interface LocationSeed {
  city: string;
  divisions: string[];
}

// ============================================
// LOCATION DATA - Uganda (Kampala & Entebbe)
// ============================================

const locations: LocationSeed[] = [
  {
    city: 'Kampala',
    divisions: [
      'Kampala Central',
      'Kawempe',
      'Makindye',
      'Nakawa',
      'Rubaga',
    ],
  },
  {
    city: 'Entebbe',
    divisions: [
      'Entebbe Central',
      'Katabi',
    ],
  },
];

export async function seedLocations() {
  console.log('Seeding locations...');

  for (let cityIndex = 0; cityIndex < locations.length; cityIndex++) {
    const locationData = locations[cityIndex];

    // Create or update city
    const city = await prisma.city.upsert({
      where: { name: locationData.city },
      update: {
        sortOrder: cityIndex + 1,
      },
      create: {
        name: locationData.city,
        sortOrder: cityIndex + 1,
        isActive: true,
      },
    });

    console.log(`  Created city: ${city.name}`);

    // Delete all existing divisions for this city that are not in the new list
    // This ensures we only keep the authoritative divisions
    const validDivisionNames = locationData.divisions;
    await prisma.division.deleteMany({
      where: {
        cityId: city.id,
        name: {
          notIn: validDivisionNames,
        },
      },
    });
    console.log(`  Cleaned up obsolete divisions for ${city.name}`);

    // Create divisions for this city
    for (let divIndex = 0; divIndex < locationData.divisions.length; divIndex++) {
      const divisionName = locationData.divisions[divIndex];

      await prisma.division.upsert({
        where: {
          cityId_name: {
            cityId: city.id,
            name: divisionName,
          },
        },
        update: {
          sortOrder: divIndex + 1,
        },
        create: {
          cityId: city.id,
          name: divisionName,
          sortOrder: divIndex + 1,
          isActive: true,
        },
      });
    }

    console.log(`    -> ${locationData.divisions.length} divisions`);
  }

  const totalDivisions = locations.reduce((sum, loc) => sum + loc.divisions.length, 0);
  console.log(`Seeded ${locations.length} cities with ${totalDivisions} divisions.`);
}

export { locations };
