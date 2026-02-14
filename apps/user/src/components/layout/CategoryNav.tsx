'use client';

import { useState, useEffect, useRef, useCallback } from 'react';
import Link from 'next/link';
import { useSearchParams } from 'next/navigation';
import { api } from '@/lib/api';
import type { Category } from '@/types';

const categoryImages: Record<string, string> = {
  women: 'https://images.unsplash.com/photo-1483985988355-763728e1935b?w=800&q=80',
  men: 'https://images.unsplash.com/photo-1490578474895-699cd4e2cf59?w=800&q=80',
  kids: 'https://images.unsplash.com/photo-1503919545889-aef636e10ad4?w=800&q=80',
  home: 'https://images.unsplash.com/photo-1616046229478-9901c5536a45?w=800&q=80',
  electronics: 'https://images.unsplash.com/photo-1468495244123-6c6c332eeece?w=800&q=80',
};

export function CategoryNav() {
  const searchParams = useSearchParams();
  const activeCategoryId = searchParams.get('categoryId') || '';
  const [categories, setCategories] = useState<Category[]>([]);
  const [hoveredCategory, setHoveredCategory] = useState<string | null>(null);
  const hoverTimeoutRef = useRef<NodeJS.Timeout | null>(null);
  const navRef = useRef<HTMLDivElement>(null);

  useEffect(() => {
    async function loadCategories() {
      try {
        const cats = await api.getCategories();
        setCategories(cats);
      } catch (error) {
        console.error('Failed to load categories:', error);
      }
    }
    loadCategories();
  }, []);

  const mainCategories = categories.filter(cat => cat.level === 1 && cat.isActive);

  const handleMouseEnter = useCallback((categoryId: string) => {
    if (hoverTimeoutRef.current) {
      clearTimeout(hoverTimeoutRef.current);
    }
    hoverTimeoutRef.current = setTimeout(() => {
      setHoveredCategory(categoryId);
    }, 100);
  }, []);

  const handleMouseLeave = useCallback(() => {
    if (hoverTimeoutRef.current) {
      clearTimeout(hoverTimeoutRef.current);
    }
    hoverTimeoutRef.current = setTimeout(() => {
      setHoveredCategory(null);
    }, 150);
  }, []);

  const handleDropdownEnter = useCallback(() => {
    if (hoverTimeoutRef.current) {
      clearTimeout(hoverTimeoutRef.current);
    }
  }, []);

  useEffect(() => {
    return () => {
      if (hoverTimeoutRef.current) {
        clearTimeout(hoverTimeoutRef.current);
      }
    };
  }, []);

  const hoveredCategoryData = mainCategories.find(c => c.id === hoveredCategory);
  const subcategories = hoveredCategoryData?.children?.filter(c => c.isActive) || [];
  const categoryImage = hoveredCategoryData ? categoryImages[hoveredCategoryData.slug] : null;

  if (mainCategories.length === 0) return null;

  return (
    <nav ref={navRef} className="hidden md:block bg-white border-b border-gray-100 relative">
      <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8">
        <ul className="flex items-center gap-1 h-12">
          {mainCategories.map((category) => {
            const isActive = activeCategoryId === category.id ||
              category.children?.some(c => c.id === activeCategoryId);
            const isHovered = hoveredCategory === category.id;

            return (
              <li
                key={category.id}
                className="relative"
                onMouseEnter={() => handleMouseEnter(category.id)}
                onMouseLeave={handleMouseLeave}
              >
                <Link
                  href={`/explore?categoryId=${category.id}`}
                  className={`block px-4 py-2 text-sm font-medium transition-colors ${
                    isActive || isHovered
                      ? 'text-primary-500'
                      : 'text-gray-700 hover:text-primary-500'
                  }`}
                >
                  {category.name}
                </Link>
                {(isActive || isHovered) && (
                  <div className="absolute bottom-0 left-4 right-4 h-0.5 bg-primary-500" />
                )}
              </li>
            );
          })}
        </ul>
      </div>

      {/* Mega Menu Dropdown */}
      {hoveredCategory && subcategories.length > 0 && (
        <div
          className="absolute left-0 right-0 bg-white border-b border-gray-200 shadow-lg z-40"
          onMouseEnter={handleDropdownEnter}
          onMouseLeave={handleMouseLeave}
        >
          <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 py-6">
            <div className="flex gap-8">
              {/* Left: Subcategory List */}
              <div className="flex-shrink-0 w-56">
                <h3 className="text-sm font-semibold text-gray-900 mb-3">
                  Top categories
                </h3>
                <ul className="space-y-0.5">
                  {subcategories.map((sub) => {
                    const isActive = activeCategoryId === sub.id;
                    return (
                      <li key={sub.id}>
                        <Link
                          href={`/explore?categoryId=${sub.id}`}
                          className={`block py-1.5 text-sm transition-colors ${
                            isActive
                              ? 'text-primary-500 font-medium'
                              : 'text-gray-600 hover:text-primary-500'
                          }`}
                        >
                          {sub.name}
                        </Link>
                      </li>
                    );
                  })}
                </ul>
              </div>

              {/* Right: Landscape Banner Image */}
              {categoryImage && (
                <div className="hidden lg:flex flex-1 min-h-0">
                  <Link
                    href={`/explore?categoryId=${hoveredCategoryData?.id}`}
                    className="relative w-full rounded-xl overflow-hidden bg-gray-100 block"
                  >
                    <img
                      src={categoryImage}
                      alt={`${hoveredCategoryData?.name} collection`}
                      className="w-full h-full object-cover"
                      style={{ minHeight: '220px', maxHeight: '280px' }}
                    />
                    <div className="absolute inset-0 bg-gradient-to-r from-black/50 to-transparent" />
                    <div className="absolute bottom-6 left-6">
                      <h4 className="text-2xl font-bold text-white mb-3">
                        {hoveredCategoryData?.name}
                      </h4>
                      <span className="inline-flex items-center gap-1.5 px-4 py-2 bg-white text-gray-900 text-sm font-semibold rounded-full">
                        Shop now
                        <svg className="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                          <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M9 5l7 7-7 7" />
                        </svg>
                      </span>
                    </div>
                  </Link>
                </div>
              )}
            </div>
          </div>
        </div>
      )}
    </nav>
  );
}

export default CategoryNav;
