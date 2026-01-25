/**
 * Vinted-style Category and Attribute Seed Script for Tekka
 *
 * This script seeds:
 * - 5 Main Categories (Women, Men, Kids, Home, Electronics)
 * - Subcategories and Product Types (3-level hierarchy)
 * - Attribute Definitions (Size, Brand, Color, Material, Condition)
 * - Attribute Values (EU shoe sizes, clothing sizes, colors, etc.)
 * - Category-Attribute links
 */

import { PrismaClient, AttributeType } from '@prisma/client';
import { PrismaPg } from '@prisma/adapter-pg';
import { Pool } from 'pg';

// Initialize Prisma with pg adapter
const pool = new Pool({
  connectionString: process.env.DATABASE_URL,
});
const adapter = new PrismaPg(pool);
const prisma = new PrismaClient({ adapter });

// ============================================
// CATEGORY DEFINITIONS (Vinted-style)
// ============================================

interface CategoryDef {
  name: string;
  slug: string;
  iconName?: string;
  children?: CategoryDef[];
}

const categoryHierarchy: CategoryDef[] = [
  {
    name: 'Women',
    slug: 'women',
    iconName: 'woman',
    children: [
      {
        name: 'Clothing',
        slug: 'women-clothing',
        children: [
          { name: 'Dresses', slug: 'women-dresses' },
          { name: 'Tops & T-shirts', slug: 'women-tops' },
          { name: 'Blouses & Shirts', slug: 'women-blouses' },
          { name: 'Sweaters & Cardigans', slug: 'women-sweaters' },
          { name: 'Jackets & Coats', slug: 'women-jackets' },
          { name: 'Jeans', slug: 'women-jeans' },
          { name: 'Trousers', slug: 'women-trousers' },
          { name: 'Shorts', slug: 'women-shorts' },
          { name: 'Skirts', slug: 'women-skirts' },
          { name: 'Suits & Blazers', slug: 'women-suits' },
          { name: 'Jumpsuits & Playsuits', slug: 'women-jumpsuits' },
          { name: 'Activewear', slug: 'women-activewear' },
          { name: 'Swimwear', slug: 'women-swimwear' },
          { name: 'Lingerie & Nightwear', slug: 'women-lingerie' },
          { name: 'Traditional Wear', slug: 'women-traditional' },
        ],
      },
      {
        name: 'Shoes',
        slug: 'women-shoes',
        children: [
          { name: 'Heels', slug: 'women-heels' },
          { name: 'Flats', slug: 'women-flats' },
          { name: 'Sandals', slug: 'women-sandals' },
          { name: 'Boots', slug: 'women-boots' },
          { name: 'Sneakers', slug: 'women-sneakers' },
          { name: 'Loafers & Slip-ons', slug: 'women-loafers' },
          { name: 'Wedges', slug: 'women-wedges' },
          { name: 'Sports Shoes', slug: 'women-sports-shoes' },
        ],
      },
      {
        name: 'Bags',
        slug: 'women-bags',
        children: [
          { name: 'Handbags', slug: 'women-handbags' },
          { name: 'Shoulder Bags', slug: 'women-shoulder-bags' },
          { name: 'Crossbody Bags', slug: 'women-crossbody' },
          { name: 'Tote Bags', slug: 'women-totes' },
          { name: 'Clutches', slug: 'women-clutches' },
          { name: 'Backpacks', slug: 'women-backpacks' },
          { name: 'Wallets & Purses', slug: 'women-wallets' },
        ],
      },
      {
        name: 'Accessories',
        slug: 'women-accessories',
        children: [
          { name: 'Jewelry', slug: 'women-jewelry' },
          { name: 'Watches', slug: 'women-watches' },
          { name: 'Sunglasses', slug: 'women-sunglasses' },
          { name: 'Belts', slug: 'women-belts' },
          { name: 'Scarves & Wraps', slug: 'women-scarves' },
          { name: 'Hats & Caps', slug: 'women-hats' },
          { name: 'Hair Accessories', slug: 'women-hair-accessories' },
        ],
      },
    ],
  },
  {
    name: 'Men',
    slug: 'men',
    iconName: 'man',
    children: [
      {
        name: 'Clothing',
        slug: 'men-clothing',
        children: [
          { name: 'T-shirts & Vests', slug: 'men-tshirts' },
          { name: 'Shirts', slug: 'men-shirts' },
          { name: 'Sweaters & Hoodies', slug: 'men-sweaters' },
          { name: 'Jackets & Coats', slug: 'men-jackets' },
          { name: 'Jeans', slug: 'men-jeans' },
          { name: 'Trousers', slug: 'men-trousers' },
          { name: 'Shorts', slug: 'men-shorts' },
          { name: 'Suits & Blazers', slug: 'men-suits' },
          { name: 'Activewear', slug: 'men-activewear' },
          { name: 'Swimwear', slug: 'men-swimwear' },
          { name: 'Underwear & Socks', slug: 'men-underwear' },
          { name: 'Traditional Wear', slug: 'men-traditional' },
        ],
      },
      {
        name: 'Shoes',
        slug: 'men-shoes',
        children: [
          { name: 'Sneakers', slug: 'men-sneakers' },
          { name: 'Formal Shoes', slug: 'men-formal-shoes' },
          { name: 'Boots', slug: 'men-boots' },
          { name: 'Sandals & Slippers', slug: 'men-sandals' },
          { name: 'Loafers', slug: 'men-loafers' },
          { name: 'Sports Shoes', slug: 'men-sports-shoes' },
        ],
      },
      {
        name: 'Bags',
        slug: 'men-bags',
        children: [
          { name: 'Backpacks', slug: 'men-backpacks' },
          { name: 'Messenger Bags', slug: 'men-messenger' },
          { name: 'Briefcases', slug: 'men-briefcases' },
          { name: 'Wallets & Card Holders', slug: 'men-wallets' },
          { name: 'Travel Bags', slug: 'men-travel-bags' },
        ],
      },
      {
        name: 'Accessories',
        slug: 'men-accessories',
        children: [
          { name: 'Watches', slug: 'men-watches' },
          { name: 'Sunglasses', slug: 'men-sunglasses' },
          { name: 'Belts', slug: 'men-belts' },
          { name: 'Ties & Bow Ties', slug: 'men-ties' },
          { name: 'Hats & Caps', slug: 'men-hats' },
          { name: 'Cufflinks & Tie Clips', slug: 'men-cufflinks' },
        ],
      },
    ],
  },
  {
    name: 'Kids',
    slug: 'kids',
    iconName: 'child',
    children: [
      {
        name: 'Girls',
        slug: 'kids-girls',
        children: [
          { name: 'Dresses', slug: 'kids-girls-dresses' },
          { name: 'Tops & T-shirts', slug: 'kids-girls-tops' },
          { name: 'Trousers & Jeans', slug: 'kids-girls-trousers' },
          { name: 'Skirts', slug: 'kids-girls-skirts' },
          { name: 'Jackets & Coats', slug: 'kids-girls-jackets' },
          { name: 'Shoes', slug: 'kids-girls-shoes' },
          { name: 'School Uniforms', slug: 'kids-girls-uniforms' },
        ],
      },
      {
        name: 'Boys',
        slug: 'kids-boys',
        children: [
          { name: 'T-shirts & Shirts', slug: 'kids-boys-tshirts' },
          { name: 'Trousers & Jeans', slug: 'kids-boys-trousers' },
          { name: 'Shorts', slug: 'kids-boys-shorts' },
          { name: 'Jackets & Coats', slug: 'kids-boys-jackets' },
          { name: 'Shoes', slug: 'kids-boys-shoes' },
          { name: 'School Uniforms', slug: 'kids-boys-uniforms' },
        ],
      },
      {
        name: 'Baby (0-2 years)',
        slug: 'kids-baby',
        children: [
          { name: 'Bodysuits & Rompers', slug: 'kids-baby-bodysuits' },
          { name: 'Sets', slug: 'kids-baby-sets' },
          { name: 'Sleepwear', slug: 'kids-baby-sleepwear' },
          { name: 'Outerwear', slug: 'kids-baby-outerwear' },
          { name: 'Shoes', slug: 'kids-baby-shoes' },
          { name: 'Accessories', slug: 'kids-baby-accessories' },
        ],
      },
      {
        name: 'Toys & Games',
        slug: 'kids-toys',
        children: [
          { name: 'Soft Toys', slug: 'kids-soft-toys' },
          { name: 'Educational Toys', slug: 'kids-educational' },
          { name: 'Outdoor Toys', slug: 'kids-outdoor-toys' },
          { name: 'Board Games', slug: 'kids-board-games' },
          { name: 'Building Blocks', slug: 'kids-building' },
        ],
      },
    ],
  },
  {
    name: 'Home',
    slug: 'home',
    iconName: 'home',
    children: [
      {
        name: 'Furniture',
        slug: 'home-furniture',
        children: [
          { name: 'Sofas & Armchairs', slug: 'home-sofas' },
          { name: 'Tables', slug: 'home-tables' },
          { name: 'Chairs', slug: 'home-chairs' },
          { name: 'Beds & Mattresses', slug: 'home-beds' },
          { name: 'Wardrobes & Storage', slug: 'home-wardrobes' },
          { name: 'Shelving', slug: 'home-shelving' },
        ],
      },
      {
        name: 'Home Décor',
        slug: 'home-decor',
        children: [
          { name: 'Mirrors', slug: 'home-mirrors' },
          { name: 'Vases', slug: 'home-vases' },
          { name: 'Candles & Holders', slug: 'home-candles' },
          { name: 'Picture Frames', slug: 'home-frames' },
          { name: 'Wall Art', slug: 'home-wall-art' },
          { name: 'Rugs & Carpets', slug: 'home-rugs' },
        ],
      },
      {
        name: 'Kitchen & Dining',
        slug: 'home-kitchen',
        children: [
          { name: 'Cookware', slug: 'home-cookware' },
          { name: 'Tableware', slug: 'home-tableware' },
          { name: 'Glassware', slug: 'home-glassware' },
          { name: 'Cutlery', slug: 'home-cutlery' },
          { name: 'Small Appliances', slug: 'home-small-appliances' },
          { name: 'Storage Containers', slug: 'home-storage' },
        ],
      },
      {
        name: 'Bedding & Bath',
        slug: 'home-bedding',
        children: [
          { name: 'Bed Linen', slug: 'home-bed-linen' },
          { name: 'Pillows & Cushions', slug: 'home-pillows' },
          { name: 'Blankets & Throws', slug: 'home-blankets' },
          { name: 'Towels', slug: 'home-towels' },
          { name: 'Bathroom Accessories', slug: 'home-bathroom' },
        ],
      },
      {
        name: 'Garden & Outdoor',
        slug: 'home-garden',
        children: [
          { name: 'Garden Furniture', slug: 'home-garden-furniture' },
          { name: 'Plants & Pots', slug: 'home-plants' },
          { name: 'Garden Tools', slug: 'home-garden-tools' },
          { name: 'BBQ & Outdoor Cooking', slug: 'home-bbq' },
        ],
      },
    ],
  },
  {
    name: 'Electronics',
    slug: 'electronics',
    iconName: 'devices',
    children: [
      {
        name: 'Phones & Tablets',
        slug: 'electronics-phones',
        children: [
          { name: 'Smartphones', slug: 'electronics-smartphones' },
          { name: 'Tablets', slug: 'electronics-tablets' },
          { name: 'Phone Cases', slug: 'electronics-phone-cases' },
          { name: 'Chargers & Cables', slug: 'electronics-chargers' },
          { name: 'Screen Protectors', slug: 'electronics-screen-protectors' },
        ],
      },
      {
        name: 'Computers',
        slug: 'electronics-computers',
        children: [
          { name: 'Laptops', slug: 'electronics-laptops' },
          { name: 'Desktop Computers', slug: 'electronics-desktops' },
          { name: 'Monitors', slug: 'electronics-monitors' },
          { name: 'Keyboards & Mice', slug: 'electronics-peripherals' },
          { name: 'Computer Accessories', slug: 'electronics-computer-accessories' },
        ],
      },
      {
        name: 'Audio',
        slug: 'electronics-audio',
        children: [
          { name: 'Headphones', slug: 'electronics-headphones' },
          { name: 'Earbuds', slug: 'electronics-earbuds' },
          { name: 'Speakers', slug: 'electronics-speakers' },
          { name: 'Home Audio', slug: 'electronics-home-audio' },
        ],
      },
      {
        name: 'Gaming',
        slug: 'electronics-gaming',
        children: [
          { name: 'Consoles', slug: 'electronics-consoles' },
          { name: 'Video Games', slug: 'electronics-games' },
          { name: 'Gaming Accessories', slug: 'electronics-gaming-accessories' },
          { name: 'Controllers', slug: 'electronics-controllers' },
        ],
      },
      {
        name: 'Cameras & Photo',
        slug: 'electronics-cameras',
        children: [
          { name: 'Digital Cameras', slug: 'electronics-digital-cameras' },
          { name: 'Camera Lenses', slug: 'electronics-lenses' },
          { name: 'Camera Accessories', slug: 'electronics-camera-accessories' },
          { name: 'Tripods & Stands', slug: 'electronics-tripods' },
        ],
      },
      {
        name: 'Wearables',
        slug: 'electronics-wearables',
        children: [
          { name: 'Smartwatches', slug: 'electronics-smartwatches' },
          { name: 'Fitness Trackers', slug: 'electronics-fitness-trackers' },
          { name: 'Watch Bands', slug: 'electronics-watch-bands' },
        ],
      },
    ],
  },
];

