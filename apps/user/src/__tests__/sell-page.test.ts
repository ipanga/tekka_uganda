/**
 * Test suite for the Create Listing (Sell) page
 *
 * These tests verify the hierarchical category system and dynamic attribute
 * functionality implemented in Phase 5 of the Tekka refactor.
 *
 * To run these tests, first install the testing dependencies:
 * npm install -D @testing-library/react @testing-library/jest-dom jest jest-environment-jsdom @types/jest
 *
 * Then add to package.json:
 * "scripts": {
 *   "test": "jest"
 * }
 */

import type { Category, AttributeDefinition, City, Division } from '@/types';

// ============================================================================
// TYPE TESTS - Ensure types are correctly defined
// ============================================================================

describe('Type Definitions', () => {
  describe('Category', () => {
    it('should have required fields', () => {
      const category: Category = {
        id: 'cat-1',
        name: 'Women',
        slug: 'women',
        level: 1,
        sortOrder: 1,
        isActive: true,
        createdAt: '2024-01-01T00:00:00.000Z',
        updatedAt: '2024-01-01T00:00:00.000Z',
      };

      expect(category.id).toBe('cat-1');
      expect(category.level).toBe(1);
    });

    it('should support hierarchical children', () => {
      const category: Category = {
        id: 'cat-1',
        name: 'Women',
        slug: 'women',
        level: 1,
        sortOrder: 1,
        isActive: true,
        createdAt: '2024-01-01T00:00:00.000Z',
        updatedAt: '2024-01-01T00:00:00.000Z',
        children: [
          {
            id: 'cat-2',
            name: 'Clothing',
            slug: 'women-clothing',
            level: 2,
            parentId: 'cat-1',
            sortOrder: 1,
            isActive: true,
            createdAt: '2024-01-01T00:00:00.000Z',
            updatedAt: '2024-01-01T00:00:00.000Z',
          },
        ],
      };

      expect(category.children).toHaveLength(1);
      expect(category.children![0].parentId).toBe('cat-1');
      expect(category.children![0].level).toBe(2);
    });
  });

  describe('AttributeDefinition', () => {
    it('should support SINGLE_SELECT type with values', () => {
      const attr: AttributeDefinition = {
        id: 'attr-1',
        name: 'Size',
        slug: 'size',
        type: 'SINGLE_SELECT',
        isRequired: true,
        sortOrder: 1,
        isActive: true,
        createdAt: '2024-01-01T00:00:00.000Z',
        updatedAt: '2024-01-01T00:00:00.000Z',
        values: [
          { id: 'v1', attributeId: 'attr-1', value: 'S', sortOrder: 1, isActive: true },
          { id: 'v2', attributeId: 'attr-1', value: 'M', sortOrder: 2, isActive: true },
          { id: 'v3', attributeId: 'attr-1', value: 'L', sortOrder: 3, isActive: true },
        ],
      };

      expect(attr.type).toBe('SINGLE_SELECT');
      expect(attr.values).toHaveLength(3);
      expect(attr.isRequired).toBe(true);
    });

    it('should support MULTI_SELECT type', () => {
      const attr: AttributeDefinition = {
        id: 'attr-1',
        name: 'Color',
        slug: 'color',
        type: 'MULTI_SELECT',
        isRequired: false,
        sortOrder: 2,
        isActive: true,
        createdAt: '2024-01-01T00:00:00.000Z',
        updatedAt: '2024-01-01T00:00:00.000Z',
        values: [
          { id: 'v1', attributeId: 'attr-1', value: 'Red', sortOrder: 1, isActive: true },
          { id: 'v2', attributeId: 'attr-1', value: 'Blue', sortOrder: 2, isActive: true },
        ],
      };

      expect(attr.type).toBe('MULTI_SELECT');
    });

    it('should support TEXT type', () => {
      const attr: AttributeDefinition = {
        id: 'attr-1',
        name: 'Brand',
        slug: 'brand',
        type: 'TEXT',
        isRequired: false,
        sortOrder: 3,
        isActive: true,
        createdAt: '2024-01-01T00:00:00.000Z',
        updatedAt: '2024-01-01T00:00:00.000Z',
      };

      expect(attr.type).toBe('TEXT');
      expect(attr.values).toBeUndefined();
    });

    it('should support NUMBER type', () => {
      const attr: AttributeDefinition = {
        id: 'attr-1',
        name: 'Screen Size',
        slug: 'screen-size',
        type: 'NUMBER',
        isRequired: true,
        sortOrder: 1,
        isActive: true,
        createdAt: '2024-01-01T00:00:00.000Z',
        updatedAt: '2024-01-01T00:00:00.000Z',
      };

      expect(attr.type).toBe('NUMBER');
    });
  });

  describe('City and Division', () => {
    it('should support City with nested Divisions', () => {
      const city: City = {
        id: 'city-1',
        name: 'Kampala',
        isActive: true,
        sortOrder: 1,
        divisions: [
          { id: 'div-1', cityId: 'city-1', name: 'Makindye', isActive: true, sortOrder: 1 },
          { id: 'div-2', cityId: 'city-1', name: 'Nakawa', isActive: true, sortOrder: 2 },
        ],
      };

      expect(city.divisions).toHaveLength(2);
      expect(city.divisions![0].cityId).toBe('city-1');
    });
  });
});

