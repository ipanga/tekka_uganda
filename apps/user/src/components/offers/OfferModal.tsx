'use client';

import { useState } from 'react';
import Image from 'next/image';
import { useRouter } from 'next/navigation';
import { api } from '@/lib/api';
import { authManager } from '@/lib/auth';
import { Listing } from '@/types';
import { formatPrice } from '@/lib/utils';
import { Modal, ModalFooter } from '@/components/ui/Modal';
import { Input } from '@/components/ui/Input';
import { Textarea } from '@/components/ui/Textarea';
import { Button } from '@/components/ui/Button';

interface OfferModalProps {
  isOpen: boolean;
  onClose: () => void;
  listing: Listing;
  onSuccess?: () => void;
}

export function OfferModal({ isOpen, onClose, listing, onSuccess }: OfferModalProps) {
  const router = useRouter();
  const [amount, setAmount] = useState('');
  const [message, setMessage] = useState('');
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState<string | null>(null);

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    setError(null);

    // Ensure we have authentication before making API calls
    // authManager.isAuthenticated() also initializes and sets API token
    if (!authManager.isAuthenticated()) {
      onClose();
      router.push('/login');
      return;
    }

    const offerAmount = parseInt(amount.replace(/,/g, ''), 10);

    if (isNaN(offerAmount) || offerAmount <= 0) {
      setError('Please enter a valid amount');
      return;
    }

    if (offerAmount >= listing.price) {
      setError('Your offer should be less than the asking price');
      return;
    }

    setLoading(true);
    try {
      await api.createOffer({
        listingId: listing.id,
        amount: offerAmount,
        message: message.trim() || undefined,
      });
      onSuccess?.();
      onClose();
    } catch (err) {
      setError(err instanceof Error ? err.message : 'Failed to submit offer');
    } finally {
      setLoading(false);
    }
  };

  const suggestedOffers = [
    Math.round(listing.price * 0.9),
    Math.round(listing.price * 0.85),
    Math.round(listing.price * 0.8),
  ];

  return (
    <Modal
      isOpen={isOpen}
      onClose={onClose}
      title="Make an Offer"
      size="md"
    >
      <form onSubmit={handleSubmit}>
        {/* Listing Preview */}
        <div className="flex gap-4 p-4 bg-gray-50 rounded-lg mb-6">
          <div className="relative w-16 h-16 rounded-lg overflow-hidden flex-shrink-0">
            {listing.imageUrls[0] ? (
              <Image
                src={listing.imageUrls[0]}
                alt={listing.title}
                fill
                className="object-cover"
              />
            ) : (
              <div className="w-full h-full bg-gray-200" />
            )}
          </div>
          <div>
            <h3 className="font-medium text-gray-900 line-clamp-1">{listing.title}</h3>
            <p className="text-lg font-bold text-pink-600">{formatPrice(listing.price)}</p>
          </div>
        </div>

        {error && (
          <div className="mb-4 p-3 bg-red-50 border border-red-200 rounded-lg">
            <p className="text-sm text-red-600">{error}</p>
          </div>
        )}

        {/* Suggested Amounts */}
        <div className="mb-4">
          <label className="block text-sm font-medium text-gray-700 mb-2">
            Quick offers
          </label>
          <div className="flex gap-2">
            {suggestedOffers.map((suggestion) => (
              <button
                key={suggestion}
                type="button"
                onClick={() => setAmount(suggestion.toString())}
                className={`px-3 py-1.5 text-sm rounded-full border transition-colors ${
                  amount === suggestion.toString()
                    ? 'border-pink-600 bg-pink-50 text-pink-600'
                    : 'border-gray-200 hover:border-gray-300'
                }`}
              >
                {formatPrice(suggestion)}
              </button>
            ))}
          </div>
        </div>

        {/* Amount Input */}
        <Input
          label="Your offer amount (UGX)"
          type="text"
          placeholder="Enter amount"
          value={amount}
          onChange={(e) => setAmount(e.target.value.replace(/[^0-9]/g, ''))}
          required
        />

        {/* Message */}
        <div className="mt-4">
          <Textarea
            label="Message to seller (optional)"
            placeholder="Add a message to your offer..."
            value={message}
            onChange={(e) => setMessage(e.target.value)}
            rows={3}
          />
        </div>

        <ModalFooter>
          <Button type="button" variant="outline" onClick={onClose}>
            Cancel
          </Button>
          <Button type="submit" loading={loading}>
            Send Offer
          </Button>
        </ModalFooter>
      </form>
    </Modal>
  );
}
