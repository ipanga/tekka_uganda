'use client';

import { useState, useEffect } from 'react';
import {
  BellIcon,
  PaperAirplaneIcon,
  UsersIcon,
  MegaphoneIcon,
} from '@heroicons/react/24/outline';
import { api } from '@/lib/api';
import { AdminNotification } from '@/types';
import { Card, CardContent, CardHeader, CardTitle } from '@/components/ui/Card';
import { Button } from '@/components/ui/Button';
import { Badge } from '@/components/ui/Badge';
import {
  Table,
  TableHeader,
  TableBody,
  TableRow,
  TableHead,
  TableCell,
} from '@/components/ui/Table';

// Mock data
const MOCK_NOTIFICATIONS: AdminNotification[] = [
  {
    id: '1',
    type: 'ANNOUNCEMENT',
    title: 'New Feature: Safe Meetup Locations',
    body: 'We\'ve added verified safe meetup locations across Kampala. Check them out when scheduling your next transaction!',
    targetType: 'ALL',
    sentAt: '2024-01-11T10:00:00Z',
    sentBy: 'admin1',
    status: 'SENT',
    recipientCount: 1250,
    readCount: 890,
    createdAt: '2024-01-11T09:00:00Z',
  },
  {
    id: '2',
    type: 'PROMOTION',
    title: 'Weekend Flash Sale',
    body: 'List your items this weekend and get featured on the homepage for FREE!',
    targetType: 'ROLE',
    targetRole: 'USER',
    sentAt: '2024-01-10T08:00:00Z',
    sentBy: 'admin1',
    status: 'SENT',
    recipientCount: 1180,
    readCount: 654,
    createdAt: '2024-01-09T16:00:00Z',
  },
  {
    id: '3',
    type: 'SYSTEM',
    title: 'Scheduled Maintenance',
    body: 'The platform will undergo maintenance on Saturday from 2AM-4AM. Thank you for your patience.',
    targetType: 'ALL',
    status: 'DRAFT',
    sentBy: 'admin1',
    recipientCount: 0,
    readCount: 0,
    createdAt: '2024-01-11T14:00:00Z',
  },
];

const NOTIFICATION_TYPES = [
  { value: 'ANNOUNCEMENT', label: 'Announcement', icon: MegaphoneIcon },
  { value: 'PROMOTION', label: 'Promotion', icon: BellIcon },
  { value: 'SYSTEM', label: 'System', icon: BellIcon },
  { value: 'ALERT', label: 'Alert', icon: BellIcon },
];

const TARGET_TYPES = [
  { value: 'ALL', label: 'All Users' },
  { value: 'ROLE', label: 'By Role' },
  { value: 'USER', label: 'Specific Users' },
];

