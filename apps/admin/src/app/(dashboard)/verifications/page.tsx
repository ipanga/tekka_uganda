'use client';

import { useState, useEffect } from 'react';
import {
  ShieldCheckIcon,
  DocumentCheckIcon,
  XMarkIcon,
  CheckIcon,
  EyeIcon,
} from '@heroicons/react/24/outline';
import { api } from '@/lib/api';
import {
  VerificationRequest,
  VerificationStatus,
  VerificationType,
  VERIFICATION_STATUS_LABELS,
  VERIFICATION_TYPE_LABELS,
} from '@/types';
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

// Mock data for demonstration
const MOCK_VERIFICATIONS: VerificationRequest[] = [
  {
    id: '1',
    userId: 'user1',
    type: 'IDENTITY',
    status: 'PENDING',
    documentType: 'National ID',
    documentUrl: 'https://example.com/doc1.jpg',
    selfieUrl: 'https://example.com/selfie1.jpg',
    createdAt: '2024-01-11T10:00:00Z',
    updatedAt: '2024-01-11T10:00:00Z',
    user: { id: 'user1', displayName: 'Grace Nambi', email: 'grace@example.com', phoneNumber: '+256700123456' } as any,
  },
  {
    id: '2',
    userId: 'user2',
    type: 'IDENTITY',
    status: 'PENDING',
    documentType: 'Passport',
    documentUrl: 'https://example.com/doc2.jpg',
    selfieUrl: 'https://example.com/selfie2.jpg',
    createdAt: '2024-01-10T14:00:00Z',
    updatedAt: '2024-01-10T14:00:00Z',
    user: { id: 'user2', displayName: 'Peter Okello', email: 'peter@example.com', phoneNumber: '+256700234567' } as any,
  },
  {
    id: '3',
    userId: 'user3',
    type: 'ADDRESS',
    status: 'APPROVED',
    documentType: 'Utility Bill',
    documentUrl: 'https://example.com/doc3.jpg',
    notes: 'Verified address matches user profile',
    reviewedAt: '2024-01-09T16:00:00Z',
    reviewedBy: 'admin1',
    createdAt: '2024-01-08T10:00:00Z',
    updatedAt: '2024-01-09T16:00:00Z',
    user: { id: 'user3', displayName: 'Sarah Kato', email: 'sarah@example.com', phoneNumber: '+256700345678' } as any,
  },
  {
    id: '4',
    userId: 'user4',
    type: 'IDENTITY',
    status: 'REJECTED',
    documentType: 'National ID',
    documentUrl: 'https://example.com/doc4.jpg',
    selfieUrl: 'https://example.com/selfie4.jpg',
    rejectionReason: 'Document image is blurry and unreadable',
    reviewedAt: '2024-01-07T11:00:00Z',
    reviewedBy: 'admin1',
    createdAt: '2024-01-06T09:00:00Z',
    updatedAt: '2024-01-07T11:00:00Z',
    user: { id: 'user4', displayName: 'Mary Ainomugisha', email: 'mary@example.com', phoneNumber: '+256700456789' } as any,
  },
];

const STATUS_OPTIONS = [
  { value: '', label: 'All Statuses' },
  { value: 'PENDING', label: 'Pending' },
  { value: 'APPROVED', label: 'Approved' },
  { value: 'REJECTED', label: 'Rejected' },
];

const TYPE_OPTIONS = [
  { value: '', label: 'All Types' },
  { value: 'IDENTITY', label: 'Identity' },
  { value: 'ADDRESS', label: 'Address' },
  { value: 'PHONE', label: 'Phone' },
  { value: 'EMAIL', label: 'Email' },
];

function getVerificationStatusVariant(status: VerificationStatus): 'success' | 'warning' | 'danger' | 'default' {
  switch (status) {
    case 'APPROVED':
      return 'success';
    case 'PENDING':
      return 'warning';
    case 'REJECTED':
    case 'EXPIRED':
      return 'danger';
    default:
      return 'default';
  }
}