// ============================================
// ATTRIBUTE DEFINITIONS
// ============================================

interface AttributeDef {
  name: string;
  slug: string;
  type: AttributeType;
  isRequired: boolean;
  values: { value: string; displayValue?: string; sortOrder: number; metadata?: Record<string, string> }[];
}

const attributeDefinitions: AttributeDef[] = [
  // Clothing Size (Women/Men/Kids)
  {
    name: 'Clothing Size',
    slug: 'size-clothing',
    type: 'SINGLE_SELECT',
    isRequired: true,
    values: [
      { value: 'XXS', sortOrder: 1 },
      { value: 'XS', sortOrder: 2 },
      { value: 'S', sortOrder: 3 },
      { value: 'M', sortOrder: 4 },
      { value: 'L', sortOrder: 5 },
      { value: 'XL', sortOrder: 6 },
      { value: 'XXL', sortOrder: 7 },
      { value: '3XL', sortOrder: 8 },
      { value: '4XL', sortOrder: 9 },
      { value: 'One Size', sortOrder: 10 },
    ],
  },
  // Shoe Size (EU)
  {
    name: 'Shoe Size (EU)',
    slug: 'size-shoes-eu',
    type: 'SINGLE_SELECT',
    isRequired: true,
    values: [
      { value: '35', displayValue: 'EU 35', sortOrder: 1 },
      { value: '36', displayValue: 'EU 36', sortOrder: 2 },
      { value: '37', displayValue: 'EU 37', sortOrder: 3 },
      { value: '38', displayValue: 'EU 38', sortOrder: 4 },
      { value: '39', displayValue: 'EU 39', sortOrder: 5 },
      { value: '40', displayValue: 'EU 40', sortOrder: 6 },
      { value: '41', displayValue: 'EU 41', sortOrder: 7 },
      { value: '42', displayValue: 'EU 42', sortOrder: 8 },
      { value: '43', displayValue: 'EU 43', sortOrder: 9 },
      { value: '44', displayValue: 'EU 44', sortOrder: 10 },
      { value: '45', displayValue: 'EU 45', sortOrder: 11 },
      { value: '46', displayValue: 'EU 46', sortOrder: 12 },
      { value: '47', displayValue: 'EU 47', sortOrder: 13 },
    ],
  },
  // Kids Clothing Size (Age-based)
  {
    name: 'Kids Size',
    slug: 'size-kids',
    type: 'SINGLE_SELECT',
    isRequired: true,
    values: [
      { value: '0-3M', displayValue: '0-3 months', sortOrder: 1 },
      { value: '3-6M', displayValue: '3-6 months', sortOrder: 2 },
      { value: '6-9M', displayValue: '6-9 months', sortOrder: 3 },
      { value: '9-12M', displayValue: '9-12 months', sortOrder: 4 },
      { value: '12-18M', displayValue: '12-18 months', sortOrder: 5 },
      { value: '18-24M', displayValue: '18-24 months', sortOrder: 6 },
      { value: '2Y', displayValue: '2 years', sortOrder: 7 },
      { value: '3Y', displayValue: '3 years', sortOrder: 8 },
      { value: '4Y', displayValue: '4 years', sortOrder: 9 },
      { value: '5Y', displayValue: '5 years', sortOrder: 10 },
      { value: '6Y', displayValue: '6 years', sortOrder: 11 },
      { value: '7Y', displayValue: '7 years', sortOrder: 12 },
      { value: '8Y', displayValue: '8 years', sortOrder: 13 },
      { value: '9Y', displayValue: '9 years', sortOrder: 14 },
      { value: '10Y', displayValue: '10 years', sortOrder: 15 },
      { value: '11Y', displayValue: '11 years', sortOrder: 16 },
      { value: '12Y', displayValue: '12 years', sortOrder: 17 },
      { value: '13Y', displayValue: '13 years', sortOrder: 18 },
      { value: '14Y', displayValue: '14 years', sortOrder: 19 },
    ],
  },
  // Kids Shoe Size (EU)
  {
    name: 'Kids Shoe Size (EU)',
    slug: 'size-kids-shoes-eu',
    type: 'SINGLE_SELECT',
    isRequired: true,
    values: [
      { value: '16', displayValue: 'EU 16', sortOrder: 1 },
      { value: '17', displayValue: 'EU 17', sortOrder: 2 },
      { value: '18', displayValue: 'EU 18', sortOrder: 3 },
      { value: '19', displayValue: 'EU 19', sortOrder: 4 },
      { value: '20', displayValue: 'EU 20', sortOrder: 5 },
      { value: '21', displayValue: 'EU 21', sortOrder: 6 },
      { value: '22', displayValue: 'EU 22', sortOrder: 7 },
      { value: '23', displayValue: 'EU 23', sortOrder: 8 },
      { value: '24', displayValue: 'EU 24', sortOrder: 9 },
      { value: '25', displayValue: 'EU 25', sortOrder: 10 },
      { value: '26', displayValue: 'EU 26', sortOrder: 11 },
      { value: '27', displayValue: 'EU 27', sortOrder: 12 },
      { value: '28', displayValue: 'EU 28', sortOrder: 13 },
      { value: '29', displayValue: 'EU 29', sortOrder: 14 },
      { value: '30', displayValue: 'EU 30', sortOrder: 15 },
      { value: '31', displayValue: 'EU 31', sortOrder: 16 },
      { value: '32', displayValue: 'EU 32', sortOrder: 17 },
      { value: '33', displayValue: 'EU 33', sortOrder: 18 },
      { value: '34', displayValue: 'EU 34', sortOrder: 19 },
      { value: '35', displayValue: 'EU 35', sortOrder: 20 },
    ],
  },
  // Color
  {
    name: 'Color',
    slug: 'color',
    type: 'MULTI_SELECT',
    isRequired: false,
    values: [
      { value: 'Black', sortOrder: 1, metadata: { hex: '#000000' } },
      { value: 'White', sortOrder: 2, metadata: { hex: '#FFFFFF' } },
      { value: 'Grey', sortOrder: 3, metadata: { hex: '#808080' } },
      { value: 'Navy', sortOrder: 4, metadata: { hex: '#000080' } },
      { value: 'Blue', sortOrder: 5, metadata: { hex: '#0000FF' } },
      { value: 'Red', sortOrder: 6, metadata: { hex: '#FF0000' } },
      { value: 'Pink', sortOrder: 7, metadata: { hex: '#FFC0CB' } },
      { value: 'Purple', sortOrder: 8, metadata: { hex: '#800080' } },
      { value: 'Green', sortOrder: 9, metadata: { hex: '#008000' } },
      { value: 'Yellow', sortOrder: 10, metadata: { hex: '#FFFF00' } },
      { value: 'Orange', sortOrder: 11, metadata: { hex: '#FFA500' } },
      { value: 'Brown', sortOrder: 12, metadata: { hex: '#8B4513' } },
      { value: 'Beige', sortOrder: 13, metadata: { hex: '#F5F5DC' } },
      { value: 'Gold', sortOrder: 14, metadata: { hex: '#FFD700' } },
      { value: 'Silver', sortOrder: 15, metadata: { hex: '#C0C0C0' } },
      { value: 'Multi', sortOrder: 16 },
    ],
  },
  // Brand (Fashion)
  {
    name: 'Brand',
    slug: 'brand-fashion',
    type: 'SINGLE_SELECT',
    isRequired: false,
    values: [
      { value: 'Adidas', sortOrder: 1 },
      { value: 'Nike', sortOrder: 2 },
      { value: 'Puma', sortOrder: 3 },
      { value: 'Zara', sortOrder: 4 },
      { value: 'H&M', sortOrder: 5 },
      { value: 'Mango', sortOrder: 6 },
      { value: 'Gucci', sortOrder: 7 },
      { value: 'Louis Vuitton', sortOrder: 8 },
      { value: 'Chanel', sortOrder: 9 },
      { value: 'Versace', sortOrder: 10 },
      { value: 'Balenciaga', sortOrder: 11 },
      { value: 'Prada', sortOrder: 12 },
      { value: 'Dior', sortOrder: 13 },
      { value: 'Burberry', sortOrder: 14 },
      { value: 'Ralph Lauren', sortOrder: 15 },
      { value: 'Tommy Hilfiger', sortOrder: 16 },
      { value: 'Calvin Klein', sortOrder: 17 },
      { value: 'Levi\'s', sortOrder: 18 },
      { value: 'New Balance', sortOrder: 19 },
      { value: 'Converse', sortOrder: 20 },
      { value: 'Vans', sortOrder: 21 },
      { value: 'Reebok', sortOrder: 22 },
      { value: 'Under Armour', sortOrder: 23 },
      { value: 'The North Face', sortOrder: 24 },
      { value: 'Michael Kors', sortOrder: 25 },
      { value: 'Coach', sortOrder: 26 },
      { value: 'Other', sortOrder: 100 },
    ],
  },
  // Material
  {
    name: 'Material',
    slug: 'material',
    type: 'SINGLE_SELECT',
    isRequired: false,
    values: [
      { value: 'Cotton', sortOrder: 1 },
      { value: 'Polyester', sortOrder: 2 },
      { value: 'Wool', sortOrder: 3 },
      { value: 'Silk', sortOrder: 4 },
      { value: 'Linen', sortOrder: 5 },
      { value: 'Denim', sortOrder: 6 },
      { value: 'Leather', sortOrder: 7 },
      { value: 'Faux Leather', sortOrder: 8 },
      { value: 'Suede', sortOrder: 9 },
      { value: 'Velvet', sortOrder: 10 },
      { value: 'Cashmere', sortOrder: 11 },
      { value: 'Nylon', sortOrder: 12 },
      { value: 'Spandex', sortOrder: 13 },
      { value: 'Canvas', sortOrder: 14 },
      { value: 'Rubber', sortOrder: 15 },
      { value: 'Mixed', sortOrder: 16 },
    ],
  },
  // Condition
  {
    name: 'Condition',
    slug: 'condition',
    type: 'SINGLE_SELECT',
    isRequired: true,
    values: [
      { value: 'New with tags', displayValue: 'New with tags', sortOrder: 1 },
      { value: 'New without tags', displayValue: 'New without tags', sortOrder: 2 },
      { value: 'Very good', displayValue: 'Very good', sortOrder: 3 },
      { value: 'Good', displayValue: 'Good', sortOrder: 4 },
      { value: 'Satisfactory', displayValue: 'Satisfactory', sortOrder: 5 },
    ],
  },
  // Brand (Phones & Tablets)
  {
    name: 'Phone Brand',
    slug: 'brand-phones',
    type: 'SINGLE_SELECT',
    isRequired: false,
    values: [
      { value: 'Apple', sortOrder: 1 },
      { value: 'Samsung', sortOrder: 2 },
      { value: 'Google', sortOrder: 3 },
      { value: 'Xiaomi', sortOrder: 4 },
      { value: 'Huawei', sortOrder: 5 },
      { value: 'OnePlus', sortOrder: 6 },
      { value: 'Oppo', sortOrder: 7 },
      { value: 'Vivo', sortOrder: 8 },
      { value: 'Infinix', sortOrder: 9 },
      { value: 'Tecno', sortOrder: 10 },
      { value: 'Itel', sortOrder: 11 },
      { value: 'Nokia', sortOrder: 12 },
      { value: 'Motorola', sortOrder: 13 },
      { value: 'Sony', sortOrder: 14 },
      { value: 'Realme', sortOrder: 15 },
      { value: 'Nothing', sortOrder: 16 },
      { value: 'Other', sortOrder: 100 },
    ],
  },
  // Brand (Computers)
  {
    name: 'Computer Brand',
    slug: 'brand-computers',
    type: 'SINGLE_SELECT',
    isRequired: false,
    values: [
      { value: 'Apple', sortOrder: 1 },
      { value: 'Dell', sortOrder: 2 },
      { value: 'HP', sortOrder: 3 },
      { value: 'Lenovo', sortOrder: 4 },
      { value: 'Asus', sortOrder: 5 },
      { value: 'Acer', sortOrder: 6 },
      { value: 'Microsoft', sortOrder: 7 },
      { value: 'MSI', sortOrder: 8 },
      { value: 'Samsung', sortOrder: 9 },
      { value: 'LG', sortOrder: 10 },
      { value: 'Razer', sortOrder: 11 },
      { value: 'Toshiba', sortOrder: 12 },
      { value: 'Huawei', sortOrder: 13 },
      { value: 'Other', sortOrder: 100 },
    ],
  },
  // Brand (Audio)
  {
    name: 'Audio Brand',
    slug: 'brand-audio',
    type: 'SINGLE_SELECT',
    isRequired: false,
    values: [
      { value: 'Apple', sortOrder: 1 },
      { value: 'Sony', sortOrder: 2 },
      { value: 'Bose', sortOrder: 3 },
      { value: 'JBL', sortOrder: 4 },
      { value: 'Beats', sortOrder: 5 },
      { value: 'Sennheiser', sortOrder: 6 },
      { value: 'Samsung', sortOrder: 7 },
      { value: 'Bang & Olufsen', sortOrder: 8 },
      { value: 'Harman Kardon', sortOrder: 9 },
      { value: 'Marshall', sortOrder: 10 },
      { value: 'Audio-Technica', sortOrder: 11 },
      { value: 'Skullcandy', sortOrder: 12 },
      { value: 'Anker', sortOrder: 13 },
      { value: 'Jabra', sortOrder: 14 },
      { value: 'Other', sortOrder: 100 },
    ],
  },
  // Brand (Gaming) - Console brands with model filtering
  {
    name: 'Console Brand',
    slug: 'brand-consoles',
    type: 'SINGLE_SELECT',
    isRequired: false,
    values: [
      { value: 'Sony PlayStation', sortOrder: 1 },
      { value: 'Microsoft Xbox', sortOrder: 2 },
      { value: 'Nintendo', sortOrder: 3 },
      { value: 'Other', sortOrder: 100 },
    ],
  },
  // Console Model - linked to brand via metadata
  {
    name: 'Console Model',
    slug: 'console-model',
    type: 'SINGLE_SELECT',
    isRequired: false,
    values: [
      // Sony PlayStation models
      { value: 'PS3', displayValue: 'PlayStation 3', sortOrder: 1, metadata: { brand: 'Sony PlayStation' } },
      { value: 'PS3-Slim', displayValue: 'PlayStation 3 Slim', sortOrder: 2, metadata: { brand: 'Sony PlayStation' } },
      { value: 'PS3-Super-Slim', displayValue: 'PlayStation 3 Super Slim', sortOrder: 3, metadata: { brand: 'Sony PlayStation' } },
      { value: 'PS4', displayValue: 'PlayStation 4', sortOrder: 4, metadata: { brand: 'Sony PlayStation' } },
      { value: 'PS4-Slim', displayValue: 'PlayStation 4 Slim', sortOrder: 5, metadata: { brand: 'Sony PlayStation' } },
      { value: 'PS4-Pro', displayValue: 'PlayStation 4 Pro', sortOrder: 6, metadata: { brand: 'Sony PlayStation' } },
      { value: 'PS5', displayValue: 'PlayStation 5', sortOrder: 7, metadata: { brand: 'Sony PlayStation' } },
      { value: 'PS5-Digital', displayValue: 'PlayStation 5 Digital Edition', sortOrder: 8, metadata: { brand: 'Sony PlayStation' } },
      { value: 'PS5-Slim', displayValue: 'PlayStation 5 Slim', sortOrder: 9, metadata: { brand: 'Sony PlayStation' } },
      { value: 'PSP', displayValue: 'PlayStation Portable (PSP)', sortOrder: 10, metadata: { brand: 'Sony PlayStation' } },
      { value: 'PS-Vita', displayValue: 'PlayStation Vita', sortOrder: 11, metadata: { brand: 'Sony PlayStation' } },
      // Microsoft Xbox models
      { value: 'Xbox-360', displayValue: 'Xbox 360', sortOrder: 20, metadata: { brand: 'Microsoft Xbox' } },
      { value: 'Xbox-360-S', displayValue: 'Xbox 360 S', sortOrder: 21, metadata: { brand: 'Microsoft Xbox' } },
      { value: 'Xbox-360-E', displayValue: 'Xbox 360 E', sortOrder: 22, metadata: { brand: 'Microsoft Xbox' } },
      { value: 'Xbox-One', displayValue: 'Xbox One', sortOrder: 23, metadata: { brand: 'Microsoft Xbox' } },
      { value: 'Xbox-One-S', displayValue: 'Xbox One S', sortOrder: 24, metadata: { brand: 'Microsoft Xbox' } },
      { value: 'Xbox-One-X', displayValue: 'Xbox One X', sortOrder: 25, metadata: { brand: 'Microsoft Xbox' } },
      { value: 'Xbox-Series-S', displayValue: 'Xbox Series S', sortOrder: 26, metadata: { brand: 'Microsoft Xbox' } },
      { value: 'Xbox-Series-X', displayValue: 'Xbox Series X', sortOrder: 27, metadata: { brand: 'Microsoft Xbox' } },
      // Nintendo models
      { value: 'Wii', displayValue: 'Nintendo Wii', sortOrder: 40, metadata: { brand: 'Nintendo' } },
      { value: 'Wii-U', displayValue: 'Nintendo Wii U', sortOrder: 41, metadata: { brand: 'Nintendo' } },
      { value: 'Switch', displayValue: 'Nintendo Switch', sortOrder: 42, metadata: { brand: 'Nintendo' } },
      { value: 'Switch-Lite', displayValue: 'Nintendo Switch Lite', sortOrder: 43, metadata: { brand: 'Nintendo' } },
      { value: 'Switch-OLED', displayValue: 'Nintendo Switch OLED', sortOrder: 44, metadata: { brand: 'Nintendo' } },
      { value: '3DS', displayValue: 'Nintendo 3DS', sortOrder: 45, metadata: { brand: 'Nintendo' } },
      { value: '3DS-XL', displayValue: 'Nintendo 3DS XL', sortOrder: 46, metadata: { brand: 'Nintendo' } },
      { value: '2DS', displayValue: 'Nintendo 2DS', sortOrder: 47, metadata: { brand: 'Nintendo' } },
      { value: 'New-3DS', displayValue: 'New Nintendo 3DS', sortOrder: 48, metadata: { brand: 'Nintendo' } },
      // Other
      { value: 'Other', displayValue: 'Other', sortOrder: 100, metadata: { brand: 'Other' } },
    ],
  },
  // Brand (Cameras & Photo)
  {
    name: 'Camera Brand',
    slug: 'brand-cameras',
    type: 'SINGLE_SELECT',
    isRequired: false,
    values: [
      { value: 'Canon', sortOrder: 1 },
      { value: 'Nikon', sortOrder: 2 },
      { value: 'Sony', sortOrder: 3 },
      { value: 'Fujifilm', sortOrder: 4 },
      { value: 'Panasonic', sortOrder: 5 },
      { value: 'Olympus', sortOrder: 6 },
      { value: 'Leica', sortOrder: 7 },
      { value: 'GoPro', sortOrder: 8 },
      { value: 'DJI', sortOrder: 9 },
      { value: 'Hasselblad', sortOrder: 10 },
      { value: 'Sigma', sortOrder: 11 },
      { value: 'Tamron', sortOrder: 12 },
      { value: 'Other', sortOrder: 100 },
    ],
  },
  // Brand (Wearables)
  {
    name: 'Wearable Brand',
    slug: 'brand-wearables',
    type: 'SINGLE_SELECT',
    isRequired: false,
    values: [
      { value: 'Apple', sortOrder: 1 },
      { value: 'Samsung', sortOrder: 2 },
      { value: 'Fitbit', sortOrder: 3 },
      { value: 'Garmin', sortOrder: 4 },
      { value: 'Xiaomi', sortOrder: 5 },
      { value: 'Huawei', sortOrder: 6 },
      { value: 'Amazfit', sortOrder: 7 },
      { value: 'Google', sortOrder: 8 },
      { value: 'Fossil', sortOrder: 9 },
      { value: 'Withings', sortOrder: 10 },
      { value: 'Polar', sortOrder: 11 },
      { value: 'Suunto', sortOrder: 12 },
      { value: 'Other', sortOrder: 100 },
    ],
  },
  // Brand (Home)
  {
    name: 'Home Brand',
    slug: 'brand-home',
    type: 'SINGLE_SELECT',
    isRequired: false,
    values: [
      { value: 'IKEA', sortOrder: 1 },
      { value: 'Ashley Furniture', sortOrder: 2 },
      { value: 'West Elm', sortOrder: 3 },
      { value: 'Pottery Barn', sortOrder: 4 },
      { value: 'Crate & Barrel', sortOrder: 5 },
      { value: 'Target Home', sortOrder: 6 },
      { value: 'Muji', sortOrder: 7 },
      { value: 'Zara Home', sortOrder: 8 },
      { value: 'H&M Home', sortOrder: 9 },
      { value: 'KitchenAid', sortOrder: 10 },
      { value: 'Le Creuset', sortOrder: 11 },
      { value: 'Cuisinart', sortOrder: 12 },
      { value: 'Other', sortOrder: 100 },
    ],
  },
  // Storage Capacity (Electronics)
  {
    name: 'Storage',
    slug: 'storage-capacity',
    type: 'SINGLE_SELECT',
    isRequired: false,
    values: [
      { value: '16GB', sortOrder: 1 },
      { value: '32GB', sortOrder: 2 },
      { value: '64GB', sortOrder: 3 },
      { value: '128GB', sortOrder: 4 },
      { value: '256GB', sortOrder: 5 },
      { value: '512GB', sortOrder: 6 },
      { value: '1TB', sortOrder: 7 },
      { value: '2TB', sortOrder: 8 },
    ],
  },
  // Screen Size (Electronics)
  {
    name: 'Screen Size',
    slug: 'screen-size',
    type: 'SINGLE_SELECT',
    isRequired: false,
    values: [
      { value: '4-5"', displayValue: '4-5 inches', sortOrder: 1 },
      { value: '5-6"', displayValue: '5-6 inches', sortOrder: 2 },
      { value: '6-7"', displayValue: '6-7 inches', sortOrder: 3 },
      { value: '10-11"', displayValue: '10-11 inches', sortOrder: 4 },
      { value: '11-12"', displayValue: '11-12 inches', sortOrder: 5 },
      { value: '13"', displayValue: '13 inches', sortOrder: 6 },
      { value: '14"', displayValue: '14 inches', sortOrder: 7 },
      { value: '15"', displayValue: '15 inches', sortOrder: 8 },
      { value: '17"', displayValue: '17 inches', sortOrder: 9 },
      { value: '21-24"', displayValue: '21-24 inches', sortOrder: 10 },
      { value: '27"', displayValue: '27 inches', sortOrder: 11 },
      { value: '32"+', displayValue: '32+ inches', sortOrder: 12 },
    ],
  },
];

