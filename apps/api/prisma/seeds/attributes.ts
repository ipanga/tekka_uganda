import { AttributeType } from '@prisma/client';
import { prisma } from './client';

interface AttributeSeed {
  name: string;
  slug: string;
  type: AttributeType;
  isRequired?: boolean;
  isActive?: boolean; // Default true, set false to deprecate
  values: string[];
  metadata?: Record<string, Record<string, string>>; // value -> metadata
}

// ============================================
// ATTRIBUTE DEFINITIONS
// ============================================

const attributes: AttributeSeed[] = [
  // ============================================
  // SIZE ATTRIBUTES
  // ============================================
  {
    name: 'Clothing Size',
    slug: 'size-clothing',
    type: 'MULTI_SELECT', // Changed: allows multiple sizes per listing
    isRequired: true,
    values: ['XXS', 'XS', 'S', 'M', 'L', 'XL', 'XXL', '3XL', '4XL'],
  },
  {
    name: 'Shoe Size (EU)',
    slug: 'size-shoes-eu',
    type: 'MULTI_SELECT', // Changed: allows multiple sizes per listing
    isRequired: true,
    values: [
      '35',
      '36',
      '37',
      '38',
      '39',
      '40',
      '41',
      '42',
      '43',
      '44',
      '45',
      '46',
      '47',
      '48',
    ],
  },
  {
    name: 'Kids Clothing Size',
    slug: 'size-kids-clothing',
    type: 'MULTI_SELECT', // Changed: allows multiple sizes per listing
    isRequired: true,
    values: [
      '0-3M',
      '3-6M',
      '6-9M',
      '9-12M',
      '12-18M',
      '18-24M',
      '2-3Y',
      '3-4Y',
      '4-5Y',
      '5-6Y',
      '6-7Y',
      '7-8Y',
      '8-9Y',
      '9-10Y',
      '10-11Y',
      '11-12Y',
      '12-13Y',
      '13-14Y',
    ],
  },
  {
    name: 'Kids Shoe Size (EU)',
    slug: 'size-kids-shoes-eu',
    type: 'MULTI_SELECT', // Changed: allows multiple sizes per listing
    isRequired: true,
    values: [
      '16',
      '17',
      '18',
      '19',
      '20',
      '21',
      '22',
      '23',
      '24',
      '25',
      '26',
      '27',
      '28',
      '29',
      '30',
      '31',
      '32',
      '33',
      '34',
      '35',
      '36',
      '37',
      '38',
    ],
  },

  // ============================================
  // FASHION BRAND (sorted A-Z, "Other" always last)
  // ============================================
  {
    name: 'Brand',
    slug: 'brand-fashion',
    type: 'SINGLE_SELECT',
    isRequired: false,
    values: [
      // Sorted alphabetically A-Z
      'Adidas',
      'ASOS',
      'Balenciaga',
      'Burberry',
      'Calvin Klein',
      'Chanel',
      'Coach',
      'Custom-made',
      'Dolce & Gabbana',
      'Fashion Nova',
      'Fendi',
      'Gucci',
      'H&M',
      "Levi's",
      'Local Tailor',
      'Louis Vuitton',
      'Mango',
      'Michael Kors',
      'Nike',
      'Prada',
      'Puma',
      'Ralph Lauren',
      'Shein',
      'Tommy Hilfiger',
      'Uniqlo',
      'Versace',
      'Zara',
      'Other', // Always last (sortOrder=999)
    ],
  },

  // ============================================
  // ELECTRONICS BRAND (DEPRECATED - use device-specific brands instead)
  // ============================================
  {
    name: 'Brand',
    slug: 'brand-electronics',
    type: 'SINGLE_SELECT',
    isRequired: false,
    isActive: false, // DEPRECATED: Electronics uses device-specific brands
    values: [
      'Apple',
      'Samsung',
      'Sony',
      'LG',
      'Huawei',
      'Xiaomi',
      'Oppo',
      'Vivo',
      'OnePlus',
      'Google',
      'Tecno',
      'Infinix',
      'Itel',
      'Nokia',
      'Motorola',
      'HP',
      'Dell',
      'Lenovo',
      'Asus',
      'Acer',
      'MSI',
      'Microsoft',
      'Toshiba',
      'JBL',
      'Bose',
      'Beats',
      'Anker',
      'Canon',
      'Nikon',
      'Fujifilm',
      'GoPro',
      'DJI',
      'PlayStation',
      'Xbox',
      'Nintendo',
      'Other',
    ],
  },

  // ============================================
  // HOME BRAND (sorted A-Z, "Other" always last)
  // ============================================
  {
    name: 'Brand',
    slug: 'brand-home',
    type: 'SINGLE_SELECT',
    isRequired: false,
    values: [
      // Sorted alphabetically A-Z
      'Ashley Furniture',
      'CB2',
      'Crate & Barrel',
      'Custom-made',
      'Home Centre',
      'IKEA',
      'Local Craftsman',
      'Pottery Barn',
      'Restoration Hardware',
      'Wayfair',
      'West Elm',
      'Williams-Sonoma',
      'Other', // Always last (sortOrder=999)
    ],
  },

  // ============================================
  // COLOR
  // ============================================
  {
    name: 'Color',
    slug: 'color',
    type: 'MULTI_SELECT',
    isRequired: false,
    values: [
      'Black',
      'White',
      'Red',
      'Blue',
      'Navy',
      'Green',
      'Yellow',
      'Orange',
      'Pink',
      'Purple',
      'Brown',
      'Beige',
      'Gray',
      'Silver',
      'Gold',
      'Multicolor',
    ],
    metadata: {
      Black: { hex: '#000000' },
      White: { hex: '#FFFFFF' },
      Red: { hex: '#FF0000' },
      Blue: { hex: '#0000FF' },
      Navy: { hex: '#000080' },
      Green: { hex: '#008000' },
      Yellow: { hex: '#FFFF00' },
      Orange: { hex: '#FFA500' },
      Pink: { hex: '#FFC0CB' },
      Purple: { hex: '#800080' },
      Brown: { hex: '#A52A2A' },
      Beige: { hex: '#F5F5DC' },
      Gray: { hex: '#808080' },
      Silver: { hex: '#C0C0C0' },
      Gold: { hex: '#FFD700' },
      Multicolor: { hex: '#GRADIENT' },
    },
  },

  // ============================================
  // MATERIAL (Fashion)
  // ============================================
  {
    name: 'Material',
    slug: 'material-fashion',
    type: 'SINGLE_SELECT',
    isRequired: false,
    values: [
      'Cotton',
      'Polyester',
      'Silk',
      'Wool',
      'Linen',
      'Denim',
      'Leather',
      'Faux Leather',
      'Suede',
      'Velvet',
      'Satin',
      'Chiffon',
      'Lace',
      'Knitwear',
      'Jersey',
      'Fleece',
      'Nylon',
      'Spandex',
      'Cashmere',
      'Mixed/Other',
    ],
  },

  // ============================================
  // MATERIAL (Home)
  // ============================================
  {
    name: 'Material',
    slug: 'material-home',
    type: 'SINGLE_SELECT',
    isRequired: false,
    values: [
      'Wood',
      'Metal',
      'Glass',
      'Plastic',
      'Fabric',
      'Leather',
      'Rattan',
      'Bamboo',
      'Marble',
      'Ceramic',
      'Stone',
      'Concrete',
      'Mixed/Other',
    ],
  },

  // ============================================
  // ELECTRONICS - STORAGE
  // ============================================
  {
    name: 'Storage',
    slug: 'storage',
    type: 'SINGLE_SELECT',
    isRequired: false,
    values: [
      '8GB',
      '16GB',
      '32GB',
      '64GB',
      '128GB',
      '256GB',
      '512GB',
      '1TB',
      '2TB',
      '4TB',
    ],
  },

  // ============================================
  // ELECTRONICS - RAM
  // ============================================
  {
    name: 'RAM',
    slug: 'ram',
    type: 'SINGLE_SELECT',
    isRequired: false,
    values: ['1GB', '2GB', '3GB', '4GB', '6GB', '8GB', '12GB', '16GB', '32GB', '64GB'],
  },

  // ============================================
  // ELECTRONICS - SCREEN SIZE
  // ============================================
  {
    name: 'Screen Size',
    slug: 'screen-size',
    type: 'SINGLE_SELECT',
    isRequired: false,
    values: [
      '4"',
      '5"',
      '5.5"',
      '6"',
      '6.5"',
      '7"',
      '8"',
      '10"',
      '11"',
      '12"',
      '13"',
      '14"',
      '15"',
      '16"',
      '17"',
      '21"',
      '24"',
      '27"',
      '32"',
      '40"',
      '43"',
      '50"',
      '55"',
      '65"',
      '75"',
      '85"',
    ],
  },

  // ============================================
  // PATTERN (DEPRECATED - kept for backward compatibility)
  // ============================================
  {
    name: 'Pattern',
    slug: 'pattern',
    type: 'SINGLE_SELECT',
    isRequired: false,
    isActive: false, // DEPRECATED: No longer shown in forms
    values: [
      'Solid',
      'Striped',
      'Checked',
      'Plaid',
      'Floral',
      'Geometric',
      'Animal Print',
      'Abstract',
      'Polka Dot',
      'Camouflage',
      'Paisley',
      'Tribal',
      'Other',
    ],
  },

  // ============================================
  // STYLE (DEPRECATED - kept for backward compatibility)
  // ============================================
  {
    name: 'Style',
    slug: 'style',
    type: 'SINGLE_SELECT',
    isRequired: false,
    isActive: false, // DEPRECATED: No longer shown in forms
    values: [
      'Casual',
      'Formal',
      'Business Casual',
      'Sporty',
      'Bohemian',
      'Vintage',
      'Streetwear',
      'Minimalist',
      'Glamorous',
      'Traditional',
      'Other',
    ],
  },

  // ============================================
  // DEVICE-SPECIFIC ELECTRONICS BRANDS
  // ============================================
  {
    name: 'Phone Brand',
    slug: 'brand-phones',
    type: 'SINGLE_SELECT',
    isRequired: true,
    values: [
      // Sorted A-Z
      'Apple',
      'Google',
      'Huawei',
      'Infinix',
      'Itel',
      'Motorola',
      'Nokia',
      'OnePlus',
      'Oppo',
      'Samsung',
      'Tecno',
      'Vivo',
      'Xiaomi',
      'Other', // Always last
    ],
  },
  {
    name: 'Laptop Brand',
    slug: 'brand-laptops',
    type: 'SINGLE_SELECT',
    isRequired: true,
    values: [
      // Sorted A-Z
      'Acer',
      'Apple',
      'Asus',
      'Dell',
      'HP',
      'Lenovo',
      'Microsoft',
      'MSI',
      'Toshiba',
      'Other', // Always last
    ],
  },
  {
    name: 'Console Brand',
    slug: 'brand-consoles',
    type: 'SINGLE_SELECT',
    isRequired: true,
    values: [
      'Nintendo',
      'PlayStation',
      'Xbox',
      'Other', // Always last
    ],
  },
  {
    name: 'Console Model',
    slug: 'console-model',
    type: 'SINGLE_SELECT',
    isRequired: true,
    values: [
      // Nintendo - modern only (Wii and newer)
      'Nintendo Switch',
      'Nintendo Switch Lite',
      'Nintendo Switch OLED',
      'Nintendo Switch 2',
      'Wii',
      'Wii U',
      // PlayStation - PS3 and newer only
      'PlayStation 3',
      'PlayStation 4',
      'PlayStation 4 Pro',
      'PlayStation 5',
      'PlayStation 5 Digital Edition',
      // Xbox - 360 and newer only
      'Xbox 360',
      'Xbox One',
      'Xbox One S',
      'Xbox One X',
      'Xbox Series S',
      'Xbox Series X',
      'Other', // Always last
    ],
    // Metadata maps each model to its brand for filtering
    metadata: {
      'Nintendo Switch': { brand: 'Nintendo' },
      'Nintendo Switch Lite': { brand: 'Nintendo' },
      'Nintendo Switch OLED': { brand: 'Nintendo' },
      'Nintendo Switch 2': { brand: 'Nintendo' },
      'Wii': { brand: 'Nintendo' },
      'Wii U': { brand: 'Nintendo' },
      'PlayStation 3': { brand: 'PlayStation' },
      'PlayStation 4': { brand: 'PlayStation' },
      'PlayStation 4 Pro': { brand: 'PlayStation' },
      'PlayStation 5': { brand: 'PlayStation' },
      'PlayStation 5 Digital Edition': { brand: 'PlayStation' },
      'Xbox 360': { brand: 'Xbox' },
      'Xbox One': { brand: 'Xbox' },
      'Xbox One S': { brand: 'Xbox' },
      'Xbox One X': { brand: 'Xbox' },
      'Xbox Series S': { brand: 'Xbox' },
      'Xbox Series X': { brand: 'Xbox' },
      'Other': { brand: 'Other' },
    },
  },
  {
    name: 'Camera Brand',
    slug: 'brand-cameras',
    type: 'SINGLE_SELECT',
    isRequired: true,
    values: [
      // Sorted A-Z
      'Canon',
      'DJI',
      'Fujifilm',
      'GoPro',
      'Nikon',
      'Panasonic',
      'Sony',
      'Other', // Always last
    ],
  },
  {
    name: 'TV Brand',
    slug: 'brand-tv',
    type: 'SINGLE_SELECT',
    isRequired: true,
    values: [
      // Sorted A-Z
      'Hisense',
      'LG',
      'Samsung',
      'Sony',
      'TCL',
      'Other', // Always last
    ],
  },
  {
    name: 'Audio Brand',
    slug: 'brand-audio',
    type: 'SINGLE_SELECT',
    isRequired: true,
    values: [
      // Sorted A-Z
      'Anker',
      'Apple',
      'Beats',
      'Bose',
      'JBL',
      'Samsung',
      'Sony',
      'Other', // Always last
    ],
  },
];