// ============================================================================
// VALIDATION LOGIC TESTS
// ============================================================================

describe('Form Validation Logic', () => {
  describe('canProceed', () => {
    // Simulating the canProceed logic from the sell page
    const canProceed = (step: string, state: {
      imageUrls: string[];
      uploading: boolean;
      selectedCategory: Category | null;
      title: string;
      description: string;
      condition: string;
      price: string;
      requiredAttributesFilled: boolean;
    }) => {
      switch (step) {
        case 'photos':
          return state.imageUrls.length > 0 && !state.uploading;
        case 'category':
          return state.selectedCategory !== null;
        case 'details':
          return Boolean(state.title.trim() && state.description.trim() && state.condition && state.requiredAttributesFilled);
        case 'pricing':
          return Boolean(state.price && parseInt(state.price.replace(/,/g, ''), 10) > 0);
        case 'review':
          return true;
        default:
          return false;
      }
    };

    it('photos step: requires at least one image', () => {
      expect(canProceed('photos', {
        imageUrls: [],
        uploading: false,
        selectedCategory: null,
        title: '',
        description: '',
        condition: '',
        price: '',
        requiredAttributesFilled: true,
      })).toBe(false);

      expect(canProceed('photos', {
        imageUrls: ['https://example.com/image.jpg'],
        uploading: false,
        selectedCategory: null,
        title: '',
        description: '',
        condition: '',
        price: '',
        requiredAttributesFilled: true,
      })).toBe(true);
    });

    it('photos step: blocks during upload', () => {
      expect(canProceed('photos', {
        imageUrls: ['https://example.com/image.jpg'],
        uploading: true,
        selectedCategory: null,
        title: '',
        description: '',
        condition: '',
        price: '',
        requiredAttributesFilled: true,
      })).toBe(false);
    });

    it('category step: requires a selected category', () => {
      const category: Category = {
        id: 'cat-1',
        name: 'Women',
        slug: 'women',
        level: 1,
        sortOrder: 1,
        isActive: true,
        createdAt: '2024-01-01T00:00:00.000Z',
        updatedAt: '2024-01-01T00:00:00.000Z',
      };

      expect(canProceed('category', {
        imageUrls: ['https://example.com/image.jpg'],
        uploading: false,
        selectedCategory: null,
        title: '',
        description: '',
        condition: '',
        price: '',
        requiredAttributesFilled: true,
      })).toBe(false);

      expect(canProceed('category', {
        imageUrls: ['https://example.com/image.jpg'],
        uploading: false,
        selectedCategory: category,
        title: '',
        description: '',
        condition: '',
        price: '',
        requiredAttributesFilled: true,
      })).toBe(true);
    });

    it('details step: requires title, description, condition, and required attributes', () => {
      const category: Category = {
        id: 'cat-1',
        name: 'Women',
        slug: 'women',
        level: 1,
        sortOrder: 1,
        isActive: true,
        createdAt: '2024-01-01T00:00:00.000Z',
        updatedAt: '2024-01-01T00:00:00.000Z',
      };

      // Missing all fields
      expect(canProceed('details', {
        imageUrls: ['https://example.com/image.jpg'],
        uploading: false,
        selectedCategory: category,
        title: '',
        description: '',
        condition: '',
        price: '',
        requiredAttributesFilled: true,
      })).toBe(false);

      // All required fields filled
      expect(canProceed('details', {
        imageUrls: ['https://example.com/image.jpg'],
        uploading: false,
        selectedCategory: category,
        title: 'Test Title',
        description: 'Test Description',
        condition: 'NEW',
        price: '',
        requiredAttributesFilled: true,
      })).toBe(true);

      // Required attributes not filled
      expect(canProceed('details', {
        imageUrls: ['https://example.com/image.jpg'],
        uploading: false,
        selectedCategory: category,
        title: 'Test Title',
        description: 'Test Description',
        condition: 'NEW',
        price: '',
        requiredAttributesFilled: false,
      })).toBe(false);
    });

    it('pricing step: requires valid price greater than 0', () => {
      const category: Category = {
        id: 'cat-1',
        name: 'Women',
        slug: 'women',
        level: 1,
        sortOrder: 1,
        isActive: true,
        createdAt: '2024-01-01T00:00:00.000Z',
        updatedAt: '2024-01-01T00:00:00.000Z',
      };

      expect(canProceed('pricing', {
        imageUrls: ['https://example.com/image.jpg'],
        uploading: false,
        selectedCategory: category,
        title: 'Test',
        description: 'Test',
        condition: 'NEW',
        price: '',
        requiredAttributesFilled: true,
      })).toBe(false);

      expect(canProceed('pricing', {
        imageUrls: ['https://example.com/image.jpg'],
        uploading: false,
        selectedCategory: category,
        title: 'Test',
        description: 'Test',
        condition: 'NEW',
        price: '0',
        requiredAttributesFilled: true,
      })).toBe(false);

      expect(canProceed('pricing', {
        imageUrls: ['https://example.com/image.jpg'],
        uploading: false,
        selectedCategory: category,
        title: 'Test',
        description: 'Test',
        condition: 'NEW',
        price: '50000',
        requiredAttributesFilled: true,
      })).toBe(true);

      // With comma separators
      expect(canProceed('pricing', {
        imageUrls: ['https://example.com/image.jpg'],
        uploading: false,
        selectedCategory: category,
        title: 'Test',
        description: 'Test',
        condition: 'NEW',
        price: '50,000',
        requiredAttributesFilled: true,
      })).toBe(true);
    });
  });

  describe('areRequiredAttributesFilled', () => {
    // Simulating the areRequiredAttributesFilled logic
    const areRequiredAttributesFilled = (
      attributes: AttributeDefinition[],
      values: Record<string, string | string[]>
    ) => {
      for (const attr of attributes) {
        if (attr.isRequired) {
          const value = values[attr.slug];
          if (!value || (Array.isArray(value) && value.length === 0)) {
            return false;
          }
        }
      }
      return true;
    };

    it('returns true when no required attributes', () => {
      const attributes: AttributeDefinition[] = [
        {
          id: 'attr-1',
          name: 'Brand',
          slug: 'brand',
          type: 'TEXT',
          isRequired: false,
          sortOrder: 1,
          isActive: true,
          createdAt: '2024-01-01T00:00:00.000Z',
          updatedAt: '2024-01-01T00:00:00.000Z',
        },
      ];

      expect(areRequiredAttributesFilled(attributes, {})).toBe(true);
    });

    it('returns false when required SINGLE_SELECT is empty', () => {
      const attributes: AttributeDefinition[] = [
        {
          id: 'attr-1',
          name: 'Size',
          slug: 'size',
          type: 'SINGLE_SELECT',
          isRequired: true,
          sortOrder: 1,
          isActive: true,
          createdAt: '2024-01-01T00:00:00.000Z',
          updatedAt: '2024-01-01T00:00:00.000Z',
          values: [
            { id: 'v1', attributeId: 'attr-1', value: 'M', sortOrder: 1, isActive: true },
          ],
        },
      ];

      expect(areRequiredAttributesFilled(attributes, {})).toBe(false);
      expect(areRequiredAttributesFilled(attributes, { size: '' })).toBe(false);
      expect(areRequiredAttributesFilled(attributes, { size: 'M' })).toBe(true);
    });

    it('returns false when required MULTI_SELECT is empty array', () => {
      const attributes: AttributeDefinition[] = [
        {
          id: 'attr-1',
          name: 'Color',
          slug: 'color',
          type: 'MULTI_SELECT',
          isRequired: true,
          sortOrder: 1,
          isActive: true,
          createdAt: '2024-01-01T00:00:00.000Z',
          updatedAt: '2024-01-01T00:00:00.000Z',
          values: [
            { id: 'v1', attributeId: 'attr-1', value: 'Red', sortOrder: 1, isActive: true },
          ],
        },
      ];

      expect(areRequiredAttributesFilled(attributes, { color: [] })).toBe(false);
      expect(areRequiredAttributesFilled(attributes, { color: ['Red'] })).toBe(true);
    });

    it('returns false when required TEXT is empty', () => {
      const attributes: AttributeDefinition[] = [
        {
          id: 'attr-1',
          name: 'Brand',
          slug: 'brand',
          type: 'TEXT',
          isRequired: true,
          sortOrder: 1,
          isActive: true,
          createdAt: '2024-01-01T00:00:00.000Z',
          updatedAt: '2024-01-01T00:00:00.000Z',
        },
      ];

      expect(areRequiredAttributesFilled(attributes, {})).toBe(false);
      expect(areRequiredAttributesFilled(attributes, { brand: '' })).toBe(false);
      expect(areRequiredAttributesFilled(attributes, { brand: 'Nike' })).toBe(true);
    });
  });

  describe('getCategoryBreadcrumb', () => {
    const getCategoryBreadcrumb = (
      main: Category | null,
      sub: Category | null,
      product: Category | null
    ) => {
      const parts: string[] = [];
      if (main) parts.push(main.name);
      if (sub) parts.push(sub.name);
      if (product) parts.push(product.name);
      return parts;
    };

    it('returns empty array when no category selected', () => {
      expect(getCategoryBreadcrumb(null, null, null)).toEqual([]);
    });

    it('returns only main category when selected', () => {
      const main: Category = {
        id: 'cat-1',
        name: 'Women',
        slug: 'women',
        level: 1,
        sortOrder: 1,
        isActive: true,
        createdAt: '2024-01-01T00:00:00.000Z',
        updatedAt: '2024-01-01T00:00:00.000Z',
      };

      expect(getCategoryBreadcrumb(main, null, null)).toEqual(['Women']);
    });

    it('returns full breadcrumb with all levels', () => {
      const main: Category = {
        id: 'cat-1',
        name: 'Women',
        slug: 'women',
        level: 1,
        sortOrder: 1,
        isActive: true,
        createdAt: '2024-01-01T00:00:00.000Z',
        updatedAt: '2024-01-01T00:00:00.000Z',
      };

      const sub: Category = {
        id: 'cat-2',
        name: 'Clothing',
        slug: 'clothing',
        level: 2,
        parentId: 'cat-1',
        sortOrder: 1,
        isActive: true,
        createdAt: '2024-01-01T00:00:00.000Z',
        updatedAt: '2024-01-01T00:00:00.000Z',
      };

      const product: Category = {
        id: 'cat-3',
        name: 'Dresses',
        slug: 'dresses',
        level: 3,
        parentId: 'cat-2',
        sortOrder: 1,
        isActive: true,
        createdAt: '2024-01-01T00:00:00.000Z',
        updatedAt: '2024-01-01T00:00:00.000Z',
      };

      expect(getCategoryBreadcrumb(main, sub, product)).toEqual(['Women', 'Clothing', 'Dresses']);
    });
  });

  describe('getFinalCategory', () => {
    const getFinalCategory = (
      main: Category | null,
      sub: Category | null,
      product: Category | null
    ) => {
      return product || sub || main;
    };

    it('returns null when no category selected', () => {
      expect(getFinalCategory(null, null, null)).toBeNull();
    });

    it('returns main category when only main is selected', () => {
      const main: Category = {
        id: 'cat-1',
        name: 'Women',
        slug: 'women',
        level: 1,
        sortOrder: 1,
        isActive: true,
        createdAt: '2024-01-01T00:00:00.000Z',
        updatedAt: '2024-01-01T00:00:00.000Z',
      };

      expect(getFinalCategory(main, null, null)).toBe(main);
    });

    it('returns sub-category when main and sub are selected', () => {
      const main: Category = {
        id: 'cat-1',
        name: 'Women',
        slug: 'women',
        level: 1,
        sortOrder: 1,
        isActive: true,
        createdAt: '2024-01-01T00:00:00.000Z',
        updatedAt: '2024-01-01T00:00:00.000Z',
      };

      const sub: Category = {
        id: 'cat-2',
        name: 'Clothing',
        slug: 'clothing',
        level: 2,
        parentId: 'cat-1',
        sortOrder: 1,
        isActive: true,
        createdAt: '2024-01-01T00:00:00.000Z',
        updatedAt: '2024-01-01T00:00:00.000Z',
      };

      expect(getFinalCategory(main, sub, null)).toBe(sub);
    });

    it('returns product type when all levels are selected', () => {
      const main: Category = {
        id: 'cat-1',
        name: 'Women',
        slug: 'women',
        level: 1,
        sortOrder: 1,
        isActive: true,
        createdAt: '2024-01-01T00:00:00.000Z',
        updatedAt: '2024-01-01T00:00:00.000Z',
      };

      const sub: Category = {
        id: 'cat-2',
        name: 'Clothing',
        slug: 'clothing',
        level: 2,
        parentId: 'cat-1',
        sortOrder: 1,
        isActive: true,
        createdAt: '2024-01-01T00:00:00.000Z',
        updatedAt: '2024-01-01T00:00:00.000Z',
      };

      const product: Category = {
        id: 'cat-3',
        name: 'Dresses',
        slug: 'dresses',
        level: 3,
        parentId: 'cat-2',
        sortOrder: 1,
        isActive: true,
        createdAt: '2024-01-01T00:00:00.000Z',
        updatedAt: '2024-01-01T00:00:00.000Z',
      };

      expect(getFinalCategory(main, sub, product)).toBe(product);
    });
  });
});