// ============================================
// CATEGORY-ATTRIBUTE MAPPINGS
// ============================================

// Define which attributes apply to which category slugs
const categoryAttributeMap: Record<string, string[]> = {
  // Women's Clothing
  'women-clothing': ['size-clothing', 'color', 'brand-fashion', 'material', 'condition'],
  'women-dresses': ['size-clothing', 'color', 'brand-fashion', 'material', 'condition'],
  'women-tops': ['size-clothing', 'color', 'brand-fashion', 'material', 'condition'],
  'women-blouses': ['size-clothing', 'color', 'brand-fashion', 'material', 'condition'],
  'women-sweaters': ['size-clothing', 'color', 'brand-fashion', 'material', 'condition'],
  'women-jackets': ['size-clothing', 'color', 'brand-fashion', 'material', 'condition'],
  'women-jeans': ['size-clothing', 'color', 'brand-fashion', 'material', 'condition'],
  'women-trousers': ['size-clothing', 'color', 'brand-fashion', 'material', 'condition'],
  'women-shorts': ['size-clothing', 'color', 'brand-fashion', 'material', 'condition'],
  'women-skirts': ['size-clothing', 'color', 'brand-fashion', 'material', 'condition'],
  'women-suits': ['size-clothing', 'color', 'brand-fashion', 'material', 'condition'],
  'women-jumpsuits': ['size-clothing', 'color', 'brand-fashion', 'material', 'condition'],
  'women-activewear': ['size-clothing', 'color', 'brand-fashion', 'material', 'condition'],
  'women-swimwear': ['size-clothing', 'color', 'brand-fashion', 'material', 'condition'],
  'women-lingerie': ['size-clothing', 'color', 'brand-fashion', 'material', 'condition'],
  'women-traditional': ['size-clothing', 'color', 'brand-fashion', 'material', 'condition'],

  // Women's Shoes
  'women-shoes': ['size-shoes-eu', 'color', 'brand-fashion', 'material', 'condition'],
  'women-heels': ['size-shoes-eu', 'color', 'brand-fashion', 'material', 'condition'],
  'women-flats': ['size-shoes-eu', 'color', 'brand-fashion', 'material', 'condition'],
  'women-sandals': ['size-shoes-eu', 'color', 'brand-fashion', 'material', 'condition'],
  'women-boots': ['size-shoes-eu', 'color', 'brand-fashion', 'material', 'condition'],
  'women-sneakers': ['size-shoes-eu', 'color', 'brand-fashion', 'material', 'condition'],
  'women-loafers': ['size-shoes-eu', 'color', 'brand-fashion', 'material', 'condition'],
  'women-wedges': ['size-shoes-eu', 'color', 'brand-fashion', 'material', 'condition'],
  'women-sports-shoes': ['size-shoes-eu', 'color', 'brand-fashion', 'material', 'condition'],

  // Women's Bags & Accessories
  'women-bags': ['color', 'brand-fashion', 'material', 'condition'],
  'women-handbags': ['color', 'brand-fashion', 'material', 'condition'],
  'women-shoulder-bags': ['color', 'brand-fashion', 'material', 'condition'],
  'women-crossbody': ['color', 'brand-fashion', 'material', 'condition'],
  'women-totes': ['color', 'brand-fashion', 'material', 'condition'],
  'women-clutches': ['color', 'brand-fashion', 'material', 'condition'],
  'women-backpacks': ['color', 'brand-fashion', 'material', 'condition'],
  'women-wallets': ['color', 'brand-fashion', 'material', 'condition'],

  'women-accessories': ['color', 'brand-fashion', 'material', 'condition'],
  'women-jewelry': ['color', 'brand-fashion', 'material', 'condition'],
  'women-watches': ['color', 'brand-fashion', 'material', 'condition'],
  'women-sunglasses': ['color', 'brand-fashion', 'condition'],
  'women-belts': ['size-clothing', 'color', 'brand-fashion', 'material', 'condition'],
  'women-scarves': ['color', 'brand-fashion', 'material', 'condition'],
  'women-hats': ['color', 'brand-fashion', 'material', 'condition'],
  'women-hair-accessories': ['color', 'brand-fashion', 'condition'],

  // Men's Clothing
  'men-clothing': ['size-clothing', 'color', 'brand-fashion', 'material', 'condition'],
  'men-tshirts': ['size-clothing', 'color', 'brand-fashion', 'material', 'condition'],
  'men-shirts': ['size-clothing', 'color', 'brand-fashion', 'material', 'condition'],
  'men-sweaters': ['size-clothing', 'color', 'brand-fashion', 'material', 'condition'],
  'men-jackets': ['size-clothing', 'color', 'brand-fashion', 'material', 'condition'],
  'men-jeans': ['size-clothing', 'color', 'brand-fashion', 'material', 'condition'],
  'men-trousers': ['size-clothing', 'color', 'brand-fashion', 'material', 'condition'],
  'men-shorts': ['size-clothing', 'color', 'brand-fashion', 'material', 'condition'],
  'men-suits': ['size-clothing', 'color', 'brand-fashion', 'material', 'condition'],
  'men-activewear': ['size-clothing', 'color', 'brand-fashion', 'material', 'condition'],
  'men-swimwear': ['size-clothing', 'color', 'brand-fashion', 'material', 'condition'],
  'men-underwear': ['size-clothing', 'color', 'brand-fashion', 'material', 'condition'],
  'men-traditional': ['size-clothing', 'color', 'brand-fashion', 'material', 'condition'],

  // Men's Shoes
  'men-shoes': ['size-shoes-eu', 'color', 'brand-fashion', 'material', 'condition'],
  'men-sneakers': ['size-shoes-eu', 'color', 'brand-fashion', 'material', 'condition'],
  'men-formal-shoes': ['size-shoes-eu', 'color', 'brand-fashion', 'material', 'condition'],
  'men-boots': ['size-shoes-eu', 'color', 'brand-fashion', 'material', 'condition'],
  'men-sandals': ['size-shoes-eu', 'color', 'brand-fashion', 'material', 'condition'],
  'men-loafers': ['size-shoes-eu', 'color', 'brand-fashion', 'material', 'condition'],
  'men-sports-shoes': ['size-shoes-eu', 'color', 'brand-fashion', 'material', 'condition'],

  // Men's Bags & Accessories
  'men-bags': ['color', 'brand-fashion', 'material', 'condition'],
  'men-backpacks': ['color', 'brand-fashion', 'material', 'condition'],
  'men-messenger': ['color', 'brand-fashion', 'material', 'condition'],
  'men-briefcases': ['color', 'brand-fashion', 'material', 'condition'],
  'men-wallets': ['color', 'brand-fashion', 'material', 'condition'],
  'men-travel-bags': ['color', 'brand-fashion', 'material', 'condition'],

  'men-accessories': ['color', 'brand-fashion', 'material', 'condition'],
  'men-watches': ['color', 'brand-fashion', 'material', 'condition'],
  'men-sunglasses': ['color', 'brand-fashion', 'condition'],
  'men-belts': ['size-clothing', 'color', 'brand-fashion', 'material', 'condition'],
  'men-ties': ['color', 'brand-fashion', 'material', 'condition'],
  'men-hats': ['color', 'brand-fashion', 'material', 'condition'],
  'men-cufflinks': ['color', 'brand-fashion', 'material', 'condition'],

  // Kids
  'kids-girls': ['size-kids', 'color', 'brand-fashion', 'material', 'condition'],
  'kids-girls-dresses': ['size-kids', 'color', 'brand-fashion', 'material', 'condition'],
  'kids-girls-tops': ['size-kids', 'color', 'brand-fashion', 'material', 'condition'],
  'kids-girls-trousers': ['size-kids', 'color', 'brand-fashion', 'material', 'condition'],
  'kids-girls-skirts': ['size-kids', 'color', 'brand-fashion', 'material', 'condition'],
  'kids-girls-jackets': ['size-kids', 'color', 'brand-fashion', 'material', 'condition'],
  'kids-girls-shoes': ['size-kids-shoes-eu', 'color', 'brand-fashion', 'material', 'condition'],
  'kids-girls-uniforms': ['size-kids', 'color', 'brand-fashion', 'material', 'condition'],

  'kids-boys': ['size-kids', 'color', 'brand-fashion', 'material', 'condition'],
  'kids-boys-tshirts': ['size-kids', 'color', 'brand-fashion', 'material', 'condition'],
  'kids-boys-trousers': ['size-kids', 'color', 'brand-fashion', 'material', 'condition'],
  'kids-boys-shorts': ['size-kids', 'color', 'brand-fashion', 'material', 'condition'],
  'kids-boys-jackets': ['size-kids', 'color', 'brand-fashion', 'material', 'condition'],
  'kids-boys-shoes': ['size-kids-shoes-eu', 'color', 'brand-fashion', 'material', 'condition'],
  'kids-boys-uniforms': ['size-kids', 'color', 'brand-fashion', 'material', 'condition'],

  'kids-baby': ['size-kids', 'color', 'brand-fashion', 'material', 'condition'],
  'kids-baby-bodysuits': ['size-kids', 'color', 'brand-fashion', 'material', 'condition'],
  'kids-baby-sets': ['size-kids', 'color', 'brand-fashion', 'material', 'condition'],
  'kids-baby-sleepwear': ['size-kids', 'color', 'brand-fashion', 'material', 'condition'],
  'kids-baby-outerwear': ['size-kids', 'color', 'brand-fashion', 'material', 'condition'],
  'kids-baby-shoes': ['size-kids-shoes-eu', 'color', 'brand-fashion', 'material', 'condition'],
  'kids-baby-accessories': ['color', 'brand-fashion', 'condition'],

  'kids-toys': ['condition'],
  'kids-soft-toys': ['condition'],
  'kids-educational': ['condition'],
  'kids-outdoor-toys': ['condition'],
  'kids-board-games': ['condition'],
  'kids-building': ['condition'],

  // Home
  'home-furniture': ['color', 'brand-home', 'material', 'condition'],
  'home-sofas': ['color', 'brand-home', 'material', 'condition'],
  'home-tables': ['color', 'brand-home', 'material', 'condition'],
  'home-chairs': ['color', 'brand-home', 'material', 'condition'],
  'home-beds': ['color', 'brand-home', 'material', 'condition'],
  'home-wardrobes': ['color', 'brand-home', 'material', 'condition'],
  'home-shelving': ['color', 'brand-home', 'material', 'condition'],

  'home-decor': ['color', 'brand-home', 'material', 'condition'],
  'home-mirrors': ['color', 'brand-home', 'material', 'condition'],
  'home-vases': ['color', 'brand-home', 'material', 'condition'],
  'home-candles': ['color', 'brand-home', 'condition'],
  'home-frames': ['color', 'brand-home', 'material', 'condition'],
  'home-wall-art': ['color', 'brand-home', 'condition'],
  'home-rugs': ['color', 'brand-home', 'material', 'condition'],

  'home-kitchen': ['color', 'brand-home', 'material', 'condition'],
  'home-cookware': ['color', 'brand-home', 'material', 'condition'],
  'home-tableware': ['color', 'brand-home', 'material', 'condition'],
  'home-glassware': ['color', 'brand-home', 'material', 'condition'],
  'home-cutlery': ['color', 'brand-home', 'material', 'condition'],
  'home-small-appliances': ['color', 'brand-home', 'condition'],
  'home-storage': ['color', 'brand-home', 'material', 'condition'],

  'home-bedding': ['color', 'brand-home', 'material', 'condition'],
  'home-bed-linen': ['color', 'brand-home', 'material', 'condition'],
  'home-pillows': ['color', 'brand-home', 'material', 'condition'],
  'home-blankets': ['color', 'brand-home', 'material', 'condition'],
  'home-towels': ['color', 'brand-home', 'material', 'condition'],
  'home-bathroom': ['color', 'brand-home', 'material', 'condition'],

  'home-garden': ['color', 'brand-home', 'material', 'condition'],
  'home-garden-furniture': ['color', 'brand-home', 'material', 'condition'],
  'home-plants': ['condition'],
  'home-garden-tools': ['brand-home', 'condition'],
  'home-bbq': ['brand-home', 'condition'],

  // Electronics - Phones & Tablets
  'electronics-phones': ['brand-phones', 'storage-capacity', 'color', 'condition'],
  'electronics-smartphones': ['brand-phones', 'storage-capacity', 'screen-size', 'color', 'condition'],
  'electronics-tablets': ['brand-phones', 'storage-capacity', 'screen-size', 'color', 'condition'],
  'electronics-phone-cases': ['color', 'condition'],
  'electronics-chargers': ['brand-phones', 'condition'],
  'electronics-screen-protectors': ['condition'],

  // Electronics - Computers
  'electronics-computers': ['brand-computers', 'storage-capacity', 'screen-size', 'condition'],
  'electronics-laptops': ['brand-computers', 'storage-capacity', 'screen-size', 'condition'],
  'electronics-desktops': ['brand-computers', 'storage-capacity', 'condition'],
  'electronics-monitors': ['brand-computers', 'screen-size', 'condition'],
  'electronics-peripherals': ['brand-computers', 'color', 'condition'],
  'electronics-computer-accessories': ['brand-computers', 'color', 'condition'],

  // Electronics - Audio
  'electronics-audio': ['brand-audio', 'color', 'condition'],
  'electronics-headphones': ['brand-audio', 'color', 'condition'],
  'electronics-earbuds': ['brand-audio', 'color', 'condition'],
  'electronics-speakers': ['brand-audio', 'color', 'condition'],
  'electronics-home-audio': ['brand-audio', 'color', 'condition'],

  // Electronics - Gaming (with console model selection)
  'electronics-gaming': ['brand-consoles', 'console-model', 'condition'],
  'electronics-consoles': ['brand-consoles', 'console-model', 'storage-capacity', 'color', 'condition'],
  'electronics-games': ['brand-consoles', 'condition'],
  'electronics-gaming-accessories': ['brand-consoles', 'color', 'condition'],
  'electronics-controllers': ['brand-consoles', 'color', 'condition'],

  // Electronics - Cameras & Photo
  'electronics-cameras': ['brand-cameras', 'condition'],
  'electronics-digital-cameras': ['brand-cameras', 'condition'],
  'electronics-lenses': ['brand-cameras', 'condition'],
  'electronics-camera-accessories': ['brand-cameras', 'condition'],
  'electronics-tripods': ['brand-cameras', 'condition'],

  // Electronics - Wearables
  'electronics-wearables': ['brand-wearables', 'color', 'condition'],
  'electronics-smartwatches': ['brand-wearables', 'color', 'condition'],
  'electronics-fitness-trackers': ['brand-wearables', 'color', 'condition'],
  'electronics-watch-bands': ['color', 'material', 'condition'],
};

