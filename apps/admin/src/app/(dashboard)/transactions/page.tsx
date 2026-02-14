'use client';

import { useState, useEffect } from 'react';
import {
  MagnifyingGlassIcon,
  CurrencyDollarIcon,
  ExclamationTriangleIcon,
} from '@heroicons/react/24/outline';
import { api } from '@/lib/api';
import {
  Transaction,
  TransactionStatus,
  TRANSACTION_STATUS_LABELS,
} from '@/types';
import { Card, CardContent, CardHeader, CardTitle } from '@/components/ui/Card';
import { Button } from '@/components/ui/Button';
import { Badge, getStatusVariant } from '@/components/ui/Badge';
import {
  Table,
  TableHeader,
  TableBody,
  TableRow,
  TableHead,
  TableCell,
} from '@/components/ui/Table';

// Mock data for demonstration
const MOCK_TRANSACTIONS: Transaction[] = [
  {
    id: '1',
    buyerId: 'user1',
    sellerId: 'user2',
    listingId: 'list1',
    amount: 150000,
    status: 'COMPLETED',
    paymentMethod: 'Mobile Money',
    completedAt: '2024-01-10T10:00:00Z',
    createdAt: '2024-01-08T10:00:00Z',
    updatedAt: '2024-01-10T10:00:00Z',
    buyer: { id: 'user1', displayName: 'Grace Nambi', email: 'grace@example.com' } as any,
    seller: { id: 'user2', displayName: 'Sarah Kato', email: 'sarah@example.com' } as any,
    listing: { id: 'list1', title: 'Beautiful Kitenge Dress', price: 150000 } as any,
  },
  {
    id: '2',
    buyerId: 'user3',
    sellerId: 'user4',
    listingId: 'list2',
    amount: 85000,
    status: 'DISPUTED',
    paymentMethod: 'Mobile Money',
    createdAt: '2024-01-09T14:00:00Z',
    updatedAt: '2024-01-11T09:00:00Z',
    buyer: { id: 'user3', displayName: 'Peter Okello', email: 'peter@example.com' } as any,
    seller: { id: 'user4', displayName: 'Mary Ainomugisha', email: 'mary@example.com' } as any,
    listing: { id: 'list2', title: 'Designer Heels Size 38', price: 85000 } as any,
  },
  {
    id: '3',
    buyerId: 'user5',
    sellerId: 'user6',
    listingId: 'list3',
    amount: 200000,
    status: 'MEETUP_SCHEDULED',
    paymentMethod: 'Cash',
    createdAt: '2024-01-11T08:00:00Z',
    updatedAt: '2024-01-11T08:00:00Z',
    buyer: { id: 'user5', displayName: 'Joan Nakamya', email: 'joan@example.com' } as any,
    seller: { id: 'user6', displayName: 'Ruth Namutebi', email: 'ruth@example.com' } as any,
    listing: { id: 'list3', title: 'Gomesi Traditional Dress', price: 200000 } as any,
  },
];

const STATUS_OPTIONS: { value: string; label: string }[] = [
  { value: '', label: 'All Statuses' },
  { value: 'PENDING', label: 'Pending' },
  { value: 'PAYMENT_PENDING', label: 'Payment Pending' },
  { value: 'PAID', label: 'Paid' },
  { value: 'MEETUP_SCHEDULED', label: 'Meetup Scheduled' },
  { value: 'COMPLETED', label: 'Completed' },
  { value: 'CANCELLED', label: 'Cancelled' },
  { value: 'DISPUTED', label: 'Disputed' },
];

function getTransactionStatusVariant(status: TransactionStatus): 'success' | 'warning' | 'danger' | 'info' | 'default' {
  switch (status) {
    case 'COMPLETED':
      return 'success';
    case 'PENDING':
    case 'PAYMENT_PENDING':
    case 'MEETUP_SCHEDULED':
      return 'warning';
    case 'CANCELLED':
      return 'danger';
    case 'DISPUTED':
      return 'danger';
    case 'PAID':
      return 'info';
    default:
      return 'default';
  }
}