// ============================================
// CATEGORY-ATTRIBUTE MAPPINGS
// ============================================
// Maps category slugs to their applicable attribute slugs
// Attributes at parent level apply to all children

interface CategoryAttributeMapping {
  categorySlug: string;
  attributeSlug: string;
  isRequired?: boolean;
  sortOrder: number;
}

const categoryAttributeMappings: CategoryAttributeMapping[] = [
  // ============================================
  // WOMEN CLOTHING - Level 2 (applies to all L3 children)
  // Pattern and Style removed (deprecated)
  // ============================================
  { categorySlug: 'women-clothing', attributeSlug: 'size-clothing', isRequired: true, sortOrder: 1 },
  { categorySlug: 'women-clothing', attributeSlug: 'brand-fashion', isRequired: false, sortOrder: 2 },
  { categorySlug: 'women-clothing', attributeSlug: 'color', isRequired: false, sortOrder: 3 },
  { categorySlug: 'women-clothing', attributeSlug: 'material-fashion', isRequired: false, sortOrder: 4 },

  // ============================================
  // WOMEN SHOES - Level 2
  // ============================================
  { categorySlug: 'women-shoes', attributeSlug: 'size-shoes-eu', isRequired: true, sortOrder: 1 },
  { categorySlug: 'women-shoes', attributeSlug: 'brand-fashion', isRequired: false, sortOrder: 2 },
  { categorySlug: 'women-shoes', attributeSlug: 'color', isRequired: false, sortOrder: 3 },
  { categorySlug: 'women-shoes', attributeSlug: 'material-fashion', isRequired: false, sortOrder: 4 },

  // ============================================
  // WOMEN BAGS - Level 2
  // ============================================
  { categorySlug: 'women-bags', attributeSlug: 'brand-fashion', isRequired: false, sortOrder: 1 },
  { categorySlug: 'women-bags', attributeSlug: 'color', isRequired: false, sortOrder: 2 },
  { categorySlug: 'women-bags', attributeSlug: 'material-fashion', isRequired: false, sortOrder: 3 },

  // ============================================
  // WOMEN ACCESSORIES - Level 2
  // ============================================
  { categorySlug: 'women-accessories', attributeSlug: 'brand-fashion', isRequired: false, sortOrder: 1 },
  { categorySlug: 'women-accessories', attributeSlug: 'color', isRequired: false, sortOrder: 2 },
  { categorySlug: 'women-accessories', attributeSlug: 'material-fashion', isRequired: false, sortOrder: 3 },

  // ============================================
  // MEN CLOTHING - Level 2
  // Pattern and Style removed (deprecated)
  // ============================================
  { categorySlug: 'men-clothing', attributeSlug: 'size-clothing', isRequired: true, sortOrder: 1 },
  { categorySlug: 'men-clothing', attributeSlug: 'brand-fashion', isRequired: false, sortOrder: 2 },
  { categorySlug: 'men-clothing', attributeSlug: 'color', isRequired: false, sortOrder: 3 },
  { categorySlug: 'men-clothing', attributeSlug: 'material-fashion', isRequired: false, sortOrder: 4 },

  // ============================================
  // MEN SHOES - Level 2
  // ============================================
  { categorySlug: 'men-shoes', attributeSlug: 'size-shoes-eu', isRequired: true, sortOrder: 1 },
  { categorySlug: 'men-shoes', attributeSlug: 'brand-fashion', isRequired: false, sortOrder: 2 },
  { categorySlug: 'men-shoes', attributeSlug: 'color', isRequired: false, sortOrder: 3 },
  { categorySlug: 'men-shoes', attributeSlug: 'material-fashion', isRequired: false, sortOrder: 4 },

  // ============================================
  // MEN BAGS - Level 2
  // ============================================
  { categorySlug: 'men-bags', attributeSlug: 'brand-fashion', isRequired: false, sortOrder: 1 },
  { categorySlug: 'men-bags', attributeSlug: 'color', isRequired: false, sortOrder: 2 },
  { categorySlug: 'men-bags', attributeSlug: 'material-fashion', isRequired: false, sortOrder: 3 },

  // ============================================
  // MEN ACCESSORIES - Level 2
  // ============================================
  { categorySlug: 'men-accessories', attributeSlug: 'brand-fashion', isRequired: false, sortOrder: 1 },
  { categorySlug: 'men-accessories', attributeSlug: 'color', isRequired: false, sortOrder: 2 },
  { categorySlug: 'men-accessories', attributeSlug: 'material-fashion', isRequired: false, sortOrder: 3 },

  // ============================================
  // KIDS GIRLS - Level 2
  // ============================================
  { categorySlug: 'kids-girls', attributeSlug: 'size-kids-clothing', isRequired: true, sortOrder: 1 },
  { categorySlug: 'kids-girls', attributeSlug: 'brand-fashion', isRequired: false, sortOrder: 2 },
  { categorySlug: 'kids-girls', attributeSlug: 'color', isRequired: false, sortOrder: 3 },

  // ============================================
  // KIDS BOYS - Level 2
  // ============================================
  { categorySlug: 'kids-boys', attributeSlug: 'size-kids-clothing', isRequired: true, sortOrder: 1 },
  { categorySlug: 'kids-boys', attributeSlug: 'brand-fashion', isRequired: false, sortOrder: 2 },
  { categorySlug: 'kids-boys', attributeSlug: 'color', isRequired: false, sortOrder: 3 },

  // ============================================
  // KIDS BABY - Level 2
  // ============================================
  { categorySlug: 'kids-baby', attributeSlug: 'size-kids-clothing', isRequired: true, sortOrder: 1 },
  { categorySlug: 'kids-baby', attributeSlug: 'brand-fashion', isRequired: false, sortOrder: 2 },
  { categorySlug: 'kids-baby', attributeSlug: 'color', isRequired: false, sortOrder: 3 },

  // ============================================
  // KIDS SHOES (L3 specific)
  // ============================================
  { categorySlug: 'girls-shoes', attributeSlug: 'size-kids-shoes-eu', isRequired: true, sortOrder: 1 },
  { categorySlug: 'boys-shoes', attributeSlug: 'size-kids-shoes-eu', isRequired: true, sortOrder: 1 },
  { categorySlug: 'baby-shoes', attributeSlug: 'size-kids-shoes-eu', isRequired: true, sortOrder: 1 },

  // ============================================
  // HOME - Level 2 categories
  // ============================================
  { categorySlug: 'home-furniture', attributeSlug: 'brand-home', isRequired: false, sortOrder: 1 },
  { categorySlug: 'home-furniture', attributeSlug: 'color', isRequired: false, sortOrder: 2 },
  { categorySlug: 'home-furniture', attributeSlug: 'material-home', isRequired: false, sortOrder: 3 },

  { categorySlug: 'home-decor', attributeSlug: 'brand-home', isRequired: false, sortOrder: 1 },
  { categorySlug: 'home-decor', attributeSlug: 'color', isRequired: false, sortOrder: 2 },
  { categorySlug: 'home-decor', attributeSlug: 'material-home', isRequired: false, sortOrder: 3 },

  { categorySlug: 'home-kitchen', attributeSlug: 'brand-home', isRequired: false, sortOrder: 1 },
  { categorySlug: 'home-kitchen', attributeSlug: 'color', isRequired: false, sortOrder: 2 },
  { categorySlug: 'home-kitchen', attributeSlug: 'material-home', isRequired: false, sortOrder: 3 },

  { categorySlug: 'home-bedding', attributeSlug: 'brand-home', isRequired: false, sortOrder: 1 },
  { categorySlug: 'home-bedding', attributeSlug: 'color', isRequired: false, sortOrder: 2 },
  { categorySlug: 'home-bedding', attributeSlug: 'material-fashion', isRequired: false, sortOrder: 3 },

  { categorySlug: 'home-lighting', attributeSlug: 'brand-home', isRequired: false, sortOrder: 1 },
  { categorySlug: 'home-lighting', attributeSlug: 'color', isRequired: false, sortOrder: 2 },

  // ============================================
  // ELECTRONICS - Phones & Tablets (L2 common attrs)
  // ============================================
  { categorySlug: 'electronics-phones', attributeSlug: 'color', isRequired: false, sortOrder: 2 },
  { categorySlug: 'electronics-phones', attributeSlug: 'storage', isRequired: false, sortOrder: 3 },
  { categorySlug: 'electronics-phones', attributeSlug: 'ram', isRequired: false, sortOrder: 4 },
  { categorySlug: 'electronics-phones', attributeSlug: 'screen-size', isRequired: false, sortOrder: 5 },

  // L3 specific: Smartphones and Tablets use phone brands
  { categorySlug: 'electronics-smartphones', attributeSlug: 'brand-phones', isRequired: true, sortOrder: 1 },
  { categorySlug: 'electronics-tablets', attributeSlug: 'brand-phones', isRequired: true, sortOrder: 1 },

  // ============================================
  // ELECTRONICS - Computers (L2 common attrs)
  // ============================================
  { categorySlug: 'electronics-computers', attributeSlug: 'color', isRequired: false, sortOrder: 2 },
  { categorySlug: 'electronics-computers', attributeSlug: 'storage', isRequired: false, sortOrder: 3 },
  { categorySlug: 'electronics-computers', attributeSlug: 'ram', isRequired: false, sortOrder: 4 },
  { categorySlug: 'electronics-computers', attributeSlug: 'screen-size', isRequired: false, sortOrder: 5 },

  // L3 specific: Laptops and Desktops use laptop brands
  { categorySlug: 'electronics-laptops', attributeSlug: 'brand-laptops', isRequired: true, sortOrder: 1 },
  { categorySlug: 'electronics-desktops', attributeSlug: 'brand-laptops', isRequired: true, sortOrder: 1 },

  // ============================================
  // ELECTRONICS - TV & Audio (L2 common attrs)
  // ============================================
  { categorySlug: 'electronics-tv-audio', attributeSlug: 'color', isRequired: false, sortOrder: 2 },

  // L3 specific: TVs use TV brands, Speakers/Headphones use audio brands
  { categorySlug: 'electronics-tvs', attributeSlug: 'brand-tv', isRequired: true, sortOrder: 1 },
  { categorySlug: 'electronics-tvs', attributeSlug: 'screen-size', isRequired: false, sortOrder: 3 },
  { categorySlug: 'electronics-speakers', attributeSlug: 'brand-audio', isRequired: true, sortOrder: 1 },
  { categorySlug: 'electronics-headphones', attributeSlug: 'brand-audio', isRequired: true, sortOrder: 1 },

  // ============================================
  // ELECTRONICS - Gaming (L2 common attrs)
  // ============================================
  { categorySlug: 'electronics-gaming', attributeSlug: 'color', isRequired: false, sortOrder: 3 },

  // L3 specific: Consoles and Games use console brands and model
  { categorySlug: 'electronics-consoles', attributeSlug: 'brand-consoles', isRequired: true, sortOrder: 1 },
  { categorySlug: 'electronics-consoles', attributeSlug: 'console-model', isRequired: true, sortOrder: 2 },
  { categorySlug: 'electronics-consoles', attributeSlug: 'storage', isRequired: false, sortOrder: 4 },
  { categorySlug: 'electronics-games', attributeSlug: 'brand-consoles', isRequired: true, sortOrder: 1 },
  { categorySlug: 'electronics-games', attributeSlug: 'console-model', isRequired: true, sortOrder: 2 },

  // ============================================
  // ELECTRONICS - Cameras (L2 common attrs)
  // ============================================
  { categorySlug: 'electronics-cameras', attributeSlug: 'color', isRequired: false, sortOrder: 2 },

  // L3 specific: Digital cameras use camera brands
  { categorySlug: 'electronics-digital-cameras', attributeSlug: 'brand-cameras', isRequired: true, sortOrder: 1 },
];