// ============================================
// SEED FUNCTIONS
// ============================================

async function seedCategories() {
  console.log('🏷️  Seeding categories...');

  const categoryIdMap: Record<string, string> = {};

  // Recursive function to create categories
  async function createCategory(
    cat: CategoryDef,
    level: number,
    parentId: string | null,
    sortOrder: number
  ): Promise<void> {
    const category = await prisma.category.upsert({
      where: { slug: cat.slug },
      update: {
        name: cat.name,
        level,
        parentId,
        iconName: cat.iconName,
        sortOrder,
        isActive: true,
      },
      create: {
        name: cat.name,
        slug: cat.slug,
        level,
        parentId,
        iconName: cat.iconName,
        sortOrder,
        isActive: true,
      },
    });

    categoryIdMap[cat.slug] = category.id;
    console.log(`  ✓ ${' '.repeat(level * 2)}${cat.name}`);

    // Create children
    if (cat.children) {
      for (let i = 0; i < cat.children.length; i++) {
        await createCategory(cat.children[i], level + 1, category.id, i);
      }
    }
  }

  // Create all categories
  for (let i = 0; i < categoryHierarchy.length; i++) {
    await createCategory(categoryHierarchy[i], 1, null, i);
  }

  console.log(`✅ Created ${Object.keys(categoryIdMap).length} categories\n`);
  return categoryIdMap;
}