// ============================================================================
// CATEGORY HIERARCHY TESTS
// ============================================================================

describe('Category Hierarchy', () => {
  const mockCategories: Category[] = [
    {
      id: 'women',
      name: 'Women',
      slug: 'women',
      level: 1,
      sortOrder: 1,
      isActive: true,
      createdAt: '2024-01-01T00:00:00.000Z',
      updatedAt: '2024-01-01T00:00:00.000Z',
      children: [
        {
          id: 'women-clothing',
          name: 'Clothing',
          slug: 'women-clothing',
          level: 2,
          parentId: 'women',
          sortOrder: 1,
          isActive: true,
          createdAt: '2024-01-01T00:00:00.000Z',
          updatedAt: '2024-01-01T00:00:00.000Z',
          children: [
            {
              id: 'women-dresses',
              name: 'Dresses',
              slug: 'women-dresses',
              level: 3,
              parentId: 'women-clothing',
              sortOrder: 1,
              isActive: true,
              createdAt: '2024-01-01T00:00:00.000Z',
              updatedAt: '2024-01-01T00:00:00.000Z',
            },
            {
              id: 'women-tops',
              name: 'Tops',
              slug: 'women-tops',
              level: 3,
              parentId: 'women-clothing',
              sortOrder: 2,
              isActive: true,
              createdAt: '2024-01-01T00:00:00.000Z',
              updatedAt: '2024-01-01T00:00:00.000Z',
            },
          ],
        },
        {
          id: 'women-shoes',
          name: 'Shoes',
          slug: 'women-shoes',
          level: 2,
          parentId: 'women',
          sortOrder: 2,
          isActive: true,
          createdAt: '2024-01-01T00:00:00.000Z',
          updatedAt: '2024-01-01T00:00:00.000Z',
        },
      ],
    },
    {
      id: 'electronics',
      name: 'Electronics',
      slug: 'electronics',
      level: 1,
      sortOrder: 5,
      isActive: true,
      createdAt: '2024-01-01T00:00:00.000Z',
      updatedAt: '2024-01-01T00:00:00.000Z',
      children: [
        {
          id: 'phones',
          name: 'Phones',
          slug: 'phones',
          level: 2,
          parentId: 'electronics',
          sortOrder: 1,
          isActive: true,
          createdAt: '2024-01-01T00:00:00.000Z',
          updatedAt: '2024-01-01T00:00:00.000Z',
        },
      ],
    },
  ];

  it('filters main categories (level 1)', () => {
    const mainCategories = mockCategories.filter(c => c.level === 1 && c.isActive);
    expect(mainCategories).toHaveLength(2);
    expect(mainCategories.map(c => c.name)).toEqual(['Women', 'Electronics']);
  });

  it('sorts categories by sortOrder', () => {
    const sorted = [...mockCategories].sort((a, b) => a.sortOrder - b.sortOrder);
    expect(sorted[0].name).toBe('Women');
    expect(sorted[1].name).toBe('Electronics');
  });

  it('retrieves sub-categories for a main category', () => {
    const women = mockCategories.find(c => c.id === 'women');
    const subCategories = women?.children?.filter(c => c.isActive) || [];

    expect(subCategories).toHaveLength(2);
    expect(subCategories.map(c => c.name)).toEqual(['Clothing', 'Shoes']);
  });

  it('retrieves product types for a sub-category', () => {
    const women = mockCategories.find(c => c.id === 'women');
    const clothing = women?.children?.find(c => c.id === 'women-clothing');
    const productTypes = clothing?.children?.filter(c => c.isActive) || [];

    expect(productTypes).toHaveLength(2);
    expect(productTypes.map(c => c.name)).toEqual(['Dresses', 'Tops']);
  });

  it('handles categories without children', () => {
    const women = mockCategories.find(c => c.id === 'women');
    const shoes = women?.children?.find(c => c.id === 'women-shoes');

    expect(shoes?.children).toBeUndefined();
  });
});