export default function NotificationsPage() {
  const [notifications, setNotifications] = useState<AdminNotification[]>([]);
  const [loading, setLoading] = useState(true);
  const [page, setPage] = useState(1);
  const [totalPages, setTotalPages] = useState(1);
  const [showCreateModal, setShowCreateModal] = useState(false);

  // Form state
  const [formType, setFormType] = useState('ANNOUNCEMENT');
  const [formTitle, setFormTitle] = useState('');
  const [formBody, setFormBody] = useState('');
  const [formTargetType, setFormTargetType] = useState('ALL');
  const [formTargetRole, setFormTargetRole] = useState('USER');
  const [formSendNow, setFormSendNow] = useState(true);
  const [formLoading, setFormLoading] = useState(false);

  useEffect(() => {
    loadNotifications();
  }, [page]);

  const loadNotifications = async () => {
    try {
      setLoading(true);
      const response = await api.getAdminNotifications({ page, limit: 10 });

      if (Array.isArray(response)) {
        setNotifications(response);
        setTotalPages(1);
      } else if (response.data) {
        setNotifications(response.data);
        setTotalPages(response.totalPages || 1);
      } else {
        setNotifications(MOCK_NOTIFICATIONS);
        setTotalPages(1);
      }
    } catch (error) {
      console.error('Error loading notifications:', error);
      setNotifications(MOCK_NOTIFICATIONS);
    } finally {
      setLoading(false);
    }
  };

  const handleCreateNotification = async () => {
    if (!formTitle || !formBody) return;

    setFormLoading(true);
    try {
      await api.createNotificationCampaign({
        type: formType,
        title: formTitle,
        body: formBody,
        targetType: formTargetType,
        targetRole: formTargetType === 'ROLE' ? formTargetRole : undefined,
      });

      await loadNotifications();
      resetForm();
      setShowCreateModal(false);
    } catch (error) {
      console.error('Error creating notification:', error);
    } finally {
      setFormLoading(false);
    }
  };

  const handleSendNotification = async (id: string) => {
    try {
      await api.sendNotificationCampaign(id);
      await loadNotifications();
    } catch (error) {
      console.error('Error sending notification:', error);
    }
  };

  const resetForm = () => {
    setFormType('ANNOUNCEMENT');
    setFormTitle('');
    setFormBody('');
    setFormTargetType('ALL');
    setFormTargetRole('USER');
    setFormSendNow(true);
  };

  const formatDate = (dateStr: string) => {
    return new Date(dateStr).toLocaleDateString('en-UG', {
      year: 'numeric',
      month: 'short',
      day: 'numeric',
      hour: '2-digit',
      minute: '2-digit',
    });
  };

  const getStatusVariant = (status: string): 'success' | 'warning' | 'danger' | 'default' => {
    switch (status) {
      case 'SENT':
        return 'success';
      case 'DRAFT':
      case 'SCHEDULED':
        return 'warning';
      case 'FAILED':
        return 'danger';
      default:
        return 'default';
    }
  };

  const getTypeLabel = (type: string) => {
    return NOTIFICATION_TYPES.find(t => t.value === type)?.label || type;
  };

  const getTargetLabel = (notification: AdminNotification) => {
    if (notification.targetType === 'ALL') return 'All Users';
    if (notification.targetType === 'ROLE') return `${notification.targetRole}s`;
    return 'Selected Users';
  };

  return (
    <div className="space-y-6">
      <div className="flex items-center justify-between">
        <div>
          <h1 className="text-2xl font-bold text-gray-900">Notifications</h1>
          <p className="text-gray-500">Send announcements and alerts to users</p>
        </div>
        <Button onClick={() => setShowCreateModal(true)}>
          <PaperAirplaneIcon className="w-5 h-5 mr-2" />
          New Notification
        </Button>
      </div>

      {/* Stats */}
      <div className="grid grid-cols-1 md:grid-cols-3 gap-6">
        <Card>
          <CardContent className="py-4">
            <div className="flex items-center gap-4">
              <div className="p-3 bg-pink-100 rounded-lg">
                <PaperAirplaneIcon className="w-6 h-6 text-pink-600" />
              </div>
              <div>
                <p className="text-2xl font-bold text-gray-900">
                  {notifications.filter(n => n.status === 'SENT').length}
                </p>
                <p className="text-sm text-gray-500">Sent Notifications</p>
              </div>
            </div>
          </CardContent>
        </Card>
        <Card>
          <CardContent className="py-4">
            <div className="flex items-center gap-4">
              <div className="p-3 bg-yellow-100 rounded-lg">
                <BellIcon className="w-6 h-6 text-yellow-600" />
              </div>
              <div>
                <p className="text-2xl font-bold text-gray-900">
                  {notifications.filter(n => n.status === 'DRAFT').length}
                </p>
                <p className="text-sm text-gray-500">Draft Notifications</p>
              </div>
            </div>
          </CardContent>
        </Card>
        <Card>
          <CardContent className="py-4">
            <div className="flex items-center gap-4">
              <div className="p-3 bg-green-100 rounded-lg">
                <UsersIcon className="w-6 h-6 text-green-600" />
              </div>
              <div>
                <p className="text-2xl font-bold text-gray-900">
                  {notifications.reduce((sum, n) => sum + n.recipientCount, 0).toLocaleString()}
                </p>
                <p className="text-sm text-gray-500">Total Recipients</p>
              </div>
            </div>
          </CardContent>
        </Card>
      </div>

      {/* Notifications Table */}
      <Card>
        <CardHeader>
          <CardTitle>Notification History</CardTitle>
        </CardHeader>
        <CardContent>
          {loading ? (
            <div className="flex justify-center py-8">
              <div className="animate-spin rounded-full h-8 w-8 border-b-2 border-pink-600"></div>
            </div>
          ) : notifications.length === 0 ? (
            <div className="text-center py-8">
              <BellIcon className="w-12 h-12 text-gray-300 mx-auto mb-4" />
              <p className="text-gray-500">No notifications yet</p>
            </div>
          ) : (
            <>
              <Table>
                <TableHeader>
                  <TableRow>
                    <TableHead>Notification</TableHead>
                    <TableHead>Type</TableHead>
                    <TableHead>Target</TableHead>
                    <TableHead>Status</TableHead>
                    <TableHead>Reach</TableHead>
                    <TableHead>Date</TableHead>
                    <TableHead>Actions</TableHead>
                  </TableRow>
                </TableHeader>
                <TableBody>
                  {notifications.map((notification) => (
                    <TableRow key={notification.id}>
                      <TableCell>
                        <div className="max-w-xs">
                          <p className="font-medium text-gray-900 truncate">
                            {notification.title}
                          </p>
                          <p className="text-sm text-gray-500 truncate">
                            {notification.body}
                          </p>
                        </div>
                      </TableCell>
                      <TableCell>
                        <Badge variant="info">{getTypeLabel(notification.type)}</Badge>
                      </TableCell>
                      <TableCell>
                        <span className="text-gray-900">{getTargetLabel(notification)}</span>
                      </TableCell>
                      <TableCell>
                        <Badge variant={getStatusVariant(notification.status)}>
                          {notification.status}
                        </Badge>
                      </TableCell>
                      <TableCell>
                        <div>
                          <p className="font-medium">{notification.recipientCount.toLocaleString()}</p>
                          {notification.status === 'SENT' && (
                            <p className="text-sm text-gray-500">
                              {notification.readCount.toLocaleString()} read (
                              {notification.recipientCount > 0
                                ? Math.round((notification.readCount / notification.recipientCount) * 100)
                                : 0}
                              %)
                            </p>
                          )}
                        </div>
                      </TableCell>
                      <TableCell>
                        <p className="text-gray-900">
                          {notification.sentAt
                            ? formatDate(notification.sentAt)
                            : formatDate(notification.createdAt)}
                        </p>
                      </TableCell>
                      <TableCell>
                        {notification.status === 'DRAFT' && (
                          <Button
                            size="sm"
                            onClick={() => handleSendNotification(notification.id)}
                          >
                            Send
                          </Button>
                        )}
                      </TableCell>
                    </TableRow>
                  ))}
                </TableBody>
              </Table>

              {/* Pagination */}
              <div className="flex justify-between items-center mt-4">
                <p className="text-sm text-gray-500">
                  Page {page} of {totalPages}
                </p>
                <div className="flex gap-2">
                  <Button
                    variant="secondary"
                    size="sm"
                    onClick={() => setPage((p) => Math.max(1, p - 1))}
                    disabled={page === 1}
                  >
                    Previous
                  </Button>
                  <Button
                    variant="secondary"
                    size="sm"
                    onClick={() => setPage((p) => Math.min(totalPages, p + 1))}
                    disabled={page === totalPages}
                  >
                    Next
                  </Button>
                </div>
              </div>
            </>
          )}
        </CardContent>
      </Card>

      {/* Create Notification Modal */}
      {showCreateModal && (
        <div className="fixed inset-0 bg-black/50 flex items-center justify-center z-50">
          <div className="bg-white rounded-lg p-6 max-w-lg w-full mx-4 max-h-[90vh] overflow-y-auto">
            <h3 className="text-lg font-bold text-gray-900 mb-4">Create Notification</h3>

            <div className="space-y-4">
              <div>
                <label className="block text-sm font-medium text-gray-700 mb-1">Type</label>
                <select
                  value={formType}
                  onChange={(e) => setFormType(e.target.value)}
                  className="w-full px-3 py-2 border border-gray-300 rounded-lg focus:outline-none focus:ring-2 focus:ring-pink-500"
                >
                  {NOTIFICATION_TYPES.map((type) => (
                    <option key={type.value} value={type.value}>
                      {type.label}
                    </option>
                  ))}
                </select>
              </div>

              <div>
                <label className="block text-sm font-medium text-gray-700 mb-1">Title</label>
                <input
                  type="text"
                  value={formTitle}
                  onChange={(e) => setFormTitle(e.target.value)}
                  className="w-full px-3 py-2 border border-gray-300 rounded-lg focus:outline-none focus:ring-2 focus:ring-pink-500"
                  placeholder="Notification title..."
                />
              </div>

              <div>
                <label className="block text-sm font-medium text-gray-700 mb-1">Message</label>
                <textarea
                  value={formBody}
                  onChange={(e) => setFormBody(e.target.value)}
                  className="w-full px-3 py-2 border border-gray-300 rounded-lg focus:outline-none focus:ring-2 focus:ring-pink-500"
                  rows={4}
                  placeholder="Notification message..."
                />
              </div>

              <div>
                <label className="block text-sm font-medium text-gray-700 mb-1">Target Audience</label>
                <select
                  value={formTargetType}
                  onChange={(e) => setFormTargetType(e.target.value)}
                  className="w-full px-3 py-2 border border-gray-300 rounded-lg focus:outline-none focus:ring-2 focus:ring-pink-500"
                >
                  {TARGET_TYPES.map((type) => (
                    <option key={type.value} value={type.value}>
                      {type.label}
                    </option>
                  ))}
                </select>
              </div>

              {formTargetType === 'ROLE' && (
                <div>
                  <label className="block text-sm font-medium text-gray-700 mb-1">Role</label>
                  <select
                    value={formTargetRole}
                    onChange={(e) => setFormTargetRole(e.target.value)}
                    className="w-full px-3 py-2 border border-gray-300 rounded-lg focus:outline-none focus:ring-2 focus:ring-pink-500"
                  >
                    <option value="USER">Users</option>
                    <option value="ADMIN">Admins</option>
                    <option value="MODERATOR">Moderators</option>
                  </select>
                </div>
              )}

              <div className="flex items-center gap-2">
                <input
                  type="checkbox"
                  id="sendNow"
                  checked={formSendNow}
                  onChange={(e) => setFormSendNow(e.target.checked)}
                  className="rounded border-gray-300 text-pink-600 focus:ring-pink-500"
                />
                <label htmlFor="sendNow" className="text-sm text-gray-700">
                  Send immediately after creation
                </label>
              </div>
            </div>

            <div className="flex justify-end gap-2 mt-6">
              <Button
                variant="secondary"
                onClick={() => {
                  setShowCreateModal(false);
                  resetForm();
                }}
              >
                Cancel
              </Button>
              <Button
                onClick={handleCreateNotification}
                disabled={!formTitle || !formBody || formLoading}
              >
                {formLoading ? 'Creating...' : formSendNow ? 'Create & Send' : 'Save as Draft'}
              </Button>
            </div>
          </div>
        </div>
      )}
    </div>
  );
}
