'use client';

import { useState, useEffect } from 'react';
import { useParams, useRouter } from 'next/navigation';
import Image from 'next/image';
import {
  ArrowLeftIcon,
  XMarkIcon,
  PlusIcon,
} from '@heroicons/react/24/outline';
import { api } from '@/lib/api';
import {
  Listing,
  ListingCategory,
  ItemCondition,
  ItemOccasion,
  CATEGORY_LABELS,
  CONDITION_LABELS,
  OCCASION_LABELS,
} from '@/types';
import Header from '@/components/layout/Header';
import Footer from '@/components/layout/Footer';
import { Button } from '@/components/ui/Button';
import { Input } from '@/components/ui/Input';
import { Textarea } from '@/components/ui/Textarea';
import { Select } from '@/components/ui/Select';
import { Card, CardContent, CardHeader, CardTitle } from '@/components/ui/Card';
import { PageLoader } from '@/components/ui/Spinner';
import { useAuthStore } from '@/stores/authStore';

type Step = 'photos' | 'details' | 'pricing' | 'review';

const STEPS: Step[] = ['photos', 'details', 'pricing', 'review'];

const CATEGORY_OPTIONS = Object.entries(CATEGORY_LABELS).map(([value, label]) => ({
  value,
  label,
}));

const CONDITION_OPTIONS = Object.entries(CONDITION_LABELS).map(([value, label]) => ({
  value,
  label,
}));

const OCCASION_OPTIONS = [
  { value: '', label: 'Select occasion (optional)' },
  ...Object.entries(OCCASION_LABELS).map(([value, label]) => ({
    value,
    label,
  })),
];