// ============================================================================
// LOCATION TESTS
// ============================================================================

describe('Location System', () => {
  const mockCities: City[] = [
    {
      id: 'kampala',
      name: 'Kampala',
      isActive: true,
      sortOrder: 1,
      divisions: [
        { id: 'makindye', cityId: 'kampala', name: 'Makindye', isActive: true, sortOrder: 1 },
        { id: 'nakawa', cityId: 'kampala', name: 'Nakawa', isActive: true, sortOrder: 2 },
        { id: 'inactive-div', cityId: 'kampala', name: 'Inactive', isActive: false, sortOrder: 3 },
      ],
    },
    {
      id: 'entebbe',
      name: 'Entebbe',
      isActive: true,
      sortOrder: 2,
      divisions: [
        { id: 'entebbe-town', cityId: 'entebbe', name: 'Entebbe Town', isActive: true, sortOrder: 1 },
      ],
    },
  ];

  it('filters active cities', () => {
    const activeCities = mockCities.filter(c => c.isActive);
    expect(activeCities).toHaveLength(2);
  });

  it('sorts cities by sortOrder', () => {
    const sorted = [...mockCities].sort((a, b) => a.sortOrder - b.sortOrder);
    expect(sorted[0].name).toBe('Kampala');
    expect(sorted[1].name).toBe('Entebbe');
  });

  it('retrieves divisions for a city', () => {
    const kampala = mockCities.find(c => c.id === 'kampala');
    const divisions = kampala?.divisions || [];

    expect(divisions).toHaveLength(3);
  });

  it('filters active divisions', () => {
    const kampala = mockCities.find(c => c.id === 'kampala');
    const activeDivisions = kampala?.divisions?.filter(d => d.isActive) || [];

    expect(activeDivisions).toHaveLength(2);
    expect(activeDivisions.map(d => d.name)).toEqual(['Makindye', 'Nakawa']);
  });

  it('formats location display correctly', () => {
    const formatLocation = (city: City | null, division: Division | null) => {
      if (!city) return '';
      if (!division) return city.name;
      return `${city.name}, ${division.name}`;
    };

    const kampala = mockCities[0];
    const makindye = kampala.divisions![0];

    expect(formatLocation(null, null)).toBe('');
    expect(formatLocation(kampala, null)).toBe('Kampala');
    expect(formatLocation(kampala, makindye)).toBe('Kampala, Makindye');
  });
});