async function seedAttributes() {
  console.log('📋 Seeding attribute definitions...');

  const attributeIdMap: Record<string, string> = {};

  for (const attr of attributeDefinitions) {
    // Create attribute definition
    const definition = await prisma.attributeDefinition.upsert({
      where: { slug: attr.slug },
      update: {
        name: attr.name,
        type: attr.type,
        isRequired: attr.isRequired,
        isActive: true,
      },
      create: {
        name: attr.name,
        slug: attr.slug,
        type: attr.type,
        isRequired: attr.isRequired,
        isActive: true,
      },
    });

    attributeIdMap[attr.slug] = definition.id;
    console.log(`  ✓ ${attr.name} (${attr.type})`);

    // Create attribute values
    for (const val of attr.values) {
      await prisma.attributeValue.upsert({
        where: {
          attributeId_value: {
            attributeId: definition.id,
            value: val.value,
          },
        },
        update: {
          displayValue: val.displayValue,
          sortOrder: val.sortOrder,
          metadata: val.metadata,
          isActive: true,
        },
        create: {
          attributeId: definition.id,
          value: val.value,
          displayValue: val.displayValue,
          sortOrder: val.sortOrder,
          metadata: val.metadata,
          isActive: true,
        },
      });
    }
    console.log(`    → ${attr.values.length} values`);
  }

  console.log(`✅ Created ${Object.keys(attributeIdMap).length} attribute definitions\n`);
  return attributeIdMap;
}