export default function VerificationsPage() {
  const [verifications, setVerifications] = useState<VerificationRequest[]>([]);
  const [loading, setLoading] = useState(true);
  const [page, setPage] = useState(1);
  const [totalPages, setTotalPages] = useState(1);
  const [statusFilter, setStatusFilter] = useState('');
  const [typeFilter, setTypeFilter] = useState('');

  const [showApproveModal, setShowApproveModal] = useState(false);
  const [showRejectModal, setShowRejectModal] = useState(false);
  const [showViewModal, setShowViewModal] = useState(false);
  const [selectedVerification, setSelectedVerification] = useState<VerificationRequest | null>(null);
  const [approvalNotes, setApprovalNotes] = useState('');
  const [rejectionReason, setRejectionReason] = useState('');
  const [actionLoading, setActionLoading] = useState(false);

  useEffect(() => {
    loadVerifications();
  }, [page, statusFilter, typeFilter]);

  const loadVerifications = async () => {
    try {
      setLoading(true);
      const response = await api.getVerificationRequests({
        page,
        limit: 10,
        status: statusFilter || undefined,
        type: typeFilter || undefined,
      });

      if (Array.isArray(response)) {
        setVerifications(response);
        setTotalPages(1);
      } else if (response.data) {
        setVerifications(response.data);
        setTotalPages(response.totalPages || 1);
      } else {
        setVerifications(MOCK_VERIFICATIONS);
        setTotalPages(1);
      }
    } catch (error) {
      console.error('Error loading verifications:', error);
      setVerifications(MOCK_VERIFICATIONS);
    } finally {
      setLoading(false);
    }
  };

  const handleApprove = async () => {
    if (!selectedVerification) return;

    setActionLoading(true);
    try {
      await api.approveVerification(selectedVerification.id, approvalNotes || undefined);
      await loadVerifications();
      setShowApproveModal(false);
      setSelectedVerification(null);
      setApprovalNotes('');
    } catch (error) {
      console.error('Error approving verification:', error);
    } finally {
      setActionLoading(false);
    }
  };

  const handleReject = async () => {
    if (!selectedVerification || !rejectionReason) return;

    setActionLoading(true);
    try {
      await api.rejectVerification(selectedVerification.id, rejectionReason);
      await loadVerifications();
      setShowRejectModal(false);
      setSelectedVerification(null);
      setRejectionReason('');
    } catch (error) {
      console.error('Error rejecting verification:', error);
    } finally {
      setActionLoading(false);
    }
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

  const pendingCount = verifications.filter(v => v.status === 'PENDING').length;

  return (
    <div className="space-y-6">
      <div className="flex items-center justify-between">
        <div>
          <h1 className="text-2xl font-bold text-gray-900">Verifications</h1>
          <p className="text-gray-500">Review and manage user verification requests</p>
        </div>
        {pendingCount > 0 && (
          <div className="flex items-center gap-2 px-4 py-2 bg-yellow-50 border border-yellow-200 rounded-lg">
            <ShieldCheckIcon className="w-5 h-5 text-yellow-500" />
            <span className="text-yellow-700 font-medium">{pendingCount} pending review</span>
          </div>
        )}
      </div>

      {/* Filters */}
      <Card>
        <CardContent className="py-4">
          <div className="flex flex-col sm:flex-row gap-4">
            <select
              value={statusFilter}
              onChange={(e) => setStatusFilter(e.target.value)}
              className="px-4 py-2 border border-gray-300 rounded-lg focus:outline-none focus:ring-2 focus:ring-primary-500"
            >
              {STATUS_OPTIONS.map((option) => (
                <option key={option.value} value={option.value}>
                  {option.label}
                </option>
              ))}
            </select>
            <select
              value={typeFilter}
              onChange={(e) => setTypeFilter(e.target.value)}
              className="px-4 py-2 border border-gray-300 rounded-lg focus:outline-none focus:ring-2 focus:ring-primary-500"
            >
              {TYPE_OPTIONS.map((option) => (
                <option key={option.value} value={option.value}>
                  {option.label}
                </option>
              ))}
            </select>
          </div>
        </CardContent>
      </Card>

      {/* Verifications Table */}
      <Card>
        <CardHeader>
          <CardTitle>Verification Requests</CardTitle>
        </CardHeader>
        <CardContent>
          {loading ? (
            <div className="flex justify-center py-8">
              <div className="animate-spin rounded-full h-8 w-8 border-b-2 border-primary-500"></div>
            </div>
          ) : verifications.length === 0 ? (
            <div className="text-center py-8">
              <DocumentCheckIcon className="w-12 h-12 text-gray-300 mx-auto mb-4" />
              <p className="text-gray-500">No verification requests found</p>
            </div>
          ) : (
            <>
              <Table>
                <TableHeader>
                  <TableRow>
                    <TableHead>User</TableHead>
                    <TableHead>Type</TableHead>
                    <TableHead>Document</TableHead>
                    <TableHead>Status</TableHead>
                    <TableHead>Submitted</TableHead>
                    <TableHead>Actions</TableHead>
                  </TableRow>
                </TableHeader>
                <TableBody>
                  {verifications.map((verification) => (
                    <TableRow key={verification.id}>
                      <TableCell>
                        <div>
                          <p className="font-medium text-gray-900">
                            {verification.user?.displayName || 'Unknown'}
                          </p>
                          <p className="text-sm text-gray-500">{verification.user?.email}</p>
                          <p className="text-sm text-gray-500">{verification.user?.phoneNumber}</p>
                        </div>
                      </TableCell>
                      <TableCell>
                        <Badge variant="info">
                          {VERIFICATION_TYPE_LABELS[verification.type]}
                        </Badge>
                      </TableCell>
                      <TableCell>
                        <p className="font-medium">{verification.documentType || 'N/A'}</p>
                        {verification.documentUrl && (
                          <button
                            onClick={() => {
                              setSelectedVerification(verification);
                              setShowViewModal(true);
                            }}
                            className="text-sm text-primary-500 hover:underline flex items-center gap-1"
                          >
                            <EyeIcon className="w-4 h-4" />
                            View Documents
                          </button>
                        )}
                      </TableCell>
                      <TableCell>
                        <Badge variant={getVerificationStatusVariant(verification.status)}>
                          {VERIFICATION_STATUS_LABELS[verification.status]}
                        </Badge>
                        {verification.rejectionReason && (
                          <p className="text-xs text-red-500 mt-1">
                            {verification.rejectionReason}
                          </p>
                        )}
                      </TableCell>
                      <TableCell>
                        <p className="text-gray-900">{formatDate(verification.createdAt)}</p>
                        {verification.reviewedAt && (
                          <p className="text-sm text-gray-500">
                            Reviewed: {formatDate(verification.reviewedAt)}
                          </p>
                        )}
                      </TableCell>
                      <TableCell>
                        {verification.status === 'PENDING' && (
                          <div className="flex gap-2">
                            <Button
                              size="sm"
                              onClick={() => {
                                setSelectedVerification(verification);
                                setShowApproveModal(true);
                              }}
                            >
                              <CheckIcon className="w-4 h-4 mr-1" />
                              Approve
                            </Button>
                            <Button
                              size="sm"
                              variant="danger"
                              onClick={() => {
                                setSelectedVerification(verification);
                                setShowRejectModal(true);
                              }}
                            >
                              <XMarkIcon className="w-4 h-4 mr-1" />
                              Reject
                            </Button>
                          </div>
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

      {/* View Documents Modal */}
      {showViewModal && selectedVerification && (
        <div className="fixed inset-0 bg-black/50 flex items-center justify-center z-50">
          <div className="bg-white rounded-lg p-6 max-w-2xl w-full mx-4 max-h-[90vh] overflow-y-auto">
            <div className="flex items-center justify-between mb-4">
              <h3 className="text-lg font-bold text-gray-900">Verification Documents</h3>
              <button
                onClick={() => {
                  setShowViewModal(false);
                  setSelectedVerification(null);
                }}
                className="p-2 hover:bg-gray-100 rounded-lg"
              >
                <XMarkIcon className="w-5 h-5" />
              </button>
            </div>

            <div className="space-y-4">
              <div>
                <p className="text-sm font-medium text-gray-700 mb-2">User Information</p>
                <div className="bg-gray-50 p-4 rounded-lg">
                  <p><strong>Name:</strong> {selectedVerification.user?.displayName}</p>
                  <p><strong>Email:</strong> {selectedVerification.user?.email}</p>
                  <p><strong>Phone:</strong> {selectedVerification.user?.phoneNumber}</p>
                </div>
              </div>

              <div>
                <p className="text-sm font-medium text-gray-700 mb-2">Document Type</p>
                <p className="text-gray-900">{selectedVerification.documentType}</p>
              </div>

              {selectedVerification.documentUrl && (
                <div>
                  <p className="text-sm font-medium text-gray-700 mb-2">ID Document</p>
                  <div className="border border-gray-200 rounded-lg p-4 bg-gray-50">
                    <p className="text-sm text-gray-500 mb-2">Document URL:</p>
                    <a
                      href={selectedVerification.documentUrl}
                      target="_blank"
                      rel="noopener noreferrer"
                      className="text-primary-500 hover:underline break-all"
                    >
                      {selectedVerification.documentUrl}
                    </a>
                  </div>
                </div>
              )}

              {selectedVerification.selfieUrl && (
                <div>
                  <p className="text-sm font-medium text-gray-700 mb-2">Selfie with Document</p>
                  <div className="border border-gray-200 rounded-lg p-4 bg-gray-50">
                    <p className="text-sm text-gray-500 mb-2">Selfie URL:</p>
                    <a
                      href={selectedVerification.selfieUrl}
                      target="_blank"
                      rel="noopener noreferrer"
                      className="text-primary-500 hover:underline break-all"
                    >
                      {selectedVerification.selfieUrl}
                    </a>
                  </div>
                </div>
              )}

              {selectedVerification.notes && (
                <div>
                  <p className="text-sm font-medium text-gray-700 mb-2">Notes</p>
                  <p className="text-gray-600">{selectedVerification.notes}</p>
                </div>
              )}
            </div>

            {selectedVerification.status === 'PENDING' && (
              <div className="flex justify-end gap-2 mt-6 pt-4 border-t">
                <Button
                  variant="danger"
                  onClick={() => {
                    setShowViewModal(false);
                    setShowRejectModal(true);
                  }}
                >
                  Reject
                </Button>
                <Button
                  onClick={() => {
                    setShowViewModal(false);
                    setShowApproveModal(true);
                  }}
                >
                  Approve
                </Button>
              </div>
            )}
          </div>
        </div>
      )}

      {/* Approve Modal */}
      {showApproveModal && selectedVerification && (
        <div className="fixed inset-0 bg-black/50 flex items-center justify-center z-50">
          <div className="bg-white rounded-lg p-6 max-w-md w-full mx-4">
            <h3 className="text-lg font-bold text-gray-900 mb-4">Approve Verification</h3>
            <p className="text-gray-600 mb-4">
              Approve {VERIFICATION_TYPE_LABELS[selectedVerification.type].toLowerCase()} verification for{' '}
              <strong>{selectedVerification.user?.displayName}</strong>?
            </p>
            <div className="mb-4">
              <label className="block text-sm font-medium text-gray-700 mb-1">
                Notes (Optional)
              </label>
              <textarea
                value={approvalNotes}
                onChange={(e) => setApprovalNotes(e.target.value)}
                className="w-full px-3 py-2 border border-gray-300 rounded-lg focus:outline-none focus:ring-2 focus:ring-primary-500"
                rows={3}
                placeholder="Add any notes..."
              />
            </div>
            <div className="flex justify-end gap-2">
              <Button
                variant="secondary"
                onClick={() => {
                  setShowApproveModal(false);
                  setSelectedVerification(null);
                  setApprovalNotes('');
                }}
              >
                Cancel
              </Button>
              <Button onClick={handleApprove} disabled={actionLoading}>
                {actionLoading ? 'Approving...' : 'Approve'}
              </Button>
            </div>
          </div>
        </div>
      )}

      {/* Reject Modal */}
      {showRejectModal && selectedVerification && (
        <div className="fixed inset-0 bg-black/50 flex items-center justify-center z-50">
          <div className="bg-white rounded-lg p-6 max-w-md w-full mx-4">
            <h3 className="text-lg font-bold text-gray-900 mb-4">Reject Verification</h3>
            <p className="text-gray-600 mb-4">
              Reject {VERIFICATION_TYPE_LABELS[selectedVerification.type].toLowerCase()} verification for{' '}
              <strong>{selectedVerification.user?.displayName}</strong>?
            </p>
            <div className="mb-4">
              <label className="block text-sm font-medium text-gray-700 mb-1">
                Rejection Reason <span className="text-red-500">*</span>
              </label>
              <textarea
                value={rejectionReason}
                onChange={(e) => setRejectionReason(e.target.value)}
                className="w-full px-3 py-2 border border-gray-300 rounded-lg focus:outline-none focus:ring-2 focus:ring-primary-500"
                rows={3}
                placeholder="Explain why this verification is being rejected..."
              />
            </div>
            <div className="flex justify-end gap-2">
              <Button
                variant="secondary"
                onClick={() => {
                  setShowRejectModal(false);
                  setSelectedVerification(null);
                  setRejectionReason('');
                }}
              >
                Cancel
              </Button>
              <Button
                variant="danger"
                onClick={handleReject}
                disabled={!rejectionReason || actionLoading}
              >
                {actionLoading ? 'Rejecting...' : 'Reject'}
              </Button>
            </div>
          </div>
        </div>
      )}
    </div>
  );
}
