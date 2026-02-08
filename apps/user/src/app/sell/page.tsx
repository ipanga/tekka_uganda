'use client';

import { useState, useEffect, useRef, useCallback } from 'react';
import { useRouter } from 'next/navigation';
import Image from 'next/image';
import {
  ArrowLeftIcon,
  XMarkIcon,
  PlusIcon,
  ChevronRightIcon,
} from '@heroicons/react/24/outline';
import { api } from '@/lib/api';
import { authManager } from '@/lib/auth';
import {
  ItemCondition,
  CONDITION_LABELS,
  Category,
  AttributeDefinition,
  City,
  Division,
} from '@/types';
import Header from '@/components/layout/Header';
import Footer from '@/components/layout/Footer';
import { Button } from '@/components/ui/Button';
import { Input } from '@/components/ui/Input';
import { Textarea } from '@/components/ui/Textarea';
import { Select } from '@/components/ui/Select';
import { Card, CardContent, CardHeader, CardTitle } from '@/components/ui/Card';
import { PageLoader } from '@/components/ui/Spinner';
import { Combobox } from '@/components/ui/Combobox';
import { useAuthStore } from '@/stores/authStore';

type Step = 'photos' | 'category' | 'details' | 'pricing' | 'review';

const STEPS: Step[] = ['photos', 'category', 'details', 'pricing', 'review'];

const CONDITION_OPTIONS = Object.entries(CONDITION_LABELS).map(([value, label]) => ({
  value,
  label,
}));