async function seedCategoryAttributes(
  categoryIdMap: Record<string, string>,
  attributeIdMap: Record<string, string>
) {
  console.log('🔗 Linking attributes to categories...');

  let linkCount = 0;

  for (const [categorySlug, attributeSlugs] of Object.entries(categoryAttributeMap)) {
    const categoryId = categoryIdMap[categorySlug];
    if (!categoryId) {
      console.log(`  ⚠️  Category not found: ${categorySlug}`);
      continue;
    }

    for (let i = 0; i < attributeSlugs.length; i++) {
      const attributeSlug = attributeSlugs[i];
      const attributeId = attributeIdMap[attributeSlug];
      if (!attributeId) {
        console.log(`  ⚠️  Attribute not found: ${attributeSlug}`);
        continue;
      }

      // Determine if this attribute should be required for this category
      const isRequired = attributeSlug === 'condition' ||
                         attributeSlug.startsWith('size-');

      await prisma.categoryAttribute.upsert({
        where: {
          categoryId_attributeId: {
            categoryId,
            attributeId,
          },
        },
        update: {
          isRequired,
          sortOrder: i,
        },
        create: {
          categoryId,
          attributeId,
          isRequired,
          sortOrder: i,
        },
      });

      linkCount++;
    }
  }

  console.log(`✅ Created ${linkCount} category-attribute links\n`);
}