export async function seedAttributes() {
  console.log('Seeding attributes...');

  // Create a map to store created attributes by slug
  const attributeMap = new Map<string, string>();

  // Create attribute definitions and their values
  for (const attr of attributes) {
    // Determine if attribute is active (defaults to true if not specified)
    const isActive = attr.isActive !== false;

    // Create or update the attribute definition
    const definition = await prisma.attributeDefinition.upsert({
      where: { slug: attr.slug },
      update: {
        name: attr.name,
        type: attr.type,
        isRequired: attr.isRequired || false,
        isActive: isActive,
      },
      create: {
        name: attr.name,
        slug: attr.slug,
        type: attr.type,
        isRequired: attr.isRequired || false,
        isActive: isActive,
      },
    });

    attributeMap.set(attr.slug, definition.id);
    const statusLabel = isActive ? '' : ' [DEPRECATED]';
    console.log(`  Created attribute: ${attr.name} (${attr.slug})${statusLabel}`);

    // Create attribute values
    for (let i = 0; i < attr.values.length; i++) {
      const value = attr.values[i];
      const metadata = attr.metadata?.[value] ?? undefined;
      // "Other" always gets sortOrder=999 to appear last
      const sortOrder = value === 'Other' ? 999 : i + 1;

      await prisma.attributeValue.upsert({
        where: {
          attributeId_value: {
            attributeId: definition.id,
            value: value,
          },
        },
        update: {
          sortOrder: sortOrder,
          ...(metadata && { metadata }),
        },
        create: {
          attributeId: definition.id,
          value: value,
          sortOrder: sortOrder,
          ...(metadata && { metadata }),
        },
      });
    }

    console.log(`    -> ${attr.values.length} values`);
  }

  console.log(`Seeded ${attributes.length} attribute definitions.`);
  return attributeMap;
}

export async function seedCategoryAttributeMappings(
  categoryMap: Map<string, string>,
  attributeMap: Map<string, string>,
) {
  console.log('Seeding category-attribute mappings...');

  let created = 0;
  let skipped = 0;

  for (const mapping of categoryAttributeMappings) {
    const categoryId = categoryMap.get(mapping.categorySlug);
    const attributeId = attributeMap.get(mapping.attributeSlug);

    if (!categoryId) {
      console.warn(`  Category not found: ${mapping.categorySlug}`);
      skipped++;
      continue;
    }

    if (!attributeId) {
      console.warn(`  Attribute not found: ${mapping.attributeSlug}`);
      skipped++;
      continue;
    }

    await prisma.categoryAttribute.upsert({
      where: {
        categoryId_attributeId: {
          categoryId,
          attributeId,
        },
      },
      update: {
        isRequired: mapping.isRequired || false,
        sortOrder: mapping.sortOrder,
      },
      create: {
        categoryId,
        attributeId,
        isRequired: mapping.isRequired || false,
        sortOrder: mapping.sortOrder,
      },
    });

    created++;
  }

  console.log(`Seeded ${created} category-attribute mappings (${skipped} skipped).`);
}

export { attributes, categoryAttributeMappings };