export default function TransactionsPage() {
  const [transactions, setTransactions] = useState<Transaction[]>([]);
  const [loading, setLoading] = useState(true);
  const [page, setPage] = useState(1);
  const [totalPages, setTotalPages] = useState(1);
  const [statusFilter, setStatusFilter] = useState('');
  const [searchQuery, setSearchQuery] = useState('');

  const [showCancelModal, setShowCancelModal] = useState(false);
  const [showDisputeModal, setShowDisputeModal] = useState(false);
  const [selectedTransaction, setSelectedTransaction] = useState<Transaction | null>(null);
  const [cancelReason, setCancelReason] = useState('');
  const [disputeResolution, setDisputeResolution] = useState('');
  const [refundAmount, setRefundAmount] = useState('');
  const [actionLoading, setActionLoading] = useState(false);

  useEffect(() => {
    loadTransactions();
  }, [page, statusFilter]);

  const loadTransactions = async () => {
    try {
      setLoading(true);
      const response = await api.getTransactions({
        page,
        limit: 10,
        status: statusFilter || undefined,
        search: searchQuery || undefined,
      });

      if (Array.isArray(response)) {
        setTransactions(response);
        setTotalPages(1);
      } else if (response.data) {
        setTransactions(response.data);
        setTotalPages(response.totalPages || 1);
      } else {
        // Use mock data if API fails
        setTransactions(MOCK_TRANSACTIONS);
        setTotalPages(1);
      }
    } catch (error) {
      console.error('Error loading transactions:', error);
      setTransactions(MOCK_TRANSACTIONS);
    } finally {
      setLoading(false);
    }
  };

  const handleCancelTransaction = async () => {
    if (!selectedTransaction || !cancelReason) return;

    setActionLoading(true);
    try {
      await api.cancelTransaction(selectedTransaction.id, cancelReason);
      await loadTransactions();
      setShowCancelModal(false);
      setSelectedTransaction(null);
      setCancelReason('');
    } catch (error) {
      console.error('Error cancelling transaction:', error);
    } finally {
      setActionLoading(false);
    }
  };

  const handleResolveDispute = async () => {
    if (!selectedTransaction || !disputeResolution) return;

    setActionLoading(true);
    try {
      await api.resolveDispute(
        selectedTransaction.id,
        disputeResolution,
        refundAmount ? parseInt(refundAmount) : undefined
      );
      await loadTransactions();
      setShowDisputeModal(false);
      setSelectedTransaction(null);
      setDisputeResolution('');
      setRefundAmount('');
    } catch (error) {
      console.error('Error resolving dispute:', error);
    } finally {
      setActionLoading(false);
    }
  };

  const formatPrice = (amount: number) => {
    return new Intl.NumberFormat('en-UG', {
      style: 'currency',
      currency: 'UGX',
      minimumFractionDigits: 0,
    }).format(amount);
  };

  const formatDate = (dateStr: string) => {
    return new Date(dateStr).toLocaleDateString('en-UG', {
      year: 'numeric',
      month: 'short',
      day: 'numeric',
    });
  };

  const disputedCount = transactions.filter(t => t.status === 'DISPUTED').length;

  return (
    <div className="space-y-6">
      <div className="flex items-center justify-between">
        <div>
          <h1 className="text-2xl font-bold text-gray-900">Transactions</h1>
          <p className="text-gray-500">Manage platform transactions and disputes</p>
        </div>
        {disputedCount > 0 && (
          <div className="flex items-center gap-2 px-4 py-2 bg-red-50 border border-red-200 rounded-lg">
            <ExclamationTriangleIcon className="w-5 h-5 text-red-500" />
            <span className="text-red-700 font-medium">{disputedCount} disputes pending</span>
          </div>
        )}
      </div>

      {/* Filters */}
      <Card>
        <CardContent className="py-4">
          <div className="flex flex-col sm:flex-row gap-4">
            <div className="flex-1">
              <div className="relative">
                <MagnifyingGlassIcon className="absolute left-3 top-1/2 -translate-y-1/2 w-5 h-5 text-gray-400" />
                <input
                  type="text"
                  placeholder="Search by buyer, seller, or listing..."
                  value={searchQuery}
                  onChange={(e) => setSearchQuery(e.target.value)}
                  onKeyDown={(e) => e.key === 'Enter' && loadTransactions()}
                  className="w-full pl-10 pr-4 py-2 border border-gray-300 rounded-lg focus:outline-none focus:ring-2 focus:ring-primary-500"
                />
              </div>
            </div>
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
          </div>
        </CardContent>
      </Card>

      {/* Transactions Table */}
      <Card>
        <CardHeader>
          <CardTitle>All Transactions</CardTitle>
        </CardHeader>
        <CardContent>
          {loading ? (
            <div className="flex justify-center py-8">
              <div className="animate-spin rounded-full h-8 w-8 border-b-2 border-primary-500"></div>
            </div>
          ) : transactions.length === 0 ? (
            <div className="text-center py-8">
              <CurrencyDollarIcon className="w-12 h-12 text-gray-300 mx-auto mb-4" />
              <p className="text-gray-500">No transactions found</p>
            </div>
          ) : (
            <>
              <Table>
                <TableHeader>
                  <TableRow>
                    <TableHead>Transaction</TableHead>
                    <TableHead className="hidden lg:table-cell">Buyer</TableHead>
                    <TableHead className="hidden lg:table-cell">Seller</TableHead>
                    <TableHead>Amount</TableHead>
                    <TableHead>Status</TableHead>
                    <TableHead>Date</TableHead>
                    <TableHead>Actions</TableHead>
                  </TableRow>
                </TableHeader>
                <TableBody>
                  {transactions.map((transaction) => (
                    <TableRow key={transaction.id}>
                      <TableCell>
                        <div>
                          <p className="font-medium text-gray-900">
                            {transaction.listing?.title || 'Unknown Listing'}
                          </p>
                          <p className="text-sm text-gray-500">
                            ID: {transaction.id.slice(0, 8)}...
                          </p>
                        </div>
                      </TableCell>
                      <TableCell className="hidden lg:table-cell">
                        <div>
                          <p className="font-medium">{transaction.buyer?.displayName || 'Unknown'}</p>
                          <p className="text-sm text-gray-500">{transaction.buyer?.email}</p>
                        </div>
                      </TableCell>
                      <TableCell className="hidden lg:table-cell">
                        <div>
                          <p className="font-medium">{transaction.seller?.displayName || 'Unknown'}</p>
                          <p className="text-sm text-gray-500">{transaction.seller?.email}</p>
                        </div>
                      </TableCell>
                      <TableCell>
                        <p className="font-bold text-gray-900">{formatPrice(transaction.amount)}</p>
                        {transaction.paymentMethod && (
                          <p className="text-sm text-gray-500">{transaction.paymentMethod}</p>
                        )}
                      </TableCell>
                      <TableCell>
                        <Badge variant={getTransactionStatusVariant(transaction.status)}>
                          {TRANSACTION_STATUS_LABELS[transaction.status]}
                        </Badge>
                      </TableCell>
                      <TableCell>
                        <p className="text-gray-900">{formatDate(transaction.createdAt)}</p>
                        {transaction.completedAt && (
                          <p className="text-sm text-green-600">
                            Completed {formatDate(transaction.completedAt)}
                          </p>
                        )}
                      </TableCell>
                      <TableCell>
                        <div className="flex gap-2">
                          {transaction.status === 'DISPUTED' && (
                            <Button
                              size="sm"
                              onClick={() => {
                                setSelectedTransaction(transaction);
                                setShowDisputeModal(true);
                              }}
                            >
                              Resolve
                            </Button>
                          )}
                          {!['COMPLETED', 'CANCELLED'].includes(transaction.status) && (
                            <Button
                              size="sm"
                              variant="danger"
                              onClick={() => {
                                setSelectedTransaction(transaction);
                                setShowCancelModal(true);
                              }}
                            >
                              Cancel
                            </Button>
                          )}
                        </div>
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

      {/* Cancel Modal */}
      {showCancelModal && selectedTransaction && (
        <div className="fixed inset-0 bg-black/50 flex items-center justify-center z-50">
          <div className="bg-white rounded-lg p-6 max-w-md w-full mx-4">
            <h3 className="text-lg font-bold text-gray-900 mb-4">Cancel Transaction</h3>
            <p className="text-gray-600 mb-4">
              Are you sure you want to cancel this transaction? This action cannot be undone.
            </p>
            <div className="mb-4">
              <label className="block text-sm font-medium text-gray-700 mb-1">
                Cancellation Reason
              </label>
              <textarea
                value={cancelReason}
                onChange={(e) => setCancelReason(e.target.value)}
                className="w-full px-3 py-2 border border-gray-300 rounded-lg focus:outline-none focus:ring-2 focus:ring-primary-500"
                rows={3}
                placeholder="Enter reason for cancellation..."
              />
            </div>
            <div className="flex justify-end gap-2">
              <Button
                variant="secondary"
                onClick={() => {
                  setShowCancelModal(false);
                  setSelectedTransaction(null);
                  setCancelReason('');
                }}
              >
                Cancel
              </Button>
              <Button
                variant="danger"
                onClick={handleCancelTransaction}
                disabled={!cancelReason || actionLoading}
              >
                {actionLoading ? 'Cancelling...' : 'Confirm Cancel'}
              </Button>
            </div>
          </div>
        </div>
      )}

      {/* Resolve Dispute Modal */}
      {showDisputeModal && selectedTransaction && (
        <div className="fixed inset-0 bg-black/50 flex items-center justify-center z-50">
          <div className="bg-white rounded-lg p-6 max-w-md w-full mx-4">
            <h3 className="text-lg font-bold text-gray-900 mb-4">Resolve Dispute</h3>
            <div className="space-y-4">
              <div>
                <p className="text-sm text-gray-600 mb-2">
                  Transaction: <strong>{selectedTransaction.listing?.title}</strong>
                </p>
                <p className="text-sm text-gray-600 mb-2">
                  Amount: <strong>{formatPrice(selectedTransaction.amount)}</strong>
                </p>
              </div>
              <div>
                <label className="block text-sm font-medium text-gray-700 mb-1">
                  Resolution Details
                </label>
                <textarea
                  value={disputeResolution}
                  onChange={(e) => setDisputeResolution(e.target.value)}
                  className="w-full px-3 py-2 border border-gray-300 rounded-lg focus:outline-none focus:ring-2 focus:ring-primary-500"
                  rows={3}
                  placeholder="Describe the resolution..."
                />
              </div>
              <div>
                <label className="block text-sm font-medium text-gray-700 mb-1">
                  Refund Amount (Optional)
                </label>
                <input
                  type="number"
                  value={refundAmount}
                  onChange={(e) => setRefundAmount(e.target.value)}
                  className="w-full px-3 py-2 border border-gray-300 rounded-lg focus:outline-none focus:ring-2 focus:ring-primary-500"
                  placeholder="Enter refund amount..."
                />
              </div>
            </div>
            <div className="flex justify-end gap-2 mt-6">
              <Button
                variant="secondary"
                onClick={() => {
                  setShowDisputeModal(false);
                  setSelectedTransaction(null);
                  setDisputeResolution('');
                  setRefundAmount('');
                }}
              >
                Cancel
              </Button>
              <Button
                onClick={handleResolveDispute}
                disabled={!disputeResolution || actionLoading}
              >
                {actionLoading ? 'Resolving...' : 'Resolve Dispute'}
              </Button>
            </div>
          </div>
        </div>
      )}
    </div>
  );
}
