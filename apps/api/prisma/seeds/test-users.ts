import { prisma, pool } from './client';

const TEST_USERS = [
  { phoneNumber: '0780050180', displayName: 'Kasongo Banza' },
  { phoneNumber: '0780050182', displayName: 'Titi Monga' },
  { phoneNumber: '0780050190', displayName: 'Simbi Kayembe' },
];

// Sample product data for fashion marketplace
const SAMPLE_PRODUCTS = [
  // User 1 - Kasongo Banza (Women's Fashion)
  [
    {
      title: 'Elegant Red Evening Dress',
      description: 'Beautiful red satin evening dress, perfect for special occasions. Worn once at a wedding. Size M, fits UK 10-12.',
      price: 150000,
      category: 'DRESSES',
      condition: 'LIKE_NEW',
      size: 'M',
      brand: 'Zara',
      color: 'Red',
      location: 'Kampala, Nakawa',
    },
    {
      title: 'Vintage Denim Jacket',
      description: 'Classic blue denim jacket with brass buttons. Great for layering. Size S.',
      price: 85000,
      category: 'TOPS',
      condition: 'GOOD',
      size: 'S',
      brand: 'Levi\'s',
      color: 'Blue',
      location: 'Kampala, Nakawa',
    },
    {
      title: 'Black Leather Handbag',
      description: 'Genuine leather crossbody bag with gold hardware. Multiple compartments. Barely used.',
      price: 200000,
      category: 'BAGS',
      condition: 'LIKE_NEW',
      brand: 'Guess',
      color: 'Black',
      location: 'Kampala, Nakawa',
    },
    {
      title: 'Traditional Kitenge Skirt',
      description: 'Handmade kitenge pencil skirt with beautiful African print. Size L, waist 32 inches.',
      price: 65000,
      category: 'TRADITIONAL_WEAR',
      condition: 'NEW',
      size: 'L',
      color: 'Multicolor',
      location: 'Kampala, Nakawa',
    },
    {
      title: 'White Nike Air Force Sneakers',
      description: 'Classic white Nike Air Force 1 sneakers. Size 38 (UK 5). Minor scuffs, overall great condition.',
      price: 120000,
      category: 'SHOES',
      condition: 'GOOD',
      size: '38',
      brand: 'Nike',
      color: 'White',
      location: 'Kampala, Nakawa',
    },
  ],
  // User 2 - Titi Monga (Mixed Fashion)
  [
    {
      title: 'Floral Summer Maxi Dress',
      description: 'Light and flowy maxi dress with beautiful floral print. Perfect for beach or casual outings. Size S.',
      price: 95000,
      category: 'DRESSES',
      condition: 'GOOD',
      size: 'S',
      brand: 'H&M',
      color: 'Pink',
      location: 'Kampala, Makindye',
    },
    {
      title: 'High-Waisted Black Jeans',
      description: 'Skinny fit high-waisted jeans. Very comfortable stretch material. Size 28.',
      price: 75000,
      category: 'BOTTOMS',
      condition: 'LIKE_NEW',
      size: '28',
      brand: 'Topshop',
      color: 'Black',
      location: 'Kampala, Makindye',
    },
    {
      title: 'Gold Statement Necklace',
      description: 'Beautiful chunky gold necklace. Perfect for special occasions. Never worn, still has tags.',
      price: 45000,
      category: 'ACCESSORIES',
      condition: 'NEW',
      color: 'Gold',
      location: 'Kampala, Makindye',
    },
    {
      title: 'Brown Ankle Boots',
      description: 'Suede ankle boots with 3-inch block heel. Size 39. Very comfortable for all-day wear.',
      price: 110000,
      category: 'SHOES',
      condition: 'GOOD',
      size: '39',
      brand: 'Aldo',
      color: 'Brown',
      location: 'Kampala, Makindye',
    },
    {
      title: 'Silk Blouse - Navy Blue',
      description: 'Elegant silk blouse perfect for office or evening wear. Size M. Dry clean only.',
      price: 80000,
      category: 'TOPS',
      condition: 'LIKE_NEW',
      size: 'M',
      brand: 'Mango',
      color: 'Navy Blue',
      location: 'Kampala, Makindye',
    },
  ],
  // User 3 - Simbi Kayembe (Trendy Fashion)
  [
    {
      title: 'African Print Gomesi',
      description: 'Traditional Buganda gomesi with modern twist. Custom made, fits size 12-14. Includes matching sash.',
      price: 250000,
      category: 'TRADITIONAL_WEAR',
      condition: 'NEW',
      size: 'L',
      color: 'Purple',
      location: 'Kampala, Kawempe',
    },
    {
      title: 'Designer Sunglasses',
      description: 'Authentic Ray-Ban Wayfarer sunglasses. Classic tortoise shell frame. Comes with original case.',
      price: 180000,
      category: 'ACCESSORIES',
      condition: 'LIKE_NEW',
      brand: 'Ray-Ban',
      color: 'Brown',
      location: 'Kampala, Kawempe',
    },
    {
      title: 'Mini Crossbody Bag',
      description: 'Cute mini bag perfect for going out. Chain strap can be worn crossbody or as shoulder bag.',
      price: 55000,
      category: 'BAGS',
      condition: 'GOOD',
      brand: 'Forever 21',
      color: 'Pink',
      location: 'Kampala, Kawempe',
    },
    {
      title: 'Crop Top Bundle - 3 pieces',
      description: 'Set of 3 basic crop tops in black, white, and gray. Size XS/S. Great for mixing and matching.',
      price: 40000,
      category: 'TOPS',
      condition: 'GOOD',
      size: 'S',
      color: 'Multicolor',
      location: 'Kampala, Kawempe',
    },
    {
      title: 'Platform Sandals',
      description: 'Trendy platform sandals with ankle strap. Size 37. Perfect for summer.',
      price: 70000,
      category: 'SHOES',
      condition: 'LIKE_NEW',
      size: '37',
      brand: 'Steve Madden',
      color: 'Tan',
      location: 'Kampala, Kawempe',
    },
  ],
];

// Sample placeholder images (using placeholder URLs)
const SAMPLE_IMAGES = [
  'https://res.cloudinary.com/demo/image/upload/v1/samples/ecommerce/leather-bag-gray',
  'https://res.cloudinary.com/demo/image/upload/v1/samples/ecommerce/shoes',
  'https://res.cloudinary.com/demo/image/upload/v1/samples/ecommerce/accessories-bag',
];

async function main() {
  console.log('========================================');
  console.log('Creating test users and listings...');
  console.log('========================================\n');

  for (let i = 0; i < TEST_USERS.length; i++) {
    const userData = TEST_USERS[i];
    const products = SAMPLE_PRODUCTS[i];

    // Check if user already exists
    let user = await prisma.user.findUnique({
      where: { phoneNumber: userData.phoneNumber },
    });

    if (user) {
      console.log(`User ${userData.displayName} already exists (ID: ${user.id})`);
    } else {
      // Create user
      user = await prisma.user.create({
        data: {
          phoneNumber: userData.phoneNumber,
          displayName: userData.displayName,
          isPhoneVerified: true,
          isOnboardingComplete: true,
        },
      });
      console.log(`Created user: ${userData.displayName} (ID: ${user.id})`);
    }

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
  console.log('Test data creation completed!');
  console.log('========================================');
}

main()
  .catch((e) => {
    console.error('Failed to create test data:', e);
    process.exit(1);
  })
  .finally(async () => {
    await prisma.$disconnect();
    await pool.end();
  });
