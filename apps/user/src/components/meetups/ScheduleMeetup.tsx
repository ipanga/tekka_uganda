'use client';

import { useState, useEffect } from 'react';
import {
  MapPinIcon,
  CalendarIcon,
  ClockIcon,
  ShieldCheckIcon,
} from '@heroicons/react/24/outline';
import { api } from '@/lib/api';
import { SafeLocation, Meetup } from '@/types';
import { Button } from '@/components/ui/Button';
import { Input } from '@/components/ui/Input';
import { Textarea } from '@/components/ui/Textarea';
import { Modal, ModalFooter } from '@/components/ui/Modal';
import { Card, CardContent } from '@/components/ui/Card';
import { Badge } from '@/components/ui/Badge';

interface ScheduleMeetupProps {
  isOpen: boolean;
  onClose: () => void;
  recipientId: string;
  listingId?: string;
  chatId?: string;
  city?: string;
  onSuccess?: (meetup: Meetup) => void;
}

export function ScheduleMeetup({
  isOpen,
  onClose,
  recipientId,
  listingId,
  chatId,
  city = 'Kampala',
  onSuccess,
}: ScheduleMeetupProps) {
  const [safeLocations, setSafeLocations] = useState<SafeLocation[]>([]);
  const [loadingLocations, setLoadingLocations] = useState(false);
  const [selectedLocation, setSelectedLocation] = useState<SafeLocation | null>(null);
  const [useCustomLocation, setUseCustomLocation] = useState(false);
  const [customLocation, setCustomLocation] = useState('');
  const [proposedDate, setProposedDate] = useState('');
  const [proposedTime, setProposedTime] = useState('');
  const [notes, setNotes] = useState('');
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState<string | null>(null);

  useEffect(() => {
    if (isOpen) {
      loadSafeLocations();
    }
  }, [isOpen, city]);

  const loadSafeLocations = async () => {
    setLoadingLocations(true);
    try {
      const locations = await api.getMeetupLocations(city);
      setSafeLocations(locations);
    } catch (err) {
      console.error('Error loading safe locations:', err);
    } finally {
      setLoadingLocations(false);
    }
  };

  const handleSubmit = async () => {
    if (!proposedDate || !proposedTime) {
      setError('Please select a date and time');
      return;
    }

    if (!selectedLocation && !customLocation.trim()) {
      setError('Please select a location');
      return;
    }

    setError(null);
    setLoading(true);

    try {
      // Build datetime from date and time inputs
      const scheduledAt = new Date(`${proposedDate}T${proposedTime}`).toISOString();

      const meetup = await api.scheduleMeetup({
        chatId: chatId || '',
        locationId: selectedLocation?.id,
        locationName: useCustomLocation ? customLocation.trim() : (selectedLocation?.name || ''),
        locationAddress: useCustomLocation ? customLocation.trim() : (selectedLocation?.address || ''),
        latitude: selectedLocation?.latitude,
        longitude: selectedLocation?.longitude,
        scheduledAt,
        notes: notes.trim() || undefined,
      });

      onSuccess?.(meetup);
      handleClose();
    } catch (err) {
      setError(err instanceof Error ? err.message : 'Failed to schedule meetup');
    } finally {
      setLoading(false);
    }
  };

  const handleClose = () => {
    setSelectedLocation(null);
    setUseCustomLocation(false);
    setCustomLocation('');
    setProposedDate('');
    setProposedTime('');
    setNotes('');
    setError(null);
    onClose();
  };

  // Get minimum date (today)
  const minDate = new Date().toISOString().split('T')[0];

  return (
    <Modal isOpen={isOpen} onClose={handleClose} title="Schedule Meetup" size="lg">
      <div className="space-y-6">
        {/* Safe Locations */}
        <div>
          <label className="block text-sm font-medium text-gray-700 dark:text-gray-300 mb-2">
            <MapPinIcon className="w-4 h-4 inline mr-1" />
            Choose a meeting location
          </label>

          {loadingLocations ? (
            <div className="text-center py-8">
              <div className="animate-spin rounded-full h-8 w-8 border-b-2 border-primary-500 dark:border-primary-400 mx-auto"></div>
              <p className="text-sm text-gray-500 dark:text-gray-400 mt-2">Loading safe locations...</p>
            </div>
          ) : (
            <>
              {/* Safe Locations Grid */}
              <div className="grid grid-cols-1 sm:grid-cols-2 gap-3 mb-4">
                {safeLocations.map((location) => (
                  <Card
                    key={location.id}
                    hoverable
                    className={`cursor-pointer transition-all ${
                      selectedLocation?.id === location.id
                        ? 'ring-2 ring-primary-500 border-primary-500'
                        : ''
                    }`}
                    onClick={() => {
                      setSelectedLocation(location);
                      setUseCustomLocation(false);
                    }}
                  >
                    <CardContent className="py-3">
                      <div className="flex items-start gap-3">
                        <div className="p-2 bg-green-100 rounded-lg">
                          <ShieldCheckIcon className="w-5 h-5 text-green-600" />
                        </div>
                        <div className="flex-1 min-w-0">
                          <div className="flex items-center gap-2">
                            <span className="font-medium text-gray-900 dark:text-gray-100 truncate">
                              {location.name}
                            </span>
                            <Badge variant="success" size="sm">Safe</Badge>
                          </div>
                          <p className="text-sm text-gray-500 dark:text-gray-400 truncate">
                            {location.address}
                          </p>
                          {location.openingHours && (
                            <p className="text-xs text-gray-400 dark:text-gray-500 mt-1">
                              {location.openingHours}
                            </p>
                          )}
                        </div>
                      </div>
                    </CardContent>
                  </Card>
                ))}
              </div>

              {/* Custom Location Toggle */}
              <button
                type="button"
                onClick={() => {
                  setUseCustomLocation(!useCustomLocation);
                  setSelectedLocation(null);
                }}
                className={`w-full p-3 border rounded-lg text-left transition-colors ${
                  useCustomLocation
                    ? 'border-primary-500 bg-primary-50 dark:bg-primary-900'
                    : 'border-gray-200 dark:border-gray-700 hover:border-gray-300 dark:hover:border-gray-600'
                }`}
              >
                <span className="font-medium text-gray-900 dark:text-gray-100">Use custom location</span>
                <p className="text-sm text-gray-500 dark:text-gray-400">
                  Enter your own meeting location
                </p>
              </button>

              {useCustomLocation && (
                <Input
                  className="mt-3"
                  placeholder="e.g., Acacia Mall Food Court"
                  value={customLocation}
                  onChange={(e) => setCustomLocation(e.target.value)}
                />
              )}
            </>
          )}
        </div>

        {/* Date and Time */}
        <div className="grid grid-cols-2 gap-4">
          <Input
            label="Date"
            type="date"
            value={proposedDate}
            onChange={(e) => setProposedDate(e.target.value)}
            min={minDate}
            leftIcon={<CalendarIcon className="w-5 h-5" />}
            required
          />

          <Input
            label="Time"
            type="time"
            value={proposedTime}
            onChange={(e) => setProposedTime(e.target.value)}
            leftIcon={<ClockIcon className="w-5 h-5" />}
            required
          />
        </div>

        {/* Notes */}
        <Textarea
          label="Additional Notes (Optional)"
          value={notes}
          onChange={(e) => setNotes(e.target.value)}
          placeholder="Any specific instructions or preferences..."
          rows={2}
          maxLength={200}
        />

        {/* Error */}
        {error && (
          <div className="p-3 bg-red-50 border border-red-200 rounded-lg">
            <p className="text-sm text-red-600">{error}</p>
          </div>
        )}

        {/* Safety Tips */}
        <div className="p-4 bg-yellow-50 rounded-lg">
          <p className="font-medium text-yellow-800 mb-2">Safety Tips</p>
          <ul className="text-sm text-yellow-700 space-y-1">
            <li>• Meet in public places during daylight hours</li>
            <li>• Tell someone where you&apos;re going</li>
            <li>• Inspect items thoroughly before paying</li>
            <li>• Trust your instincts - if something feels off, leave</li>
          </ul>
        </div>
      </div>

      <ModalFooter>
        <Button variant="outline" onClick={handleClose}>
          Cancel
        </Button>
        <Button onClick={handleSubmit} loading={loading}>
          Send Meetup Request
        </Button>
      </ModalFooter>
    </Modal>
  );
}