// ============================================
// LOCATION DEFINITIONS (Uganda)
// ============================================

interface DivisionDef {
  name: string;
}

interface CityDef {
  name: string;
  divisions: DivisionDef[];
}

const locationData: CityDef[] = [
  {
    name: 'Kampala',
    divisions: [
      { name: 'Kampala Central' },
      { name: 'Kawempe' },
      { name: 'Makindye' },
      { name: 'Nakawa' },
      { name: 'Rubaga' },
    ],
  },
  {
    name: 'Entebbe',
    divisions: [
      { name: 'Central' },
      { name: 'Kigungu' },
      { name: 'Kiwafu' },
      { name: 'Katabi' },
    ],
  },
];

async function seedLocations() {
  console.log('🏙️  Seeding locations...');

  let cityCount = 0;
  let divisionCount = 0;

  for (let cityIndex = 0; cityIndex < locationData.length; cityIndex++) {
    const cityDef = locationData[cityIndex];

    // Create or update city
    const city = await prisma.city.upsert({
      where: { name: cityDef.name },
      update: {
        isActive: true,
        sortOrder: cityIndex,
      },
      create: {
        name: cityDef.name,
        isActive: true,
        sortOrder: cityIndex,
      },
    });

    console.log(`  ✓ ${city.name}`);
    cityCount++;

    // Create divisions for this city
    for (let divIndex = 0; divIndex < cityDef.divisions.length; divIndex++) {
      const divDef = cityDef.divisions[divIndex];

      await prisma.division.upsert({
        where: {
          cityId_name: {
            cityId: city.id,
            name: divDef.name,
          },
        },
        update: {
          isActive: true,
          sortOrder: divIndex,
        },
        create: {
          cityId: city.id,
          name: divDef.name,
          isActive: true,
          sortOrder: divIndex,
        },
      });

      console.log(`      → ${divDef.name}`);
      divisionCount++;
    }
  }

  console.log(`✅ Created ${cityCount} cities with ${divisionCount} divisions\n`);
}

