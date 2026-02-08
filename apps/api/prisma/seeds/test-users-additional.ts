import { prisma, pool } from './client';

const TEST_USERS = [
  { phoneNumber: '0780050180', displayName: 'Kasongo Banza' },
  { phoneNumber: '0780050182', displayName: 'Titi Monga' },
  { phoneNumber: '0780050190', displayName: 'Simbi Kayembe' },
];

// Additional product data - mostly clothes for men and women
const ADDITIONAL_PRODUCTS = [
  // User 1 - Kasongo Banza (Women's Clothing)
  [
    {
      title: 'Casual Linen Jumpsuit',
      description: 'Comfortable beige linen jumpsuit with belt. Perfect for warm weather. Size M, adjustable waist.',
      price: 125000,
      category: 'DRESSES',
      condition: 'LIKE_NEW',
      size: 'M',
      brand: 'Massimo Dutti',
      color: 'Beige',
      location: 'Kampala, Nakawa',
    },
    {
      title: 'Men\'s Polo Shirt - Navy',
      description: 'Classic fit polo shirt, 100% cotton. Size L. Great for casual or semi-formal occasions.',
      price: 55000,
      category: 'TOPS',
      condition: 'NEW',
      size: 'L',
      brand: 'Lacoste',
      color: 'Navy Blue',
      location: 'Kampala, Nakawa',
    },
    {
      title: 'Flowy Midi Skirt',
      description: 'Beautiful pleated midi skirt in forest green. Elastic waistband fits sizes 10-14.',
      price: 78000,
      category: 'BOTTOMS',
      condition: 'GOOD',
      size: 'M',
      brand: 'Zara',
      color: 'Green',
      location: 'Kampala, Nakawa',
    },
    {
      title: 'Men\'s Chino Pants - Khaki',
      description: 'Slim fit chino trousers, waist 32, length 32. Barely worn, perfect condition.',
      price: 65000,
      category: 'BOTTOMS',
      condition: 'LIKE_NEW',
      size: '32',
      brand: 'H&M',
      color: 'Khaki',
      location: 'Kampala, Nakawa',
    },
  ],
  // User 2 - Titi Monga (Mixed Clothing)
  [
    {
      title: 'Ankara Print Blazer - Unisex',
      description: 'Stunning African print blazer, can be worn by men or women. Size M. Custom tailored.',
      price: 180000,
      category: 'TOPS',
      condition: 'NEW',
      size: 'M',
      color: 'Multicolor',
      location: 'Kampala, Makindye',
    },
    {
      title: 'Women\'s Bodycon Dress',
      description: 'Elegant black bodycon dress, knee length. Perfect for parties. Size S, stretchy material.',
      price: 89000,
      category: 'DRESSES',
      condition: 'GOOD',
      size: 'S',
      brand: 'Fashion Nova',
      color: 'Black',
      location: 'Kampala, Makindye',
    },
    {
      title: 'Men\'s Denim Shirt',
      description: 'Light wash denim button-up shirt. Size XL. Great for layering or wearing alone.',
      price: 72000,
      category: 'TOPS',
      condition: 'LIKE_NEW',
      size: 'XL',
      brand: 'Pull & Bear',
      color: 'Blue',
      location: 'Kampala, Makindye',
    },
    {
      title: 'Wide Leg Palazzo Pants',
      description: 'Flowy black palazzo pants with high waist. Size L. Very comfortable and stylish.',
      price: 68000,
      category: 'BOTTOMS',
      condition: 'GOOD',
      size: 'L',
      brand: 'Mango',
      color: 'Black',
      location: 'Kampala, Makindye',
    },
  ],
  // User 3 - Simbi Kayembe (Mixed Clothing)
  [
    {
      title: 'Men\'s Formal Suit Jacket',
      description: 'Charcoal grey blazer, single breasted. Size 40R. Worn once to a wedding.',
      price: 220000,
      category: 'TOPS',
      condition: 'LIKE_NEW',
      size: '40',
      brand: 'Hugo Boss',
      color: 'Grey',
      location: 'Kampala, Kawempe',
    },
    {
      title: 'Off-Shoulder Blouse',
      description: 'Romantic white off-shoulder top with ruffles. Size M. Perfect for date nights.',
      price: 48000,
      category: 'TOPS',
      condition: 'NEW',
      size: 'M',
      brand: 'River Island',
      color: 'White',
      location: 'Kampala, Kawempe',
    },
    {
      title: 'Men\'s Jogger Pants',
      description: 'Comfortable black joggers with zip pockets. Size M. Great for gym or casual wear.',
      price: 45000,
      category: 'BOTTOMS',
      condition: 'GOOD',
      size: 'M',
      brand: 'Nike',
      color: 'Black',
      location: 'Kampala, Kawempe',
    },
    {
      title: 'Wrap Maxi Dress - Floral',
      description: 'Gorgeous wrap dress with tropical print. Size L. Adjustable fit, very flattering.',
      price: 95000,
      category: 'DRESSES',
      condition: 'LIKE_NEW',
      size: 'L',
      brand: 'ASOS',
      color: 'Multicolor',
      location: 'Kampala, Kawempe',
    },
  ],
];

// Sample placeholder images
const SAMPLE_IMAGES = [
  'https://res.cloudinary.com/demo/image/upload/v1/samples/ecommerce/leather-bag-gray',
  'https://res.cloudinary.com/demo/image/upload/v1/samples/ecommerce/shoes',
  'https://res.cloudinary.com/demo/image/upload/v1/samples/ecommerce/accessories-bag',
];

async function main() {
  console.log('========================================');
  console.log('Adding additional products to test users...');
  console.log('========================================\n');

  for (let i = 0; i < TEST_USERS.length; i++) {
    const userData = TEST_USERS[i];
    const products = ADDITIONAL_PRODUCTS[i];

    // Find existing user
    const user = await prisma.user.findUnique({
      where: { phoneNumber: userData.phoneNumber },
    });

    if (!user) {
      console.log(`User ${userData.displayName} not found, skipping...`);
      continue;
    }

    console.log(`Adding products for: ${userData.displayName}`);

    // Create listings for this user
    for (const product of products) {
      const existingListing = await prisma.listing.findFirst({
        where: {
          sellerId: user.id,
          title: product.title,
        },
      });

      if (existingListing) {
        console.log(`  - Listing "${product.title}" already exists`);
        continue;
      }

      await prisma.listing.create({
        data: {
          sellerId: user.id,
          title: product.title,
          description: product.description,
          price: product.price,
          category: product.category as any,
          condition: product.condition as any,
          size: product.size,
          brand: product.brand,
          color: product.color,
          location: product.location,
          status: 'ACTIVE',
          imageUrls: SAMPLE_IMAGES,
        },
      });
      console.log(`  + Created listing: ${product.title}`);
    }

    console.log('');
  }

  console.log('========================================');
  console.log('Additional products created!');
  console.log('========================================');
}

main()
  .catch((e) => {
    console.error('Failed to create additional products:', e);
    process.exit(1);
  })
  .finally(async () => {
    await prisma.$disconnect();
    await pool.end();
  });