export default function EditListingPage() {
  const params = useParams();
  const router = useRouter();
  const listingId = params.id as string;

  const { user, isAuthenticated, isLoading: authLoading } = useAuthStore();

  const [listing, setListing] = useState<Listing | null>(null);
  const [loadingListing, setLoadingListing] = useState(true);
  const [currentStep, setCurrentStep] = useState<Step>('photos');
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState<string | null>(null);

  // Form state
  const [imageUrls, setImageUrls] = useState<string[]>([]);
  const [title, setTitle] = useState('');
  const [description, setDescription] = useState('');
  const [category, setCategory] = useState<ListingCategory | ''>('');
  const [condition, setCondition] = useState<ItemCondition | ''>('');
  const [occasion, setOccasion] = useState<ItemOccasion | ''>('');
  const [size, setSize] = useState('');
  const [brand, setBrand] = useState('');
  const [color, setColor] = useState('');
  const [material, setMaterial] = useState('');
  const [location, setLocation] = useState('');
  const [price, setPrice] = useState('');
  const [originalPrice, setOriginalPrice] = useState('');

  useEffect(() => {
    if (!authLoading && !isAuthenticated) {
      router.push('/login');
      return;
    }

    if (isAuthenticated && listingId) {
      loadListing();
    }
  }, [authLoading, isAuthenticated, listingId]);

  const loadListing = async () => {
    try {
      setLoadingListing(true);
      const data = await api.getListing(listingId);

      // Check if user owns this listing
      if (data.sellerId !== user?.id) {
        router.push('/my-listings');
        return;
      }

      setListing(data);

      // Populate form with existing data
      setImageUrls(data.imageUrls || []);
      setTitle(data.title);
      setDescription(data.description);
      setCategory(data.category);
      setCondition(data.condition);
      setOccasion(data.occasion || '');
      setSize(data.size || '');
      setBrand(data.brand || '');
      setColor(data.color || '');
      setMaterial(data.material || '');
      setLocation(data.location || '');
      setPrice(data.price.toString());
      setOriginalPrice(data.originalPrice?.toString() || '');
    } catch (err) {
      setError('Failed to load listing');
      console.error(err);
    } finally {
      setLoadingListing(false);
    }
  };

  const currentStepIndex = STEPS.indexOf(currentStep);

  const canProceed = () => {
    switch (currentStep) {
      case 'photos':
        return imageUrls.length > 0;
      case 'details':
        return title.trim() && description.trim() && category && condition;
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

  const handleAddImage = () => {
    // For now, use placeholder URLs
    // In production, this would open a file picker and upload to cloud storage
    const placeholderUrl = `https://picsum.photos/seed/${Date.now()}/400/400`;
    setImageUrls([...imageUrls, placeholderUrl]);
  };

  const handleRemoveImage = (index: number) => {
    setImageUrls(imageUrls.filter((_, i) => i !== index));
  };

  const handleSubmit = async () => {
    setError(null);
    setLoading(true);

    try {
      await api.updateListing(listingId, {
        title: title.trim(),
        description: description.trim(),
        price: parseInt(price.replace(/,/g, ''), 10),
        originalPrice: originalPrice
          ? parseInt(originalPrice.replace(/,/g, ''), 10)
          : undefined,
        category: category as ListingCategory,
        condition: condition as ItemCondition,
        occasion: occasion as ItemOccasion || undefined,
        size: size.trim() || undefined,
        brand: brand.trim() || undefined,
        color: color.trim() || undefined,
        material: material.trim() || undefined,
        location: location.trim() || undefined,
        imageUrls,
      });

      router.push(`/listing/${listingId}`);
    } catch (err) {
      setError(err instanceof Error ? err.message : 'Failed to update listing');
    } finally {
      setLoading(false);
    }
  };

  if (authLoading || loadingListing) {
    return (
      <div className="min-h-screen flex flex-col">
        <Header />
        <PageLoader message="Loading listing..." />
        <Footer />
      </div>
    );
  }

  if (!listing) {
    return (
      <div className="min-h-screen flex flex-col">
        <Header />
        <main className="flex-1 flex items-center justify-center">
          <div className="text-center">
            <h1 className="text-xl font-bold text-gray-900 mb-2">Listing not found</h1>
            <Button onClick={() => router.push('/my-listings')}>Back to My Listings</Button>
          </div>
        </main>
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

          <h1 className="text-2xl font-bold text-gray-900 mb-6">Edit Listing</h1>

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
                      className={`w-full h-1 mx-2 ${
                        index < currentStepIndex ? 'bg-pink-600' : 'bg-gray-200'
                      }`}
                      style={{ minWidth: '60px' }}
                    />
                  )}
                </div>
              ))}
            </div>
            <div className="flex justify-between text-xs text-gray-500">
              <span>Photos</span>
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
                <CardTitle>Edit Photos</CardTitle>
              </CardHeader>
              <CardContent>
                <p className="text-gray-500 mb-4">
                  Add up to 10 photos. The first photo will be your cover image.
                </p>

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
                      onClick={handleAddImage}
                      className="aspect-square border-2 border-dashed border-gray-300 rounded-lg flex flex-col items-center justify-center gap-2 hover:border-pink-500 hover:bg-pink-50 transition-colors"
                    >
                      <PlusIcon className="w-8 h-8 text-gray-400" />
                      <span className="text-sm text-gray-500">Add Photo</span>
                    </button>
                  )}
                </div>

                <p className="text-xs text-gray-400 mt-4">
                  Tip: Use natural lighting and show the item from multiple angles
                </p>
              </CardContent>
            </Card>
          )}

          {/* Step 2: Details */}
          {currentStep === 'details' && (
            <Card>
              <CardHeader>
                <CardTitle>Item Details</CardTitle>
              </CardHeader>
              <CardContent className="space-y-4">
                <Input
                  label="Title"
                  value={title}
                  onChange={(e) => setTitle(e.target.value)}
                  placeholder="e.g., Beautiful Kitenge Dress"
                  required
                />

                <Textarea
                  label="Description"
                  value={description}
                  onChange={(e) => setDescription(e.target.value)}
                  placeholder="Describe your item in detail..."
                  rows={4}
                  required
                />

                <div className="grid grid-cols-2 gap-4">
                  <Select
                    label="Category"
                    options={CATEGORY_OPTIONS}
                    value={category}
                    onChange={(e) => setCategory(e.target.value as ListingCategory)}
                    placeholder="Select category"
                    required
                  />

                  <Select
                    label="Condition"
                    options={CONDITION_OPTIONS}
                    value={condition}
                    onChange={(e) => setCondition(e.target.value as ItemCondition)}
                    placeholder="Select condition"
                    required
                  />
                </div>

                <Select
                  label="Occasion"
                  options={OCCASION_OPTIONS}
                  value={occasion}
                  onChange={(e) => setOccasion(e.target.value as ItemOccasion)}
                />

                <div className="grid grid-cols-2 gap-4">
                  <Input
                    label="Size"
                    value={size}
                    onChange={(e) => setSize(e.target.value)}
                    placeholder="e.g., M, L, 38"
                  />

                  <Input
                    label="Brand"
                    value={brand}
                    onChange={(e) => setBrand(e.target.value)}
                    placeholder="e.g., Zara, Local"
                  />
                </div>

                <div className="grid grid-cols-2 gap-4">
                  <Input
                    label="Color"
                    value={color}
                    onChange={(e) => setColor(e.target.value)}
                    placeholder="e.g., Red, Multi-color"
                  />

                  <Input
                    label="Material"
                    value={material}
                    onChange={(e) => setMaterial(e.target.value)}
                    placeholder="e.g., Cotton, Silk"
                  />
                </div>

                <Input
                  label="Location"
                  value={location}
                  onChange={(e) => setLocation(e.target.value)}
                  placeholder="e.g., Kampala, Entebbe"
                  helperText="Where the item can be picked up"
                />
              </CardContent>
            </Card>
          )}

          {/* Step 3: Pricing */}
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

          {/* Step 4: Review */}
          {currentStep === 'review' && (
            <Card>
              <CardHeader>
                <CardTitle>Review Your Changes</CardTitle>
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
                    <p>{CATEGORY_LABELS[category as ListingCategory]}</p>
                  </div>
                  <div>
                    <span className="text-sm text-gray-500">Condition</span>
                    <p>{CONDITION_LABELS[condition as ItemCondition]}</p>
                  </div>
                  <div>
                    <span className="text-sm text-gray-500">Description</span>
                    <p className="text-gray-600">{description}</p>
                  </div>
                </div>

                <div className="p-4 bg-blue-50 rounded-lg">
                  <p className="text-sm text-blue-800">
                    Your changes will be saved immediately. If you made significant changes, your
                    listing may be reviewed again.
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
                  onClick={() => router.push(`/listing/${listingId}`)}
                  className="flex-1"
                >
                  Cancel
                </Button>
                <Button
                  onClick={handleSubmit}
                  loading={loading}
                  className="flex-1"
                >
                  Save Changes
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
