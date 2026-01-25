'use client';

import { useState } from 'react';
import { api } from '@/lib/api';
import { ReportReason } from '@/types';
import { Modal, ModalFooter } from '@/components/ui/Modal';
import { Select } from '@/components/ui/Select';
import { Textarea } from '@/components/ui/Textarea';
import { Button } from '@/components/ui/Button';

interface ReportModalProps {
  isOpen: boolean;
  onClose: () => void;
  listingId?: string;
  userId?: string;
}

const REPORT_REASONS: { value: ReportReason; label: string }[] = [
  { value: 'SPAM', label: 'Spam or misleading' },
  { value: 'SCAM', label: 'Scam or fraud' },
  { value: 'INAPPROPRIATE_CONTENT', label: 'Inappropriate content' },
  { value: 'HARASSMENT', label: 'Harassment or abuse' },
  { value: 'FAKE_PROFILE', label: 'Fake profile' },
  { value: 'COUNTERFEIT_ITEMS', label: 'Counterfeit items' },
  { value: 'NO_SHOW', label: 'No show at meetup' },
  { value: 'OTHER', label: 'Other' },
];

export function ReportModal({ isOpen, onClose, listingId, userId }: ReportModalProps) {
  const [reason, setReason] = useState<ReportReason | ''>('');
  const [description, setDescription] = useState('');
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState<string | null>(null);
  const [success, setSuccess] = useState(false);

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    setError(null);

    if (!reason) {
      setError('Please select a reason');
      return;
    }

    setLoading(true);
    try {
      await api.createReport({
        reportedListingId: listingId,
        reportedUserId: userId,
        reason,
        description: description.trim() || undefined,
      });
      setSuccess(true);
      setTimeout(() => {
        onClose();
      }, 2000);
    } catch (err) {
      setError(err instanceof Error ? err.message : 'Failed to submit report');
    } finally {
      setLoading(false);
    }
  };

  if (success) {
    return (
      <Modal
        isOpen={isOpen}
        onClose={onClose}
        title="Report Submitted"
        size="sm"
      >
        <div className="text-center py-6">
          <div className="w-16 h-16 bg-green-100 rounded-full flex items-center justify-center mx-auto mb-4">
            <svg className="w-8 h-8 text-green-600" fill="none" viewBox="0 0 24 24" stroke="currentColor">
              <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M5 13l4 4L19 7" />
            </svg>
          </div>
          <h3 className="text-lg font-semibold text-gray-900 mb-2">Thank you for your report</h3>
          <p className="text-gray-500">We&apos;ll review this and take appropriate action.</p>
        </div>
      </Modal>
    );
  }

  return (
    <Modal
      isOpen={isOpen}
      onClose={onClose}
      title={listingId ? 'Report Listing' : 'Report User'}
      description="Help us keep Tekka safe by reporting inappropriate content or behavior."
      size="md"
    >
      <form onSubmit={handleSubmit}>
        {error && (
          <div className="mb-4 p-3 bg-red-50 border border-red-200 rounded-lg">
            <p className="text-sm text-red-600">{error}</p>
          </div>
        )}

        <Select
          label="What's the issue?"
          options={REPORT_REASONS}
          value={reason}
          onChange={(e) => setReason(e.target.value as ReportReason)}
          placeholder="Select a reason"
          required
        />

        <div className="mt-4">
          <Textarea
            label="Additional details (optional)"
            placeholder="Provide more context about this report..."
            value={description}
            onChange={(e) => setDescription(e.target.value)}
            rows={4}
          />
        </div>

        <ModalFooter>
          <Button type="button" variant="outline" onClick={onClose}>
            Cancel
          </Button>
          <Button type="submit" loading={loading}>
            Submit Report
          </Button>
        </ModalFooter>
      </form>
    </Modal>
  );
}
