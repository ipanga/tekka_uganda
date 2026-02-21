'use client';

import { useState, useEffect, useRef } from 'react';
import { useRouter, useSearchParams } from 'next/navigation';
import Link from 'next/link';
import { ArrowLeftIcon, CameraIcon, CheckCircleIcon, ExclamationTriangleIcon } from '@heroicons/react/24/outline';
import { api } from '@/lib/api';
import Header from '@/components/layout/Header';
import Footer from '@/components/layout/Footer';
import { Button } from '@/components/ui/Button';
import { Input } from '@/components/ui/Input';
import { Textarea } from '@/components/ui/Textarea';
import { Select } from '@/components/ui/Select';
import { Avatar } from '@/components/ui/Avatar';
import { Card, CardContent, CardHeader, CardTitle } from '@/components/ui/Card';
import { PageLoader } from '@/components/ui/Spinner';
import { useAuthStore } from '@/stores/authStore';
import type { City, Division } from '@/types';

export default function EditProfilePage() {
  const router = useRouter();
  const { user, isAuthenticated, isLoading: authLoading, setUser } = useAuthStore();

  const [displayName, setDisplayName] = useState('');
  const [bio, setBio] = useState('');
  const [selectedCityId, setSelectedCityId] = useState('');
  const [selectedDivisionId, setSelectedDivisionId] = useState('');
  const [email, setEmail] = useState('');
  const [photoUrl, setPhotoUrl] = useState<string | undefined>(undefined);
  const [uploadingPhoto, setUploadingPhoto] = useState(false);
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState<string | null>(null);
  const [success, setSuccess] = useState(false);
  const fileInputRef = useRef<HTMLInputElement>(null);

  // Location data
  const [cities, setCities] = useState<City[]>([]);
  const [divisions, setDivisions] = useState<Division[]>([]);
  const [loadingLocations, setLoadingLocations] = useState(true);

  // Load cities on mount
  useEffect(() => {
    const loadCities = async () => {
      try {
        const citiesData = await api.getCitiesWithDivisions();
        setCities(citiesData);
      } catch (err) {
        console.error('Failed to load cities:', err);
      } finally {
        setLoadingLocations(false);
      }
    };
    loadCities();
  }, []);

  // Update divisions when city changes
  useEffect(() => {
    if (selectedCityId) {
      const city = cities.find((c) => c.id === selectedCityId);
      setDivisions(city?.divisions || []);
      // Reset division selection if current division is not in new city
      if (selectedDivisionId) {
        const divisionExists = city?.divisions?.some((d) => d.id === selectedDivisionId);
        if (!divisionExists) {
          setSelectedDivisionId('');
        }
      }
    } else {
      setDivisions([]);
      setSelectedDivisionId('');
    }
  }, [selectedCityId, cities]);

  useEffect(() => {
    if (!authLoading && !isAuthenticated) {
      router.push('/login');
      return;
    }

    if (user) {
      setDisplayName(user.displayName || '');
      setBio(user.bio || '');
      setEmail(user.email || '');
      setPhotoUrl(user.photoUrl || undefined);

      // Parse existing location to set city and division
      // Location format is "City" or "City - Division"
      if (user.location && cities.length > 0) {
        const parts = user.location.split(' - ');
        const cityName = parts[0]?.trim();
        const divisionName = parts[1]?.trim();

        const city = cities.find((c) => c.name === cityName);
        if (city) {
          setSelectedCityId(city.id);
          if (divisionName && city.divisions) {
            const division = city.divisions.find((d) => d.name === divisionName);
            if (division) {
              setSelectedDivisionId(division.id);
            }
          }
        }
      }
    }
  }, [user, authLoading, isAuthenticated, cities]);

  // Build location string from selected city and division
  const buildLocationString = (): string | undefined => {
    if (!selectedCityId) return undefined;
    const city = cities.find((c) => c.id === selectedCityId);
    if (!city) return undefined;

    if (selectedDivisionId) {
      const division = divisions.find((d) => d.id === selectedDivisionId);
      if (division) {
        return `${city.name} - ${division.name}`;
      }
    }
    return city.name;
  };

  const handlePhotoUpload = async (e: React.ChangeEvent<HTMLInputElement>) => {
    const file = e.target.files?.[0];
    if (!file) return;

    setUploadingPhoto(true);
    setError(null);
    try {
      const { url } = await api.uploadImage(file);
      setPhotoUrl(url);
    } catch (err) {
      setError(err instanceof Error ? err.message : 'Failed to upload photo');
    } finally {
      setUploadingPhoto(false);
      if (fileInputRef.current) fileInputRef.current.value = '';
    }
  };

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    setError(null);
    setSuccess(false);
    setLoading(true);

    try {
      const locationString = buildLocationString();
      const updatedUser = await api.updateMe({
        displayName: displayName.trim(),
        bio: bio.trim() || undefined,
        location: locationString,
        email: email.trim() || undefined,
        photoUrl,
      });

      setUser(updatedUser);
      setSuccess(true);
      setTimeout(() => {
        router.push('/profile');
      }, 1500);
    } catch (err) {
      setError(err instanceof Error ? err.message : 'Failed to update profile');
    } finally {
      setLoading(false);
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

  if (!user) {
    return null;
  }

  return (
    <div className="min-h-screen flex flex-col bg-gray-50">
      <Header />

      <main className="flex-1 py-8">
        <div className="max-w-2xl mx-auto px-4">
          {/* Back Button */}
          <button
            onClick={() => router.back()}
            className="flex items-center gap-2 text-gray-600 hover:text-gray-900 mb-6"
          >
            <ArrowLeftIcon className="w-5 h-5" />
            Back
          </button>

          <Card>
            <CardHeader>
              <CardTitle>Edit Profile</CardTitle>
            </CardHeader>
            <CardContent>
              <form onSubmit={handleSubmit} className="space-y-6">
                {/* Avatar */}
                <div className="flex flex-col items-center">
                  <div className="relative">
                    <Avatar
                      src={photoUrl || user.photoUrl}
                      name={displayName || user.displayName}
                      size="xl"
                    />
                    <button
                      type="button"
                      onClick={() => fileInputRef.current?.click()}
                      disabled={uploadingPhoto}
                      className="absolute bottom-0 right-0 p-2 bg-primary-500 text-white rounded-full hover:bg-primary-600 transition-colors disabled:opacity-50"
                    >
                      {uploadingPhoto ? (
                        <div className="w-4 h-4 border-2 border-white border-t-transparent rounded-full animate-spin" />
                      ) : (
                        <CameraIcon className="w-4 h-4" />
                      )}
                    </button>
                    <input
                      ref={fileInputRef}
                      type="file"
                      accept="image/*"
                      onChange={handlePhotoUpload}
                      className="hidden"
                    />
                  </div>
                  <p className="text-sm text-gray-500 mt-2">Click to change photo</p>
                </div>

                {/* Error Message */}
                {error && (
                  <div className="p-4 bg-red-50 border border-red-200 rounded-lg">
                    <p className="text-sm text-red-600">{error}</p>
                  </div>
                )}

                {/* Success Message */}
                {success && (
                  <div className="p-4 bg-green-50 border border-green-200 rounded-lg">
                    <p className="text-sm text-green-600">Profile updated successfully!</p>
                  </div>
                )}

                {/* Form Fields */}
                <Input
                  label="Display Name"
                  value={displayName}
                  onChange={(e) => setDisplayName(e.target.value)}
                  placeholder="How others will see you"
                  required
                />

                <Textarea
                  label="Bio"
                  value={bio}
                  onChange={(e) => setBio(e.target.value)}
                  placeholder="Tell others a bit about yourself..."
                  rows={4}
                  helperText="Optional - Max 200 characters"
                />

                {/* City Selection */}
                <Select
                  label="City/Town"
                  value={selectedCityId}
                  onChange={(e) => setSelectedCityId(e.target.value)}
                  disabled={loadingLocations}
                  helperText="Select your city or town"
                  placeholder="Select a city"
                  options={cities.map((city) => ({
                    value: city.id,
                    label: city.name,
                  }))}
                />

                {/* Division Selection */}
                {divisions.length > 0 && (
                  <Select
                    label="Division/Area"
                    value={selectedDivisionId}
                    onChange={(e) => setSelectedDivisionId(e.target.value)}
                    helperText="Optional - Select your specific area"
                    options={[
                      { value: '', label: 'Select a division (optional)' },
                      ...divisions.map((division) => ({
                        value: division.id,
                        label: division.name,
                      })),
                    ]}
                  />
                )}

                {/* Email with verification status */}
                <div>
                  <Input
                    label="Email"
                    type="email"
                    value={email}
                    onChange={(e) => setEmail(e.target.value)}
                    placeholder="your@email.com"
                    helperText="Used for notifications and account recovery"
                  />
                  {user.email && (
                    <div className="mt-2">
                      {user.isEmailVerified ? (
                        <span className="inline-flex items-center gap-1 text-sm text-green-600">
                          <CheckCircleIcon className="w-4 h-4" />
                          Verified
                        </span>
                      ) : (
                        <div className="flex items-center gap-2">
                          <span className="inline-flex items-center gap-1 text-sm text-amber-600">
                            <ExclamationTriangleIcon className="w-4 h-4" />
                            Not verified
                          </span>
                          <Link
                            href="/profile/verify-email"
                            className="text-sm font-medium text-primary-500 hover:text-primary-600"
                          >
                            Verify now
                          </Link>
                        </div>
                      )}
                    </div>
                  )}
                </div>

                {/* Phone Number (Read-only) */}
                <div>
                  <label className="block text-sm font-medium text-gray-700 mb-1">
                    Phone Number
                  </label>
                  <div className="px-4 py-2.5 bg-gray-50 border border-gray-200 rounded-lg text-gray-600">
                    {user.phoneNumber}
                  </div>
                  <p className="mt-1 text-sm text-gray-500">
                    Phone number cannot be changed
                  </p>
                </div>

                {/* Submit Buttons */}
                <div className="flex gap-3 pt-4">
                  <Button
                    type="button"
                    variant="outline"
                    onClick={() => router.back()}
                    className="flex-1"
                  >
                    Cancel
                  </Button>
                  <Button type="submit" loading={loading} className="flex-1">
                    Save Changes
                  </Button>
                </div>
              </form>
            </CardContent>
          </Card>
        </div>
      </main>

      <Footer />
    </div>
  );
}