export default function CreateListingPage() {
  const router = useRouter();
  const { isAuthenticated, isLoading: authLoading } = useAuthStore();

  const [currentStep, setCurrentStep] = useState<Step>('photos');
  const [loading, setLoading] = useState(false);
  const [uploading, setUploading] = useState(false);
  const [error, setError] = useState<string | null>(null);
  const fileInputRef = useRef<HTMLInputElement>(null);

  // Form state
  const [imageUrls, setImageUrls] = useState<string[]>([]);
  const [title, setTitle] = useState('');
  const [description, setDescription] = useState('');
  const [condition, setCondition] = useState<ItemCondition | ''>('');
  const [price, setPrice] = useState('');
  const [originalPrice, setOriginalPrice] = useState('');

  // New hierarchical category state
  const [categories, setCategories] = useState<Category[]>([]);
  const [categoriesLoading, setCategoriesLoading] = useState(true);
  const [selectedMainCategory, setSelectedMainCategory] = useState<Category | null>(null);
  const [selectedSubCategory, setSelectedSubCategory] = useState<Category | null>(null);
  const [selectedProductType, setSelectedProductType] = useState<Category | null>(null);

  // Dynamic attributes state
  const [categoryAttributes, setCategoryAttributes] = useState<AttributeDefinition[]>([]);
  const [attributesLoading, setAttributesLoading] = useState(false);
  const [attributeValues, setAttributeValues] = useState<Record<string, string | string[]>>({});

  // Location state
  const [cities, setCities] = useState<City[]>([]);
  const [citiesLoading, setCitiesLoading] = useState(true);
  const [selectedCity, setSelectedCity] = useState<City | null>(null);
  const [selectedDivision, setSelectedDivision] = useState<Division | null>(null);

  // Load categories and cities on mount
  useEffect(() => {
    const loadInitialData = async () => {
      try {
        const [categoriesData, citiesData] = await Promise.all([
          api.getCategories(),
          api.getCitiesWithDivisions(),
        ]);
        setCategories(categoriesData);
        setCities(citiesData);
      } catch (err) {
        console.error('Failed to load initial data:', err);
      } finally {
        setCategoriesLoading(false);
        setCitiesLoading(false);
      }
    };

    loadInitialData();
  }, []);

  // Load attributes when product type is selected
  useEffect(() => {
    const loadAttributes = async () => {
      const categoryId = selectedProductType?.id || selectedSubCategory?.id || selectedMainCategory?.id;
      if (!categoryId) {
        setCategoryAttributes([]);
        setAttributeValues({});
        return;
      }

      setAttributesLoading(true);
      try {
        const attributes = await api.getCategoryAttributes(categoryId);
        setCategoryAttributes(attributes);
        // Reset attribute values when category changes
        setAttributeValues({});
      } catch (err) {
        console.error('Failed to load attributes:', err);
        setCategoryAttributes([]);
      } finally {
        setAttributesLoading(false);
      }
    };

    loadAttributes();
  }, [selectedProductType, selectedSubCategory, selectedMainCategory]);

  useEffect(() => {
    if (!authLoading && !isAuthenticated) {
      router.push('/login');
    }
  }, [authLoading, isAuthenticated, router]);

  const currentStepIndex = STEPS.indexOf(currentStep);

  // Get the final selected category (most specific level)
  const getFinalCategory = useCallback(() => {
    return selectedProductType || selectedSubCategory || selectedMainCategory;
  }, [selectedProductType, selectedSubCategory, selectedMainCategory]);

  // Check if all required category levels are selected
  const isCategorySelectionComplete = useCallback(() => {
    // Main category is always required
    if (!selectedMainCategory) return false;

    // If main category has children (sub-categories), one must be selected
    const hasSubCategories = selectedMainCategory.children && selectedMainCategory.children.filter(c => c.isActive).length > 0;
    if (hasSubCategories && !selectedSubCategory) return false;

    // If sub-category has children (product types), one must be selected
    if (selectedSubCategory) {
      const hasProductTypes = selectedSubCategory.children && selectedSubCategory.children.filter(c => c.isActive).length > 0;
      if (hasProductTypes && !selectedProductType) return false;
    }

    return true;
  }, [selectedMainCategory, selectedSubCategory, selectedProductType]);

  // Get category breadcrumb for display
  const getCategoryBreadcrumb = useCallback(() => {
    const parts: string[] = [];
    if (selectedMainCategory) parts.push(selectedMainCategory.name);
    if (selectedSubCategory) parts.push(selectedSubCategory.name);
    if (selectedProductType) parts.push(selectedProductType.name);
    return parts;
  }, [selectedMainCategory, selectedSubCategory, selectedProductType]);

  // Check if all required attributes are filled
  // Note: 'condition' is excluded because it's handled separately as a dedicated form field
  const areRequiredAttributesFilled = useCallback(() => {
    for (const attr of categoryAttributes) {
      if (attr.isRequired && attr.slug !== 'condition') {
        const value = attributeValues[attr.slug];
        if (!value || (Array.isArray(value) && value.length === 0)) {
          return false;
        }
      }
    }
    return true;
  }, [categoryAttributes, attributeValues]);

  const canProceed = () => {
    switch (currentStep) {
      case 'photos':
        return imageUrls.length > 0 && !uploading;
      case 'category':
        return isCategorySelectionComplete();
      case 'details':
        return title.trim() && description.trim() && condition && selectedCity && areRequiredAttributesFilled();
      case 'pricing':
        return price && parseInt(price.replace(/,/g, ''), 10) > 0;
      case 'review':
        return true;
      default:
        return false;
    }
  };

  const handleNext = () => {
    if (currentStepIndex < STEPS.length - 1) {
      setCurrentStep(STEPS[currentStepIndex + 1]);
    }
  };

  const handleBack = () => {
    if (currentStepIndex > 0) {
      setCurrentStep(STEPS[currentStepIndex - 1]);
    }
  };

  const handleAddImageClick = () => {
    fileInputRef.current?.click();
  };

  const handleFileSelect = async (e: React.ChangeEvent<HTMLInputElement>) => {
    const files = e.target.files;
    if (!files || files.length === 0) return;

    if (!authManager.isAuthenticated()) {
      setError('Please log in to upload images');
      return;
    }

    setUploading(true);
    setError(null);

    try {
      const validFiles: File[] = [];
      const maxFiles = Math.min(files.length, 10 - imageUrls.length);

      for (let i = 0; i < maxFiles; i++) {
        const file = files[i];
        if (!file.type.startsWith('image/')) continue;
        if (file.size > 5 * 1024 * 1024) {
          setError('Each image must be less than 5MB');
          continue;
        }
        validFiles.push(file);
      }

      if (validFiles.length === 0) {
        setError('No valid images selected');
        return;
      }

      const { urls } = await api.uploadImages(validFiles);
      setImageUrls([...imageUrls, ...urls]);
    } catch (err) {
      console.error('Upload error:', err);
      setError(err instanceof Error ? err.message : 'Failed to upload images. Please try again.');
    } finally {
      setUploading(false);
      if (fileInputRef.current) {
        fileInputRef.current.value = '';
      }
    }
  };

  const handleRemoveImage = (index: number) => {
    setImageUrls(imageUrls.filter((_, i) => i !== index));
  };

  const handleMainCategorySelect = (category: Category) => {
    setSelectedMainCategory(category);
    setSelectedSubCategory(null);
    setSelectedProductType(null);
  };

  const handleSubCategorySelect = (category: Category) => {
    setSelectedSubCategory(category);
    setSelectedProductType(null);
  };

  const handleProductTypeSelect = (category: Category) => {
    setSelectedProductType(category);
  };

  const handleAttributeChange = (slug: string, value: string | string[]) => {
    setAttributeValues((prev) => ({
      ...prev,
      [slug]: value,
    }));
  };

  const handleSubmit = async (isDraft: boolean = false) => {
    setError(null);

    if (!authManager.isAuthenticated()) {
      router.push('/login');
      return;
    }

    const finalCategory = getFinalCategory();
    if (!finalCategory) {
      setError('Please select a category');
      return;
    }

    // Validate images for non-draft listings
    if (!isDraft && imageUrls.length === 0) {
      setError('Please add at least one photo');
      return;
    }

    setLoading(true);

    try {
      const listing = await api.createListing({
        title: title.trim(),
        description: description.trim(),
        price: parseInt(price.replace(/,/g, ''), 10),
        originalPrice: originalPrice
          ? parseInt(originalPrice.replace(/,/g, ''), 10)
          : undefined,
        condition: condition as ItemCondition,
        imageUrls,
        isDraft,
        // New hierarchical category system
        categoryId: finalCategory.id,
        attributes: attributeValues,
        cityId: selectedCity?.id,
        divisionId: selectedDivision?.id,
      });

      if (!listing || !listing.id) {
        throw new Error('Failed to create listing - invalid response');
      }

      router.push(`/listing/${listing.id}`);
    } catch (err) {
      setError(err instanceof Error ? err.message : 'Failed to create listing');
    } finally {
      setLoading(false);
    }
  };

  // Render attribute field based on type
  const renderAttributeField = (attr: AttributeDefinition) => {
    const value = attributeValues[attr.slug];
    const isRequired = attr.isRequired;

    switch (attr.type) {
      case 'SINGLE_SELECT':
        // Use searchable Combobox for brand fields
        if (attr.slug.startsWith('brand-')) {
          return (
            <Combobox
              label={attr.name}
              options={
                attr.values?.map((v) => ({
                  value: v.value,
                  label: v.displayValue || v.value,
                })) || []
              }
              value={(value as string) || ''}
              onChange={(newValue) => {
                handleAttributeChange(attr.slug, newValue);
                // Clear console-model when console brand changes
                if (attr.slug === 'brand-consoles') {
                  handleAttributeChange('console-model', '');
                }
              }}
              placeholder={`Search ${attr.name.toLowerCase()}...`}
              showRequired={isRequired}
            />
          );
        }

        // Filter console-model options based on selected console brand
        if (attr.slug === 'console-model') {
          const selectedBrand = attributeValues['brand-consoles'] as string;
          const filteredOptions = selectedBrand
            ? attr.values?.filter((v) => {
                // Filter by brand metadata or show "Other" if brand is "Other"
                const brandMeta = v.metadata?.brand;
                return brandMeta === selectedBrand || (selectedBrand === 'Other' && brandMeta === 'Other');
              }) || []
            : [];

          return (
            <Select
              label={attr.name}
              options={filteredOptions.map((v) => ({
                value: v.value,
                label: v.displayValue || v.value,
              }))}
              value={(value as string) || ''}
              onChange={(e) => handleAttributeChange(attr.slug, e.target.value)}
              placeholder={selectedBrand ? `Select ${attr.name.toLowerCase()}` : 'Select console brand first'}
              showRequired={isRequired}
              disabled={!selectedBrand}
            />
          );
        }

        // Regular dropdown for other SINGLE_SELECT
        return (
          <Select
            label={attr.name}
            options={
              attr.values?.map((v) => ({
                value: v.value,
                label: v.displayValue || v.value,
              })) || []
            }
            value={(value as string) || ''}
            onChange={(e) => handleAttributeChange(attr.slug, e.target.value)}
            placeholder={`Select ${attr.name.toLowerCase()}`}
            showRequired={isRequired}
          />
        );

      case 'MULTI_SELECT':
        const selectedValues = (value as string[]) || [];
        return (
          <div className="space-y-2">
            <label className="block text-sm font-medium text-gray-700">
              {attr.name}
              {isRequired && <span className="text-red-500 ml-1">*</span>}
            </label>
            <div className="flex flex-wrap gap-2">
              {attr.values?.map((v, index) => (
                <button
                  key={`${attr.id}-value-${index}`}
                  type="button"
                  onClick={() => {
                    const currentValues = (attributeValues[attr.slug] as string[]) || [];
                    const isCurrentlySelected = currentValues.includes(v.value);
                    const newValues = isCurrentlySelected
                      ? currentValues.filter((val) => val !== v.value)
                      : [...currentValues, v.value];
                    handleAttributeChange(attr.slug, newValues);
                  }}
                  className={`px-3 py-1.5 text-sm rounded-full border transition-colors ${
                    selectedValues.includes(v.value)
                      ? 'bg-pink-600 text-white border-pink-600'
                      : 'bg-white text-gray-700 border-gray-300 hover:border-pink-400'
                  }`}
                >
                  {v.displayValue || v.value}
                </button>
              ))}
            </div>
          </div>
        );

      case 'TEXT':
        return (
          <Input
            label={attr.name}
            value={(value as string) || ''}
            onChange={(e) => handleAttributeChange(attr.slug, e.target.value)}
            placeholder={`Enter ${attr.name.toLowerCase()}`}
            showRequired={isRequired}
          />
        );

      case 'NUMBER':
        return (
          <Input
            label={attr.name}
            type="number"
            value={(value as string) || ''}
            onChange={(e) => handleAttributeChange(attr.slug, e.target.value)}
            placeholder={`Enter ${attr.name.toLowerCase()}`}
            showRequired={isRequired}
          />
        );

      default:
        return null;
    }
  };

  if (authLoading) {
    return (
      <div className="min-h-screen flex flex-col">
        <Header />
        <PageLoader />
        <Footer />
      </div>
    );
  }

  return (
    <div className="min-h-screen flex flex-col bg-gray-50">
      <Header />

      <main className="flex-1 py-8">
        <div className="max-w-2xl mx-auto px-4">
          {/* Back Button */}
          <button
            onClick={() => (currentStepIndex > 0 ? handleBack() : router.back())}
            className="flex items-center gap-2 text-gray-600 hover:text-gray-900 mb-6"
          >
            <ArrowLeftIcon className="w-5 h-5" />
            {currentStepIndex > 0 ? 'Previous step' : 'Cancel'}
          </button>

          {/* Progress Bar */}
          <div className="mb-8">
            <div className="flex items-center justify-between mb-2">
              {STEPS.map((step, index) => (
                <div key={step} className="flex items-center">
                  <div
                    className={`w-8 h-8 rounded-full flex items-center justify-center text-sm font-medium ${
                      index <= currentStepIndex
                        ? 'bg-pink-600 text-white'
                        : 'bg-gray-200 text-gray-500'
                    }`}
                  >
                    {index + 1}
                  </div>
                  {index < STEPS.length - 1 && (
                    <div
                      className={`w-full h-1 mx-1 ${
                        index < currentStepIndex ? 'bg-pink-600' : 'bg-gray-200'
                      }`}
                      style={{ minWidth: '40px' }}
                    />
                  )}
                </div>
              ))}
            </div>
            <div className="flex justify-between text-xs text-gray-500">
              <span>Photos</span>
              <span>Category</span>
              <span>Details</span>
              <span>Pricing</span>
              <span>Review</span>
            </div>
          </div>

          {/* Error Message */}
          {error && (
            <div className="mb-6 p-4 bg-red-50 border border-red-200 rounded-lg">
              <p className="text-sm text-red-600">{error}</p>
            </div>
          )}

          {/* Step 1: Photos */}
          {currentStep === 'photos' && (
            <Card>
              <CardHeader>
                <CardTitle>Add Photos</CardTitle>
              </CardHeader>
              <CardContent>
                <p className="text-gray-500 mb-4">
                  Add up to 10 photos. The first photo will be your cover image.
                </p>

                <input
                  ref={fileInputRef}
                  type="file"
                  accept="image/*"
                  multiple
                  onChange={handleFileSelect}
                  className="hidden"
                />

                <div className="grid grid-cols-3 gap-4">
                  {imageUrls.map((url, index) => (
                    <div key={index} className="relative aspect-square">
                      <Image
                        src={url}
                        alt={`Photo ${index + 1}`}
                        fill
                        className="object-cover rounded-lg"
                      />
                      <button
                        onClick={() => handleRemoveImage(index)}
                        className="absolute -top-2 -right-2 p-1 bg-red-500 text-white rounded-full"
                        disabled={uploading}
                      >
                        <XMarkIcon className="w-4 h-4" />
                      </button>
                      {index === 0 && (
                        <span className="absolute bottom-2 left-2 px-2 py-1 bg-black/50 text-white text-xs rounded">
                          Cover
                        </span>
                      )}
                    </div>
                  ))}

                  {imageUrls.length < 10 && (
                    <button
                      onClick={handleAddImageClick}
                      disabled={uploading}
                      className="aspect-square border-2 border-dashed border-gray-300 rounded-lg flex flex-col items-center justify-center gap-2 hover:border-pink-500 hover:bg-pink-50 transition-colors disabled:opacity-50 disabled:cursor-not-allowed"
                    >
                      {uploading ? (
                        <>
                          <div className="w-8 h-8 border-2 border-pink-600 border-t-transparent rounded-full animate-spin" />
                          <span className="text-sm text-gray-500">Uploading...</span>
                        </>
                      ) : (
                        <>
                          <PlusIcon className="w-8 h-8 text-gray-400" />
                          <span className="text-sm text-gray-500">Add Photo</span>
                        </>
                      )}
                    </button>
                  )}
                </div>

                <p className="text-xs text-gray-400 mt-4">
                  Tip: Use natural lighting and show the item from multiple angles
                </p>
              </CardContent>
            </Card>
          )}

          {/* Step 2: Category Selection */}
          {currentStep === 'category' && (
            <Card>
              <CardHeader>
                <CardTitle>Select Category</CardTitle>
              </CardHeader>
              <CardContent>
                {categoriesLoading ? (
                  <div className="flex items-center justify-center py-12">
                    <div className="w-8 h-8 border-2 border-pink-600 border-t-transparent rounded-full animate-spin" />
                  </div>
                ) : (
                  <div className="space-y-6">
                    {/* Category Breadcrumb */}
                    {getCategoryBreadcrumb().length > 0 && (
                      <div className="flex items-center gap-2 text-sm text-gray-600 bg-gray-100 p-3 rounded-lg">
                        {getCategoryBreadcrumb().map((name, index) => (
                          <span key={index} className="flex items-center gap-2">
                            {index > 0 && <ChevronRightIcon className="w-4 h-4 text-gray-400" />}
                            <span className={index === getCategoryBreadcrumb().length - 1 ? 'font-medium text-pink-600' : ''}>
                              {name}
                            </span>
                          </span>
                        ))}
                      </div>
                    )}

                    {/* Main Categories (Level 1) */}
                    <div>
                      <label className="block text-sm font-medium text-gray-700 mb-3">
                        Main Category <span className="text-red-500">*</span>
                      </label>
                      <div className="grid grid-cols-2 gap-3">
                        {categories
                          .filter((c) => c.level === 1 && c.isActive)
                          .sort((a, b) => a.sortOrder - b.sortOrder)
                          .map((category) => (
                            <button
                              key={category.id}
                              onClick={() => handleMainCategorySelect(category)}
                              className={`p-4 text-left rounded-lg border-2 transition-colors ${
                                selectedMainCategory?.id === category.id
                                  ? 'border-pink-600 bg-pink-50'
                                  : 'border-gray-200 hover:border-pink-300'
                              }`}
                            >
                              <span className="font-medium">{category.name}</span>
                            </button>
                          ))}
                      </div>
                    </div>

                    {/* Sub Categories (Level 2) */}
                    {selectedMainCategory && selectedMainCategory.children && selectedMainCategory.children.length > 0 && (
                      <div>
                        <label className="block text-sm font-medium text-gray-700 mb-3">
                          Sub-Category <span className="text-red-500">*</span>
                        </label>
                        <div className="grid grid-cols-2 gap-3">
                          {selectedMainCategory.children
                            .filter((c) => c.isActive)
                            .sort((a, b) => a.sortOrder - b.sortOrder)
                            .map((category) => (
                              <button
                                key={category.id}
                                onClick={() => handleSubCategorySelect(category)}
                                className={`p-3 text-left rounded-lg border-2 transition-colors ${
                                  selectedSubCategory?.id === category.id
                                    ? 'border-pink-600 bg-pink-50'
                                    : 'border-gray-200 hover:border-pink-300'
                                }`}
                              >
                                <span className="text-sm font-medium">{category.name}</span>
                              </button>
                            ))}
                        </div>
                      </div>
                    )}

                    {/* Product Types (Level 3) */}
                    {selectedSubCategory && selectedSubCategory.children && selectedSubCategory.children.length > 0 && (
                      <div>
                        <label className="block text-sm font-medium text-gray-700 mb-3">
                          Product Type <span className="text-red-500">*</span>
                        </label>
                        <div className="grid grid-cols-2 gap-3">
                          {selectedSubCategory.children
                            .filter((c) => c.isActive)
                            .sort((a, b) => a.sortOrder - b.sortOrder)
                            .map((category) => (
                              <button
                                key={category.id}
                                onClick={() => handleProductTypeSelect(category)}
                                className={`p-3 text-left rounded-lg border-2 transition-colors ${
                                  selectedProductType?.id === category.id
                                    ? 'border-pink-600 bg-pink-50'
                                    : 'border-gray-200 hover:border-pink-300'
                                }`}
                              >
                                <span className="text-sm font-medium">{category.name}</span>
                              </button>
                            ))}
                        </div>
                      </div>
                    )}
                  </div>
                )}
              </CardContent>
            </Card>
          )}

          {/* Step 3: Details */}
          {currentStep === 'details' && (
            <Card>
              <CardHeader>
                <CardTitle>Item Details</CardTitle>
              </CardHeader>
              <CardContent className="space-y-4">
                <Input
                  label="Title"
                  value={title}
                  onChange={(e) => setTitle(e.target.value.slice(0, 150))}
                  placeholder="e.g., Beautiful Kitenge Dress"
                  required
                  showRequired
                  maxLength={150}
                  helperText={`${title.length}/150 characters`}
                />

                <Textarea
                  label="Description"
                  value={description}
                  onChange={(e) => setDescription(e.target.value)}
                  placeholder="Describe your item in detail..."
                  rows={4}
                  required
                  showRequired
                />

                <Select
                  label="Condition"
                  options={CONDITION_OPTIONS}
                  value={condition}
                  onChange={(e) => setCondition(e.target.value as ItemCondition)}
                  placeholder="Select condition"
                  required
                  showRequired
                />

                {/* Dynamic Attributes */}
                {attributesLoading ? (
                  <div className="flex items-center justify-center py-8">
                    <div className="w-6 h-6 border-2 border-pink-600 border-t-transparent rounded-full animate-spin" />
                    <span className="ml-2 text-sm text-gray-500">Loading attributes...</span>
                  </div>
                ) : categoryAttributes.filter((attr) => attr.slug !== 'condition').length > 0 ? (
                  <div className="space-y-4 pt-4 border-t">
                    <h4 className="text-sm font-medium text-gray-900">Additional Details</h4>
                    {categoryAttributes
                      .filter((attr) => attr.slug !== 'condition')
                      .map((attr) => (
                        <div key={attr.id}>{renderAttributeField(attr)}</div>
                      ))}
                  </div>
                ) : null}

                {/* Location Selection */}
                <div className="space-y-4 pt-4 border-t">
                  <h4 className="text-sm font-medium text-gray-900">Pickup Location</h4>

                  {citiesLoading ? (
                    <div className="flex items-center py-4">
                      <div className="w-5 h-5 border-2 border-pink-600 border-t-transparent rounded-full animate-spin" />
                      <span className="ml-2 text-sm text-gray-500">Loading locations...</span>
                    </div>
                  ) : (
                    <div className="grid grid-cols-2 gap-4">
                      <div>
                        <label className="block text-sm font-medium text-gray-700 mb-1">
                          City <span className="text-red-500">*</span>
                        </label>
                        <Select
                          options={cities.map((c) => ({ value: c.id, label: c.name }))}
                          value={selectedCity?.id || ''}
                          onChange={(e) => {
                            const city = cities.find((c) => c.id === e.target.value);
                            setSelectedCity(city || null);
                            setSelectedDivision(null);
                          }}
                          placeholder="Select city"
                        />
                      </div>

                      {selectedCity && selectedCity.divisions && selectedCity.divisions.length > 0 && (
                        <Select
                          label="Area"
                          options={selectedCity.divisions.map((d) => ({ value: d.id, label: d.name }))}
                          value={selectedDivision?.id || ''}
                          onChange={(e) => {
                            const division = selectedCity.divisions?.find((d) => d.id === e.target.value);
                            setSelectedDivision(division || null);
                          }}
                          placeholder="Select area"
                        />
                      )}
                    </div>
                  )}
                </div>
              </CardContent>
            </Card>
          )}

          {/* Step 4: Pricing */}
          {currentStep === 'pricing' && (
            <Card>
              <CardHeader>
                <CardTitle>Set Your Price</CardTitle>
              </CardHeader>
              <CardContent className="space-y-4">
                <Input
                  label="Selling Price (UGX)"
                  value={price}
                  onChange={(e) => setPrice(e.target.value.replace(/[^0-9]/g, ''))}
                  placeholder="Enter price"
                  required
                  showRequired
                  helperText="This is what buyers will pay"
                />

                <Input
                  label="Original Price (optional)"
                  value={originalPrice}
                  onChange={(e) => setOriginalPrice(e.target.value.replace(/[^0-9]/g, ''))}
                  placeholder="Enter original price"
                  helperText="Show buyers the value they're getting"
                />

                {price && originalPrice && parseInt(originalPrice) > parseInt(price) && (
                  <div className="p-4 bg-green-50 rounded-lg">
                    <p className="text-green-700 font-medium">
                      {Math.round(
                        ((parseInt(originalPrice) - parseInt(price)) / parseInt(originalPrice)) *
                          100
                      )}
                      % discount
                    </p>
                  </div>
                )}
              </CardContent>
            </Card>
          )}

          {/* Step 5: Review */}
          {currentStep === 'review' && (
            <Card>
              <CardHeader>
                <CardTitle>Review Your Listing</CardTitle>
              </CardHeader>
              <CardContent className="space-y-6">
                {/* Preview Image */}
                {imageUrls[0] && (
                  <div className="relative aspect-video rounded-lg overflow-hidden">
                    <Image
                      src={imageUrls[0]}
                      alt={title}
                      fill
                      className="object-cover"
                    />
                  </div>
                )}

                {/* Details Summary */}
                <div className="space-y-3">
                  <div>
                    <span className="text-sm text-gray-500">Title</span>
                    <p className="font-medium">{title}</p>
                  </div>
                  <div>
                    <span className="text-sm text-gray-500">Price</span>
                    <p className="text-xl font-bold text-pink-600">
                      UGX {parseInt(price).toLocaleString()}
                    </p>
                  </div>
                  <div>
                    <span className="text-sm text-gray-500">Category</span>
                    <p>{getCategoryBreadcrumb().join(' > ')}</p>
                  </div>
                  <div>
                    <span className="text-sm text-gray-500">Condition</span>
                    <p>{CONDITION_LABELS[condition as ItemCondition]}</p>
                  </div>
                  {selectedCity && (
                    <div>
                      <span className="text-sm text-gray-500">Location</span>
                      <p>
                        {selectedCity.name}
                        {selectedDivision && `, ${selectedDivision.name}`}
                      </p>
                    </div>
                  )}
                  {/* Show selected attributes */}
                  {Object.keys(attributeValues).length > 0 && (
                    <div>
                      <span className="text-sm text-gray-500">Attributes</span>
                      <div className="mt-1 space-y-1">
                        {categoryAttributes.map((attr) => {
                          const value = attributeValues[attr.slug];
                          if (!value || (Array.isArray(value) && value.length === 0)) return null;
                          return (
                            <p key={attr.id} className="text-sm">
                              <span className="text-gray-600">{attr.name}:</span>{' '}
                              {Array.isArray(value) ? value.join(', ') : value}
                            </p>
                          );
                        })}
                      </div>
                    </div>
                  )}
                  <div>
                    <span className="text-sm text-gray-500">Description</span>
                    <p className="text-gray-600">{description}</p>
                  </div>
                </div>

                <div className="p-4 bg-yellow-50 rounded-lg">
                  <p className="text-sm text-yellow-800">
                    Your listing will be reviewed before going live. This usually takes less than 24
                    hours.
                  </p>
                </div>
              </CardContent>
            </Card>
          )}

          {/* Navigation Buttons */}
          <div className="flex gap-3 mt-6">
            {currentStep === 'review' ? (
              <>
                <Button
                  variant="outline"
                  onClick={() => handleSubmit(true)}
                  loading={loading}
                  className="flex-1"
                >
                  Save as Draft
                </Button>
                <Button
                  onClick={() => handleSubmit(false)}
                  loading={loading}
                  className="flex-1"
                >
                  Publish Listing
                </Button>
              </>
            ) : (
              <Button
                onClick={handleNext}
                disabled={!canProceed()}
                className="flex-1"
              >
                Continue
              </Button>
            )}
          </div>
        </div>
      </main>

      <Footer />
    </div>
  );
}
