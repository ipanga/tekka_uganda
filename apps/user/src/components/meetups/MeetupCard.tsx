'use client';

import { useState } from 'react';
import Link from 'next/link';
import {
  MapPinIcon,
  CalendarIcon,
  ClockIcon,
  CheckCircleIcon,
  XCircleIcon,
} from '@heroicons/react/24/outline';
import { Meetup, MEETUP_STATUS_LABELS } from '@/types';
import { formatDate, formatTime } from '@/lib/utils';
import { api } from '@/lib/api';
import { Button } from '@/components/ui/Button';
import { Badge } from '@/components/ui/Badge';
import { Card, CardContent } from '@/components/ui/Card';
import { Avatar } from '@/components/ui/Avatar';

interface MeetupCardProps {
  meetup: Meetup;
  currentUserId: string;
  onUpdate?: (meetup: Meetup) => void;
}

export function MeetupCard({ meetup, currentUserId, onUpdate }: MeetupCardProps) {
  const [loading, setLoading] = useState(false);

  const isProposer = meetup.proposerId === currentUserId;
  const otherUser = isProposer ? meetup.responder : meetup.proposer;
  const isPending = meetup.status === 'PROPOSED';
  const canRespond = isPending && !isProposer;

  const handleAccept = async () => {
    setLoading(true);
    try {
      const updated = await api.acceptMeetup(meetup.id);
      onUpdate?.(updated);
    } catch (error) {
      console.error('Error accepting meetup:', error);
    } finally {
      setLoading(false);
    }
  };

  const handleDecline = async () => {
    setLoading(true);
    try {
      const updated = await api.declineMeetup(meetup.id);
      onUpdate?.(updated);
    } catch (error) {
      console.error('Error declining meetup:', error);
    } finally {
      setLoading(false);
    }
  };

  const handleComplete = async () => {
    setLoading(true);
    try {
      const updated = await api.completeMeetup(meetup.id);
      onUpdate?.(updated);
    } catch (error) {
      console.error('Error completing meetup:', error);
    } finally {
      setLoading(false);
    }
  };

  const getStatusBadge = () => {
    switch (meetup.status) {
      case 'PROPOSED':
        return <Badge variant="warning">Pending</Badge>;
      case 'ACCEPTED':
        return <Badge variant="success">Confirmed</Badge>;
      case 'DECLINED':
        return <Badge variant="danger">Declined</Badge>;
      case 'COMPLETED':
        return <Badge variant="success">Completed</Badge>;
      case 'CANCELLED':
        return <Badge variant="default">Cancelled</Badge>;
      default:
        return <Badge>{MEETUP_STATUS_LABELS[meetup.status]}</Badge>;
    }
  };

  return (
    <Card>
      <CardContent className="py-4">
        <div className="flex items-start gap-4">
          {/* User Avatar */}
          <Avatar
            src={otherUser?.photoUrl}
            name={otherUser?.displayName}
            size="lg"
          />

          {/* Details */}
          <div className="flex-1 min-w-0">
            <div className="flex items-center justify-between gap-2">
              <Link href={`/profile/${otherUser?.id}`} className="hover:text-pink-600">
                <span className="font-medium text-gray-900">
                  {otherUser?.displayName || 'Unknown User'}
                </span>
              </Link>
              {getStatusBadge()}
            </div>

            {/* Location and Time */}
            <div className="mt-3 space-y-2">
              <div className="flex items-center gap-2 text-sm text-gray-600">
                <MapPinIcon className="w-4 h-4 text-gray-400" />
                <span>
                  {meetup.location ? (
                    <span className="flex items-center gap-1">
                      {meetup.locationName}
                      <Badge variant="success" size="sm">Safe Spot</Badge>
                    </span>
                  ) : (
                    meetup.locationName || 'Location TBD'
                  )}
                </span>
              </div>

              <div className="flex items-center gap-2 text-sm text-gray-600">
                <CalendarIcon className="w-4 h-4 text-gray-400" />
                <span>{formatDate(meetup.scheduledAt)}</span>
              </div>

              <div className="flex items-center gap-2 text-sm text-gray-600">
                <ClockIcon className="w-4 h-4 text-gray-400" />
                <span>{formatTime(meetup.scheduledAt)}</span>
              </div>
            </div>

            {/* Notes */}
            {meetup.notes && (
              <p className="mt-3 text-sm text-gray-600 bg-gray-50 p-3 rounded-lg">
                {meetup.notes}
              </p>
            )}

            {/* Actions */}
            {canRespond && (
              <div className="flex gap-2 mt-4">
                <Button
                  variant="outline"
                  size="sm"
                  onClick={handleDecline}
                  loading={loading}
                  className="text-red-600 hover:bg-red-50"
                >
                  <XCircleIcon className="w-4 h-4 mr-1" />
                  Decline
                </Button>
                <Button
                  size="sm"
                  onClick={handleAccept}
                  loading={loading}
                >
                  <CheckCircleIcon className="w-4 h-4 mr-1" />
                  Accept
                </Button>
              </div>
            )}

            {meetup.status === 'ACCEPTED' && (
              <div className="flex gap-2 mt-4">
                <Button
                  size="sm"
                  onClick={handleComplete}
                  loading={loading}
                  className="bg-green-600 hover:bg-green-700"
                >
                  <CheckCircleIcon className="w-4 h-4 mr-1" />
                  Mark as Completed
                </Button>
              </div>
            )}

            {isProposer && isPending && (
              <p className="text-sm text-gray-500 mt-3">
                Waiting for {otherUser?.displayName || 'them'} to respond...
              </p>
            )}
          </div>
        </div>
      </CardContent>
    </Card>
  );
}