// ============================================
// MAIN EXECUTION
// ============================================

async function main() {
  console.log('🌱 Starting Vinted-style category seed...\n');
  console.log('━'.repeat(50));

  try {
    // Seed categories
    const categoryIdMap = await seedCategories();

    // Seed attributes
    const attributeIdMap = await seedAttributes();

    // Link attributes to categories
    await seedCategoryAttributes(categoryIdMap, attributeIdMap);

    // Seed locations (Cities and Divisions)
    await seedLocations();

    console.log('━'.repeat(50));
    console.log('🎉 Seed completed successfully!\n');

    // Summary
    const categoryCount = await prisma.category.count();
    const attributeCount = await prisma.attributeDefinition.count();
    const valueCount = await prisma.attributeValue.count();
    const linkCount = await prisma.categoryAttribute.count();
    const cityCount = await prisma.city.count();
    const divisionCount = await prisma.division.count();

    console.log('📊 Summary:');
    console.log(`   Categories: ${categoryCount}`);
    console.log(`   Attributes: ${attributeCount}`);
    console.log(`   Attribute Values: ${valueCount}`);
    console.log(`   Category-Attribute Links: ${linkCount}`);
    console.log(`   Cities: ${cityCount}`);
    console.log(`   Divisions: ${divisionCount}`);

  } catch (error) {
    console.error('❌ Seed failed:', error);
    throw error;
  } finally {
    await prisma.$disconnect();
    await pool.end();
  }
}

main();
